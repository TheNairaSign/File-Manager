package com.example.file_manager;

public class StorageInfo {
    private final long totalBytes;
    private final long freeBytes;

    public StorageInfo(long totalBytes, long freeBytes) {
        this.totalBytes = totalBytes;
        this.freeBytes = freeBytes;
    }

    public long getTotalBytes() {
        return totalBytes;
    }

    public long getFreeBytes() {
        return freeBytes;
    }

    public long getUsedBytes() {
        return totalBytes - freeBytes;
    }
}