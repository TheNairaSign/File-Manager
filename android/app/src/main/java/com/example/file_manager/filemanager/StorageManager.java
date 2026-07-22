package com.example.file_manager.filemanager;

import android.os.Environment;
import android.os.StatFs;
import com.example.file_manager.StorageInfo;

import java.io.File;
import java.util.HashMap;
import java.util.Map;

public class StorageManager {

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
}