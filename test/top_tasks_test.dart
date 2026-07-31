import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:quotes_app/controllers/quotes_controller.dart';
import 'package:quotes_app/controllers/streak_controller.dart';
import 'package:quotes_app/controllers/subscription_controller.dart';
import 'package:quotes_app/controllers/user_controller.dart';
import 'package:quotes_app/models/quotable_model.dart';
import 'package:quotes_app/models/quote_model.dart';
import 'package:quotes_app/models/streak_model.dart';
import 'package:quotes_app/models/user_model.dart';
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

  setUp(() async {
    await Hive.box('topTasksBox').clear();
  });

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

  test('unfinished tasks carry over and completed tasks archive at 6 a.m.',
      () async {
    final repository = TopTasksRepository();
    final completedAt = DateTime(2026, 7, 30, 10);
    await repository.saveActive(
      [
        const TopTask(id: 'open', text: 'Keep going'),
        TopTask(
          id: 'done',
          text: 'Ship it',
          completed: true,
          completedAt: completedAt,
        ),
      ],
      now: completedAt,
    );

    expect(
      (await repository.fetchActive(now: DateTime(2026, 7, 31, 5, 59)))
          .map((task) => task.id),
      ['open', 'done'],
    );
    expect(
      (await repository.fetchActive(now: DateTime(2026, 7, 31, 6, 1)))
          .map((task) => task.id),
      ['open'],
    );
    expect(
      (await repository.fetchHistory(now: DateTime(2026, 7, 31, 6, 1)))
          .map((task) => task.id),
      ['done'],
    );
  });

  test('migrates the latest date-keyed list without resetting it', () async {
    await Hive.box('topTasksBox').put('2026-7-29', [
      const TopTask(id: 'legacy', text: 'Carry me forward').toJson(),
    ]);

    final tasks = await TopTasksRepository().fetchActive(
      now: DateTime(2026, 7, 30, 9),
    );

    expect(tasks.single.id, 'legacy');
  });

  test('top three visibility defaults on and persists', () async {
    final repository = TopTasksRepository();

    expect(await repository.fetchVisible(), isTrue);
    await repository.saveVisible(false);
    expect(await repository.fetchVisible(), isFalse);
  });

  testWidgets('task completion requires a subscription', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
    InAppPurchasePlatform.instance = _NoopPurchasePlatform();
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await tester.runAsync(
      () => Hive.box('topTasksBox').put('active', [
        const TopTask(id: '1', text: 'Finish the work').toJson(),
      ]),
    );
    final router = GoRouter(
      initialLocation: '/quotes',
      routes: [
        GoRoute(path: '/quotes', builder: (_, __) => const QuotesPage()),
        GoRoute(
          path: '/subscription',
          builder: (_, __) => const Scaffold(body: Text('Pixos Plus')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscribedProvider.overrideWithValue(false),
          getQuotesProvider.overrideWith(
            (ref) async => [Quotable(id: '1', content: 'A')],
          ),
          favoriteQuotesProvider.overrideWith((ref) async => const <Quote>[]),
          streakProvider.overrideWith((ref) async => const <Streak>[]),
          userProvider.overrideWith((ref) async => User(id: 'test')),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(find.byType(Checkbox));
    await _pumpFrames(tester);

    expect(find.text('Pixos Plus'), findsOneWidget);
    final stored = Hive.box('topTasksBox').get('active') as List;
    expect((stored.single as Map)['completed'], isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('top three starts visible and opens history from settings',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
    InAppPurchasePlatform.instance = _NoopPurchasePlatform();
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(
      () => Hive.box('topTasksBox').put('history', [
        TopTask(
          id: 'history',
          text: 'Finished from settings',
          completed: true,
          completedAt: DateTime.now(),
        ).toJson(),
      ]),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          getQuotesProvider.overrideWith(
            (ref) async => [Quotable(id: '1', content: 'Do the work.')],
          ),
          favoriteQuotesProvider.overrideWith((ref) async => const <Quote>[]),
          streakProvider.overrideWith((ref) async => const <Streak>[]),
          userProvider.overrideWith((ref) async => User(id: 'test')),
        ],
        child: const MaterialApp(home: QuotesPage()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 2));

    final quoteCard = find.byKey(const Key('home-quote-card'));
    expect(find.byKey(const Key('top-three-card')), findsOneWidget);
    expect(find.byTooltip('Show top three'), findsNothing);
    expect(find.byTooltip('Hide top three'), findsNothing);
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

    final taskCard = find.byKey(const Key('top-three-card'));
    final cardBottom = tester.getBottomRight(taskCard).dy;
    await tester.tap(find.text('ADD YOUR FIRST TASK'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));
    expect(tester.getBottomRight(taskCard).dy, closeTo(cardBottom, 0.1));
    await _pumpFrames(tester);
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
    await _pumpFrames(tester);
    expect(find.byKey(const Key('inline-task-editor')), findsNothing);

    await tester.tap(find.byTooltip('Open settings'));
    await _pumpFrames(tester);
    await tester.tap(find.text('Task history'));
    await _pumpFrames(tester);
    expect(find.text('Finished from settings'), findsOneWidget);
    expect(find.byKey(const Key('task-history')), findsOneWidget);

    await tester.tap(find.byTooltip('Close task history'));
    await _pumpFrames(tester);
    await tester.tap(find.byTooltip('Close profile'));
    await _pumpFrames(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('task completion haptics distinguish finishing all three',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
    InAppPurchasePlatform.instance = _NoopPurchasePlatform();
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await tester.runAsync(
      () => Hive.box('topTasksBox').put('active', [
        const TopTask(id: '1', text: 'First').toJson(),
        const TopTask(id: '2', text: 'Second').toJson(),
        const TopTask(id: '3', text: 'Third').toJson(),
      ]),
    );
    final haptics = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments);
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          getQuotesProvider.overrideWith(
            (ref) async => [Quotable(id: '1', content: 'A')],
          ),
          favoriteQuotesProvider.overrideWith((ref) async => const <Quote>[]),
          streakControllerProvider.overrideWithValue(_NoopStreakController()),
          streakProvider.overrideWith((ref) async => const <Streak>[]),
          userProvider.overrideWith((ref) async => User(id: 'test')),
        ],
        child: const MaterialApp(home: QuotesPage()),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(seconds: 2));
    haptics.clear();

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }

    expect(haptics, [
      'HapticFeedbackType.selectionClick',
      'HapticFeedbackType.selectionClick',
      'HapticFeedbackType.successNotification',
    ]);
    await tester.pumpWidget(const SizedBox.shrink());
    debugDefaultTargetPlatformOverride = null;
  });
}

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

class _NoopPurchasePlatform extends InAppPurchasePlatform {
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => const Stream.empty();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) =>
      Future.value(ProductDetailsResponse(
        productDetails: const [],
        notFoundIDs: identifiers.toList(),
      ));

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async =>
      false;

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {}

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {}
}

class _NoopStreakController extends StreakController {
  @override
  Future<bool> completeToday({bool topThreeCompleted = false}) async => true;
}
