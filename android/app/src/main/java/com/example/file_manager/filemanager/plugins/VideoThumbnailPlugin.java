package com.example.file_manager.filemanager.plugins;

import android.content.Context;
import android.graphics.Bitmap;
import android.media.MediaMetadataRetriever;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.NonNull;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/**
 * VideoThumbnailPlugin
 */
public class VideoThumbnailPlugin {
    private static final String TAG = "ThumbnailPlugin";
    private static final int HIGH_QUALITY_MIN_VAL = 70;

    private Context context;
    private ExecutorService executor;
    private MethodChannel channel;

//    @Override
//    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
//        context = binding.getApplicationContext();
//        executor = Executors.newCachedThreadPool();
//        channel = new MethodChannel(binding.getBinaryMessenger(), "plugins.justsoft.xyz/video_thumbnail");
//        channel.setMethodCallHandler(this);
//    }
//
//    @Override
//    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
//        channel.setMethodCallHandler(null);
//        channel = null;
//        executor.shutdown();
//        executor = null;
//    }

    @SuppressWarnings("unchecked")
    private static Map<String, String> castHeaders(Object raw) {
        if (raw == null) return null;
        // Defensive: build a clean String->String map instead of blindly
        // trusting the platform-channel deserialization.
        Map<String, String> safe = new HashMap<>();
        if (raw instanceof Map) {
            for (Map.Entry<?, ?> entry : ((Map<?, ?>) raw).entrySet()) {
                if (entry.getKey() instanceof String && entry.getValue() instanceof String) {
                    safe.put((String) entry.getKey(), (String) entry.getValue());
                }
            }
        }
        return safe;
    }

    /**
     * Extracts and returns thumbnail data or file path based on the method call arguments.
     *
     * @param call The Flutter MethodCall containing method name and arguments.
     * @return String (file path) or byte[] (data) depending on method, or null if method is unhandled.
     * @throws Exception if thumbnail processing fails.
     */
    public Object buildThumbnail(MethodCall call) throws Exception {
        final Map<String, Object> args = call.arguments();
        if (args == null) {
            throw new IllegalArgumentException("Arguments cannot be null");
        }

        final String video = (String) args.get("video");
        final Map<String, String> headers = castHeaders(args.get("headers"));
        final int format = intArg(args, "format");
        final int maxh = intArg(args, "maxh");
        final int maxw = intArg(args, "maxw");
        final int timeMs = intArg(args, "timeMs");
        final int quality = intArg(args, "quality");

        switch (call.method) {
            case "file":
                final String path = (String) args.get("path");
                return buildThumbnailFile(video, headers, path, format, maxh, maxw, timeMs, quality);

            case "data":
                return buildThumbnailData(video, headers, format, maxh, maxw, timeMs, quality);

            default:
                return null; // Signals an unhandled/not implemented method
        }
    }

    /** Safely unbox an int argument, defaulting to 0 if missing/null. */
    private static int intArg(Map<String, Object> args, String key) {
        Object v = args.get(key);
        if (v == null) return 0;
        return ((Number) v).intValue();
    }

