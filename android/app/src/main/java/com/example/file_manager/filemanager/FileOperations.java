// copy/move/delete/rename/create

package com.example.file_manager.filemanager;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;

/**
 * Pure service layer — no MethodChannel or Context references here.
 * All methods are synchronous and safe to call from any background thread.
 * Threading (ExecutorService) is the caller's responsibility (FileChannelHandler).
 */
public class FileOperations {

    public boolean createDirectory(String absolutePath) {
        if (absolutePath == null || absolutePath.isEmpty()) return false;
        File folder = new File(absolutePath);
        if (folder.exists()) return folder.isDirectory();
        return folder.mkdirs();
    }

    public boolean deleteRecursive(File fileOrDirectory) {
        if (!fileOrDirectory.exists()) return true;

        if (fileOrDirectory.isDirectory()) {
            File[] children = fileOrDirectory.listFiles();
            if (children != null) {
                for (File child : children) {
                    if (!deleteRecursive(child)) return false;
                }
            }
        }
        return fileOrDirectory.delete();
    }

    /**
     * Renames (or moves within the same volume) a file or directory.
     * Prefer this over copyEntry + deleteEntry when source and destination
     * are on the same filesystem — it's atomic and instant.
     */
    public boolean renameEntry(String sourcePath, String destinationPath) throws IOException {
        File source = new File(sourcePath);
        if (!source.exists()) throw new IOException("Source not found: " + sourcePath);

        File destination = new File(destinationPath);
        if (destination.exists()) return false; // don't silently overwrite

        return source.renameTo(destination);
    }

    /**
     * Copies a file or directory tree from source to destination.
     * Uses java.nio.file.Files.copy (API 26+) for individual files, which
     * hands the work to the OS and avoids the double-close resource-leak bug
     * in the original FileChannel approach.
     */
    public boolean copyFileOrDirectory(File source, File destination) throws IOException {
        if (!source.exists()) throw new IOException("Source not found: " + source.getAbsolutePath());

        if (source.isDirectory()) {
            if (!destination.exists() && !destination.mkdirs()) {
                throw new IOException("Could not create destination directory: " + destination.getAbsolutePath());
            }
            File[] children = source.listFiles();
            if (children != null) {
                for (File child : children) {
                    copyFileOrDirectory(child, new File(destination, child.getName()));
                }
            }
        } else {
            // Ensure parent directory exists
            File parent = destination.getParentFile();
            if (parent != null && !parent.exists() && !parent.mkdirs()) {
                throw new IOException("Could not create parent directory: " + parent.getAbsolutePath());
            }
            Files.copy(source.toPath(), destination.toPath());
        }
        return true;
    }

    /**
     * Moves a file or directory.
     * Strategy:
     *   1. Try File.renameTo — instant on same volume (no data copied)
     *   2. Fall back to copy + delete for cross-volume moves
     */
    public boolean moveEntry(String sourcePath, String destinationPath) throws IOException {
        File source = new File(sourcePath);
        File destination = new File(destinationPath);

        if (!source.exists()) throw new IOException("Source not found: " + sourcePath);

        // Fast path — same filesystem
        if (source.renameTo(destination)) return true;

        // Slow path — cross-volume: copy then delete original
        boolean copied = copyFileOrDirectory(source, destination);
        if (!copied) return false;

        boolean deleted = deleteRecursive(source);
        if (!deleted) {
            // Copy succeeded but cleanup failed — don't leave a duplicate silently
            throw new IOException("Move copied successfully but could not delete source: " + sourcePath);
        }
        return true;
    }
}