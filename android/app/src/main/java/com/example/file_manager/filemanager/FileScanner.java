package com.example.file_manager.filemanager;

import android.content.Context;
import android.database.Cursor;
import android.net.Uri;
import android.provider.MediaStore;
import android.webkit.MimeTypeMap;
import org.jetbrains.annotations.NotNull;

import java.io.File;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * Scanner — directory listing and file search.
 *
 * All methods are synchronous and designed to run on a background thread
 * (ExecutorService in MainActivity). Nothing here touches the main thread.
 *
 * Two implementations per operation:
 *   - MediaStore-backed: fast, uses Android's indexed database.
 *     Best for media files (images, video, audio) in standard locations.
 *   - File API fallback: works for any path, including non-indexed dirs
 *     (Downloads, Documents, app-specific folders, SD card subdirs).
 *
 * listDirectory uses File API (reliable across all paths, paginated).
 * searchFiles uses MediaStore for media types, File API for everything else.
 */
public class FileScanner {

    private final Context context;

    // Sort options — passed from Dart as a string argument
    public static final String SORT_NAME_ASC   = "name_asc";
    public static final String SORT_NAME_DESC  = "name_desc";
    public static final String SORT_SIZE_ASC   = "size_asc";
    public static final String SORT_SIZE_DESC  = "size_desc";
    public static final String SORT_DATE_ASC   = "date_asc";
    public static final String SORT_DATE_DESC  = "date_desc";

    public FileScanner(Context context) {
        this.context = context;
    }

    // ─── Directory listing ────────────────────────────────────────────────────

    /**
     * Lists the contents of a directory, paginated.
     *
     * Returns a Map with two keys:
     *   "items"   → List<Map<String, Object>>  (the file entries for this page)
     *   "hasMore" → Boolean                    (true if more pages exist)
     *
     * Each item map matches the FileItem model in file_channel.dart:
     *   name, path, isDirectory, size, lastModified, mimeType (nullable)
     *
     * @param directoryPath Absolute path to list
     * @param page          0-indexed page number
     * @param pageSize      Number of items per page (recommend 50)
     * @param sortOrder     One of the SORT_* constants above
     * @return              Map with "items" and "hasMore", or throws on error
     */
    public Map<String, Object> listDirectory(
            String directoryPath,
            int page,
            int pageSize,
            String sortOrder
    ) throws Exception {

        File[] allFiles = getFiles(directoryPath);

        // Sort before paginating — result must be stable across pages
        List<File> sorted = sortFiles(allFiles, sortOrder);

        // Paginate
        int totalCount = sorted.size();
        int fromIndex = page * pageSize;
        int toIndex = Math.min(fromIndex + pageSize, totalCount);
        boolean hasMore = toIndex < totalCount;

        List<Map<String, Object>> items = new ArrayList<>();

        // Return empty page if caller asked beyond the end
        if (fromIndex < totalCount) {
            List<File> page_files = sorted.subList(fromIndex, toIndex);
            for (File file : page_files) {
                items.add(fileToMap(file));
            }
        }

        Map<String, Object> result = new HashMap<>();
        result.put("items", items);
        result.put("hasMore", hasMore);
        return result;
    }

    private static File @NotNull [] getFiles(String directoryPath) throws Exception {
        final File directory = new File(directoryPath);

        if (!directory.exists()) {
            throw new Exception("Directory not found: " + directoryPath);
        }
        if (!directory.isDirectory()) {
            throw new Exception("Path is not a directory: " + directoryPath);
        }
        if (!directory.canRead()) {
            throw new Exception("Permission denied reading: " + directoryPath);
        }

        File[] allFiles = directory.listFiles();
        if (allFiles == null) {
            // listFiles() returns null on I/O error (not just empty dir)
            throw new Exception("Could not read directory contents: " + directoryPath);
        }
        return allFiles;
    }

//    public static List<FolderInfo> getSubFolders(String directoryPath) {
//
//        List<FolderInfo> folders = new ArrayList<>();
//
//        File directory = new File(directoryPath);
//
//        if (!directory.exists() || !directory.isDirectory()) {
//            return folders;
//        }
//
//        File[] files = directory.listFiles();
//
//        if (files == null) {
//            return folders;
//        }
//
//        for (File file : files) {
//            if (file.isDirectory()) {
//
//                File[] children = file.listFiles();
//                int itemCount = children == null ? 0 : children.length;
//
//                folders.add(
//                        new FolderInfo(
//                                file.getName(),
//                                file.getAbsolutePath(),
//                                itemCount
//                        )
//                );
//            }
//        }

//        return folders;
//    }

