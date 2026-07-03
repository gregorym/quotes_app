import 'package:flutter/material.dart';
import 'package:quotes_app/views/themes/colors.dart';

class MyTheme {
  static final _scheme = ColorScheme.fromSeed(
    seedColor: MyColors.primary,
    brightness: Brightness.dark,
    surface: MyColors.surface,
  );

  // Light Theme
  static final lightTheme = ThemeData(
    colorScheme: _scheme,
    useMaterial3: true,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    scaffoldBackgroundColor: MyColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: MyColors.background,
      elevation: 0,
      foregroundColor: MyColors.ink,
      surfaceTintColor: Colors.transparent,
    ),
    iconTheme: const IconThemeData(color: MyColors.ink),
    canvasColor: MyColors.darkPanel,
    cardColor: MyColors.surface,
  );

  // Dark Theme
  static final darkTheme = ThemeData(
    useMaterial3: true,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    colorScheme: _scheme,
    scaffoldBackgroundColor: MyColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: MyColors.background,
      elevation: 0,
      foregroundColor: MyColors.ink,
      surfaceTintColor: Colors.transparent,
    ),
    iconTheme: const IconThemeData(color: MyColors.ink),
    canvasColor: MyColors.darkPanel,
    cardColor: MyColors.surface,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: MyColors.surface,
      selectedItemColor: MyColors.primary,
      unselectedItemColor: MyColors.muted,
    ),
  );
}
