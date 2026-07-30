import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:quotes_app/controllers/quotes_controller.dart';
import 'package:quotes_app/controllers/streak_controller.dart';
import 'package:quotes_app/models/quotable_model.dart';
import 'package:quotes_app/models/quote_model.dart';
import 'package:quotes_app/models/streak_model.dart';
import 'package:quotes_app/repositories/favorite_repository.dart';
import 'package:quotes_app/repositories/top_tasks_repository.dart';
import 'package:quotes_app/views/templates/quotes_page_template.dart';

void main() {
  late Directory hiveDirectory;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('top_tasks_test');
    Hive.init(hiveDirectory.path);
    await Hive.openBox('topTasksBox');
  });

  setUp(() => Hive.box('topTasksBox').clear());

  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  test('completed top tasks move below incomplete tasks', () {
    const tasks = [
      TopTask(id: '1', text: 'First', completed: true),
      TopTask(id: '2', text: 'Second'),
      TopTask(id: '3', text: 'Third', completed: true),
    ];

    expect(orderTopTasks(tasks).map((task) => task.id), ['2', '1', '3']);
  });

  testWidgets('top three starts hidden and shrinks the quote card when shown',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          getQuotesProvider.overrideWith(
            (ref) async => [Quotable(id: '1', content: 'Do the work.')],
          ),
          favoriteQuotesProvider.overrideWith((ref) async => const <Quote>[]),
          streakProvider.overrideWith((ref) async => const <Streak>[]),
        ],
        child: const MaterialApp(home: QuotesPage()),
      ),
    );
    await tester.pumpAndSettle();

    final quoteCard = find.byKey(const Key('home-quote-card'));
    final fullHeight = tester.getSize(quoteCard).height;
    expect(find.byKey(const Key('top-three-card')), findsNothing);
    final share = find.descendant(
      of: quoteCard,
      matching: find.byTooltip('Share quote'),
    );
    final bookmark = find.descendant(
      of: quoteCard,
      matching: find.byTooltip('Add to bookmarks'),
    );
    expect(share, findsOneWidget);
    expect(bookmark, findsOneWidget);
    expect(tester.getCenter(share).dx, lessThan(tester.getCenter(bookmark).dx));
    expect(
      tester
          .widget<IconButton>(
            find.ancestor(of: share, matching: find.byType(IconButton)),
          )
          .iconSize,
      24,
    );

    await tester.tap(find.byTooltip('Show top three'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('top-three-card')), findsOneWidget);
    expect(tester.getSize(quoteCard).height, lessThan(fullHeight));

    final taskCard = find.byKey(const Key('top-three-card'));
    final cardBottom = tester.getBottomRight(taskCard).dy;
    await tester.tap(find.text('ADD YOUR FIRST TASK'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));
    expect(tester.getBottomRight(taskCard).dy, closeTo(cardBottom, 0.1));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const Key('top-three-card')),
        matching: find.byKey(const Key('inline-task-editor')),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Cancel task edit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));
    expect(tester.getBottomRight(taskCard).dy, closeTo(cardBottom, 0.1));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inline-task-editor')), findsNothing);

    await tester.tap(find.byTooltip('Hide top three'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('top-three-card')), findsNothing);
  });
}
