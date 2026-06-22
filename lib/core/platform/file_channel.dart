import 'package:dartz/dartz.dart';
import 'package:file_manager/core/platform/file_channel_error.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

// ─── Channel ─────────────────────────────────────────────────────────────────

/// Thin wrapper around the platform channel.
///
/// Rules:
/// - This class owns nothing except the channel name — no state, no streams.
/// - Method names must exactly match the switch cases in MainActivity.java.
/// - Return type is always Either<FileChannelError, T> — callers handle errors
///   explicitly; nothing is thrown or swallowed.
class FileChannel {
  const FileChannel();

  static const MethodChannel _channel = MethodChannel('com.example.filemanager/files');


  Future<Either<FileChannelError, String>> getStoragePath() async {
    return _invoke<String>('getStoragePath');
  }

  /// [page] and [pageSize] must match the paginated contract defined in
  /// MainActivity.java. Never call without pagination — see Phase 2 notes.
  Future<Either<FileChannelError, List<FileItem>>> listDirectory({
    required String path,
    required int page,
    int pageSize = 50,
  }) async {
    final result = await _invoke<Map<Object?, Object?>>('listDirectory', {
      'path': path,
      'page': page,
      'pageSize': pageSize,
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