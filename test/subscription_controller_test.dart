import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:quotes_app/controllers/subscription_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads both plans and completes only a verified purchase', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
    final store = InAppPurchase.instance;
    final platform = _FakePurchasePlatform();
    InAppPurchasePlatform.instance = platform;
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    const channel = MethodChannel('test/storekit');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (_) async => <String>[annualProductId],
    );

    final controller = SubscriptionController(
      store: store,
      entitlementChannel: channel,
    );
    await _waitFor(() => !controller.isLoading);

    expect(controller.products, hasLength(2));
    expect(controller.selectedProduct?.id, annualProductId);
    expect(controller.isEntitled, isTrue);

    final purchase = PurchaseDetails(
      productID: annualProductId,
      verificationData: PurchaseVerificationData(
        localVerificationData: 'verified-locally',
        serverVerificationData: 'verified-by-storekit',
        source: 'test',
      ),
      transactionDate: DateTime.now().millisecondsSinceEpoch.toString(),
      status: PurchaseStatus.purchased,
    )..pendingCompletePurchase = true;

    platform.purchases.add([purchase]);
    await _waitFor(() => platform.completedPurchases == 1);

    expect(controller.isEntitled, isTrue);
    expect(controller.message, 'Premium is active.');

    controller.dispose();
    await platform.purchases.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('preserves verified access through a transient entitlement error',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
    final store = InAppPurchase.instance;
    final platform = _FakePurchasePlatform();
    InAppPurchasePlatform.instance = platform;
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    const channel = MethodChannel('test/storekit-error');
    var shouldFail = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
      if (shouldFail) throw PlatformException(code: 'offline');
      return <String>[weeklyProductId];
    });

    final controller = SubscriptionController(
      store: store,
      entitlementChannel: channel,
    );
    await _waitFor(() => !controller.isLoading);
    expect(controller.isEntitled, isTrue);

    shouldFail = true;
    await controller.refreshEntitlement();
    expect(controller.isEntitled, isTrue);

    controller.dispose();
    await platform.purchases.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('does not complete an unverified purchase', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
    final store = InAppPurchase.instance;
    final platform = _FakePurchasePlatform();
    InAppPurchasePlatform.instance = platform;
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    const channel = MethodChannel('test/storekit-unverified');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => <String>[]);

    final controller = SubscriptionController(
      store: store,
      entitlementChannel: channel,
    );
    await _waitFor(() => !controller.isLoading);
    expect(controller.canAccessContent, isFalse);
    controller.skipPaywall();
    expect(controller.canAccessContent, isTrue);

    final purchase = PurchaseDetails(
      productID: weeklyProductId,
      verificationData: PurchaseVerificationData(
        localVerificationData: 'unverified',
        serverVerificationData: 'unverified',
        source: 'test',
      ),
      transactionDate: DateTime.now().millisecondsSinceEpoch.toString(),
      status: PurchaseStatus.purchased,
    )..pendingCompletePurchase = true;
    platform.purchases.add([purchase]);
    await _waitFor(() => controller.message != null);

    expect(platform.completedPurchases, 0);
    expect(controller.isEntitled, isFalse);
    expect(controller.message, 'The purchase could not be verified.');

    controller.dispose();
    await platform.purchases.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });
}

Future<void> _waitFor(bool Function() condition) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('Timed out waiting for subscription state.');
}

class _FakePurchasePlatform extends InAppPurchasePlatform {
  final purchases = StreamController<List<PurchaseDetails>>.broadcast();
  var completedPurchases = 0;

  final _products = [
    ProductDetails(
      id: weeklyProductId,
      title: 'Weekly',
      description: 'Weekly premium',
      price: r'$9.99',
      rawPrice: 9.99,
      currencyCode: 'USD',
    ),
    ProductDetails(
      id: annualProductId,
      title: 'Annual',
      description: 'Annual premium',
      price: r'$99.00',
      rawPrice: 99,
      currencyCode: 'USD',
    ),
  ];

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => purchases.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) {
    return Future.value(
      ProductDetailsResponse(
        productDetails: _products
            .where((product) => identifiers.contains(product.id))
            .toList(),
        notFoundIDs: const [],
      ),
    );
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    return true;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completedPurchases++;
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {}
}