    // ─── Search ───────────────────────────────────────────────────────────────

    /**
     * Searches recursively under rootPath for entries whose name contains query.
     *
     * Uses MediaStore for media files (much faster on large libraries —
     * avoids walking 200K image files manually). Falls back to recursive
     * File walk for non-media paths and file types.
     *
     * @param query         Case-insensitive substring to match against file name
     * @param rootPath      Absolute path to search from
     * @param cancellation  Set to true from the calling thread to abort mid-search.
     *                      Check this in the Dart layer on every new keystroke —
     *                      cancel the previous search before starting a new one.
     * @return              List of matching FileItem maps
     */
    public List<Map<String, Object>> searchFiles(
            String query,
            String rootPath,
            AtomicBoolean cancellation
    ) throws Exception {

        if (query == null || query.trim().isEmpty()) {
            return Collections.emptyList();
        }

        String lowerQuery = query.trim().toLowerCase();
        List<Map<String, Object>> results = new ArrayList<>();

        // MediaStore search — covers images, video, audio efficiently
        searchMediaStore(lowerQuery, rootPath, cancellation, results);

        // File walk search — covers documents, zips, apks, anything MediaStore misses
        if (!cancellation.get()) {
            File root = new File(rootPath);
            if (root.exists() && root.isDirectory()) {
                walkAndSearch(root, lowerQuery, cancellation, results);
            }
        }

        return results;
    }

    /**
     * Returns available storage volumes (internal + SD card if present).
     * Each map has: "path", "name", "totalBytes", "freeBytes", "isRemovable"
     */
    public List<Map<String, Object>> getStorageVolumes() {
        List<Map<String, Object>> volumes = new ArrayList<>();

        // Internal storage is always present
        File internal = android.os.Environment.getExternalStorageDirectory();
        volumes.add(buildVolumeMap(internal, "Internal Storage", false));

        // SD card — check secondary storage paths
        // Environment.getExternalStoragePaths() is API 19+ but hidden;
        // check common mount points as a reliable fallback
        String[] sdCardPaths = {
                "/storage/sdcard1",
                "/storage/extsdcard",
                "/storage/external_SD",
                "/mnt/extsd"
        };
        for (String sdPath : sdCardPaths) {
            File sd = new File(sdPath);
            if (sd.exists() && sd.canRead()) {
                volumes.add(buildVolumeMap(sd, "SD Card", true));
                break; // take the first valid one
            }
        }

        return volumes;
    }

    private void searchMediaStore(
            String lowerQuery,
            String rootPath,
            AtomicBoolean cancellation,
            List<Map<String, Object>> results
    ) {
        // Search across all three media collections
        searchMediaCollection(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                lowerQuery, rootPath, cancellation, results
        );
        if (!cancellation.get()) {
            searchMediaCollection(
                    MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                    lowerQuery, rootPath, cancellation, results
            );
        }
        if (!cancellation.get()) {
            searchMediaCollection(
                    MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                    lowerQuery, rootPath, cancellation, results
            );
        }
    }

