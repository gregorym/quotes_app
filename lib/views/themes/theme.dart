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
    fontFamily: 'Nunito Sans',
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
    dividerColor: MyColors.disabled,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: MyColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(58),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: MyColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
    ),
  );

  // Dark Theme
  static final darkTheme = lightTheme;
}
