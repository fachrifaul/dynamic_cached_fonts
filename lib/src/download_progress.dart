/// Progress of the file that is being downloaded from the [originalUrl].
class DownloadProgress {
  /// Progress of the file that is being downloaded from the [originalUrl].
  const DownloadProgress({
    required this.originalUrl,
    required this.totalSize,
    required this.downloaded,
  });

  /// Progress of the file that is being downloaded from the [originalUrl].
  final String originalUrl;

  /// download progress as an double between 0 and 1.
  /// When the final size is unknown or the downloaded size exceeds the total
  /// size [progress] is null.
  double? get progress {
    // ignore: avoid_returning_null
    if (totalSize == null || downloaded > totalSize!) return null;
    return downloaded / totalSize!;
  }

  /// Final size of the download. If total size is unknown this will be null.
  final int? totalSize;

  /// Total of currently downloaded bytes.
  final int downloaded;
}
