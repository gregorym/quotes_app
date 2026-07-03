import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../controllers/quotes_controller.dart';
import '../../controllers/streak_controller.dart';
import '../../models/quotable_model.dart';
import '../../models/quote_model.dart';
import '../../models/streak_model.dart';
import '../../repositories/favorite_repository.dart';
import '../../widgets/reminder.dart';
import '../themes/colors.dart';
import '../themes/typography.dart';
import '../widgets/snackbar.dart';

class QuotesPage extends ConsumerStatefulWidget {
  const QuotesPage({super.key});

  @override
  ConsumerState<QuotesPage> createState() => _QuotesPageState();
}

class _QuotesPageState extends ConsumerState<QuotesPage> {
  static const _fallbackQuote =
      "You don't need more time. You need more balls.";
  static const _feedBackgrounds = [
    MyColors.background,
    Color(0xFFE8F0EC),
    Color(0xFFEAF0F7),
    Color(0xFFF4E9E9),
  ];

  int _quoteIndex = 0;
  int _backgroundIndex = 0;

  @override
  Widget build(BuildContext context) {
    final quotesState = ref.watch(getQuotesProvider);
    final favoritesState = ref.watch(favoriteQuotesProvider);
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
      backgroundColor: _feedBackgrounds[_backgroundIndex],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: _CircleButton(
                  icon: Icons.lock_outline,
                  onTap: () => context.push('/subscription'),
                ),
              ),
              const Spacer(flex: 7),
              GestureDetector(
                onTap: () => _showNextQuote(quotes),
                child: AutoSizeText(
                  quoteText,
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  maxFontSize: 32,
                  minFontSize: 24,
                  style: MyTypography.quote.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1.12,
                  ),
                ),
              ),
              const Spacer(flex: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => _copyQuote(context, quoteText),
                    icon: const Icon(Icons.ios_share),
                    color: MyColors.ink,
                    iconSize: 34,
                  ),
                  const SizedBox(width: 72),
                  IconButton(
                    onPressed: () =>
                        _toggleFavorite(context, quote, quoteText, isFavorite),
                    icon: Icon(
                      isFavorite ? Icons.star : Icons.star_border,
                    ),
                    color: isFavorite ? MyColors.orange : MyColors.ink,
                    iconSize: 36,
                  ),
                ],
              ),
              const Spacer(flex: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CircleButton(
                    icon: Icons.person,
                    onTap: () => _showProfileSheet(context),
                  ),
                  GestureDetector(
                    onTap: () => _needsClarification(
                      context,
                      'Category selection needs target categories and ranking rules.',
                    ),
                    child: Container(
                      height: 54,
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: MyColors.surface,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Text(
                        'For you',
                        style: MyTypography.h3.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  _CircleButton(
                    icon: Icons.palette,
                    onTap: _cycleBackground,
                  ),
                ],
              ),
            ],
          ),
        ),
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

  void _showNextQuote(List<Quotable> quotes) {
    if (quotes.length < 2) return;
    setState(() {
      _quoteIndex = (_quoteIndex + 1) % quotes.length;
    });
  }

  void _cycleBackground() {
    setState(() {
      _backgroundIndex = (_backgroundIndex + 1) % _feedBackgrounds.length;
    });
  }

  Future<void> _copyQuote(BuildContext context, String quoteText) async {
    await Clipboard.setData(ClipboardData(text: quoteText));
    if (!context.mounted) return;
    showSnackbar(context, 'Punchline copied.', isError: false);
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

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: MyColors.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: MyColors.ink, size: 26),
      ),
    );
  }
}

class _ProfileSheet extends ConsumerWidget {
  const _ProfileSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streaks = ref.watch(streakProvider).maybeWhen(
          data: (streaks) => streaks,
          orElse: () => const <Streak>[],
        );
    final favorites = ref.watch(favoriteQuotesProvider).maybeWhen(
          data: (favorites) => favorites,
          orElse: () => const <Quote>[],
        );

