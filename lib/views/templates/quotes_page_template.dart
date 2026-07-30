import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/quotes_controller.dart';
import '../../controllers/subscription_controller.dart';
import '../../models/quotable_model.dart';
import '../../models/quote_model.dart';
import '../../repositories/favorite_repository.dart';
import '../../repositories/onboarding_repository.dart';
import '../../utils/quote_share.dart';
import '../../utils/external_links.dart';
import '../../widgets/reminder.dart';
import '../themes/colors.dart';
import '../themes/typography.dart';
import '../widgets/snackbar.dart';
import '../widgets/streak_card.dart';

class QuotesPage extends ConsumerStatefulWidget {
  const QuotesPage({super.key});

  @override
  ConsumerState<QuotesPage> createState() => _QuotesPageState();
}

class _QuotesPageState extends ConsumerState<QuotesPage> {
  static const _fallbackQuote =
      "You don't need more time. You need more balls.";
  late final PageController _quotePageController;
  int _quoteIndex = 0;

  @override
  void initState() {
    super.initState();
    _quotePageController = PageController();
  }

  @override
  void dispose() {
    _quotePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quotesState = ref.watch(getQuotesProvider);
    final favoritesState = ref.watch(favoriteQuotesProvider);
    final subscription = ref.watch(subscriptionProvider);
    if (subscriptionPlatformSupported && !subscription.entitlementChecked) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: MyColors.orange),
        ),
      );
    }
    if (subscriptionPlatformSupported &&
        subscription.entitlementChecked &&
        !subscription.canAccessContent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/subscription');
      });
    }
    final quotes = quotesState.maybeWhen(
      data: (quotes) => quotes,
      orElse: () => const <Quotable>[],
    );
    final quote = quotes.isEmpty ? null : quotes[_quoteIndex % quotes.length];
    final quoteText = quotesState.maybeWhen(
      data: (_) => quote?.content ?? _fallbackQuote,
      loading: () => 'Finding your next punchline...',
      orElse: () => _fallbackQuote,
    );
    final favorites = favoritesState.maybeWhen(
      data: (quotes) => quotes,
      orElse: () => const <Quote>[],
    );
    final favoriteIds =
        favorites.map((quote) => quote.id ?? quote.content).toSet();
    final quoteId = _quoteId(quote, quoteText);
    final isFavorite = favoriteIds.contains(quoteId);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              const StreakCard(),
              Expanded(
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 14, 8, 24),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF17181B),
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  child: PageView.builder(
                                    controller: _quotePageController,
                                    itemCount:
                                        quotes.isEmpty ? 1 : quotes.length,
                                    onPageChanged: (index) {
                                      if (quotes.isEmpty) return;
                                      setState(() => _quoteIndex = index);
                                    },
                                    itemBuilder: (context, index) {
                                      final pageQuote =
                                          quotes.isEmpty ? null : quotes[index];
                                      final pageQuoteText =
                                          quotesState.maybeWhen(
                                        data: (_) =>
                                            pageQuote?.content ??
                                            _fallbackQuote,
                                        loading: () =>
                                            'Finding your next punchline...',
                                        orElse: () => _fallbackQuote,
                                      );

                                      return Semantics(
                                        button: true,
                                        label: 'Open quote full screen',
                                        child: GestureDetector(
                                          onTap: () => _showQuoteDialog(
                                            context,
                                            pageQuoteText,
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Flexible(
                                                child: quotes.isNotEmpty &&
                                                        index == _quoteIndex
                                                    ? _TypewriterQuote(
                                                        key: ValueKey(
                                                            pageQuoteText),
                                                        text: pageQuoteText,
                                                        onTap: () =>
                                                            _showQuoteDialog(
                                                          context,
                                                          pageQuoteText,
                                                        ),
                                                      )
                                                    : _QuoteText(
                                                        text: pageQuoteText),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              tooltip: 'Share quote',
                              onPressed: () =>
                                  _shareQuote(context, quote, quoteText),
                              icon: const Icon(Icons.ios_share),
                              color: Colors.white,
                              iconSize: 34,
                            ),
                            const SizedBox(width: 72),
                            IconButton(
                              tooltip: isFavorite
                                  ? 'Remove from favorites'
                                  : 'Add to favorites',
                              onPressed: () => _toggleFavorite(
                                  context, quote, quoteText, isFavorite),
                              icon: Icon(
                                isFavorite
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                              ),
                              color:
                                  isFavorite ? MyColors.orange : Colors.white,
                              iconSize: 36,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 4,
            right: 12,
            child: IconButton(
              tooltip: 'Open settings',
              onPressed: () => _showProfileSheet(context),
              icon: const Icon(Icons.settings),
              color: Colors.white,
              iconSize: 28,
            ),
          ),
        ],
      ),
    );
  }

  String _quoteId(Quotable? quote, String quoteText) {
    return quote?.id ?? quoteText;
  }

  Quote _favoriteQuoteFrom(Quotable? quote, String quoteText) {
    return Quote(
      id: _quoteId(quote, quoteText),
      content: quoteText,
      categories: quote?.tags ?? const [],
    );
  }

  void _showQuoteDialog(
    BuildContext context,
    String quoteText,
  ) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, _, __) => GestureDetector(
        key: const Key('quote-dialog'),
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pop(dialogContext),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: ColoredBox(
            color: Colors.black.withValues(alpha: 0.72),
            child: SafeArea(
              child: Dialog(
                insetPadding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                child: SizedBox(
                  height: MediaQuery.sizeOf(dialogContext).height * 0.62,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                    child: Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: _TypewriterQuote(
                              key: ValueKey('dialog-$quoteText'),
                              text: quoteText,
                              onTap: () => Navigator.pop(dialogContext),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      transitionBuilder: (context, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );
  }

  Future<void> _shareQuote(
    BuildContext context,
    Quotable? quote,
    String quoteText,
  ) async {
    try {
      await shareQuoteImage(context, _favoriteQuoteFrom(quote, quoteText));
    } catch (error) {
      if (!context.mounted) return;
      showSnackbar(context, error.toString(), isError: true);
    }
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    Quotable? quote,
    String quoteText,
    bool isFavorite,
  ) async {
    final repository = ref.read(favoriteRepositoryProvider);
    final favoriteQuote = _favoriteQuoteFrom(quote, quoteText);

    if (isFavorite) {
      await repository.deleteFavoriteQuote(favoriteQuote);
    } else {
      await repository.addFavoriteQuote(favoriteQuote);
    }

    ref.invalidate(favoriteQuotesProvider);
    if (!context.mounted) return;
    showSnackbar(
      context,
      isFavorite ? 'Removed from favorites.' : 'Added to favorites.',
      isError: false,
    );
  }

  void _showProfileSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.22),
      isScrollControlled: true,
      builder: (context) => const _ProfileSheet(),
    );
  }
}

class _QuoteText extends StatelessWidget {
  const _QuoteText({required this.text});

  final String text;

  static final style = MyTypography.quote.copyWith(
    color: Colors.white,
    fontSize: 36,
    height: 1.12,
  );

  @override
  Widget build(BuildContext context) => AutoSizeText(
        text,
        textAlign: TextAlign.center,
        maxLines: 5,
        maxFontSize: 36,
        minFontSize: 18,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
}

class _TypewriterQuote extends StatefulWidget {
  const _TypewriterQuote({
    super.key,
    required this.text,
    required this.onTap,
  });

  final String text;
  final VoidCallback onTap;

  @override
  State<_TypewriterQuote> createState() => _TypewriterQuoteState();
}

class _TypewriterQuoteState extends State<_TypewriterQuote> {
  static const _characterSpeed = Duration(milliseconds: 28);
  static const _hapticInterval = Duration(milliseconds: 84);

  Timer? _hapticTimer;
  bool? _motionDisabled;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disabled = MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    if (_motionDisabled == disabled) return;
    _motionDisabled = disabled;
    _hapticTimer?.cancel();
    if (!disabled) _startHaptics();
  }

  void _startHaptics() {
    final finishAt = DateTime.now().add(
      _characterSpeed * widget.text.runes.length,
    );
    _hapticTimer = Timer.periodic(_hapticInterval, (timer) {
      if (DateTime.now().isAfter(finishAt) ||
          !(ModalRoute.of(context)?.isCurrent ?? true)) {
        timer.cancel();
      } else {
        HapticFeedback.selectionClick();
      }
    });
  }

  @override
  void dispose() {
    _hapticTimer?.cancel();
    super.dispose();
  }

  void _handleTap() {
    _hapticTimer?.cancel();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    if (_motionDisabled ?? true) return _QuoteText(text: widget.text);

    return LayoutBuilder(
      builder: (context, constraints) {
        final style = _QuoteText.style.copyWith(
          fontSize: _fittingFontSize(context, constraints),
        );
        return Semantics(
          label: widget.text,
          excludeSemantics: true,
          child: AnimatedTextKit(
            animatedTexts: [
              TypewriterAnimatedText(
                widget.text,
                textAlign: TextAlign.center,
                textStyle: style,
                speed: _characterSpeed,
                cursor: '▍',
              ),
            ],
            isRepeatingAnimation: false,
            onTap: _handleTap,
          ),
        );
      },
    );
  }

  double _fittingFontSize(BuildContext context, BoxConstraints constraints) {
    for (var size = 36.0; size >= 18; size--) {
      final painter = TextPainter(
        text: TextSpan(
          text: '${widget.text}▍',
          style: _QuoteText.style.copyWith(fontSize: size),
        ),
        maxLines: 5,
        textAlign: TextAlign.center,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: constraints.maxWidth);
      if (!painter.didExceedMaxLines &&
          painter.height <= constraints.maxHeight) {
        return size;
      }
    }
    return 18;
  }
}

class _ProfileSheet extends ConsumerWidget {
  const _ProfileSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteQuotesProvider).maybeWhen(
          data: (favorites) => favorites,
          orElse: () => const <Quote>[],
        );

    return FractionallySizedBox(
      heightFactor: 0.96,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: MyColors.darkPanel,
          borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(26, 14, 26, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 54,
                    height: 5,
                    decoration: BoxDecoration(
                      color: MyColors.disabled,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'My profile',
                        maxLines: 2,
                        style: MyTypography.h1.copyWith(fontSize: 38),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close profile',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: MyColors.muted,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _ProfileSection(
                  title: 'Settings',
                  rows: [
                    _ProfileAction(
                      label: 'Personalization',
                      onTap: () => _showPersonalizationSheet(context, ref),
                    ),
                    _ProfileAction(
                      label: 'Widgets',
                      onTap: () => _showWidgetInstructions(context),
                    ),
                    _ProfileAction(
                      label: 'Notifications',
                      onTap: () => _showReminderSheet(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _ProfileSection(
                  title: 'Punchlines',
                  rows: [
                    _ProfileAction(
                      label: 'Favorites (${favorites.length})',
                      onTap: () => _showFavoritesSheet(context, favorites),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _ProfileSection(
                  title: 'Support',
                  rows: [
                    _ProfileAction(
                      label: 'Help & support',
                      onTap: () => openExternalUrl(supportUrl),
                    ),
                    _ProfileAction(
                      label: 'Terms & privacy',
                      onTap: () => _showTermsAndPrivacy(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileAction {
  const _ProfileAction({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.rows});

  final String title;
  final List<_ProfileAction> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 18, bottom: 14),
          child: Text(
            title,
            style: MyTypography.body1.copyWith(
              color: MyColors.muted,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: MyColors.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              for (var index = 0; index < rows.length; index++) ...[
                _ProfileRow(action: rows[index]),
                if (index != rows.length - 1)
                  const Divider(
                    height: 1,
                    indent: 20,
                    endIndent: 20,
                    color: MyColors.disabled,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.action});

  final _ProfileAction action;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: action.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: action.onTap,
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  action.label,
                  style: MyTypography.h3.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: MyColors.ink, size: 30),
              const SizedBox(width: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoritesSheet extends ConsumerWidget {
  const _FavoritesSheet({required this.favorites});

  final List<Quote> favorites;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listHeight = favorites.isEmpty
        ? 110.0
        : (favorites.length > 4 ? 330.0 : favorites.length * 82.0);

    return FractionallySizedBox(
      heightFactor: favorites.isEmpty ? 0.34 : 0.52,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: MyColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 54,
                    height: 5,
                    decoration: BoxDecoration(
                      color: MyColors.disabled,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Favorites', style: MyTypography.h2),
                const SizedBox(height: 18),
                SizedBox(
                  height: listHeight,
                  child: favorites.isEmpty
                      ? Center(
                          child: Text(
                            'No favorites yet.',
                            style: MyTypography.body1.copyWith(
                              color: MyColors.muted,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: favorites.length,
                          separatorBuilder: (_, __) => const Divider(
                            color: MyColors.disabled,
                          ),
                          itemBuilder: (context, index) {
                            final quote = favorites[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                quote.content,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: MyTypography.quote,
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  await ref
                                      .read(favoriteRepositoryProvider)
                                      .deleteFavoriteQuote(quote);
                                  ref.invalidate(favoriteQuotesProvider);
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  showSnackbar(
                                    context,
                                    'Removed from favorites.',
                                    isError: false,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _showFavoritesSheet(BuildContext context, List<Quote> favorites) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.22),
    isScrollControlled: true,
    builder: (context) => _FavoritesSheet(favorites: favorites),
  );
}

Future<void> _showPersonalizationSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final answers = await ref.read(onboardingRepositoryProvider).fetchAnswers();
  if (!context.mounted) return;
  final categories = (answers['categories'] as List? ?? const []).join(' · ');
  final frictions = onboardingFrictionSummary(answers);
  final router = GoRouter.of(context);
  _showInfoSheet(
    context,
    title: 'Your protocol',
    children: [
      _InfoLine('Name', answers['name']?.toString() ?? 'Not set'),
      _InfoLine(
          'Primary goal', answers['primary_goal']?.toString() ?? 'Not set'),
      _InfoLine('Focus', categories.isEmpty ? 'Not set' : categories),
      _InfoLine(
        'Frictions',
        frictions.isEmpty ? 'Not set' : frictions,
      ),
      _InfoLine(
        'Pressure',
        answers['tone'] == 'extra hard' ? 'Extra Hard' : 'Hard',
      ),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () {
            Navigator.of(context).popUntil((route) => route is PageRoute);
            router.go('/onboarding');
          },
          child: const Text('Change my protocol'),
        ),
      ),
    ],
  );
}

void _showWidgetInstructions(BuildContext context) {
  _showInfoSheet(
    context,
    title: 'Daily Home Screen quote',
    children: [
      Text(
        'Touch and hold an empty area of your Home Screen, tap Edit, then Add Widget. Search for No Excuses and choose the square or wide layout.',
        style: MyTypography.body1,
      ),
      SizedBox(height: 14),
      Text(
        'The quote changes automatically at local midnight.',
        style: MyTypography.body1,
      ),
    ],
  );
}

void _showTermsAndPrivacy(BuildContext context) {
  _showInfoSheet(
    context,
    title: 'Terms & privacy',
    children: [
      Text(
        'Subscriptions renew automatically unless canceled at least 24 hours before the end of the current period. Manage or cancel in App Store account settings. Apple’s Standard End User License Agreement applies.',
        style: MyTypography.body1,
      ),
      SizedBox(height: 18),
      Text(
        'Your onboarding answers, reminder schedule, and favorites are stored on this device. Apple processes purchases. No Excuses does not sell your personal information.',
        style: MyTypography.body1,
      ),
      const SizedBox(height: 18),
      Wrap(
        spacing: 10,
        children: [
          OutlinedButton(
            onPressed: () => openExternalUrl(termsOfUseUrl),
            child: const Text('Terms of use'),
          ),
          OutlinedButton(
            onPressed: () => openExternalUrl(privacyPolicyUrl),
            child: const Text('Privacy policy'),
          ),
        ],
      ),
    ],
  );
}

void _showInfoSheet(
  BuildContext context, {
  required String title,
  required List<Widget> children,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: MyColors.darkPanel,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: MyTypography.h2)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    ),
  );
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: MyTypography.caption1.copyWith(color: MyColors.muted),
          ),
          const SizedBox(height: 4),
          Text(value, style: MyTypography.body1),
        ],
      ),
    );
  }
}

void _showReminderSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.22),
    isScrollControlled: true,
    builder: (context) {
      return const FractionallySizedBox(
        heightFactor: 0.82,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: ReminderWidget(requiresSubscription: true),
        ),
      );
    },
  );
}
