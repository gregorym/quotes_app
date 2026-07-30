import 'package:flutter/material.dart';
import 'package:quotes_app/views/themes/colors.dart';

class MyTypography {
  static const displayFontFamily = 'Anton';
  static const bodyFontFamily = 'Nunito Sans';
  static const quoteFontFamily = displayFontFamily;

  // * Headings
  static const TextStyle h1 = TextStyle(
    fontFamily: displayFontFamily,
    fontSize: 34,
    fontWeight: FontWeight.w400,
    color: MyColors.black,
    height: 1.05,
    letterSpacing: -0.6,
  );
  static const TextStyle h2 = TextStyle(
    fontFamily: displayFontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w400,
    color: MyColors.black,
    height: 1.05,
    letterSpacing: -0.4,
  );
  static const TextStyle h3 = TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w900,
    color: MyColors.black,
    height: 1.1,
  );

  // * Body
  static const TextStyle body1 = TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: MyColors.black,
    height: 1.25,
  );
  static const TextStyle body2 = TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: MyColors.black,
    height: 1.25,
  );

  static const TextStyle quote = TextStyle(
    fontFamily: displayFontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w400,
    color: MyColors.black,
    height: 1.08,
  );

  // * Caption
  static const TextStyle caption1 = TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: MyColors.muted,
    height: 1.25,
  );
}
