class MediaChannelError {
  final String code;
  final String message;
  final String? stackTrace;

  MediaChannelError({required this.code, required this.message, this.stackTrace});
}