import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/subscription_controller.dart';
import '../themes/colors.dart';
import '../themes/typography.dart';
import '../widgets/snackbar.dart';

class SubscriptionPage extends ConsumerWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionState = ref.watch(subscriptionProvider);
    subscriptionState.checkSubscription();

    return Scaffold(
      backgroundColor: MyColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  color: MyColors.muted,
                  icon: const Icon(Icons.close),
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/quotes'),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 58),
                  Text(
                    "Start your 7-day free trial",
                    textAlign: TextAlign.center,
                    style: MyTypography.h2,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    "✓  Unique offer applied",
                    style: MyTypography.body1.copyWith(
                      color: MyColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 38),
                  const FeatureItem(
                    icon: Icons.lock,
                    color: MyColors.primary,
                    title: "Today",
                    text: "Get full access and see how it changes your life.",
                  ),
                  const FeatureItem(
                    icon: Icons.notifications,
                    color: MyColors.primary,
                    title: "Day 5",
                    text: "You receive a reminder before your trial ends.",
                  ),
                  const FeatureItem(
                    icon: Icons.workspace_premium,
                    color: MyColors.teal,
                    title: "Day 7",
                    text: "Only \$19.99/year after trial. Cancel anytime.",
                  ),
                ],
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    const Center(
                      child: Text(
                        "3 days free, then just \$19.99/year",
                        style: TextStyle(
                          fontSize: 16,
                          color: MyColors.ink,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    SizedBox(
                      width: double.infinity,
                      height: 60.0,
                      child: TextButton(
                        onPressed: () async {
                          final didStartPurchase =
                              await subscriptionState.buyPremium();
                          if (!context.mounted) return;
                          showSnackbar(
                            context,
                            didStartPurchase
                                ? 'Purchase started.'
                                : 'Premium product is not available yet.',
                            isError: !didStartPurchase,
                          );
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: MyColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16.0),
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(32.0)),
                          ),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.0,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () async {
                            final didRestore =
                                await subscriptionState.restorePurchases();
                            if (!context.mounted) return;
                            showSnackbar(
                              context,
                              didRestore
                                  ? 'Restore requested.'
                                  : 'Restore is not available yet.',
                              isError: !didRestore,
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: MyColors.muted,
                          ),
                          child: const Text("Restore"),
                        ),
                        TextButton(
                          onPressed: () {
                            showSnackbar(
                              context,
                              'Terms and privacy URLs need to be configured.',
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: MyColors.muted,
                          ),
                          child: const Text("Terms & Conditions"),
                        ),
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
  const FeatureItem({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withValues(alpha: 0.72),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: MyTypography.body1.copyWith(
                      fontWeight: FontWeight.w900,
                    )),
                const SizedBox(height: 5),
                Text(text, style: MyTypography.body2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
