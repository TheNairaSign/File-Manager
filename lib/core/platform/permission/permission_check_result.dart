import 'package:file_manager/core/platform/permission/permission_result.dart';
import 'package:file_manager/core/platform/permission/permission_state.dart';

class PermissionCheckResult {
  final int apiLevel;
  final bool canManageAllFiles;
  final StoragePermissionStatus status;
  final bool needsRationale;

  PermissionCheckResult({
    required this.apiLevel,
    required this.canManageAllFiles,
    required this.status,
    required this.needsRationale,
  });

  factory PermissionCheckResult.fromMap(Map<String, dynamic> map) {
    return PermissionCheckResult(
      apiLevel: map['apiLevel'] as int? ?? 0,
      canManageAllFiles: map['canManageAllFiles'] as bool? ?? false,
      status: parseStatus(map['status'] as String?),
      needsRationale: map['needsRationale'] as bool? ?? false,
    );
  }
}