class FileItem {
  const FileItem({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.size,
    required this.lastModified,
    this.mimeType,
  });

  final String name;
  final String path;
  final bool isDirectory;
  final int size;            // bytes; 0 for directories
  final int lastModified;    // milliseconds since epoch
  final String? mimeType;

  factory FileItem.fromMap(Map<Object?, Object?> map) {
    return FileItem(
      name: map['name'] as String,
      path: map['path'] as String,
      isDirectory: map['isDirectory'] as bool,
      size: map['size'] as int,
      lastModified: map['lastModified'] as int,
      mimeType: map['mimeType'] as String?,
    );
  }

  @override
  String toString() => 'FileItem($path, isDir: $isDirectory)';
}