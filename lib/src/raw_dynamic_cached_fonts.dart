part of dynamic_cached_fonts;

/// A more customizable implementation of [DynamicCachedFonts] which uses
/// multiple static methods to download, cache, load and remove font assets.
///
/// [DynamicCachedFonts] is a concrete implementation of this class.
abstract class RawDynamicCachedFonts {
  const RawDynamicCachedFonts._();

  /// Downloads and caches font from the [url] with the given configuration.
  ///
  /// - **REQUIRED** The [url] property is used to specify the download url
  ///   for the required font. It should be a valid http/https url which points to
  ///   a font file.
  ///   Currently, only OpenType (OTF) and TrueType (TTF) fonts are supported.
  ///
  /// - The [maxCacheObjects] property defines how large the cache is allowed to be.
  ///   If there are more files the files that haven't been used for the longest
  ///   time will be removed.
  ///
  ///   It is used to specify the cache configuration, [Config],
  ///   for [CacheManager].
  ///
  /// - [cacheStalePeriod] is the time duration in which
  ///   a cache object is considered 'stale'. When a file is cached but
  ///   not being used for a certain time the file will be deleted
  ///
  ///   It is used to specify the cache configuration, [Config],
  ///   for [CacheManager].

  /// Same as cacheFont, but not using cache manager
  static Future<ByteData> cacheFont(
    String url, {
    required int maxCacheObjects,
    required Duration cacheStalePeriod,
  }) async {
    final String cacheKey = Utils.fileName(url);
    final uri = Uri.tryParse(url);
    if (uri == null) {
      throw Exception('Invalid fontUrl: $url');
    }

    Response response;
    try {
      response = await get(uri);
    } catch (e) {
      throw Exception('Failed to load font with url: $url');
    }
    if (response.statusCode == 200) {
      await saveFontToDeviceFileSystem(cacheKey, response.bodyBytes);

      final file = await localFile(cacheKey);
      Utils.verifyFileExtension(file);

      return ByteData.view(response.bodyBytes.buffer);
    } else {
      // If that call was not successful, throw an error.
      throw Exception('Failed to load font with url: $url');
    }
  }

