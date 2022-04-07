import 'dart:developer' as dev;
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';

/// Signature for `itemCountProgressListener` and `progressListener` callbacks
/// that return no data and have the following arguments -
///
/// - The [progress] argument is a double between 0.0 and 1.0, indicating the
///   fraction of items that have been downloaded.
///
/// - The [totalItems] argument is the total number of items to be downloaded.
///
/// - The [downloadedItems] argument is the number of items that have been
///   downloaded so far.
typedef ItemCountProgressListener = void Function(
    double progress, int totalItems, int downloadedItems);

/// Signature for `downloadProgressListener` and `progressListener` callbacks
/// that return no data and has a single argument -
///
/// - The [progress] argument is a [DownloadProgress] object that contains
///   information about the download progress.
typedef DownloadProgressListener = void Function(double progress);

/// Gets the sanitized url from [url] which is used as `cacheKey` when
/// downloading, caching or loading.
@visibleForTesting
String cacheKeyFromUrl(String url) => Utils.sanitizeUrl(url);

/// The name for for [dev.log].
@internal
const String kLoggerName = 'DynamicCachedFonts';

/// The default `cacheStalePeriod`.
const Duration kDefaultCacheStalePeriod = Duration(days: 365);

/// The default `maxCacheObjects`.
const int kDefaultMaxCacheObjects = 200;

/// Logs a message to the console.
@internal
void devLog(
  List<String> messageList, {
  bool? overrideLoggerConfig,
}) {
  if (overrideLoggerConfig ?? Utils.shouldVerboseLog) {
    final String message = '[dynamic_cached_fonts] ${messageList.join('\n')}';
    dev.log(
      message,
      name: kLoggerName,
    );
  }
}

/// Logs a message to the console.
@internal
void devLog1(
  String message1, {
  bool? overrideLoggerConfig,
}) {
  if (overrideLoggerConfig ?? Utils.shouldVerboseLog) {
    final String message = '[dynamic_cached_fonts] $message1';
    dev.log(
      message,
      name: kLoggerName,
    );
  }
}

class _FontFileExtensionManager {
  _FontFileExtensionManager();

  final Map<String, List<int>> _validExtensions = {};

  void addExtension(
      {required String extension, required List<int> magicNumber}) {
    _validExtensions[extension] = magicNumber;
  }

  bool matchesFileExtension(String path, Uint8List fileBytes) {
    String fontExtension;

    final int index = path.lastIndexOf('.');
    if (index < 0 || index + 1 >= path.length) fontExtension = '';
    fontExtension = path.substring(index + 1).toLowerCase();

    final List<int> headerBytes = fileBytes.sublist(0, 5).toList();

    return _validExtensions.keys.contains(fontExtension) ||
        _validExtensions.values.any(
          (List<int> magicNumber) => listEquals(headerBytes, magicNumber),
        );
  }
}

/// A class for [DynamicCachedFonts] which performs actions which are not exposed as APIs.
@internal
class Utils {
  Utils._();

  static final _FontFileExtensionManager _fontFileExtensionManager =
      _FontFileExtensionManager()
        ..addExtension(
          extension: 'ttf',
          magicNumber: <int>[
            0x00,
            0x01,
            0x00,
            0x00,
            0x00,
          ],
        )
        ..addExtension(
          extension: 'otf',
          magicNumber: <int>[
            0x4F,
            0x54,
            0x54,
            0x4F,
            0x00,
          ],
        );

  /// A property used to specify whether detailed logs should be printed for debugging.
  static bool shouldVerboseLog = false;

  /// Checks whether the [font] has a valid extension which is supported by Flutter.
  static void verifyFileExtension(File font) {
    if (!_fontFileExtensionManager.matchesFileExtension(
        basename(font.path), font.readAsBytesSync())) {
      throw UnsupportedError(
        'Bad File Format\n'
        'The provided file extension is not supported. '
        'Currently, only OpenType (OTF) and TrueType (TTF) fonts are supported.',
      );
    }
  }

  /// Remove reserved characters from url which can cause errors when used as
  /// storage paths in some operating systems.
  static String sanitizeUrl(String url) =>
      url.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '');

  /// Returns the file name of the font or the url if the url cannot be parsed.
  static String getFileNameOrUrl(String url) {
    final int index = url.lastIndexOf('/');
    final int? endIndex =
        url.contains(RegExp(r'\?|#')) ? url.indexOf(RegExp(r'\?|#')) : null;
    if (index < 0 || index + 1 >= url.length) return url;
    return url.substring(index + 1, endIndex);
  }

  /// Remove `/` or `:` from url which can cause errors when used as storage paths
  /// in some operating systems.
  static String fileName(String url) {
    final file = File(url);
    return basename(file.path);
  }
}

/// Converts [input] into a [Uint8List].
///
/// If [input] is a [TypedData], this just returns a view on [input].
Uint8List toUint8List(List<int> input) {
  if (input is Uint8List) return input;
  if (input is TypedData) {
    return Uint8List.view((input as TypedData).buffer);
  }
  return Uint8List.fromList(input);
}
