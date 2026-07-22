
import 'package:file_manager/core/platform/permission/permission_check_result.dart';

sealed class FileChannelError {
  const FileChannelError();
  String get message;
}

/// Java returned result.error() with a known code.
final class FileOperationError extends FileChannelError {
  const FileOperationError({required this.code, required this.message});
  final String code;     // e.g. "INVALID_ARGUMENT", "FILE_ERROR"
  
  @override
  final String message;

  @override
  String toString() => 'FileOperationError($code): $message';
}

/// Channel threw something unexpected (not a PlatformException).
final class UnexpectedChannelError extends FileChannelError {
  const UnexpectedChannelError(this.error);
  final Object error;

  @override
  String get message => error.toString();

  @override
  String toString() => 'UnexpectedChannelError: $error';
}

final class FileChannelPermissionCheckResult extends FileChannelError {
  @override
  final String message;
  final PermissionCheckResult? fallbackResult;
  const FileChannelPermissionCheckResult({required this.message, this.fallbackResult});
}