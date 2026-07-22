import 'package:flutter/material.dart';

// final ThemeData darkTheme = ThemeData(
//   scaffoldBackgroundColor: Color(0xff020202),
//   colorScheme: ColorScheme.dark(
//     primary: Color(0xFF0088cc),
//     onPrimary: Colors.white,
//     surface: Color(0xff161616),
//     brightness: Brightness.dark,
//   ),
//   appBarTheme: AppBarTheme(
//     backgroundColor: Color(0xff161616),
//     titleSpacing: 0,
    
//   )
// );

final ThemeData darkThemeData = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  fontFamily: 'Poppins',

  colorScheme: const ColorScheme(
    brightness: Brightness.dark,

    // Brand
    primary: Color(0xFFF3F3F3),
    onPrimary: Color(0xFF111111),

    secondary: Color(0xFFB7B7B7),
    onSecondary: Color(0xFF111111),

    tertiary: Color(0xFF8B8B8B),
    onTertiary: Colors.white,

    // Main surfaces
    surface: Color(0xFF171717),
    onSurface: Color(0xFFF5F5F5),

    surfaceContainerLowest: Color(0xFF121212),
    surfaceContainerLow: Color(0xFF171717),
    surfaceContainer: Color(0xFF1D1D1D),
    surfaceContainerHigh: Color(0xFF242424),
    surfaceContainerHighest: Color(0xFF2C2C2C),

    // Background
    surfaceTint: Colors.transparent,

    // Error
    error: Color(0xFFE5484D),
    onError: Colors.white,

    // Outline
    outline: Color(0xFF404040),
    outlineVariant: Color(0xFF2A2A2A),

    // Others
    shadow: Colors.black,
    scrim: Colors.black54,

    inverseSurface: Color(0xFFF3F3F3),
    onInverseSurface: Color(0xFF181818),
    inversePrimary: Color(0xFF292929),
  ),

  scaffoldBackgroundColor: const Color(0xFF121212),
  canvasColor: const Color(0xFF121212),

  dividerColor: const Color(0xFF2C2C2C),

  cardTheme: const CardThemeData(
    color: Color(0xFF1D1D1D),
    elevation: 0,
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF171717),
    elevation: 0,
    centerTitle: false,
  ),
);