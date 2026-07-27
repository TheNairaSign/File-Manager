// registers MethodChannel + EventChannel

package com.example.file_manager;

import android.content.Context;
import android.os.Environment;
import android.os.Handler;
import android.os.Looper;

import android.content.Intent;

import android.os.storage.StorageManager;
import com.example.file_manager.filemanager.*;

import com.example.file_manager.filemanager.managers.MediaManager;
import com.example.file_manager.filemanager.managers.PermissionManager;
import com.example.file_manager.filemanager.managers.DeviceStorageManager;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

import org.jetbrains.annotations.NotNull;

import java.io.File;
import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicBoolean;

public class JavaMainActivity extends FlutterActivity {

    private static final String CHANNEL = "com.example.filemanager/files";

    // 4 threads: enough for concurrent ops (copy + delete + two listings)
    // without starving the device. Increase only with profiling evidence.
    private final ExecutorService executor = Executors.newFixedThreadPool(4);
    private final Handler mainHandler = new Handler(Looper.getMainLooper());
    private final FileOperations fileOps = new FileOperations();

    // Scanner is initialised in configureFlutterEngine (needs Context)
    private FileScanner fileScanner;

    private Context context;

    // PermissionManager needs the Activity reference (for startActivityForResult
    // and onRequestPermissionsResult forwarding) — init in configureFlutterEngine
    private PermissionManager permissionManager;

    // Shared cancellation token for search — replaced on every new search call
    // so the previous walk aborts cleanly without needing to kill its thread
    private final AtomicBoolean searchCancellation = new AtomicBoolean(false);

    @Override
    public void configureFlutterEngine(@NotNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        fileScanner = new FileScanner(this);
        permissionManager = new PermissionManager(this);
        context = this;

        BinaryMessenger messenger = flutterEngine.getDartExecutor().getBinaryMessenger();
        new MethodChannel(messenger, CHANNEL).setMethodCallHandler(this::handleCall);
    }


    public void handleCall(MethodCall call, MethodChannel.Result result) {
        // Run every case on a background thread — never block the main thread
        // with file I/O. Reply is always posted back to mainHandler.
        executor.execute(() -> {
            try {
                switch (call.method) {
                    case "checkPermissionStatus" -> handleCheckPermissionStatus(result);
                    case "requestPermission" -> handleRequestPermission(result);
                    case "openAppSettings" -> handleOpenAppSettings(result);
                    case "getStoragePath" -> handleGetStoragePath(result);
                    case "createDirectory" -> handleCreateDirectory(call, result);
                    case "deleteEntry" -> handleDeleteEntry(call, result);
                    case "copyEntry" -> handleCopyEntry(call, result);
                    case "moveEntry" -> handleMoveEntry(call, result);
                    case "renameEntry" -> handleRenameEntry(call, result);
                    case "listDirectory" -> handleListDirectory(call, result);
                    case "searchFiles" -> handleSearchFiles(call, result);
                    case "getStorageInfo" -> handleStorageInfo(result);
                    case "getMedia" -> handleGetMedia(call, result, context);
                    case "getStorageVolumes" -> handleStorageVolumes(context, result);
                    default -> mainHandler.post(result::notImplemented);
                }
            } catch (Exception e) {
                // Catch-all: should rarely fire if each handler validates properly,
                // but keeps the channel from going silent on unexpected errors.
                postError(result, "UNEXPECTED_ERROR", e.getMessage());
            }
        });
    }

    // ─── Handlers ────────────────────────────────────────────────────────────

    private void handleStorageVolumes(Context context, MethodChannel.Result result) {
        final List<Map<String, Object>> deviceStorageManager = DeviceStorageManager.getStorageVolumes(context);
        mainHandler.post(() -> result.success(deviceStorageManager));
    }

    private void handleGetMedia(
            MethodCall call,
            MethodChannel.Result result,
            Context context
    ) {

        String type = call.argument("type");

        List<Map<String, Object>> media;

        switch (Objects.requireNonNull(type)) {
            case "audio":
                media = MediaManager.getAudio(context);
                break;

            case "videos":
                media = MediaManager.getVideos(context);
                break;

            case "images":
                media = MediaManager.getImages(context);
                break;

            case "docs":
                media = MediaManager.getDocuments(context);
                break;

            default:
                postError(result, "INVALID_TYPE", "Unknown media type");
                return;
        }

        mainHandler.post(() -> result.success(media));
    }

    private void handleStorageInfo(MethodChannel.Result result) {
        final Map<String, Long> storageInfo = DeviceStorageManager.getStorageInfo();
        mainHandler.post(() -> result.success(storageInfo));
    }

    private void handleGetStoragePath(MethodChannel.Result result) {
        String path = Environment.getExternalStorageDirectory().getAbsolutePath();
        mainHandler.post(() -> result.success(path));
    }

    private void handleCreateDirectory(MethodCall call, MethodChannel.Result result) {
        String path = call.argument("path");
        if (path == null || path.isEmpty()) {
            postError(result, "INVALID_ARGUMENT", "'path' is required for createDirectory");
            return;
        }
        boolean created = fileOps.createDirectory(path);
        mainHandler.post(() -> result.success(created));
    }

    private void handleDeleteEntry(MethodCall call, MethodChannel.Result result) {
        String path = call.argument("path");
        if (path == null || path.isEmpty()) {
            postError(result, "INVALID_ARGUMENT", "'path' is required for deleteEntry");
            return;
        }
        boolean deleted = fileOps.deleteRecursive(new File(path));
        mainHandler.post(() -> result.success(deleted));
    }

