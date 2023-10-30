import 'package:auto_size_text/auto_size_text.dart';
import 'package:banner_carousel/banner_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:quotes_app/models/quotable_model.dart';

import '../../controllers/quotes_controller.dart';
import '../themes/colors.dart';

class QuotesCard extends ConsumerWidget {
  const QuotesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotesState = ref.watch(getQuotesProvider);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text("Quote",
                style: GoogleFonts.getFont("Nunito Sans",
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(
              width: 8,
            ),
            Icon(Icons.lock, color: MyColors.primaryDark, size: 24)
          ],
        ),
        BannerCarousel(
          animation: true,
          margin: EdgeInsets.all(0),
          borderRadius: 0,
          viewportFraction: 1,
          showIndicator: false,
          height: 400,
          customizedBanners: quotesState.value != null 
    ? (quotesState.value ?? []).map((e) => QuoteCard(quote: e)).toList() 
    : [SizedBox(height: 0)]
        ),
      ],
    );
  }
}

class QuoteCard extends StatelessWidget {
  final Quotable quote;

  const QuoteCard({Key? key, required this.quote}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: MyColors.primary,
      ),
      child: Stack(
        children: [
          Positioned(
            left: 168,
            top: -90,
            child: Icon(PhosphorIcons.fill.quotes, size: 220, color: MyColors.primaryDark.withOpacity(0.3)),

          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 24,
              bottom: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: Expanded(
                      child: AutoSizeText(
                        quote.content!,
                        textAlign: TextAlign.start,
                        maxLines: 8,
                        maxFontSize: 112,
                        minFontSize: 24,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.getFont("Nunito Sans", fontSize: 42, color: Colors.white, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
