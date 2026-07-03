import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../../models/quote_model.dart';
import '../themes/typography.dart';
import 'app_background.dart';

class QuotWidgetShare extends StatelessWidget {
  const QuotWidgetShare({
    super.key,
    required this.quote,
    required this.height,
    required this.width,
  });
  final Quote quote;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: AppBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: AutoSizeText(
              quote.content,
              textAlign: TextAlign.center,
              maxFontSize: 34,
              minFontSize: 18,
              maxLines: 9,
              style: MyTypography.quote.copyWith(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
