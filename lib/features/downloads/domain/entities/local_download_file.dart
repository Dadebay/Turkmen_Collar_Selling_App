class LocalDownloadFile {
  final String uri;
  final String name;
  final String relativePath;

  /// Byte size of the source file, or null when unknown. Used to skip copying
  /// files that already exist on the USB with an identical size.
  final int? size;

  const LocalDownloadFile({
    required this.uri,
    required this.name,
    required this.relativePath,
    this.size,
  });

  factory LocalDownloadFile.fromMap(Map<dynamic, dynamic> map) {
    return LocalDownloadFile(
      uri: map['uri']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      relativePath: _normalizePath(map['relativePath']?.toString() ?? ''),
      size: (map['size'] as num?)?.toInt(),
    );
  }

  static String _normalizePath(String path) {
    return path
        .split('/')
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .join('/');
  }
}
