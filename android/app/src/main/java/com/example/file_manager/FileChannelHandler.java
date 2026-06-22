//import android.os.Environment;
//import android.os.Handler;
//import androidx.annotation.NonNull;
//import com.example.file_manager.filemanager.FileOperations;
//import io.flutter.plugin.common.MethodCall;
//import io.flutter.plugin.common.MethodChannel;
//import org.jetbrains.annotations.NotNull;
//
//import java.io.File;
//import java.io.IOException;
//import java.util.concurrent.ExecutorService;
//
//// filemanager/FileChannelHandler.java
//public class FileChannelHandler implements MethodChannel.MethodCallHandler {
//
//    private final FileOperations fileOps;
//    private final Handler mainHandler;
//
//    private final ExecutorService executor;
//
//    // Constructor injection — makes it testable (pass a mock in tests,
//    // pass the real thing in MainActivity)
//    public FileChannelHandler(FileOperations fileOps, Handler mainHandler, ExecutorService executor) {
//        this.fileOps = fileOps;
//        this.mainHandler = mainHandler;
//        this.executor = executor;
//    }
//
//    @Override
//    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
//        executor.execute(() -> {
//            try {
//                switch (call.method) {
//                    case "createDirectory" -> handleCreateDirectory(call, result);
//                    case "deleteEntry"     -> handleDeleteEntry(call, result);
//                    case "copyEntry"       -> handleCopyEntry(call, result);
//                    case "moveEntry"       -> handleMoveEntry(call, result);
//                    case "renameEntry"     -> handleRenameEntry(call, result);
//                    default               -> mainHandler.post(result::notImplemented);
//                }
//            } catch (Exception e) {
//                postError(result, "UNEXPECTED_ERROR", e.getMessage());
//            }
//        });
//    }
//
//    private void handleGetStoragePath(MethodChannel.Result result) {
//        String path = Environment.getExternalStorageDirectory().getAbsolutePath();
//        mainHandler.post(() -> result.success(path));
//    }
//
//    private void handleCreateDirectory(MethodCall call, MethodChannel.Result result) {
//        String path = call.argument("path");
//        if (path == null || path.isEmpty()) {
//            postError(result, "INVALID_ARGUMENT", "'path' is required for createDirectory");
//            return;
//        }
//        boolean created = fileOps.createDirectory(path);
//        mainHandler.post(() -> result.success(created));
//    }
//
//    private void handleDeleteEntry(MethodCall call, MethodChannel.Result result) {
//        String path = call.argument("path");
//        if (path == null || path.isEmpty()) {
//            postError(result, "INVALID_ARGUMENT", "'path' is required for deleteEntry");
//            return;
//        }
//        boolean deleted = fileOps.deleteRecursive(new File(path));
//        mainHandler.post(() -> result.success(deleted));
//    }
//
//    private void handleCopyEntry(MethodCall call, MethodChannel.Result result) throws IOException {
//        String src  = call.argument("path");
//        String dest = call.argument("destination");
//        if (src == null || src.isEmpty()) {
//            postError(result, "INVALID_ARGUMENT", "'path' is required for copyEntry");
//            return;
//        }
//        if (dest == null || dest.isEmpty()) {
//            postError(result, "INVALID_ARGUMENT", "'destination' is required for copyEntry");
//            return;
//        }
//        boolean copied = fileOps.copyFileOrDirectory(new File(src), new File(dest));
//        mainHandler.post(() -> result.success(copied));
//    }
//
//    private void handleMoveEntry(MethodCall call, MethodChannel.Result result) throws IOException {
//        String src  = call.argument("path");
//        String dest = call.argument("destination");
//        if (src == null || src.isEmpty()) {
//            postError(result, "INVALID_ARGUMENT", "'path' is required for moveEntry");
//            return;
//        }
//        if (dest == null || dest.isEmpty()) {
//            postError(result, "INVALID_ARGUMENT", "'destination' is required for moveEntry");
//            return;
//        }
//        boolean moved = fileOps.moveEntry(src, dest);
//        mainHandler.post(() -> result.success(moved));
//    }
//
//    private void handleRenameEntry(MethodCall call, MethodChannel.Result result) throws IOException {
//        String src  = call.argument("path");
//        String dest = call.argument("destination");
//        if (src == null || src.isEmpty()) {
//            postError(result, "INVALID_ARGUMENT", "'path' is required for renameEntry");
//            return;
//        }
//        if (dest == null || dest.isEmpty()) {
//            postError(result, "INVALID_ARGUMENT", "'destination' is required for renameEntry");
//            return;
//        }
//        boolean renamed = fileOps.renameEntry(src, dest);
//        mainHandler.post(() -> result.success(renamed));
//    }
//
//    /**
//     * Posts a result.error() back to the main thread.
//     * Always use this instead of calling result.error() directly from a
//     * background thread — Flutter will throw a AssertionError otherwise.
//     */
//    private void postError(MethodChannel.Result result, String code, String message) {
//        mainHandler.post(() -> result.error(code, message, null));
//    }
//}