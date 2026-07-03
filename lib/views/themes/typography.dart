import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quotes_app/views/themes/colors.dart';

class MyTypography {
  static const quoteFontFamily = 'Roboto Slab';

  // * Headings
  static TextStyle h1 = GoogleFonts.getFont(
    'Nunito Sans',
    fontSize: 34,
    fontWeight: FontWeight.w900,
    color: MyColors.black,
    height: 1.12,
  );
  static TextStyle h2 = GoogleFonts.getFont(
    'Nunito Sans',
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: MyColors.black,
    height: 1.12,
  );
  static TextStyle h3 = GoogleFonts.getFont(
    'Nunito Sans',
    fontSize: 22,
    fontWeight: FontWeight.w900,
    color: MyColors.black,
    height: 1.12,
  );

  // * Body
  static TextStyle body1 = GoogleFonts.getFont(
    'Nunito Sans',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: MyColors.black,
    height: 1.25,
  );
  static TextStyle body2 = GoogleFonts.getFont(
    'Nunito Sans',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: MyColors.black,
    height: 1.25,
  );

  static TextStyle quote = GoogleFonts.getFont(
    quoteFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: MyColors.black,
    height: 1.25,
  );

  // * Caption
  static TextStyle caption1 = GoogleFonts.getFont(
    'Nunito Sans',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: MyColors.muted,
    height: 1.25,
  );
}