  /// Downloads and caches font from the [url] with the given configuration.
  /// A single [FileInfo] object is returned as a stream and the download
  /// progress is can be listened to using the [progressListener] callback.
  ///
  /// If this method is called multiple times for the same font [url], then the
  /// cached file is returned with no progress events being emitted to the
  /// [progressListener] callback.
  ///
  /// - **REQUIRED** The [url] property is used to specify the download url
  ///   for the required font. It should be a valid http/https url which points to
  ///   a font file.
  ///   Currently, only OpenType (OTF) and TrueType (TTF) fonts are supported.
  ///
  /// - The [maxCacheObjects] property defines how large the cache is allowed to be.
  ///   If there are more files the files that haven't been used for the longest
  ///   time will be removed.
  ///
  ///   It is used to specify the cache configuration, [Config],
  ///   for [CacheManager].
  ///
  /// - [cacheStalePeriod] is the time duration in which
  ///   a cache object is considered 'stale'. When a file is cached but
  ///   not being used for a certain time the file will be deleted
  ///
  ///   It is used to specify the cache configuration, [Config],
  ///   for [CacheManager].
  ///
  /// - The [progressListener] property is used to listen to the download progress
  ///   of the font. It is called with a [DownloadProgress] object which contains
  ///   information about the download progress.
  static Stream<ByteData> cacheFontStream(
    String url, {
    required int maxCacheObjects,
    required Duration cacheStalePeriod,
    required DownloadProgressListener? progressListener,
  }) async* {
    WidgetsFlutterBinding.ensureInitialized();

    final String cacheKey = Utils.fileName(url);
    final uri = Uri.tryParse(url);
    if (uri == null) {
      throw Exception('Invalid fontUrl: $url');
    }

    final client = Client();

    StreamedResponse response;

    try {
      response = await client.send(Request('GET', uri));
    } catch (e) {
      throw Exception('Failed to load font with url: $url');
    }

    final length = response.contentLength ?? 0;
    List<int> bodyBytes = [];
    int received = 0;

    Stream<List<int>> stream2 = response.stream.transform(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          bodyBytes = data;
          received += data.length;

          print(received);

          sink.add(data);

          final progress = (received / length) * 100;
          progressListener?.call(progress);

          devLog([
            'Download progress: $progress% for ${Utils.getFileNameOrUrl(cacheKey)}'
          ]);
        },
        handleError: (error, stack, sink) {
          // If that call was not successful, throw an error.
          throw Exception('Failed to load font with url: $url');
        },
        // ignore: void_checks
        handleDone: (sink) async* {
          sink.close();

          await saveFontToDeviceFileSystem(cacheKey, bodyBytes);

          final file = await localFile(cacheKey);
          Utils.verifyFileExtension(file);

          final buffer = toUint8List(bodyBytes);
          yield ByteData.view(buffer.buffer);
        },
      ),
    );
  }

  /// Checks whether the given [url] can be loaded directly from cache.
  ///
  /// - **REQUIRED** The [url] property is used to specify the url
  ///   for the required font. It should be a valid http/https url which points to
  ///   a font file. The [url] should match the url passed to [cacheFont].
  static Future<bool> canLoadFont(String url) async {
    WidgetsFlutterBinding.ensureInitialized();

    final String cacheKey = Utils.fileName(url);

    final cachedFontBytes = await loadFontFromDeviceFileSystem(cacheKey);

    return cachedFontBytes != null;
  }

  /// Fetches the given [url] from cache and loads it as an asset.
  ///
  /// Call [canLoadFont] before calling this method to make sure the font is
  /// available in cache.
  ///
  /// - **REQUIRED** The [url] property is used to specify the url
  ///   for the required font. It should be a valid http/https url which points to
  ///   a font file. The [url] should match the url passed to [cacheFont].
  ///
  /// - **REQUIRED** The [fontFamily] property is used to specify the name
  ///   of the font family which is to be used as [TextStyle.fontFamily].

  static Future<ByteData?> loadCachedFont(
    String url, {
    required String fontFamily,
    @visibleForTesting FontLoader? fontLoader,
  }) async {
    fontLoader ??= FontLoader(fontFamily);

    WidgetsFlutterBinding.ensureInitialized();

    final String cacheKey = Utils.fileName(url);
    final cachedFontBytes = loadFontFromDeviceFileSystem(cacheKey);
    final cachedFontBytesValue = await cachedFontBytes;
    if (cachedFontBytesValue != null) {
      fontLoader.addFont(
        Future<ByteData>.value(cachedFontBytesValue),
      );

      await fontLoader.load();

      devLog(<String>[
        'Font has been loaded!',
      ]);
    }

    return cachedFontBytes;
  }

  /// Fetches the given [urls] from cache and loads them into the engine to be used.
  ///
  /// [urls] should be a series of related font assets,
  /// each of which defines how to render a specific [FontWeight] and [FontStyle]
  /// within the family.
  ///
  /// Call [canLoadFont] before calling this method to make sure the font is
  /// available in cache.
  ///
  /// - **REQUIRED** The [urls] property is used to specify the urls
  ///   for the required family. It should be a list of valid http/https urls
  ///   which point to font files.
  ///   Every url in [urls] should be loaded into cache by calling [cacheFont] for each.
  ///
  /// - **REQUIRED** The [fontFamily] property is used to specify the name
  ///   of the font family which is to be used as [TextStyle.fontFamily].
  /// Same as loadCachedFamily, but not using cache manager
  static Future<Iterable<ByteData>> loadCachedFamily(
    List<String> urls, {
    required String fontFamily,
    @visibleForTesting FontLoader? fontLoader,
  }) async {
    fontLoader ??= FontLoader(fontFamily);

    WidgetsFlutterBinding.ensureInitialized();

    final Iterable<ByteData?> fontBytes = await Future.wait(
      urls.map((String url) async {
        final String cacheKey = Utils.fileName(url);
        final cache = await loadFontFromDeviceFileSystem(cacheKey);
        return cache;
      }),
    );

    if (fontBytes.any((ByteData? font) => font == null))
      throw StateError('Font should already be cached to be loaded');

    // The null-check above ensures that this line simply acts as a cast.
    final Iterable<ByteData> nonNullFontFiles = fontBytes.whereType<ByteData>();

    final Iterable<Future<ByteData>> cachedFontBytes =
        nonNullFontFiles.map((ByteData byteData) async {
      return byteData;
    });

    for (final Future<ByteData> bytes in cachedFontBytes)
      fontLoader.addFont(bytes);

    await fontLoader.load();

    devLog(<String>['Font has been loaded!']);

    return nonNullFontFiles;
  }

  /// Fetches the given [urls] from cache and loads them into the engine to be used.
  /// A stream of [FileInfo] objects is returned, which emits the font files as they
  /// are loaded. The total number of files returned corresponds to the number of
  /// urls provided. The download progress can be listened to using [progressListener].
  ///
  /// [urls] should be a series of related font assets,
  /// each of which defines how to render a specific [FontWeight] and [FontStyle]
  /// within the family.
  ///
  /// Call [canLoadFont] before calling this method to make sure the font is
  /// available in cache.
  ///
  /// - **REQUIRED** The [urls] property is used to specify the urls
  ///   for the required family. It should be a list of valid http/https urls
  ///   which point to font files.
  ///   Every url in [urls] should be loaded into cache by calling [cacheFont] for each.
  ///
  /// - **REQUIRED** The [fontFamily] property is used to specify the name
  ///   of the font family which is to be used as [TextStyle.fontFamily].
  ///
  /// - The [progressListener] property is used to listen to the download progress
  ///   of the font. It gives information about the number of files
  ///   downloaded and the total number of files to be downloaded.
  ///   It is called with
  ///
  ///   a [double] value which indicates the fraction of items that have been downloaded,
  ///   an [int] value which indicates the total number of items to be downloaded and,
  ///   another [int] value which indicates the number of items that have been
  ///   downloaded so far.
  static Stream<ByteData> loadCachedFamilyStream(
    List<String> urls, {
    required String fontFamily,
    required ItemCountProgressListener? progressListener,
    @visibleForTesting FontLoader? fontLoader,
  }) async* {
    fontLoader ??= FontLoader(fontFamily);

    WidgetsFlutterBinding.ensureInitialized();

    for (final String url in urls) {
      final String cacheKey = Utils.fileName(url);
      final font = await loadFontFromDeviceFileSystem(cacheKey);
      // return cache;

      if (font == null)
        throw StateError('Font should already be cached to be loaded');

      fontLoader.addFont(Future.value(font));

      final totalItems = urls.length, downloadedItems = urls.indexOf(url) + 1;

      progressListener?.call(
        downloadedItems / totalItems,
        totalItems,
        downloadedItems,
      );

      devLog([
        'Downloaded $downloadedItems of $totalItems fonts (${((downloadedItems / totalItems) * 100).toStringAsFixed(1)}%)'
      ]);

      yield font;
    }

    await fontLoader.load();

    devLog(<String>['Font has been loaded!']);
  }

  /// Removes the given [url] can be loaded directly from cache.
  ///
  /// Call [canLoadFont] before calling this method to make sure the font is
  /// available in cache.
  ///
  /// - **REQUIRED** The [url] property is used to specify the url
  ///   for the required font. It should be a valid http/https url which points to
  ///   a font file. The [url] should match the url passed to [cacheFont].
  static Future<void> removeCachedFont(String url) async {
    WidgetsFlutterBinding.ensureInitialized();

    final String cacheKey = Utils.fileName(url);

    try {
      final file = await localFile(cacheKey);
      file.delete();
    } catch (e) {
      throw StateError('Cant delete font $cacheKey');
    }
  }
}
