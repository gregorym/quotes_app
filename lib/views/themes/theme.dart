import 'package:flutter/material.dart';
import 'package:quotes_app/views/themes/colors.dart';

class MyTheme {
  static MaterialColor _swatch(Color color) {
    return MaterialColor(
      color.toARGB32(),
      <int, Color>{
        50: color.withValues(alpha: 0.1),
        100: color.withValues(alpha: 0.2),
        200: color.withValues(alpha: 0.3),
        300: color.withValues(alpha: 0.4),
        400: color.withValues(alpha: 0.5),
        500: color.withValues(alpha: 0.6),
        600: color.withValues(alpha: 0.7),
        700: color.withValues(alpha: 0.8),
        800: color.withValues(alpha: 0.9),
        900: color,
      },
    );
  }

  // Light Theme
  static final lightTheme = ThemeData(
    colorSchemeSeed: _swatch(MyColors.primary),
    useMaterial3: true,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    scaffoldBackgroundColor: MyColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: MyColors.background,
      elevation: 0,
      foregroundColor: MyColors.ink,
      surfaceTintColor: Colors.transparent,
    ),
  );

  // Dark Theme
  static final darkTheme = ThemeData(
    useMaterial3: true,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    colorSchemeSeed: _swatch(MyColors.primary),
    scaffoldBackgroundColor: MyColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: MyColors.background,
      elevation: 0,
      foregroundColor: MyColors.ink,
      surfaceTintColor: Colors.transparent,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: MyColors.surface,
      selectedItemColor: MyColors.primary,
      unselectedItemColor: MyColors.muted,
    ),
  );
}
