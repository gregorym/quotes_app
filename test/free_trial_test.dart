import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';
import 'package:quotes_app/controllers/subscription_controller.dart';

void main() {
  test('formats the free trial supplied by StoreKit', () {
    final product = AppStoreProduct2Details.fromSK2Product(
      SK2Product(
        id: weeklyProductId,
        displayName: 'Weekly',
        displayPrice: r'$9.99',
        description: 'Weekly premium',
        price: 9.99,
        type: SK2ProductType.autoRenewable,
        priceLocale: SK2PriceLocale(
          currencyCode: 'USD',
          currencySymbol: r'$',
        ),
        subscription: SK2SubscriptionInfo(
          subscriptionGroupID: 'premium',
          subscriptionPeriod: const SK2SubscriptionPeriod(
            value: 1,
            unit: SK2SubscriptionPeriodUnit.week,
          ),
          promotionalOffers: [
            SK2SubscriptionOffer(
              price: 0,
              type: SK2SubscriptionOfferType.introductory,
              period: const SK2SubscriptionPeriod(
                value: 3,
                unit: SK2SubscriptionPeriodUnit.day,
              ),
              periodCount: 1,
              paymentMode: SK2SubscriptionOfferPaymentMode.freeTrial,
            ),
          ],
        ),
      ),
    );

    expect(freeTrialLabel(product), '3-day free trial');
  });

  test('calculates annual savings against 52 weekly payments', () {
    expect(annualSavingsPercent(9.99, 99), 81);
    expect(annualSavingsPercent(2, 104), isNull);
  });
}
