import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../controllers/subscription_controller.dart';
import '../../repositories/onboarding_repository.dart';
import '../../utils/external_links.dart';
import '../themes/colors.dart';
import '../themes/typography.dart';

final _paywallAnswersProvider = FutureProvider(
  (ref) => ref.watch(onboardingRepositoryProvider).fetchAnswers(),
);

class SubscriptionPage extends ConsumerWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);
    final answers =
        ref.watch(_paywallAnswersProvider).value ?? const <String, dynamic>{};
    final selected = subscription.selectedProduct;
    final annual = subscription.product(annualProductId);
    final weekly = subscription.product(weeklyProductId);
    final annualDiscount = annual == null || weekly == null
        ? null
        : annualSavingsPercent(weekly.rawPrice, annual.rawPrice);
    final selectedTrial = subscription.trialLabel(selected);

    return Scaffold(
      backgroundColor: MyColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Semantics(
                    label: 'Close paywall',
                    button: true,
                    child: IconButton.filled(
                      onPressed: () {
                        subscription.skipPaywall();
                        context.go('/quotes');
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: MyColors.surface,
                        foregroundColor: MyColors.ink,
                      ),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                  TextButton(
                    onPressed: subscription.isBusy
                        ? null
                        : subscription.restorePurchases,
                    child: const Text('Restore'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _PaywallHero(),
                    const SizedBox(height: 6),
                    _BenefitsCard(answers: answers),
                    const SizedBox(height: 8),
                    if (subscription.isLoading)
                      const SizedBox(
                        height: 112,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      SizedBox(
                        key: const Key('subscription-plans'),
                        height: 112,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _PlanCard(
                                title: 'WEEKLY',
                                cadence: 'per week',
                                trial: subscription.trialLabel(weekly),
                                product: weekly,
                                selected: selected?.id == weeklyProductId,
                                onTap: subscription.select,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _PlanCard(
                                title: 'ANNUAL',
                                cadence: 'per year',
                                badge: annualDiscount == null
                                    ? null
                                    : '-$annualDiscount%',
                                trial: subscription.trialLabel(annual),
                                product: annual,
                                selected: selected?.id == annualProductId,
                                onTap: subscription.select,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (subscription.message != null)
                      Semantics(
                        liveRegion: true,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            subscription.message!,
                            textAlign: TextAlign.center,
                            style: MyTypography.caption1,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            _PurchaseFooter(
              subscription: subscription,
              selected: selected,
              selectedTrial: selectedTrial,
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseFooter extends StatelessWidget {
  const _PurchaseFooter({
    required this.subscription,
    required this.selected,
    required this.selectedTrial,
  });

  final SubscriptionController subscription;
  final ProductDetails? selected;
  final String? selectedTrial;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('subscription-footer'),
      color: MyColors.background,
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton(
            onPressed: subscription.isEntitled
                ? () => context.go('/quotes')
                : selected == null || subscription.isBusy
                    ? null
                    : subscription.buySelected,
            child: subscription.isBusy
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    subscription.isEntitled
                        ? 'Enter No Excuses'
                        : selected == null
                            ? 'Subscriptions unavailable'
                            : selectedTrial == null
                                ? 'Commit to my goal'
                                : 'Start $selectedTrial',
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            selected == null
                ? 'Prices are provided by the App Store.'
                : '${selected!.price} per ${selected!.id == weeklyProductId ? 'week' : 'year'}. Auto-renews until canceled.',
            textAlign: TextAlign.center,
            style: MyTypography.caption1,
          ),
          SizedBox(
            height: 34,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => openExternalUrl(termsOfUseUrl),
                  child: const Text('Terms'),
                ),
                TextButton(
                  onPressed: () => openExternalUrl(privacyPolicyUrl),
                  child: const Text('Privacy'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaywallHero extends StatelessWidget {
  const _PaywallHero();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0x553A1A08), Colors.transparent],
                  radius: .72,
                ),
              ),
            ),
          ),
          Positioned(
            left: 8,
            top: 26,
            child: Transform.rotate(
              angle: -.12,
              child: Container(
                width: 40,
                height: 54,
                decoration: BoxDecoration(
                  color: MyColors.selected,
                  border: Border.all(color: MyColors.primary, width: 2),
                ),
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 26,
            child: Transform.rotate(
              angle: .12,
              child: Container(
                width: 48,
                height: 32,
                color: MyColors.primary,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Image.asset(
                  'assets/images/onboarding/mascot_victory.png',
                  fit: BoxFit.contain,
                  semanticLabel: 'A determined athlete reaching the top',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'NO EXCUSES.',
                style: MyTypography.h1.copyWith(
                  fontSize: 32,
                  letterSpacing: .4,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: MyColors.surface,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: MyColors.disabled),
                ),
                child: Text(
                  'PREMIUM',
                  style: MyTypography.caption1.copyWith(
                    color: MyColors.ink,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard({required this.answers});

  final Map<String, dynamic> answers;

  @override
  Widget build(BuildContext context) {
    final goal = answers['primary_goal']?.toString().trim();
    final namedFrictions = onboardingFrictions(answers).take(2).join(' and ');
    final pressure = answers['tone'] == 'extra hard' ? 'Extra Hard' : 'Hard';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: MyColors.disabled),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'THE RETURN ON YOUR COMMITMENT',
            style: MyTypography.caption1.copyWith(
              color: MyColors.primary,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _Benefit(
            title: 'Back your goal with hours, not intentions.',
            subtitle: goal == null || goal.isEmpty
                ? 'Every extra hour you show up is this investment doing what '
                    'you paid it to do.'
                : 'Every extra hour on “$goal” is this investment doing what '
                    'you paid it to do.',
          ),
          const _Benefit(
            title: 'Expensive by design. Cheap if you use it.',
            subtitle: 'If the investment gets you to show up, the time and '
                'momentum you gain can dwarf the price.',
          ),
          _Benefit(
            title: 'Built around what stops you',
            subtitle: namedFrictions.isEmpty
                ? 'No generic inspiration. Direct prompts push you back to '
                    'the work.'
                : 'We call out $namedFrictions instead of serving generic '
                    'inspiration.',
          ),
          _Benefit(
            title: 'Pressure on your terms',
            subtitle:
                'You chose $pressure. It shows up inside the schedule you built.',
          ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.check_circle,
              color: MyColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: MyTypography.body1.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: MyTypography.caption1.copyWith(color: MyColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.cadence,
    required this.product,
    required this.selected,
    required this.onTap,
    this.badge,
    this.trial,
  });

  final String title;
  final String cadence;
  final String? badge;
  final String? trial;
  final ProductDetails? product;
  final bool selected;
  final ValueChanged<ProductDetails> onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label:
          '$title plan, ${product?.price ?? 'not available'}${badge == null ? '' : ', $badge'}',
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: product == null ? null : () => onTap(product!),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? MyColors.selected : MyColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? MyColors.primary : MyColors.disabled,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: MyTypography.caption1.copyWith(
                      color: MyColors.ink,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: MyColors.primary,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 7,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    selected ? Icons.check_circle : Icons.circle_outlined,
                    color: selected ? MyColors.primary : MyColors.muted,
                    size: 21,
                  ),
                ],
              ),
              const Spacer(),
              Text(product?.price ?? 'Unavailable', style: MyTypography.h3),
              Text(
                cadence,
                style: MyTypography.caption1.copyWith(color: MyColors.muted),
              ),
              if (trial != null)
                Text(
                  trial!.toUpperCase(),
                  style: MyTypography.caption1.copyWith(
                    color: MyColors.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
