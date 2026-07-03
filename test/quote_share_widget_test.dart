import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quotes_app/models/quote_model.dart';
import 'package:quotes_app/views/widgets/app_background.dart';
import 'package:quotes_app/views/widgets/quot_widget_share.dart';

void main() {
  testWidgets('share image uses app background and centers the quote', (
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

    expect((quoteCenter.dx - squareCenter.dx).abs(), lessThan(1));
    expect((quoteCenter.dy - squareCenter.dy).abs(), lessThan(1));
  });
}
