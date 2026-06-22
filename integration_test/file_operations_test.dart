// integration_test/file_operations_test.dart
import 'package:dartz/dartz.dart';
import 'package:file_manager/core/platform/file_channel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('createDirectory and deleteEntry round trip', (tester) async {
    final channel = FileChannel();
  
    final pathResult = await channel.getStoragePath();
  
    // ❌ Don't do this
    // final root = (pathResult as Right).value;
  
    // ✅ Check the result first
    expect(pathResult.isRight(), true, reason: 'getStoragePath should succeed');
  
    final root = pathResult.getOrElse(() => '');
    final testPath = '$root/fm_test_${DateTime.now().millisecondsSinceEpoch}';
  
    final created = await channel.createDirectory(testPath);
    expect(created, equals(const Right(true)));
  
    final deleted = await channel.deleteEntry(testPath);
    expect(deleted, equals(const Right(true)));
  });
}