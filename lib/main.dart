import 'package:file_manager/core/theme/dark_theme.dart';
import 'package:file_manager/core/theme/light_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_manager/features/browser/presentation/pages/browser_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'File Manager',
      theme: lightThemeData,
      darkTheme: darkThemeData,
      // themeMode: ThemeMode.dark,
      home: const BrowserPage(),
    );
  }
}