    @SuppressWarnings("deprecation")
    private static Bitmap.CompressFormat intToFormat(int format) {
        return switch (format) {
            case 1 -> Bitmap.CompressFormat.PNG;
            case 2 -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    yield Bitmap.CompressFormat.WEBP_LOSSY;
                }
                yield Bitmap.CompressFormat.WEBP;
            }
            default -> Bitmap.CompressFormat.JPEG;
        };
    }

    private static String formatExt(int format) {
        return switch (format) {
            case 1 -> "png";
            case 2 -> "webp";
            default -> "jpg";
        };
    }

    private byte[] buildThumbnailData(final String vidPath, final Map<String, String> headers, int format, int maxh,
                                      int maxw, int timeMs, int quality) {
        Bitmap bitmap = createVideoThumbnail(vidPath, headers, maxh, maxw, timeMs);
        if (bitmap == null)
            throw new NullPointerException("Could not decode a frame from: " + vidPath);

        ByteArrayOutputStream stream = new ByteArrayOutputStream();
        bitmap.compress(intToFormat(format), quality, stream);
        bitmap.recycle();
        return stream.toByteArray();
    }

    private String buildThumbnailFile(final String vidPath, final Map<String, String> headers, String path,
                                      int format, int maxh, int maxw, int timeMs,
                                      int quality) {
        final byte[] bytes = buildThumbnailData(vidPath, headers, format, maxh, maxw, timeMs, quality);
        final String ext = formatExt(format);
        final int i = vidPath.lastIndexOf(".");
        String fullpath = vidPath.substring(0, i + 1) + ext;
        final boolean isLocalFile = (vidPath.startsWith("/") || vidPath.startsWith("file://"));

        if (path == null && !isLocalFile) {
            path = context.getCacheDir().getAbsolutePath();
        }

        if (path != null) {
            if (path.endsWith(ext)) {
                fullpath = path;
            } else {
                final int j = fullpath.lastIndexOf("/");

                if (path.endsWith("/")) {
                    fullpath = path + fullpath.substring(j + 1);
                } else {
                    fullpath = path + fullpath.substring(j);
                }
            }
        }

        try (FileOutputStream f = new FileOutputStream(fullpath)) {
            f.write(bytes);
            Log.d(TAG, String.format("buildThumbnailFile( written:%d )", bytes.length));
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        return fullpath;
    }

    private void onResult(final Result result, final Object thumbnail, final boolean handled, final Exception e) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (!handled) {
                    result.notImplemented();
                    return;
                }

                if (e != null) {
                    e.printStackTrace();
                    result.error("exception", e.getMessage(), null);
                    return;
                }

                result.success(thumbnail);
            }
        });
    }

    private static void runOnUiThread(Runnable runnable) {
        new Handler(Looper.getMainLooper()).post(runnable);
    }

    public Bitmap createVideoThumbnail(final String video, final Map<String, String> headers, int targetH,
                                       int targetW, int timeMs) {
        Bitmap bitmap = null;
        MediaMetadataRetriever retriever = new MediaMetadataRetriever();
        try {
            if (video.startsWith("/")) {
                setDataSource(video, retriever);
            } else if (video.startsWith("file://")) {
                setDataSource(video.substring(7), retriever);
            } else {
                retriever.setDataSource(video, (headers != null) ? headers : new HashMap<String, String>());
            }

            if (targetH != 0 || targetW != 0) {
                if (Build.VERSION.SDK_INT >= 27 && targetH != 0 && targetW != 0) {
                    bitmap = retriever.getScaledFrameAtTime(timeMs * 1000L, MediaMetadataRetriever.OPTION_CLOSEST,
                            targetW, targetH);
                } else {
                    bitmap = retriever.getFrameAtTime(timeMs * 1000L, MediaMetadataRetriever.OPTION_CLOSEST);
                    if (bitmap != null) {
                        int width = bitmap.getWidth();
                        int height = bitmap.getHeight();
                        if (targetW == 0) {
                            targetW = Math.round(((float) targetH / height) * width);
                        }
                        if (targetH == 0) {
                            targetH = Math.round(((float) targetW / width) * height);
                        }
                        Log.d(TAG, String.format("original w:%d, h:%d => %d, %d", width, height, targetW, targetH));
                        bitmap = Bitmap.createScaledBitmap(bitmap, targetW, targetH, true);
                    }
                }
            } else {
                bitmap = retriever.getFrameAtTime(timeMs * 1000L, MediaMetadataRetriever.OPTION_CLOSEST);
            }
        } catch (RuntimeException | IOException ex) {
            ex.printStackTrace();
        } finally {
            try {
                retriever.release();
            } catch (RuntimeException | IOException ex) {
                ex.printStackTrace();
            }
        }

        return bitmap;
    }

    private static void setDataSource(String video, final MediaMetadataRetriever retriever) throws IOException {
        File videoFile = new File(video);
        try (FileInputStream inputStream = new FileInputStream(videoFile.getAbsolutePath())) {
            retriever.setDataSource(inputStream.getFD());
        }
    }
}