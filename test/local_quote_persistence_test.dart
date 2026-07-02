import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:quotes_app/models/quote_model.dart';
import 'package:quotes_app/repositories/favorite_repository.dart';
import 'package:quotes_app/repositories/quotes_repository.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp();
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('stores and removes favorite quotes locally', () async {
    final repository = FavoriteRepository();
    final quote = Quote(id: 'favorite-1', content: 'Move first.');

    await repository.addFavoriteQuote(quote);
    expect(await repository.getFavoriteQuotes(), hasLength(1));
    expect(
        (await repository.getFavoriteQuotes()).single.content, 'Move first.');

    await repository.deleteFavoriteQuote(quote);
    expect(await repository.getFavoriteQuotes(), isEmpty);

    await repository.addFavoriteQuote(quote);
    await repository.deleteAllFavoriteQuotes('unused-user');
    expect(await repository.getFavoriteQuotes(), isEmpty);
  });

  test('stores and removes created quotes locally', () async {
    final repository = QuotesRepository();
    final quote = Quote(id: 'created-1', content: 'Build the habit.');

    await repository.createQuote(quote);
    expect(await repository.getQuotesByMe(), hasLength(1));
    expect((await repository.getQuotesByMe()).single.id, 'created-1');

    await repository.deleteQuote(quote);
    expect(await repository.getQuotesByMe(), isEmpty);
  });
}
