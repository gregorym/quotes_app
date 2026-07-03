import 'package:auto_size_text/auto_size_text.dart';
import 'package:banner_carousel/banner_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quotes_app/models/quotable_model.dart';

import '../../controllers/quotes_controller.dart';
import '../themes/colors.dart';
import '../themes/typography.dart';

class QuotesCard extends ConsumerWidget {
  const QuotesCard({super.key});

  static const double _cardHeight = 360;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotesState = ref.watch(getQuotesProvider);
    final banners = quotesState.when<List<Widget>>(
      data: (quotes) => quotes.isEmpty
          ? const [
              _QuoteMessage(
                title: 'No quotes found',
                subtitle: 'Try again in a moment.',
              ),
            ]
          : quotes.map((quote) => QuoteCard(quote: quote)).toList(),
      loading: () => const [
        _QuoteMessage(
          title: 'Finding a quote',
          subtitle: 'This usually takes a second.',
        ),
      ],
      error: (error, stackTrace) => const [
        _QuoteMessage(
          title: 'Could not load quotes',
          subtitle: 'Check your connection and try again.',
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Daily Quotes",
          style: MyTypography.h3,
        ),
        const SizedBox(height: 12),
        BannerCarousel(
          animation: true,
          margin: const EdgeInsets.all(0),
          borderRadius: 0,
          viewportFraction: 1,
          showIndicator: false,
          height: _cardHeight,
          customizedBanners: banners,
        ),
      ],
    );
  }
}

class QuoteCard extends StatelessWidget {
  final Quotable quote;

  const QuoteCard({super.key, required this.quote});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: QuotesCard._cardHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: MyColors.surface,
      ),
      child: Stack(
        children: [
          Positioned(
            left: 168,
            top: -90,
            child: Icon(
              Icons.format_quote,
              size: 220,
              color: MyColors.selected.withValues(alpha: 0.70),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 28,
              bottom: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AutoSizeText(
                    quote.content ?? 'Keep going.',
                    textAlign: TextAlign.start,
                    maxLines: 8,
                    maxFontSize: 36,
                    minFontSize: 20,
                    overflow: TextOverflow.ellipsis,
                    style: MyTypography.quote.copyWith(
                      fontSize: 36,
                      color: MyColors.ink,
                      fontWeight: FontWeight.w900,
                      height: 1.18,
                    ),
                  ),
                ),
                if (quote.author?.isNotEmpty == true) ...[
                  const SizedBox(height: 24),
                  Text(
                    quote.author!,
                    style: GoogleFonts.getFont(
                      "Nunito Sans",
                      color: MyColors.muted,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteMessage extends StatelessWidget {
  const _QuoteMessage({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: QuotesCard._cardHeight,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: MyColors.surface,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.format_quote,
              size: 56,
              color: MyColors.teal,
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.getFont(
                "Nunito Sans",
                color: MyColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.getFont(
                "Nunito Sans",
                color: MyColors.muted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
