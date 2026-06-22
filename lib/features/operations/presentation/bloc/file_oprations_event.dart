abstract class FileOperationsEvent {}

class FileOperationsSearch extends FileOperationsEvent {
  final String query;
  final String rootPath;
  FileOperationsSearch({required this.query, required this.rootPath});
}

class FileOperationsDelete extends FileOperationsEvent {
  final String path;
  FileOperationsDelete(this.path);
}

class FileOperationsCreate extends FileOperationsEvent {}

class FileOperationsCopy extends FileOperationsEvent {
  final String path, destination;
  FileOperationsCopy({required this.path, required this.destination});
}

class FileOperationsMove extends FileOperationsEvent {
  final String path, destination;
  FileOperationsMove({required this.path, required this.destination});
}