    private void searchMediaCollection(
            Uri collectionUri,
            String lowerQuery,
            String rootPath,
            AtomicBoolean cancellation,
            List<Map<String, Object>> results
    ) {
        String[] projection = {
                MediaStore.MediaColumns.DISPLAY_NAME,
                MediaStore.MediaColumns.DATA,           // absolute path
                MediaStore.MediaColumns.SIZE,
                MediaStore.MediaColumns.DATE_MODIFIED,
                MediaStore.MediaColumns.MIME_TYPE,
        };

        // Filter by name (LIKE) and root path to scope the search
        String selection = MediaStore.MediaColumns.DISPLAY_NAME + " LIKE ? AND "
                + MediaStore.MediaColumns.DATA + " LIKE ?";
        String[] selectionArgs = { "%" + lowerQuery + "%", rootPath + "%" };

        try (Cursor cursor = context.getContentResolver().query(
                collectionUri, projection, selection, selectionArgs,
                MediaStore.MediaColumns.DISPLAY_NAME + " ASC"
        )) {
            if (cursor == null) return;

            int nameCol = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DISPLAY_NAME);
            int pathCol = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATA);
            int sizeCol = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.SIZE);
            int dateCol = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATE_MODIFIED);
            int mimeCol = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.MIME_TYPE);

            while (cursor.moveToNext() && !cancellation.get()) {
                Map<String, Object> item = new HashMap<>();
                item.put("name", cursor.getString(nameCol));
                item.put("path", cursor.getString(pathCol));
                item.put("isDirectory",  false);
                item.put("size", cursor.getLong(sizeCol));
                // MediaStore stores seconds, FileItem expects milliseconds
                item.put("lastModified", cursor.getLong(dateCol) * 1000L);
                item.put("mimeType", cursor.getString(mimeCol));
                results.add(item);
            }
        } catch (Exception e) {
            // MediaStore query failed (e.g. permission not granted yet) —
            // log and continue; File walk below will still catch media files
            android.util.Log.w("Scanner", "MediaStore query failed: " + e.getMessage());
        }
    }

    // ─── Private: recursive file walk ────────────────────────────────────────

    private void walkAndSearch(
            File dir,
            String lowerQuery,
            AtomicBoolean cancellation,
            List<Map<String, Object>> results
    ) {
        if (cancellation.get()) return;

        File[] children = dir.listFiles();
        if (children == null) return;

        for (File child : children) {
            if (cancellation.get()) return;

            if (child.getName().toLowerCase().contains(lowerQuery)) {
                // Only add non-media files here — MediaStore already got images/video/audio
                String mime = getMimeType(child);
                if (!isMediaMime(mime)) {
                    results.add(fileToMap(child));
                }
            }

            // Recurse into subdirectories
            if (child.isDirectory() && child.canRead()) {
                walkAndSearch(child, lowerQuery, cancellation, results);
            }
        }
    }

    // ─── Private: sorting ─────────────────────────────────────────────────────

    private List<File> sortFiles(File[] files, String sortOrder) {
        List<File> list = new ArrayList<>();

        // Directories always come before files regardless of sort order —
        // consistent with how every major file manager handles it
        List<File> dirs = new ArrayList<>();
        List<File> plain = new ArrayList<>();
        for (File f : files) {
            if (f.isDirectory()) dirs.add(f); else plain.add(f);
        }

        Comparator<File> comparator = switch (sortOrder) {
            case SORT_NAME_DESC -> (a, b) -> b.getName().compareToIgnoreCase(a.getName());
            case SORT_SIZE_ASC -> Comparator.comparingLong(File::length);
            case SORT_SIZE_DESC -> (a, b) -> Long.compare(b.length(), a.length());
            case SORT_DATE_ASC -> Comparator.comparingLong(File::lastModified);
            case SORT_DATE_DESC -> (a, b) -> Long.compare(b.lastModified(), a.lastModified());
            default -> (a, b) -> a.getName().compareToIgnoreCase(b.getName()); // SORT_NAME_ASC
        };

        dirs.sort(comparator);
        plain.sort(comparator);

        list.addAll(dirs);
        list.addAll(plain);
        return list;
    }

    /**
     * Converts a File to the Map structure expected by FileItem.fromMap() in Dart.
     * Fields must exactly match the factory constructor in file_channel.dart.
     */
    private Map<String, Object> fileToMap(File file) {
        Map<String, Object> map = new HashMap<>();
        map.put("name", file.getName());
        map.put("path", file.getAbsolutePath());
        map.put("isDirectory", file.isDirectory());
        map.put("size", file.isDirectory() ? 0L : file.length());
        map.put("lastModified", file.lastModified());  // already milliseconds
        map.put("mimeType", file.isDirectory() ? null : getMimeType(file));
        return map;
    }

    /**
     * Returns the MIME type for a file based on its extension.
     * Returns null for unknown types — Dart side handles null gracefully.
     */
    private String getMimeType(File file) {
        String name = file.getName();
        int dot = name.lastIndexOf('.');
        if (dot < 0) return null;
        String ext = name.substring(dot + 1).toLowerCase();
        return MimeTypeMap.getSingleton().getMimeTypeFromExtension(ext);
    }

    /** Returns true for MIME types already covered by MediaStore queries. */
    private boolean isMediaMime(String mime) {
        if (mime == null) return false;
        return mime.startsWith("image/")
                || mime.startsWith("video/")
                || mime.startsWith("audio/");
    }

    private Map<String, Object> buildVolumeMap(File root, String name, boolean isRemovable) {
        Map<String, Object> map = new HashMap<>();
        map.put("path", root.getAbsolutePath());
        map.put("name", name);
        map.put("totalBytes", root.getTotalSpace());
        map.put("freeBytes", root.getFreeSpace());
        map.put("isRemovable", isRemovable);
        return map;
    }
}