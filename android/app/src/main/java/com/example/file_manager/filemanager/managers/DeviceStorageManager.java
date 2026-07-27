package com.example.file_manager.filemanager.managers;

import android.content.Context;
import android.os.Build;
import android.os.Environment;
import android.os.StatFs;
import android.os.storage.StorageManager;
import android.os.storage.StorageVolume;

import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class DeviceStorageManager {

    public static Map<String, Long> getStorageInfo() {
        try {
            File storage = Environment.getExternalStorageDirectory();
            StatFs stat = new StatFs(storage.getAbsolutePath());

            Map<String, Long> storageInfo = new HashMap<>();

            long total = stat.getTotalBytes();
            long free = stat.getAvailableBytes();

            storageInfo.put("total", total);
            storageInfo.put("free", free);
            storageInfo.put("used", total - free);

            return storageInfo;

        } catch (Exception e) {
            e.printStackTrace(); // Optional: Log the error

            Map<String, Long> storageInfo = new HashMap<>();
            storageInfo.put("total", 0L);
            storageInfo.put("free", 0L);
            storageInfo.put("used", 0L);

            return storageInfo;
        }
    }

    public static List<Map<String, Object>> getStorageVolumes(Context context) {
        List<Map<String, Object>> volumeList = new ArrayList<>();
        StorageManager storageManager = (StorageManager) context.getSystemService(Context.STORAGE_SERVICE);

        if (storageManager == null) return volumeList;

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            List<StorageVolume> storageVolumes = storageManager.getStorageVolumes();

            for (StorageVolume volume : storageVolumes) {
                Map<String, Object> map = new HashMap<>();

                String state = volume.getState();
                map.put("state", state != null ? state : "mounted");
                map.put("description", volume.getDescription(context));
                map.put("isRemovable", volume.isRemovable());
                map.put("isPrimary", volume.isPrimary());

                String uuid = null;
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    uuid = volume.getUuid();
                }
                map.put("uuid", uuid != null ? uuid : (volume.isPrimary() ? "primary" : "external"));

                File dir = null;
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    dir = volume.getDirectory();
                }
                if (dir == null && volume.isPrimary()) {
                    dir = Environment.getExternalStorageDirectory();
                }

                if (dir != null) {
                    map.put("path", dir.getAbsolutePath());
                    try {
                        StatFs stat = new StatFs(dir.getPath());
                        long totalBytes = stat.getTotalBytes();
                        long availableBytes = stat.getAvailableBytes();
                        map.put("totalBytes", totalBytes);
                        map.put("availableBytes", availableBytes);
                        map.put("usedBytes", totalBytes - availableBytes);
                    } catch (Exception e) {
                        map.put("totalBytes", 0L);
                        map.put("availableBytes", 0L);
                        map.put("usedBytes", 0L);
                    }
                } else {
                    map.put("path", "");
                    map.put("totalBytes", 0L);
                    map.put("availableBytes", 0L);
                    map.put("usedBytes", 0L);
                }
                volumeList.add(map);
            }
        } else {
            File primaryDir = Environment.getExternalStorageDirectory();
            Map<String, Object> map = new HashMap<>();
            map.put("state", Environment.MEDIA_MOUNTED);
            map.put("description", "Internal storage");
            map.put("isRemovable", false);
            map.put("isPrimary", true);
            map.put("uuid", "primary");
            map.put("path", primaryDir.getAbsolutePath());
            try {
                StatFs stat = new StatFs(primaryDir.getPath());
                long totalBytes = stat.getTotalBytes();
                long availableBytes = stat.getAvailableBytes();
                map.put("totalBytes", totalBytes);
                map.put("availableBytes", availableBytes);
                map.put("usedBytes", totalBytes - availableBytes);
            } catch (Exception e) {
                map.put("totalBytes", 0L);
                map.put("availableBytes", 0L);
                map.put("usedBytes", 0L);
            }
            volumeList.add(map);
        }
        return volumeList;
    }
}