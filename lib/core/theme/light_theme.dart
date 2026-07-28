import 'package:flutter/material.dart';

final ThemeData lightThemeData = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  fontFamily: 'Poppins',

  colorScheme: const ColorScheme(
    brightness: Brightness.light,

    // Brand
    primary: Color(0xFF202020),
    onPrimary: Colors.white,

    secondary: Color(0xFF5F5F5F),
    onSecondary: Colors.white,

    tertiary: Color(0xFF7D7D7D),
    onTertiary: Colors.white,

    // Main surfaces
    // surface: Color(0xFFF8F8F8),
    surface: Colors.white,
    onSurface: Color(0xFF181818),

    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Color(0xFFF8F8F8),
    surfaceContainer: Color(0xFFF3F3F3),
    surfaceContainerHigh: Color(0xFFECECEC),
    surfaceContainerHighest: Color(0xFFE4E4E4),

    surfaceTint: Colors.transparent,

    error: Color(0xFFD32F2F),
    onError: Colors.white,

    outline: Color(0xFFD4D4D4),
    outlineVariant: Color(0xFFE8E8E8),

    shadow: Colors.black12,
    scrim: Colors.black54,

    inverseSurface: Color(0xFF1A1A1A),
    onInverseSurface: Colors.white,
    inversePrimary: Color(0xFFF3F3F3),
  ),

  scaffoldBackgroundColor: const Color(0xFFF4F4F4),
  canvasColor: const Color(0xFFF4F4F4),

  dividerColor: const Color(0xFFE2E2E2),

  cardTheme: const CardThemeData(
    color: Colors.white,
    elevation: 0,
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    elevation: 0,
    centerTitle: false,
  ),
);