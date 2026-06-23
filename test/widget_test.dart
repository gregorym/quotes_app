import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quotes_app/models/quotable_model.dart';
import 'package:quotes_app/views/widgets/quotes_card.dart';

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
}
