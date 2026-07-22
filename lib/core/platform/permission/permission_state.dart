enum StoragePermissionStatus { granted, denied, permanentlyDenied, unknown }

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
      'granted' => StoragePermissionStatus.granted,
      'permanentlyDenied' => StoragePermissionStatus.permanentlyDenied,
      _ => StoragePermissionStatus.denied,
    };
    return PermissionState(
      status: status,
      canManageAllFiles: map['canManageAllFiles'] as bool,
      needsRationale: map['needsRationale'] as bool,
      apiLevel: map['apiLevel'] as int,
    );
  }

  @override
  String toString() => 'PermissionState(status: $status, canManageAllFiles: $canManageAllFiles)';
}