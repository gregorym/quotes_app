import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotes_app/controllers/quotes_controller.dart';
import 'package:quotes_app/controllers/streak_controller.dart';
import 'package:quotes_app/controllers/user_controller.dart';
import 'package:quotes_app/models/quotable_model.dart';
import 'package:quotes_app/models/quote_model.dart';
import 'package:quotes_app/models/streak_model.dart';
import 'package:quotes_app/models/user_model.dart';
import 'package:quotes_app/repositories/favorite_repository.dart';
import 'package:quotes_app/views/templates/quotes_page_template.dart';
import 'package:quotes_app/views/widgets/quotes_card.dart';
import 'package:quotes_app/views/widgets/streak_card.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  testWidgets('quote card shows quote content and author', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuoteCard(
            quote: Quotable(
              content: 'Keep going.',
              author: 'Snarky Motivation',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Keep going.'), findsOneWidget);
    expect(find.text('Snarky Motivation'), findsOneWidget);
  });

  testWidgets('home quote swipes and opens in a dismissible dialog',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          getQuotesProvider.overrideWith(
            (ref) async => [
              Quotable(id: '1', content: 'First quote.'),
              Quotable(id: '2', content: 'Second quote.'),
            ],
          ),
          favoriteQuotesProvider.overrideWith((ref) async => const <Quote>[]),
          streakProvider.overrideWith((ref) async => const <Streak>[]),
          userProvider.overrideWith((ref) async => User(id: 'test')),
        ],
        child: const MaterialApp(home: QuotesPage()),
      ),
    );

    await tester.pumpAndSettle();
    String visibleQuote() => tester
        .widget<RichText>(
          find
              .descendant(
                of: find.byType(AnimatedTextKit),
                matching: find.byType(RichText),
              )
              .first,
        )
        .text
        .toPlainText();
    expect(visibleQuote(), startsWith('First quote.'));

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(visibleQuote(), startsWith('Second quote.'));

    await tester.tap(find.byType(AnimatedTextKit));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('quote-dialog')), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('quote-dialog')),
        matching: find.byTooltip('Share quote'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('quote-dialog')),
        matching: find.byTooltip('Add to bookmarks'),
      ),
      findsOneWidget,
    );

    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('quote-dialog')), findsNothing);
  });

  testWidgets('home quote types in before showing the full text',
      (tester) async {
    const quote = 'Discipline beats motivation.';
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          getQuotesProvider.overrideWith(
            (ref) async => [Quotable(id: '1', content: quote)],
          ),
          favoriteQuotesProvider.overrideWith((ref) async => const <Quote>[]),
          streakProvider.overrideWith((ref) async => const <Streak>[]),
          userProvider.overrideWith((ref) async => User(id: 'test')),
        ],
        child: const MaterialApp(home: QuotesPage()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final animatedText = find.descendant(
      of: find.byType(AnimatedTextKit),
      matching: find.byType(RichText),
    );
    expect(
      tester.widget<RichText>(animatedText).text.toPlainText(),
      isNot(startsWith(quote)),
    );

    await tester.pump(const Duration(seconds: 2));
    expect(
      tester.widget<RichText>(animatedText).text.toPlainText(),
      startsWith(quote),
    );
  });

  testWidgets('completed streak uses the full challenge panel', (tester) async {
    final now = DateTime.now();
    final completedToday = Streak(
      score: 1,
      createdAt: tz.TZDateTime.utc(now.year, now.month, now.day),
      topThreeCompleted: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          streakProvider.overrideWith((ref) async => [completedToday]),
          userProvider.overrideWith((ref) async => User(id: 'test')),
        ],
        child: const MaterialApp(home: Scaffold(body: StreakCard())),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.byType(FilledButton), findsNothing);
    expect(find.byKey(const Key('animated-top-three-flame')), findsOneWidget);
    expect(
      tester.widgetList<Column>(find.byType(Column)).any(
            (column) =>
                column.mainAxisAlignment == MainAxisAlignment.spaceEvenly,
          ),
      isTrue,
    );
  });
}
