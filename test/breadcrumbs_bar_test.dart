import 'package:file_manager/features/browser/presentation/widgets/breadcrumbs_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BreadcrumbsBar Widget Tests', () {
    testWidgets('renders Home for empty path', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BreadcrumbsBar(currentPath: ''),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('renders segments correctly for storage path', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BreadcrumbsBar(
              currentPath: '/storage/emulated/0/Download/Documents',
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);
      expect(find.text('Documents'), findsOneWidget);
    });
  });
}
