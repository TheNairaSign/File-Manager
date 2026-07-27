package com.example.file_manager.filemanager.managers;

import android.content.Context;
import android.database.Cursor;
import android.provider.MediaStore;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class MediaManager {

    public static List<Map<String, Object>> getImages(Context context) {

        List<Map<String, Object>> images = new ArrayList<>();

        String[] projection = {
                MediaStore.Images.Media._ID,
                MediaStore.Images.Media.DISPLAY_NAME,
                MediaStore.Images.Media.DATA,
                MediaStore.Images.Media.SIZE,
                MediaStore.Images.Media.DATE_MODIFIED,
                MediaStore.Images.Media.MIME_TYPE
        };

        Cursor cursor = context.getContentResolver().query(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                projection,
                null,
                null,
                MediaStore.Images.Media.DATE_MODIFIED + " DESC"
        );

        if (cursor != null) {

            int id = cursor.getColumnIndexOrThrow(MediaStore.Images.Media._ID);
            int name = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DISPLAY_NAME);
            int path = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA);
            int size = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.SIZE);
            int date = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATE_MODIFIED);
            int mime = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.MIME_TYPE);

            while (cursor.moveToNext()) {

                images.add(
                        createMediaMap(cursor, id, name, size, date, mime, path)
                );
            }

            cursor.close();
        }

        return images;
    }

    public static List<Map<String, Object>> getVideos(Context context) {

        List<Map<String, Object>> videos = new ArrayList<>();

        String[] projection = new String[]{
                MediaStore.Video.Media._ID,
                MediaStore.Video.Media.DISPLAY_NAME,
                MediaStore.Video.Media.DATA,
                MediaStore.Video.Media.SIZE,
                MediaStore.Video.Media.DATE_MODIFIED,
                MediaStore.Video.Media.MIME_TYPE,
                MediaStore.Video.Media.DURATION,
                MediaStore.Video.Media.WIDTH,
                MediaStore.Video.Media.HEIGHT
        };

        Cursor cursor = context.getContentResolver().query(
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                projection,
                null,
                null,
                MediaStore.Video.Media.DATE_MODIFIED + " DESC"
        );

        if (cursor != null) {

            int id = cursor.getColumnIndexOrThrow(MediaStore.Video.Media._ID);
            int name = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.DISPLAY_NAME);
            int path = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.DATA);
            int size = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.SIZE);
            int date = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.DATE_MODIFIED);
            int mime = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.MIME_TYPE);
            int duration = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.DURATION);
            int width = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.WIDTH);
            int height = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.HEIGHT);

            while (cursor.moveToNext()) {

                videos.add(
                        createMediaMap(cursor, id, name, size, date, mime, path, duration, height, width)
                );
            }

            cursor.close();
        }

        return videos;
    }

    public static List<Map<String, Object>> getAudio(Context context) {

        List<Map<String, Object>> audio = new ArrayList<>();

        String[] projection = {
                MediaStore.Audio.Media._ID,
                MediaStore.Audio.Media.DISPLAY_NAME,
                MediaStore.Audio.Media.DATA,
                MediaStore.Audio.Media.SIZE,
                MediaStore.Audio.Media.DATE_MODIFIED,
                MediaStore.Audio.Media.MIME_TYPE,
                MediaStore.Audio.Media.ARTIST,
                MediaStore.Audio.Media.ALBUM,
                MediaStore.Audio.Media.DURATION
        };

        Cursor cursor = context.getContentResolver().query(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                projection,
                null,
                null,
                MediaStore.Audio.Media.DATE_MODIFIED + " DESC"
        );

        if (cursor != null) {

            int id = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID);
            int name = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DISPLAY_NAME);
            int path = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA);
            int size = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.SIZE);
            int date = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_MODIFIED);
            int mime = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.MIME_TYPE);

            int artist = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST);
            int album = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM);
            int duration = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION);

            while (cursor.moveToNext()) {

                Map<String, Object> media =
                        createMediaMap(cursor, id, name, size, date, mime, path);

                media.put("artist", cursor.getString(artist));
                media.put("album", cursor.getString(album));
                media.put("duration", cursor.getLong(duration));

                audio.add(media);
            }

            cursor.close();
        }

        return audio;
    }

    public static List<Map<String, Object>> getDocuments(Context context) {

        List<Map<String, Object>> docs = new ArrayList<>();

        String[] projection = {
                MediaStore.Files.FileColumns._ID,
                MediaStore.Files.FileColumns.DISPLAY_NAME,
                MediaStore.Files.FileColumns.DATA,
                MediaStore.Files.FileColumns.SIZE,
                MediaStore.Files.FileColumns.DATE_MODIFIED,
                MediaStore.Files.FileColumns.MIME_TYPE
        };

        String selection =
                MediaStore.Files.FileColumns.MIME_TYPE + "=? OR " +
                        MediaStore.Files.FileColumns.MIME_TYPE + "=? OR " +
                        MediaStore.Files.FileColumns.MIME_TYPE + "=?";

        String[] args = {
                "application/pdf",
                "application/msword",
                "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        };

        Cursor cursor = context.getContentResolver().query(
                MediaStore.Files.getContentUri("external"),
                projection,
                selection,
                args,
                MediaStore.Files.FileColumns.DATE_MODIFIED + " DESC"
        );

        if (cursor != null) {

            int id = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns._ID);
            int name = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DISPLAY_NAME);
            int path = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATA);
            int size = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.SIZE);
            int date = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATE_MODIFIED);
            int mime = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.MIME_TYPE);

            while (cursor.moveToNext()) {

                docs.add(
                        createMediaMap(cursor, id, name, size, date, mime, path)
                );
            }

            cursor.close();
        }

        return docs;
    }

    private static Map<String, Object> createMediaMap(
        Cursor cursor,
        int idIndex,
        int nameIndex,
        int sizeIndex,
        int dateIndex,
        int mimeIndex,
        int pathIndex,
        int durationIndex,
        int heightIndex,
        int widthIndex
    ) {

            Map<String, Object> media = new HashMap<>();

            media.put("id", cursor.getLong(idIndex));
            media.put("name", cursor.getString(nameIndex));
            media.put("path", cursor.getString(pathIndex));
            media.put("size", cursor.getLong(sizeIndex));
            media.put("mimeType", cursor.getString(mimeIndex));
            media.put("dateModified", cursor.getLong(dateIndex));

            media.put("duration", cursor.getLong(durationIndex));
            media.put("width", cursor.getInt(widthIndex));
            media.put("height", cursor.getInt(heightIndex));

            return media;
    }

    private static Map<String, Object> createMediaMap(
        Cursor cursor,
        int idIndex,
        int nameIndex,
        int sizeIndex,
        int dateIndex,
        int mimeIndex,
        int pathIndex
    ) {

            Map<String, Object> media = new HashMap<>();

            media.put("id", cursor.getLong(idIndex));
            media.put("name", cursor.getString(nameIndex));
            media.put("path", cursor.getString(pathIndex));
            media.put("size", cursor.getLong(sizeIndex));
            media.put("mimeType", cursor.getString(mimeIndex));
            media.put("dateModified", cursor.getLong(dateIndex));

            return media;
    }
}
