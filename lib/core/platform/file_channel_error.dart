
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