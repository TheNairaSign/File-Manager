package com.example.file_manager;

import io.flutter.plugin.common.MethodChannel;
import org.jetbrains.annotations.NotNull;

// Add this class inside your test file or as a separate file in your test directory
public class MockResult implements MethodChannel.Result {
    public Object successResult;
    public String errorCode;
    public String errorMessage;
    public Object errorDetails;
    public boolean notImplemented = false;

    @Override
    public void success(Object result) {
        this.successResult = result;
    }

    @Override
    public void error(@NotNull String errorCode, String errorMessage, Object errorDetails) {
        this.errorCode = errorCode;
        this.errorMessage = errorMessage;
        this.errorDetails = errorDetails;
    }

    @Override
    public void notImplemented() {
        this.notImplemented = true;
    }
}
