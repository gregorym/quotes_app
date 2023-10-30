import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../models/quote_model.dart';

class QuotWidgetShare extends StatelessWidget {
  const QuotWidgetShare({
    super.key,
    required this.quote,
    required this.height,
    required this.width,
    this.showBackgroundPattern = false,
  });
  final Quote quote;
  final double height;
  final double width;
  final bool showBackgroundPattern;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(36),
      ),
      child: Stack(
        children: [
          // Background pattern
          if (showBackgroundPattern)
            Positioned(
              left: 168 + 30,
              top: -70 - 10,
              child: Image.asset(
                "assets/img_bg_pattern.png",
                width: 254,
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 30,
              vertical: 50,
            ),
            child: Column(
              children: [
                Icon(
                  PhosphorIcons.fill.quotes,
                  size: 70,
                  color: Colors.white
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: AutoSizeText(
                    quote.content,
                    maxFontSize: 28,
                    minFontSize: 18,
                    maxLines: 10,
                    style: GoogleFonts.getFont(
                      "Nunito Sans",
                      color: Colors.white,
                      fontSize:  28,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
