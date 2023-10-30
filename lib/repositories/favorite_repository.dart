import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quote_model.dart';

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  return FavoriteRepository();
});

class FavoriteRepository {

  Future<List<Quote>> getFavoriteQuotes() async {
    try {

      List<Quote> quotes = [];

      // for (var quote in response) {
      //   quotes.add(Quote.fromJson(quote['quotes']));
      // }

      return quotes;
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  Future<void> addFavoriteQuote(Quote quote) async {
    try {
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  Future<void> deleteFavoriteQuote(Quote quote) async {
    try {
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  // delete all favorite quotes
  Future<void> deleteAllFavoriteQuotes(String userId) async {
    try {
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }
}
