import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/quotable_model.dart';
import '../../repositories/quotes_repository.dart';
import '../themes/colors.dart';
import '../themes/typography.dart';
import '../widgets/icon_solid_light.dart';
import 'quote_detail_page_template.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  var _query = '';
  var _isLoading = false;
  var _searchVersion = 0;
  List<Quotable> _results = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: MyColors.background,
        leadingWidth: 76,
        leading: IconSolidLight(
          icon: Icons.chevron_left,
          onTap: () => Navigator.pop(context),
        ),
        title: Text(
          "Search Quote",
          style: MyTypography.h3,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 0.0,
            ),
            decoration: BoxDecoration(
              color: MyColors.secondary,
              borderRadius: BorderRadius.circular(25),
            ),
            margin: const EdgeInsets.only(
              bottom: 10,
              left: 20,
              right: 20,
            ),
            child: Center(
              child: IntrinsicWidth(
                child: TextField(
                  cursorColor: MyColors.black,
                  decoration: InputDecoration(
                    hintText: "Find a quote here",
                    hintStyle: MyTypography.body1.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    prefixIcon: Icon(
                      Icons.search,
                      color: MyColors.black,
                    ),
                  ),
                  onChanged: _search,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_query.isEmpty || _results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 40,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: MyColors.secondary,
                borderRadius: BorderRadius.circular(100),
              ),
              padding: const EdgeInsets.all(40),
              child: const Icon(
                Icons.format_quote,
                size: 48,
              ),
            ),
            const SizedBox(height: 50),
            Text(
              _query.isEmpty ? "It's empty here" : 'No quotes found',
              style: MyTypography.h2,
            ),
            const SizedBox(height: 20),
            Text(
              "Try to find a quote by typing the keyword in the search bar above",
              style: MyTypography.body1.copyWith(
                fontWeight: FontWeight.w400,
                color: MyColors.muted,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final quote = _results[index];

        return ListTile(
          tileColor: MyColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            quote.content ?? '',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: MyTypography.body1,
          ),
          subtitle: Text(
            quote.author ?? 'Unknown',
            style: MyTypography.body2.copyWith(color: MyColors.muted),
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => QuoteDetailPage(
                content: quote.content ?? '',
                author: quote.author ?? 'Unknown',
                authorAvatar: 'assets/images/avatar.png',
                authorJob: quote.tags?.join(', ') ?? '',
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _search(String value) async {
    final version = ++_searchVersion;
    final query = value.trim();

    setState(() {
      _query = query;
      _isLoading = query.isNotEmpty;
      if (query.isEmpty) _results = [];
    });

    if (query.isEmpty) return;

    final results =
        await ref.read(quotesRepositoryProvider).searchQuotes(query);
    if (!mounted || version != _searchVersion) return;

    setState(() {
      _results = results;
      _isLoading = false;
    });
  }
}
