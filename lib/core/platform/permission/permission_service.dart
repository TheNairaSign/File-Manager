import 'package:dartz/dartz.dart';
import 'package:file_manager/core/platform/file_channel_error.dart';
import 'package:file_manager/core/platform/permission/permission_check_result.dart';
import 'package:file_manager/core/platform/permission/permission_result.dart';
import 'package:file_manager/core/platform/permission/permission_state.dart';
import 'package:flutter/services.dart';

class PermissionService {
  static const MethodChannel _channel = MethodChannel('com.example.filemanager/files');

  /// Checks current permission status without triggering any system dialogs.
  /// Use this during app startup to determine if you need to show a permission gate.
  static Future<Either<FileChannelError, PermissionCheckResult>> checkPermissionStatus() async {
    try {
      final Map<Object?, Object?>? rawMap = 
          await _channel.invokeMethod<Map<Object?, Object?>>('checkPermissionStatus');
      
      if (rawMap == null) {
        throw Exception("Received null response from permission check.");
      }

      final map = rawMap.cast<String, dynamic>();
      return right(PermissionCheckResult.fromMap(map));
    } on PlatformException catch (e) {
      print("Failed to check permissions: ${e.message}");
      // return left();
      return left(FileChannelPermissionCheckResult(
        message: e.message ?? '', 
        fallbackResult: PermissionCheckResult(
          apiLevel: 0,
          canManageAllFiles: false,
          status: StoragePermissionStatus.unknown,
          needsRationale: false,
        ))
      );
    }
  }

  /// Requests the appropriate storage permissions.
  /// Awaits the system dialog or the return from the Android Settings app.
  static Future<PermissionRequestResult> requestPermission() async {
    try {
      final Map<Object?, Object?>? rawMap = 
          await _channel.invokeMethod<Map<Object?, Object?>>('requestPermission');
      
      if (rawMap == null) {
        throw Exception("Received null response from permission request.");
      }

      final map = rawMap.cast<String, dynamic>();
      return PermissionRequestResult.fromMap(map);
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_IN_FLIGHT') {
        print("A permission request is already processing.");
      } else {
        print("Failed to request permissions: ${e.message}");
      }
      return PermissionRequestResult(
        granted: false,
        permanentlyDenied: false,
        status: StoragePermissionStatus.unknown,
      );
    }
  }

  /// Opens the Android application settings page if the user permanently denied access.
  static Future<void> openAppSettings() async {
    try {
      await _channel.invokeMethod('openAppSettings');
    } on PlatformException catch (e) {
      print("Failed to open app settings: ${e.message}");
    }
  }
}