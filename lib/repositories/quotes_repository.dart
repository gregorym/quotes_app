import 'dart:convert';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:quotes_app/models/quotable_model.dart';
import 'package:quotes_app/models/quote_model.dart';

final quotesRepositoryProvider =
    Provider<QuotesRepository>((ref) => QuotesRepository());

class QuotesRepository {
  Future<List<Quotable>> getRandomQuotes() async {
    final response = await http.get(
      Uri.parse(
          'https://nft-art-generator.nyc3.digitaloceanspaces.com/static/quotes/db.json'),
    );

    if (response.statusCode != 200) {
      return [];
    }

    final data = jsonDecode(response.body);
    final quotes =
        (data['quotes'] as List).map((e) => Quotable.fromJson(e)).toList();
    quotes.shuffle();
    return quotes;
  }

  Future<List<Quotable>> searchQuotes(String query) async {
    return [];
  }

  // Create a quote
  Future<void> createQuote(Quote quote) async {
    try {} catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  // Get quotes by me
  Future<List<Quote>> getQuotesByMe() async {
    try {
      List<Quote> quotes = [];
      return quotes;
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  // delete a quote
  Future<void> deleteQuote(Quote quote) async {
    try {} catch (e) {
      log(e.toString());
      rethrow;
    }
  }
}
