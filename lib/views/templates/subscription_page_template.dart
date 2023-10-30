import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotes_app/views/templates/quotes_page_template.dart';

import '../../controllers/subscription_controller.dart';

class SubscriptionPage extends ConsumerWidget {
  const SubscriptionPage({
    super.key
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionState = ref.watch(subscriptionProvider);
    subscriptionState.checkSubscription();


    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
            child: Stack(
              children: [
                // Close icon
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    color: Colors.white,
                    icon: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                            const QuotesPage(),
                          ),
                        );

                      },
                  )
                ),

                // Content in the center
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 50),
                      // Premium text
                      const Text("Try Motivation Premium", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

                        // Crown icon
                        Center(child: Text("⚡️", style: TextStyle(fontSize: 50))),

                        const SizedBox(height: 20),

                          // Unlock everything text
                          const Text("Unlock everything", style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),

                            const SizedBox(height: 50),

                              // List of features
                              FeatureItem("Enjoy your first 3 days, it's free"),
                              FeatureItem("Cancel anytime"),
                              FeatureItem("Quotes to remind you to keep pushing"),
                              FeatureItem("Streaks to track your progress"),
                              FeatureItem("Only \$1.66/month, billed annually"),
                  ],
                ),

                // Bottom content with absolute positioning
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      // Pricing info
                      Center(
                        child: Text("3 days free, then just \$19.99/year",
                          style: TextStyle(fontSize: 16, color: Colors.white)
                        )
                      ),

                      const SizedBox(height: 5),

                        // Continue button
                        SizedBox(
                          width: double.infinity, // makes the button expand to full width
                          height: 60.0,

                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.all(16.0),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(32.0)),
                                )
                            ),
                            child: const Text(
                              'Continue',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18.0,
                              ),
                            ),
                          ),
                        ),

                        // Links
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(onPressed: () {}, child: Text("Restore"), style: TextButton.styleFrom(foregroundColor: Colors.white)),
                            TextButton(onPressed: () {}, child: Text("Terms & Conditions"), style: TextButton.styleFrom(foregroundColor: Colors.white)),
                          ],
                        ),
                    ],
                  ),
                )
              ],
            ),
        ),
      ),
    );
  }
}

class FeatureItem extends StatelessWidget {
  final String text;

  FeatureItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: Row(
          children: [
            Icon(Icons.check, color: Colors.white, size: 24),
            SizedBox(width: 10),
            Expanded(child: Text(text, style: TextStyle(fontSize: 16, color: Colors.white))),
          ],
        ),
    );
  }
}