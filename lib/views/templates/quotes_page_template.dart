import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotes_app/controllers/quotes_controller.dart';
import 'package:quotes_app/views/templates/subscription_page_template.dart';
import 'package:quotes_app/views/widgets/quotes_card.dart';
import 'package:quotes_app/views/widgets/streak_card.dart';

import '../themes/colors.dart';

class QuotesPage extends ConsumerWidget {
  const QuotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotesState = ref.watch(quotesProvider);

    return Scaffold(
        backgroundColor: MyColors
            .primaryDark, // make sure to define MyColors class with secondary color
        body: SafeArea(
            child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32.0),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SubscriptionPage(),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize:
                          MainAxisSize.max, // Use minimum space of Row
                      children: const <Widget>[
                        Text('Try it free ⚡'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 42),
                      const StreakCard(),
                      SizedBox(height: 42),
                      QuotesCard()
                    ])),
          ],
        )));
  }
}
