import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:quotes_app/models/quotable_model.dart';
import 'package:quotes_app/models/quote_model.dart';

final quotesRepositoryProvider =
    Provider<QuotesRepository>((ref) => QuotesRepository());

class QuotesRepository {
  List<Quotable>? _cache;

  Future<List<Quotable>> getRandomQuotes() async {
    _cache ??= await _loadQuotes();
    return List<Quotable>.of(_cache!)..shuffle();
  }

  Future<List<Quotable>> _loadQuotes() async {
    return decodeQuotes(await rootBundle.loadString('db.txt'));
  }

  Future<List<Quotable>> searchQuotes(String query) async {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return [];

    final quotes = await getRandomQuotes();
    return quotes
        .where((quote) =>
            (quote.content ?? '').toLowerCase().contains(normalizedQuery))
        .toList();
  }

  // Create a quote
  Future<void> createQuote(Quote quote) async {
    try {
      final box = await Hive.openBox('createdQuotesBox');
      final id = quote.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      await box.put(
          id,
          Quote(id: id, content: quote.content, categories: quote.categories)
              .toJson());
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  // Get quotes by me
  Future<List<Quote>> getQuotesByMe() async {
    try {
      final box = await Hive.openBox('createdQuotesBox');
      return box.values
          .whereType<Map<dynamic, dynamic>>()
          .map((data) => Quote.fromJson(Map<String, dynamic>.from(data)))
          .toList();
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  // delete a quote
  Future<void> deleteQuote(Quote quote) async {
    try {
      final box = await Hive.openBox('createdQuotesBox');
      await box.delete(quote.id ?? quote.content);
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }
}

List<Quotable> decodeQuotes(String source) {
  return source
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .map((line) => Quotable(content: line))
      .toList();
}
