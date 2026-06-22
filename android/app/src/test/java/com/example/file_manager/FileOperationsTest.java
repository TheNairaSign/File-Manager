package com.example.file_manager;

import com.example.file_manager.filemanager.FileOperations;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;

import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
public class FileOperationsTest {
    final FileOperations fileOps = new FileOperations();

    @Test
    public void deleteRecursive_deletesNestedDirectory() throws IOException {
        // Arrange — build a real temp dir tree
        File root = Files.createTempDirectory("test_root").toFile();
        new File(root, "subdir/nested").mkdirs();
        new File(root, "subdir/nested/file.txt").createNewFile();


        // Act
        boolean result = fileOps.deleteRecursive(root);

        // Assert
        assertTrue(result);
        assertFalse(root.exists());
    }

    @Test
    public void copyFileOrDirectory_throwsOnMissingSource() {
        File missing = new File("/does/not/exist");
        assertThrows(
                IOException.class, () ->
                fileOps.copyFileOrDirectory(missing, new File("/tmp/dest"))
        );
    }

    @Test
    public void deleteEntry_withNullPath_returnsInvalidArgumentError() {
        // Create a map where 'path' is explicitly null or missing
        Map<String, Object> arguments = new HashMap<>();
        arguments.put("path", null);

        MethodCall call = new MethodCall("deleteEntry", arguments);
        MockResult result = new MockResult();

        JavaMainActivity handler = new JavaMainActivity();
        handler.handleCall(call, result);

        assertEquals("INVALID_ARGUMENT", result.errorCode);
    }
}