    private void handleCopyEntry(MethodCall call, MethodChannel.Result result) throws IOException {
        String src  = call.argument("path");
        String dest = call.argument("destination");
        if (src == null || src.isEmpty()) {
            postError(result, "INVALID_ARGUMENT", "'path' is required for copyEntry");
            return;
        }
        if (dest == null || dest.isEmpty()) {
            postError(result, "INVALID_ARGUMENT", "'destination' is required for copyEntry");
            return;
        }
        boolean copied = fileOps.copyFileOrDirectory(new File(src), new File(dest));
        mainHandler.post(() -> result.success(copied));
    }

    private void handleMoveEntry(MethodCall call, MethodChannel.Result result) throws IOException {
        String src  = call.argument("path");
        String dest = call.argument("destination");
        if (src == null || src.isEmpty()) {
            postError(result, "INVALID_ARGUMENT", "'path' is required for moveEntry");
            return;
        }
        if (dest == null || dest.isEmpty()) {
            postError(result, "INVALID_ARGUMENT", "'destination' is required for moveEntry");
            return;
        }
        boolean moved = fileOps.moveEntry(src, dest);
        mainHandler.post(() -> result.success(moved));
    }

    private void handleRenameEntry(MethodCall call, MethodChannel.Result result) throws IOException {
        String src  = call.argument("path");
        String dest = call.argument("destination");
        if (src == null || src.isEmpty()) {
            postError(result, "INVALID_ARGUMENT", "'path' is required for renameEntry");
            return;
        }
        if (dest == null || dest.isEmpty()) {
            postError(result, "INVALID_ARGUMENT", "'destination' is required for renameEntry");
            return;
        }
        boolean renamed = fileOps.renameEntry(src, dest);
        mainHandler.post(() -> result.success(renamed));
    }

    private void handleListDirectory(MethodCall call, MethodChannel.Result result) throws Exception {
        String path = call.argument("path");
        Integer page = call.argument("page");
        Integer pageSize = call.argument("pageSize");
        String sortOrder = call.argument("sortOrder");

        if (path == null || path.isEmpty()) {
            postError(result, "INVALID_ARGUMENT", "'path' is required for listDirectory");
            return;
        }

        int p = page != null ? page : 0;
        int ps = pageSize != null ? pageSize : 50;
        String s = sortOrder != null ? sortOrder : FileScanner.SORT_NAME_ASC;

        Map<String, Object> listing = fileScanner.listDirectory(path, p, ps, s);
        mainHandler.post(() -> result.success(listing));
    }

    private void handleSearchFiles(MethodCall call, MethodChannel.Result result) throws Exception {
        String query    = call.argument("query");
        String rootPath = call.argument("rootPath");

        if (query == null || query.isEmpty()) {
            postError(result, "INVALID_ARGUMENT", "'query' is required for searchFiles");
            return;
        }
        if (rootPath == null || rootPath.isEmpty()) {
            postError(result, "INVALID_ARGUMENT", "'rootPath' is required for searchFiles");
            return;
        }

        // Cancel any in-flight search before starting a new one
        searchCancellation.set(true);
        AtomicBoolean thisCancellation = new AtomicBoolean(false);
        // Reassign the field so future calls cancel this one
        // (small race window is acceptable — worst case an extra result comes back)
        searchCancellation.set(false);

        List<Map<String, Object>> matches = fileScanner.searchFiles(query, rootPath, thisCancellation);

        if (!thisCancellation.get()) {
            mainHandler.post(() -> result.success(matches));
        }
        // If cancelled, don't reply — Dart side will receive the newer search's result
    }

    private void handleGetStorageVolumes(MethodChannel.Result result) {
        List<Map<String, Object>> volumes = fileScanner.getStorageVolumes();
        mainHandler.post(() -> result.success(volumes));
    }

    private void handleCheckPermissionStatus(MethodChannel.Result result) {
        // checkPermissionStatus reads static state only — safe on background thread
        Map<String, Object> status = permissionManager.checkPermissionStatus();
        mainHandler.post(() -> result.success(status));
    }

    private void handleRequestPermission(MethodChannel.Result result) {
        // requestPermission calls startActivityForResult / requestPermissions —
        // MUST run on the main thread, not the executor
        mainHandler.post(() -> permissionManager.requestPermission(result));
    }

    private void handleOpenAppSettings(MethodChannel.Result result) {
        mainHandler.post(() -> {
            permissionManager.openAppSettings();
            result.success(null);   // fire-and-forget — no meaningful return value
        });
    }

    // ─── Android lifecycle callbacks ──────────────────────────────────────────

    /**
     * Forward to PermissionManager so it can resolve the pending Dart result
     * when the user responds to a runtime permission dialog (API 26–29, 33+).
     */
    @Override
    public void onRequestPermissionsResult(
            int requestCode, @NotNull String[] permissions, @NotNull int[] grantResults
    ) {
        if (!permissionManager.onRequestPermissionsResult(requestCode, permissions, grantResults)) {
            super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        }
    }

    /**
     * Forward to PermissionManager so it can resolve the pending Dart result
     * when the user returns from the MANAGE_EXTERNAL_STORAGE settings screen (API 30+).
     */
    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        if (!permissionManager.onActivityResult(requestCode, resultCode, data)) {
            super.onActivityResult(requestCode, resultCode, data);
        }
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    /**
     * Posts a result.error() back to the main thread.
     * Always use this instead of calling result.error() directly from a
     * background thread — Flutter will throw a AssertionError otherwise.
     */
    private void postError(MethodChannel.Result result, String code, String message) {
        mainHandler.post(() -> result.error(code, message, null));
    }
}