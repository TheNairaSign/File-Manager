package com.example.file_manager.filemanager;

import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.Settings;

import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import io.flutter.plugin.common.MethodChannel;

import java.util.HashMap;
import java.util.Map;

/**
 * PermissionManager — handles all storage permission flows for the file manager.
 *
 * Why this class exists separately:
 * Permissions are fundamentally different from file I/O. Every other service
 * class (Scanner, FileOperations) is synchronous — call a method, get a result.
 * Permissions are asynchronous: you request them, Android shows a system dialog,
 * and the result comes back minutes later via onRequestPermissionsResult() or
 * onActivityResult() in the Activity. This class bridges that gap by holding
 * the pending MethodChannel.Result and resolving it when Android calls back.
 *
 * Android version matrix (what this class handles):
 *
 *   API 26–28 (Android 8–8.1):
 *     READ_EXTERNAL_STORAGE  — runtime permission, standard dialog
 *     WRITE_EXTERNAL_STORAGE — runtime permission, standard dialog
 *
 *   API 29 (Android 10):
 *     READ_EXTERNAL_STORAGE  — still works, WRITE is scoped by default
 *     requestLegacyExternalStorage in manifest extends WRITE temporarily
 *
 *   API 30–32 (Android 11–12L):
 *     MANAGE_EXTERNAL_STORAGE — "All files access", requires special Settings intent
 *     READ_EXTERNAL_STORAGE still needed as fallback for some operations
 *
 *   API 33+ (Android 13+):
 *     READ_MEDIA_IMAGES / READ_MEDIA_VIDEO / READ_MEDIA_AUDIO — granular
 *     MANAGE_EXTERNAL_STORAGE still available for true file manager scope
 *
 * For a full-featured file manager (our confirmed scope), MANAGE_EXTERNAL_STORAGE
 * is what we want on API 30+. On API 26–29, READ + WRITE covers the same ground.
 *
 * Request codes (must be unique per Activity):
 *   100 — READ/WRITE runtime permission request
 *   101 — granular media permissions (API 33+)
 *   (MANAGE_EXTERNAL_STORAGE has no request code — it's an intent to Settings,
 *    result checked on Activity resume via onActivityResult with code 102)
 */
public class PermissionManager {

    // Request codes — must stay stable; changing them breaks in-flight permission requests
    public static final int REQUEST_CODE_LEGACY    = 100;  // READ/WRITE (API 26-29)
    public static final int REQUEST_CODE_MEDIA     = 101;  // granular media (API 33+)
    public static final int REQUEST_CODE_ALL_FILES = 102;  // MANAGE_EXTERNAL_STORAGE settings intent

    private final Activity activity;

    // Holds the pending Dart result while Android's permission dialog is open.
    // Only one permission request can be in flight at a time — the Dart side
    // must await the result before calling again.
    private MethodChannel.Result pendingResult;

    public PermissionManager(Activity activity) {
        this.activity = activity;
    }

    // ─── Public API (called from MainActivity) ────────────────────────────────

    /**
     * Returns the current permission state without requesting anything.
     * Call this on app start to decide whether to show the permission gate screen.
     *
     * Returns a Map with:
     *   "status"              → String: "granted" | "denied" | "permanentlyDenied"
     *   "canManageAllFiles"   → Boolean (true on API 30+ if MANAGE_EXTERNAL_STORAGE granted)
     *   "needsRationale"      → Boolean (true if you should show explanation before requesting)
     *   "apiLevel"            → int
     */
    public Map<String, Object> checkPermissionStatus() {
        Map<String, Object> status = new HashMap<>();
        int api = Build.VERSION.SDK_INT;
        status.put("apiLevel", api);

        if (api >= Build.VERSION_CODES.R) {
            // API 30+: check MANAGE_EXTERNAL_STORAGE
            boolean manageGranted = Environment.isExternalStorageManager();
            status.put("canManageAllFiles", manageGranted);
            status.put("status", manageGranted ? "granted" : "denied");
            // MANAGE_EXTERNAL_STORAGE doesn't have a rationale concept —
            // it's always a Settings redirect, never a popup
            status.put("needsRationale", false);

        } else if (api >= Build.VERSION_CODES.TIRAMISU) {
            // API 33+: granular media (images/video/audio separately)
            // Note: API 33 > 30, so this branch is unreachable with current ordering.
            // Kept explicit for clarity if version constants are re-checked.
            boolean images = hasPermission(android.Manifest.permission.READ_MEDIA_IMAGES);
            boolean videos = hasPermission(android.Manifest.permission.READ_MEDIA_VIDEO);
            boolean audio  = hasPermission(android.Manifest.permission.READ_MEDIA_AUDIO);
            boolean allMedia = images && videos && audio;
            status.put("canManageAllFiles", false);
            status.put("status", allMedia ? "granted" : "denied");
            status.put("needsRationale",
                    shouldShowRationale(android.Manifest.permission.READ_MEDIA_IMAGES));

        } else {
            // API 26–29: classic READ + WRITE
            boolean read  = hasPermission(android.Manifest.permission.READ_EXTERNAL_STORAGE);
            boolean write = hasPermission(android.Manifest.permission.WRITE_EXTERNAL_STORAGE);
            boolean both  = read && write;
            status.put("canManageAllFiles", false);
            status.put("status", both ? "granted" : "denied");
            status.put("needsRationale",
                    shouldShowRationale(android.Manifest.permission.READ_EXTERNAL_STORAGE));
        }

        return status;
    }

