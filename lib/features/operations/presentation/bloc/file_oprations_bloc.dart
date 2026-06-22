import 'package:file_manager/core/platform/file_channel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:file_manager/features/operations/presentation/bloc/file_operations_state.dart';
import 'package:file_manager/features/operations/presentation/bloc/file_oprations_event.dart';

class FileOperationsBloc
    extends Bloc<FileOperationsEvent, FileOperationsState> {
  final FileChannel _fileChannel;

  FileOperationsBloc(this._fileChannel) : super(FileOperationsInitial()) {
    on<FileOperationsSearch>(_searchFiles);
    on<FileOperationsDelete>(_deleteFile);
    on<FileOperationsCopy>(_copyFile);
    on<FileOperationsMove>(_moveFile);
  }

  Future<void> _searchFiles(
    FileOperationsSearch event,
    Emitter<FileOperationsState> emit,
  ) async {
    emit(FileOperationsLoading());
    final files = await _fileChannel.searchFiles(query: event.query, rootPath: event.rootPath);

    files.fold(
      (l) => emit(FileOperationsSearchFailure(l.toString())),
      (r) => emit(FileOperationsSearchLoaded(r)),
    );
  }

  Future<void> _deleteFile(
    FileOperationsDelete event,
    Emitter<FileOperationsState> emit,
  ) async {
    emit(FileOperationsDeleting());

    final result = await _fileChannel.deleteEntry(event.path);

    result.fold(
      (l) => emit(FileOperationsDeletedFailure(l.toString())),
      (r) => emit(FileOperationsDeleted()),
    );
  }

  Future<void> _copyFile(
    FileOperationsCopy event,
    Emitter<FileOperationsState> emit,
  ) async {
    emit(FileOperationsCopying());

    final result = await _fileChannel.copyEntry(sourcePath: event.path, destinationPath: event.destination);

    result.fold(
      (l) => emit(FileOperationsCopyFailure(l.toString())),
      (r) => emit(FileOperationsCopySuccess()),
    );
  }

  Future<void> _moveFile(
    FileOperationsMove event,
    Emitter<FileOperationsState> emit,
  ) async {
    emit(FileOperationsMoving());

    final result = await _fileChannel.moveEntry(sourcePath: event.path, destinationPath: event.destination);

    result.fold(
      (l) => emit(FileOperationsDeletedFailure(l.toString())),
      (r) => emit(FileOperationsDeleted()),
    );
  }
}
