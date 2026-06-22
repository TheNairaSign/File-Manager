// test/file_channel_test.dart
import 'package:dartz/dartz.dart';
import 'package:file_manager/core/platform/file_channel.dart';
import 'package:file_manager/core/platform/file_channel_error.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.example.filemanager/files'),
      (call) async {
        switch (call.method) {
          case 'deleteEntry':
            return true;
          case 'createDirectory':
            return true;
          case 'getStoragePath':              // ← add this
            return '/storage/emulated/0';
          default:
            throw PlatformException(code: 'NOT_IMPLEMENTED');
        }
      },
    );
  });

  test('deleteEntry returns Right(true) on success', () async {
    final channel = FileChannel();
    final result = await channel.deleteEntry('/storage/emulated/0/test');
    expect(result, equals(const Right(true)));
  });

  test('deleteEntry returns Left(FileOperationError) on PlatformException', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.example.filemanager/files'),
      (call) async => throw PlatformException(
        code: 'FILE_ERROR',
        message: 'Permission denied',
      ),
    );

    final result = await FileChannel().deleteEntry('/some/path');
    expect(result.isLeft(), true);
    result.fold(
      (err) {
        expect(err, isA<FileOperationError>());
        expect((err as FileOperationError).code, 'FILE_ERROR');
      },
      (_) => fail('expected Left'),
    );
  });
}