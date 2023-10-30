import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotes_app/models/quotable_model.dart';
import 'package:quotes_app/repositories/quotes_repository.dart';

import '../models/quote_model.dart';

final getQuotesProvider = FutureProvider<List<Quotable>>((ref) async {
  final repo = ref.watch(quotesRepositoryProvider);
  final controller = QuotesController(repo);

  return await controller.getRandomQuotes();
});

final randomQuoteProvider = FutureProvider<Quotable>((ref) async {
  final repo = ref.watch(quotesRepositoryProvider);
  final controller = QuotesController(repo);

  return await controller.getRandomQuote();
});

final quotesProvider =
    StateNotifierProvider<QuotesController, AsyncValue<List<Quote>?>>((ref) {
  final repo = ref.watch(quotesRepositoryProvider);

  return QuotesController(repo)..getQuotesByMe();
});

class QuotesController extends StateNotifier<AsyncValue<List<Quote>?>> {
  QuotesController(this.quotesRepository) : super(const AsyncValue.data(null));

  final QuotesRepository quotesRepository;

  Future<List<Quotable>> getRandomQuotes() async {
    final result = await quotesRepository.getRandomQuotes();

    return result;
  }

  Future<Quotable> getRandomQuote() async {
    final result = await quotesRepository.getRandomQuotes();

    final randomIndex = Random().nextInt(result.length);
    final randomQuote = result[randomIndex];
    return randomQuote;
  }

  Future<void> createQuote(Quote quote) async {
    await quotesRepository.createQuote(quote);
  }

  Future<void> getQuotesByMe() async {
    state = const AsyncValue.loading();

    final result = await quotesRepository.getQuotesByMe();

    if (mounted) {
      state = AsyncValue.data(result);
    }
  }

  // delete a quote
  Future<void> deleteQuote(Quote quote) async {
    state = const AsyncValue.loading();

    await quotesRepository.deleteQuote(quote);

    state = const AsyncValue.data(null);
  }
}
