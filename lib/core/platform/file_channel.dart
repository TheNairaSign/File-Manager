import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Error type ──────────────────────────────────────────────────────────────

/// Typed error codes that mirror the Java side's result.error() codes.
/// Using a sealed class means every call site is forced to handle
/// every error kind — no silent fallthrough to a generic Exception.
sealed class FileChannelError {
  const FileChannelError();
}

/// Java returned result.error() with a known code.
final class FileOperationError extends FileChannelError {
  const FileOperationError({required this.code, required this.message});
  final String code;     // e.g. "INVALID_ARGUMENT", "FILE_ERROR"
  final String message;

  @override
  String toString() => 'FileOperationError($code): $message';
}

/// Channel threw something unexpected (not a PlatformException).
final class UnexpectedChannelError extends FileChannelError {
  const UnexpectedChannelError(this.error);
  final Object error;

  @override
  String toString() => 'UnexpectedChannelError: $error';
}

// ─── Permission models ────────────────────────────────────────────────────────

enum StoragePermissionStatus { granted, denied, permanentlyDenied }

/// Mirrors the Map returned by Java's PermissionManager.checkPermissionStatus().
class PermissionState {
  const PermissionState({
    required this.status,
    required this.canManageAllFiles,
    required this.needsRationale,
    required this.apiLevel,
  });

  final StoragePermissionStatus status;

  /// True on API 30+ when MANAGE_EXTERNAL_STORAGE is granted —
  /// the gold standard for a full-featured file manager.
  final bool canManageAllFiles;

  /// True if a rationale UI should be shown before requesting (API 26–29 only).
  final bool needsRationale;

  final int apiLevel;

  bool get isGranted => status == StoragePermissionStatus.granted;

  factory PermissionState.fromMap(Map<Object?, Object?> map) {
    final raw = map['status'] as String;
    final status = switch (raw) {
      'granted'          => StoragePermissionStatus.granted,
      'permanentlyDenied'=> StoragePermissionStatus.permanentlyDenied,
      _                  => StoragePermissionStatus.denied,
    };
    return PermissionState(
      status:           status,
      canManageAllFiles: map['canManageAllFiles'] as bool,
      needsRationale:   map['needsRationale']    as bool,
      apiLevel:         map['apiLevel']           as int,
    );
  }

  @override
  String toString() => 'PermissionState(status: $status, canManageAllFiles: $canManageAllFiles)';
}

/// Result of a requestPermission() call.
class PermissionRequestResult {
  const PermissionRequestResult({
    required this.granted,
    required this.permanentlyDenied,
    required this.status,
  });

  final bool granted;
  final bool permanentlyDenied;
  final StoragePermissionStatus status;

  factory PermissionRequestResult.fromMap(Map<Object?, Object?> map) {
    final raw = map['status'] as String;
    final status = switch (raw) {
      'granted'          => StoragePermissionStatus.granted,
      'permanentlyDenied'=> StoragePermissionStatus.permanentlyDenied,
      _                  => StoragePermissionStatus.denied,
    };
    return PermissionRequestResult(
      granted:          map['granted']           as bool,
      permanentlyDenied: map['permanentlyDenied'] as bool,
      status:           status,
    );
  }
}

// ─── File item model ─────────────────────────────────────────────────────────

/// Mirrors the Map<String, Object> returned by Java's Scanner.listDirectory().
/// Extend fields here as Scanner.java is built out.
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
      name:         map['name']         as String,
      path:         map['path']         as String,
      isDirectory:  map['isDirectory']  as bool,
      size:         map['size']         as int,
      lastModified: map['lastModified'] as int,
      mimeType:     map['mimeType']     as String?,
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

  static const MethodChannel _channel = MethodChannel(
    'com.example.filemanager/files',
  );

  // ── Permissions ────────────────────────────────────────────────────────────

  /// Returns current permission state without prompting the user.
  /// Call this on app startup to decide whether to show the permission gate.
  Future<Either<FileChannelError, PermissionState>> checkPermissionStatus() async {
    final result = await _invoke<Map<Object?, Object?>>('checkPermissionStatus');
    return result.map(PermissionState.fromMap);
  }

  /// Requests storage permission appropriate for the device's API level:
  ///   API 30+  → opens MANAGE_EXTERNAL_STORAGE settings screen
  ///   API 33+  → requests READ_MEDIA_IMAGES/VIDEO/AUDIO
  ///   API 26-29 → requests READ/WRITE_EXTERNAL_STORAGE
  ///
  /// This call will not return until the user responds (dialog dismissed
  /// or returns from Settings). Only call one at a time — Java will error
  /// if a request is already pending.
  Future<Either<FileChannelError, PermissionRequestResult>> requestPermission() async {
    final result = await _invoke<Map<Object?, Object?>>('requestPermission');
    return result.map(PermissionRequestResult.fromMap);
  }

  /// Opens the app's system settings page so the user can manually grant
  /// permissions that were permanently denied ("Don't ask again").
  /// Fire-and-forget — check status again with [checkPermissionStatus]
  /// once the user returns to the app (e.g. in AppLifecycleState.resumed).
  Future<Either<FileChannelError, void>> openAppSettings() async {
    return _invoke<void>('openAppSettings');
  }

  // ── Storage info ───────────────────────────────────────────────────────────

  Future<Either<FileChannelError, String>> getStoragePath() async {
    return _invoke<String>('getStoragePath');
  }

  // ── Directory listing ──────────────────────────────────────────────────────

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

  // ── File operations ────────────────────────────────────────────────────────

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

  // ── Search (stub — ready when Scanner.java implements it) ──────────────────

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

// ─── Riverpod provider ───────────────────────────────────────────────────────

/// FileChannel is stateless — a single instance is fine for the whole app.
/// Features that need file listing state (loading, pagination cursor, etc.)
/// should live in their own StateNotifier, not here.
final fileChannelProvider = Provider<FileChannel>((_) => const FileChannel());