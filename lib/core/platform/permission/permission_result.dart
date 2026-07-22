import 'package:file_manager/core/platform/permission/permission_state.dart';

class PermissionRequestResult {
  const PermissionRequestResult({
    required this.granted,
    required this.permanentlyDenied,
    required this.status,
  });

  final bool granted;
  final bool permanentlyDenied;
  final StoragePermissionStatus status;

  // factory PermissionRequestResult.fromMap(Map<Object?, Object?> map) {
  //   final raw = map['status'] as String;
  //   final status = switch (raw) {
  //     'granted' => StoragePermissionStatus.granted,
  //     'permanentlyDenied' => StoragePermissionStatus.permanentlyDenied,
  //     _ => StoragePermissionStatus.denied,
  //   };
  //   return PermissionRequestResult(
  //     granted: map['granted'] as bool,
  //     permanentlyDenied: map['permanentlyDenied'] as bool,
  //     status: status,
  //   );
  // }

  factory PermissionRequestResult.fromMap(Map<String, dynamic> map) {
    return PermissionRequestResult(
      granted: map['granted'] as bool? ?? false,
      permanentlyDenied: map['permanentlyDenied'] as bool? ?? false,
      status: parseStatus(map['status'] as String?),
    );
  }
}

 StoragePermissionStatus parseStatus(String? status) {
    switch (status) {
      case 'granted':
        return StoragePermissionStatus.granted;
      case 'denied':
        return StoragePermissionStatus.denied;
      case 'permanentlyDenied':
        return StoragePermissionStatus.permanentlyDenied;
      default:
        return StoragePermissionStatus.unknown;
    }
  }