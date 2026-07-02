import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/quote_model.dart';

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  return FavoriteRepository();
});

final favoriteQuotesProvider = FutureProvider<List<Quote>>((ref) {
  return ref.watch(favoriteRepositoryProvider).getFavoriteQuotes();
});

class FavoriteRepository {
  static const _boxName = 'favoriteQuotesBox';

  Future<Box<dynamic>> _box() => Hive.openBox(_boxName);

  String _keyFor(Quote quote) => quote.id ?? quote.content;

  Future<List<Quote>> getFavoriteQuotes() async {
    try {
      final box = await _box();

      return box.values
          .whereType<Map<dynamic, dynamic>>()
          .map((data) => Quote.fromJson(Map<String, dynamic>.from(data)))
          .toList();
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  Future<void> addFavoriteQuote(Quote quote) async {
    try {
      final box = await _box();
      await box.put(_keyFor(quote), quote.toJson());
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  Future<void> deleteFavoriteQuote(Quote quote) async {
    try {
      final box = await _box();
      await box.delete(_keyFor(quote));
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  // delete all favorite quotes
  Future<void> deleteAllFavoriteQuotes(String userId) async {
    try {
      final box = await _box();
      await box.clear();
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }
}
