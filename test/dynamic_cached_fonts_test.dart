import 'package:dynamic_cached_fonts/dynamic_cached_fonts.dart';
import 'package:dynamic_cached_fonts/src/utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const String cacheKey = 'DynamicCachedFontsTest';
  const String firebaseMockUrl = 'gs://mockurl.appspot.com/a.ttf';
  const String mockUrl = 'https://example.com/font.ttf';
  const String mockFontFamily = 'FontFamily';

  const List<String> mockUrls = [
    firebaseMockUrl,
    'https://example.com/fontTest1.ttf',
    'https://example.com/fontTest2.ttf?v=1',
    'https://example.com/fontTest3.ttf?v=1&u=2',
    'http://font.example.com/fontTest4.ttf',
    'https://example.com/dir1/dir2/fontTest5.ttf',
    'https://example.com/fontTest6.ttf#test',
    'https://example.com/fontTest7.ttf#test?v=1',
  ];

  test('Default constructor applies default values', () {
    final DynamicCachedFonts fontLoader =
        DynamicCachedFonts(url: mockUrl, fontFamily: mockFontFamily);

    expect(fontLoader.urls.length, 1);
    expect(fontLoader.maxCacheObjects, 200);
    expect(fontLoader.cacheStalePeriod, const Duration(days: 365));
  });

  test('Firebase constructor applies default values', () {
    final DynamicCachedFonts fontLoader = DynamicCachedFonts.fromFirebase(
      bucketUrl: firebaseMockUrl,
      fontFamily: 'Font',
    );

    expect(fontLoader.urls.length, 1);
    expect(fontLoader.maxCacheObjects, 200);
    expect(fontLoader.cacheStalePeriod, const Duration(days: 365));
  });

  group('DynamicCachedFonts.toggleVerboseLogging', () {
    test('should have logging disabled by default',
        () => expect(Utils.shouldVerboseLog, isFalse));

    test('should enable logging when toggled', () {
      DynamicCachedFonts.toggleVerboseLogging(true);
      expect(Utils.shouldVerboseLog, isTrue);
    });

    test('should disable logging when toggled', () {
      Utils.shouldVerboseLog = true;

      DynamicCachedFonts.toggleVerboseLogging(false);
      expect(Utils.shouldVerboseLog, isFalse);
    });
  });

  test('cacheKeyFromUrl', () {
    const List<String> expectedCacheKeys = [
      'gsmockurl.appspot.coma.ttf',
      'httpsexample.comfontTest1.ttf',
      'httpsexample.comfontTest2.ttfv1',
      'httpsexample.comfontTest3.ttfv1u2',
      'httpfont.example.comfontTest4.ttf',
      'httpsexample.comdir1dir2fontTest5.ttf',
      'httpsexample.comfontTest6.ttftest',
      'httpsexample.comfontTest7.ttftestv1',
    ];

    expect(mockUrls.map(cacheKeyFromUrl), orderedEquals(expectedCacheKeys));
  });

  test('getFileNameOrUrl', () {
    const List<String> expectedFileNames = [
      'a.ttf',
      'fontTest1.ttf',
      'fontTest2.ttf',
      'fontTest3.ttf',
      'fontTest4.ttf',
      'fontTest5.ttf',
      'fontTest6.ttf',
      'fontTest7.ttf',
    ];

    expect(
        mockUrls.map(Utils.getFileNameOrUrl), orderedEquals(expectedFileNames));
  });
}