    /**
     * Requests the appropriate storage permission for the running API level.
     *
     * On API 30+: opens the MANAGE_EXTERNAL_STORAGE settings page.
     *   The result is NOT immediate — Android sends the user to Settings and
     *   the app resumes. Call checkPermissionStatus() again in onResume to see
     *   if they granted it. Pass result here so we can resolve it from
     *   onActivityResult when the user comes back.
     *
     * On API 26–29: shows the standard runtime permission dialog.
     *   Result comes back via onRequestPermissionsResult().
     *
     * @param result  The Dart MethodChannel.Result to resolve when Android responds.
     *                Must not be called again until the previous result is resolved.
     */
    public void requestPermission(MethodChannel.Result result) {
        if (pendingResult != null) {
            // A request is already in flight — reject the new one rather than
            // silently dropping the old result
            result.error("PERMISSION_IN_FLIGHT",
                    "A permission request is already pending. Await the previous result first.", null);
            return;
        }

        pendingResult = result;
        int api = Build.VERSION.SDK_INT;

        if (api >= Build.VERSION_CODES.R) {
            // MANAGE_EXTERNAL_STORAGE — must send to system settings
            try {
                Intent intent = new Intent(
                        Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
                        Uri.parse("package:" + activity.getPackageName())
                );
                activity.startActivityForResult(intent, REQUEST_CODE_ALL_FILES);
            } catch (Exception e) {
                // Some OEM ROMs don't support the package-specific URI —
                // fall back to the general "all files" settings screen
                Intent fallback = new Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION);
                activity.startActivityForResult(fallback, REQUEST_CODE_ALL_FILES);
            }

        } else if (api >= Build.VERSION_CODES.TIRAMISU) {
            // API 33+: request granular media permissions
            ActivityCompat.requestPermissions(activity, new String[]{
                    android.Manifest.permission.READ_MEDIA_IMAGES,
                    android.Manifest.permission.READ_MEDIA_VIDEO,
                    android.Manifest.permission.READ_MEDIA_AUDIO,
            }, REQUEST_CODE_MEDIA);

        } else {
            // API 26–29: request legacy READ + WRITE
            ActivityCompat.requestPermissions(activity, new String[]{
                    android.Manifest.permission.READ_EXTERNAL_STORAGE,
                    android.Manifest.permission.WRITE_EXTERNAL_STORAGE,
            }, REQUEST_CODE_LEGACY);
        }
    }

    /**
     * Opens the app's general settings page so the user can manually grant
     * permissions that were permanently denied (they ticked "Don't ask again").
     * Does NOT hold a pending result — caller should re-check status on resume.
     */
    public void openAppSettings() {
        Intent intent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
        intent.setData(Uri.parse("package:" + activity.getPackageName()));
        activity.startActivity(intent);
    }

    // ─── Android callbacks (called from MainActivity) ─────────────────────────

    /**
     * Call this from MainActivity.onRequestPermissionsResult().
     * Resolves the pending Dart result with the outcome of a runtime permission dialog.
     *
     * @return true if this manager handled the request code, false otherwise
     */
    public boolean onRequestPermissionsResult(
            int requestCode,
            String[] permissions,
            int[] grantResults
    ) {
        if (requestCode != REQUEST_CODE_LEGACY && requestCode != REQUEST_CODE_MEDIA) {
            return false;   // not ours
        }

        if (pendingResult == null) return true;  // result already resolved or abandoned

        boolean allGranted = grantResults.length > 0;
        for (int r : grantResults) {
            if (r != PackageManager.PERMISSION_GRANTED) {
                allGranted = false;
                break;
            }
        }

        // Check if any permission is permanently denied
        // (user ticked "Don't ask again" — rationale returns false AND not granted)
        boolean permanentlyDenied = false;
        if (!allGranted) {
            for (String permission : permissions) {
                if (!ActivityCompat.shouldShowRequestPermissionRationale(activity, permission)
                        && !hasPermission(permission)) {
                    permanentlyDenied = true;
                    break;
                }
            }
        }

        Map<String, Object> response = new HashMap<>();
        response.put("granted",           allGranted);
        response.put("permanentlyDenied", permanentlyDenied);
        response.put("status",
                allGranted ? "granted" : permanentlyDenied ? "permanentlyDenied" : "denied");

        pendingResult.success(response);
        pendingResult = null;
        return true;
    }

    /**
     * Call this from MainActivity.onActivityResult().
     * Resolves the pending Dart result after the user returns from the
     * MANAGE_EXTERNAL_STORAGE settings screen.
     *
     * @return true if this manager handled the request code, false otherwise
     */
    public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode != REQUEST_CODE_ALL_FILES) return false;

        if (pendingResult == null) return true;

        // Don't trust resultCode here — the settings screen always returns
        // RESULT_CANCELED regardless of what the user did. Check the actual state.
        boolean granted = (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R)
                && Environment.isExternalStorageManager();

        Map<String, Object> response = new HashMap<>();
        response.put("granted", granted);
        response.put("permanentlyDenied", false);  // settings page can always be reopened
        response.put("status", granted ? "granted" : "denied");

        pendingResult.success(response);
        pendingResult = null;
        return true;
    }

    // ─── Private helpers ──────────────────────────────────────────────────────

    private boolean hasPermission(String permission) {
        return ContextCompat.checkSelfPermission(activity, permission)
                == PackageManager.PERMISSION_GRANTED;
    }

    private boolean shouldShowRationale(String permission) {
        return ActivityCompat.shouldShowRequestPermissionRationale(activity, permission);
    }
}