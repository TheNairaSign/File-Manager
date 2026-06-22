import 'package:file_manager/core/platform/file_channel.dart';

abstract class FileOperationsState {}

class FileOperationsInitial extends FileOperationsState {}

class FileOperationsCreating extends FileOperationsState {}

class FileOperationsCreatedSuccess extends FileOperationsState {}

class FileOperationsCreatedFailure extends FileOperationsState {}

class FileOperationsDeleting extends FileOperationsState {}

class FileOperationsDeleted extends FileOperationsState {}

class FileOperationsDeletedFailure extends FileOperationsState {
  final String errorMessage;
  FileOperationsDeletedFailure(this.errorMessage);
}

class FileOperationsCopying extends FileOperationsState {}

class FileOperationsCopySuccess extends FileOperationsState {}

class FileOperationsCopyFailure extends FileOperationsState {
  final String errorMessage;
  FileOperationsCopyFailure(this.errorMessage);
}

class FileOperationsMoving extends FileOperationsState {}

class FileOperationsMovedSuccess extends FileOperationsState {}

class FileOperationsMovedFailure extends FileOperationsState {
  final String errorMessage;
  FileOperationsMovedFailure(this.errorMessage);
}

class FileOperationsLoading extends FileOperationsState {}

class FileOperationsSearchLoaded extends FileOperationsState {
  final List<FileItem> files;
  FileOperationsSearchLoaded(this.files);
}

class FileOperationsSearchFailure extends FileOperationsState {
  final String errorMessage;
  FileOperationsSearchFailure(this.errorMessage);
}
