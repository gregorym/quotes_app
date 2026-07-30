import 'package:flutter_test/flutter_test.dart';
import 'package:quotes_app/repositories/quotes_repository.dart';

void main() {
  test('quote decoding reads non-empty lines', () {
    final quotes = decodeQuotes('''
      Do the work.

      Stay focused.
    ''');

    expect(
      quotes.map((quote) => quote.content),
      ['Do the work.', 'Stay focused.'],
    );
  });
}
