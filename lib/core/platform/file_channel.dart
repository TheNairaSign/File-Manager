import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:file_manager/core/platform/file_channel_error.dart';
import 'package:file_manager/models/file_item.dart';
import 'package:file_manager/models/storage_info.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FileChannel {
  const FileChannel();

  static const MethodChannel _channel = MethodChannel('com.example.filemanager/files');

  Future<StorageInfo> getStorageInfo() async {
    log('Invoking getStorageInfo');
    final Map<dynamic, dynamic> storage = await _channel.invokeMethod('getStorageInfo');

    log('Result $storage');

    log("Total: ${storage['total']}", name: 'storage');
    log("Free: ${storage['free']}", name: 'storage');
    log("Used: ${storage['used']}", name: 'storage');

    return StorageInfo(
      total: storage['total'], 
      free: storage['free'], 
      used: storage['used']
    );
  }

  // Future<Either<FileChannelError, PermissionState>> checkPermissionStatus() async {
  //   final result = await _invoke<Map<Object?, Object?>>('checkPermissionStatus');
  //   return result.map(PermissionState.fromMap);
  // }

  // Future<Either<FileChannelError, PermissionRequestResult>> requestPermission() async {
  //   final result = await _invoke<Map<Object?, Object?>>('requestPermission');
  //   return result.map(PermissionRequestResult.fromMap);
  // }

  Future<Either<FileChannelError, void>> openAppSettings() async {
    return _invoke<void>('openAppSettings');
  }

  Future<Either<FileChannelError, String>> getStoragePath() async {
    return _invoke<String>('getStoragePath');
  }

  /// [page] and [pageSize] must match the paginated contract defined in
  /// MainActivity.java. Never call without pagination — see Phase 2 notes.
  Future<Either<FileChannelError, List<FileItem>>> listDirectory({
    required String path,
    required int page,
    int pageSize = 50,
    String? sortOrder
  }) async {
    final result = await _invoke<Map<Object?, Object?>>('listDirectory', {
      'path': path,
      'page': page,
      'pageSize': pageSize,
      'sortOrder' : sortOrder
    });

    return result.map((raw) {
      final items = raw['items'] as List<Object?>;
      return items
          .cast<Map<Object?, Object?>>()
          .map(FileItem.fromMap)
          .toList();
    });
  }

  Future<Either<FileChannelError, bool>> createDirectory(String path) async {
    return _invoke<bool>('createDirectory', {'path': path});
  }

  Future<Either<FileChannelError, bool>> deleteEntry(String path) async {
    return _invoke<bool>('deleteEntry', {'path': path});
  }

  Future<Either<FileChannelError, bool>> copyEntry({
    required String sourcePath,
    required String destinationPath,
  }) async {
    return _invoke<bool>('copyEntry', {
      'path': sourcePath,
      'destination': destinationPath,
    });
  }

  Future<Either<FileChannelError, bool>> moveEntry({
    required String sourcePath,
    required String destinationPath,
  }) async {
    return _invoke<bool>('moveEntry', {
      'path': sourcePath,
      'destination': destinationPath,
    });
  }

  Future<Either<FileChannelError, bool>> renameEntry({
    required String sourcePath,
    required String destinationPath,
  }) async {
    return _invoke<bool>('renameEntry', {
      'path': sourcePath,
      'destination': destinationPath,
    });
  }

  Future<Either<FileChannelError, List<FileItem>>> searchFiles({
    required String query,
    required String rootPath,
  }) async {
    final result = await _invoke<List<Object?>>('searchFiles', {
      'query': query,
      'rootPath': rootPath,
    });

    return result.map((raw) => raw
        .cast<Map<Object?, Object?>>()
        .map(FileItem.fromMap)
        .toList());
  }

  // ── Private helper ─────────────────────────────────────────────────────────

  /// Invokes [method] on the channel and wraps the result in Either.
  /// All public methods funnel through here so error handling is consistent.
  Future<Either<FileChannelError, T>> _invoke<T>(
      String method, [
        Map<String, Object?>? arguments,
      ]) async {
    try {
      final result = await _channel.invokeMethod<T>(method, arguments);
      // invokeMethod returns null only if the Java side called result.success(null).
      // For bool/String returns that's always a Java-side bug, not a Dart one.
      if (result == null) {
        return Left(FileOperationError(
          code: 'NULL_RESULT',
          message: '$method returned null unexpectedly',
        ));
      }
      return Right(result);
    } on PlatformException catch (e) {
      debugPrint('[FileChannel] $method failed — ${e.code}: ${e.message}');
      return Left(FileOperationError(
        code: e.code,
        message: e.message ?? 'No message',
      ));
    } catch (e) {
      debugPrint('[FileChannel] $method unexpected error: $e');
      return Left(UnexpectedChannelError(e));
    }
  }
}

final fileChannelProvider = Provider<FileChannel>((_) => const FileChannel());