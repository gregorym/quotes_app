import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quotes_app/models/quote_model.dart';
import 'package:quotes_app/utils/quote_share.dart';
import 'package:quotes_app/views/widgets/app_background.dart';
import 'package:quotes_app/views/widgets/quot_widget_share.dart';

void main() {
  testWidgets('native share receives the quote image and text', (tester) async {
    const channel = MethodChannel('com.mars6.noexcuse/share');
    MethodCall? received;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async {
        received = call;
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );

    await shareNativeQuote('Do the work.', '/tmp/quote.png');

    expect(received?.method, 'share');
    expect(received?.arguments, {
      'text': 'Do the work.',
      'filePath': '/tmp/quote.png',
    });
  });

  testWidgets('share image centers the quote and brands the bottom right', (
    tester,
  ) async {
    const squareKey = Key('share-square');

    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            key: squareKey,
            width: 512,
            height: 512,
            child: QuotWidgetShare(
              quote: Quote(content: 'Centered quote.'),
              height: 512,
              width: 512,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(AppBackground), findsOneWidget);
    expect(find.byIcon(Icons.format_quote), findsNothing);

    final squareCenter = tester.getCenter(find.byKey(squareKey));
    final quoteCenter = tester.getCenter(find.byType(AutoSizeText));
    final squareBottomRight = tester.getBottomRight(find.byKey(squareKey));
    final brandBottomRight = tester.getBottomRight(find.text('No Excuses'));

    expect((quoteCenter.dx - squareCenter.dx).abs(), lessThan(1));
    expect((quoteCenter.dy - squareCenter.dy).abs(), lessThan(1));
    expect(squareBottomRight.dx - brandBottomRight.dx, 24);
    expect(squareBottomRight.dy - brandBottomRight.dy, 20);
  });
}
