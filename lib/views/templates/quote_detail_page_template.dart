import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/quote_model.dart';
import '../../repositories/favorite_repository.dart';
import '../../utils/quote_share.dart';
import '../themes/colors.dart';
import '../themes/typography.dart';
import '../widgets/icon_solid_light.dart';
import '../widgets/snackbar.dart';

class QuoteDetailPage extends ConsumerWidget {
  const QuoteDetailPage({
    super.key,
    required this.content,
    required this.author,
    required this.authorAvatar,
    required this.authorJob,
  });
  final String content;
  final String author;
  final String authorAvatar;
  final String authorJob;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: MyColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: MyColors.background,
        leadingWidth: 76,
        leading: IconSolidLight(
          icon: Icons.chevron_left,
          onTap: () => Navigator.pop(context),
        ),
        title: Text(
          "Quote Detail",
          style: MyTypography.h3,
        ),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        margin: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 30,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 30,
          vertical: 50,
        ),
        decoration: BoxDecoration(
          color: MyColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.format_quote,
              size: 70,
              color: MyColors.teal,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: AutoSizeText(
                content,
                maxFontSize: 30,
                minFontSize: 18,
                maxLines: 10,
                textAlign: TextAlign.center,
                style: MyTypography.quote.copyWith(
                  color: MyColors.ink,
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: AssetImage(authorAvatar),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author,
                        style: MyTypography.body2.copyWith(
                          color: MyColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        authorJob,
                        style: MyTypography.caption1.copyWith(
                          color: MyColors.muted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 70),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconSolidLight(
                  icon: Icons.favorite,
                  onTap: () async {
                    await ref.read(favoriteRepositoryProvider).addFavoriteQuote(
                          Quote(id: content, content: content),
                        );
                    ref.invalidate(favoriteQuotesProvider);
                    if (!context.mounted) return;
                    showSnackbar(
                      context,
                      'Added to bookmarks.',
                      isError: false,
                    );
                  },
                ),
                const SizedBox(width: 16),
                // share button with icon
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await shareQuoteImage(
                        context,
                        Quote(id: content, content: content),
                      );
                    } catch (error) {
                      if (!context.mounted) return;
                      showSnackbar(
                        context,
                        error.toString(),
                        isError: true,
                      );
                    }
                  },
                  icon: const Icon(Icons.share),
                  label: const Text("Share"),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: MyColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
