import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/quote_model.dart';
import '../themes/colors.dart';

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
        color: MyColors.darkPanel,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Background pattern
          if (showBackgroundPattern)
            Positioned(
              left: 168 + 30,
              top: -70 - 10,
              child: Image.asset(
                "assets/images/img_bg_pattern.png",
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
                const Icon(Icons.format_quote, size: 70, color: MyColors.teal),
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
                      fontSize: 28,
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
