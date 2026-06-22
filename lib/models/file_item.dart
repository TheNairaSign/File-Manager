class FileItem {
  final String path;
  final bool isDirectory;
  final int size;
  final DateTime createdAt;
  final DateTime updatedAt;

  FileItem({
    required this.path,
    required this.isDirectory,
    required this.size,
    required this.createdAt,
    required this.updatedAt,
  });
}