    return FractionallySizedBox(
      heightFactor: 0.96,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: MyColors.background,
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
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'My profile',
                      style: MyTypography.h1.copyWith(fontSize: 38),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: MyColors.muted,
                    ),
                    const SizedBox(width: 4),
                    Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: MyColors.darkPanel,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.ac_unit,
                            color: Color(0xFF9EDDF3),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '0',
                            style: MyTypography.body1.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _ProfileStreakCard(
                  streakCount: _streakCount(streaks),
                  checkedWeekdays: _checkedWeekdays(streaks),
                ),
                const SizedBox(height: 24),
                _ProfileSection(
                  title: 'Settings',
                  rows: [
                    _ProfileAction(
                      label: 'My account',
                      onTap: () => _needsClarification(
                        context,
                        'Account management needs auth/account routes.',
                      ),
                    ),
                    _ProfileAction(
                      label: 'Personalization',
                      onTap: () => _needsClarification(
                        context,
                        'Personalization needs the target preference model.',
                      ),
                    ),
                    _ProfileAction(
                      label: 'Widgets',
                      onTap: () => _needsClarification(
                        context,
                        'Widget setup needs supported widget types.',
                      ),
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
                    _ProfileAction(
                      label: 'Collections',
                      onTap: () => _needsClarification(
                        context,
                        'Collections need a local collection data model.',
                      ),
                    ),
                    _ProfileAction(
                      label: 'Custom punchlines',
                      onTap: () => _needsClarification(
                        context,
                        'Custom punchlines need a destination screen.',
                      ),
                    ),
                    _ProfileAction(
                      label: 'Hidden punchlines',
                      onTap: () => _needsClarification(
                        context,
                        'Hidden punchlines need hide/unhide rules.',
                      ),
                    ),
                    _ProfileAction(
                      label: 'History',
                      onTap: () => _needsClarification(
                        context,
                        'History needs tracking rules.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _ProfileSection(
                  title: 'Support',
                  rows: [
                    _ProfileAction(
                      label: 'Help & support',
                      onTap: () => _needsClarification(
                        context,
                        'Help support needs a support URL or contact channel.',
                      ),
                    ),
                    _ProfileAction(
                      label: 'Terms & privacy',
                      onTap: () => _needsClarification(
                        context,
                        'Terms privacy needs legal document URLs.',
                      ),
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

class _ProfileStreakCard extends StatelessWidget {
  const _ProfileStreakCard({
    required this.streakCount,
    required this.checkedWeekdays,
  });

  final int streakCount;
  final Set<int> checkedWeekdays;

  @override
  Widget build(BuildContext context) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: MyColors.darkPanel,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                streakCount.toString(),
                style: MyTypography.h1.copyWith(
                  color: Colors.white,
                  fontSize: 42,
                ),
              ),
              Text(
                'Streak',
                style: MyTypography.body1.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(days.length, (index) {
                final isChecked = checkedWeekdays.contains(index);
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      days[index],
                      style: MyTypography.body2.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    CircleAvatar(
                      radius: 14,
                      backgroundColor:
                          isChecked ? const Color(0xFF63A867) : Colors.white,
                      child: isChecked
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 22,
                            )
                          : null,
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
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
                    color: Color(0xFFE8E6E1),
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
    return GestureDetector(
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
      heightFactor: favorites.isEmpty ? 0.3 : 0.52,
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
                            color: Color(0xFFE8E6E1),
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
          child: ReminderWidget(),
        ),
      );
    },
  );
}

void _needsClarification(BuildContext context, String message) {
  showSnackbar(context, message);
}

int _streakCount(List<Streak> streaks) {
  final days = streaks.map((streak) => _dateKey(streak.createdAt)).toSet();
  if (days.isEmpty) return 0;

  final today = _dateOnly(_streakNow());
  var cursor = days.contains(_dateKey(today))
      ? today
      : today.subtract(const Duration(days: 1));
  var count = 0;

  while (days.contains(_dateKey(cursor))) {
    count++;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  return count;
}

Set<int> _checkedWeekdays(List<Streak> streaks) {
  final now = _streakNow();
  final weekStart = _dateOnly(now).subtract(Duration(days: now.weekday - 1));
  final weekEnd = weekStart.add(const Duration(days: 7));

  return streaks
      .where((streak) =>
          !streak.createdAt.isBefore(weekStart) &&
          streak.createdAt.isBefore(weekEnd))
      .map((streak) => streak.createdAt.weekday - 1)
      .toSet();
}

DateTime _dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

int _dateKey(DateTime date) {
  return date.year * 10000 + date.month * 100 + date.day;
}

DateTime _streakNow() {
  return tz.TZDateTime.now(tz.local);
}
