import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';

const weeklyProductId = 'com.mars6.noexcuse.premium.weekly';
const annualProductId = 'com.mars6.noexcuse.premium.annual';
const premiumProductIds = {weeklyProductId, annualProductId};
bool get subscriptionPlatformSupported =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

String? freeTrialLabel(ProductDetails? product) {
  if (product is AppStoreProductDetails) {
    final offer = product.skProduct.introductoryPrice;
    if (offer == null || offer.paymentMode.name != 'freeTrail') return null;
    return _trialDuration(
      offer.subscriptionPeriod.numberOfUnits * offer.numberOfPeriods,
      offer.subscriptionPeriod.unit.name,
    );
  }
  if (product is AppStoreProduct2Details) {
    final offers =
        product.sk2Product.subscription?.promotionalOffers ?? const [];
    for (final offer in offers) {
      if (offer.type.name == 'introductory' &&
          offer.paymentMode.name == 'freeTrial') {
        return _trialDuration(
          offer.period.value * offer.periodCount,
          offer.period.unit.name,
        );
      }
    }
  }
  return null;
}

String _trialDuration(int value, String unit) => '$value-$unit free trial';

int? annualSavingsPercent(double weeklyPrice, double annualPrice) {
  final weeklyYear = weeklyPrice * 52;
  if (weeklyYear <= 0 || annualPrice >= weeklyYear) return null;
  return ((weeklyYear - annualPrice) / weeklyYear * 100).round();
}

final subscriptionProvider =
    ChangeNotifierProvider<SubscriptionController>((ref) {
  final controller = SubscriptionController();
  return controller;
});

final subscribedProvider = Provider<bool>(
  (ref) => ref.watch(subscriptionProvider).isEntitled,
);

class SubscriptionController extends ChangeNotifier
    with WidgetsBindingObserver {
  SubscriptionController({
    InAppPurchase? store,
    MethodChannel? entitlementChannel,
  })  : _store = store ?? InAppPurchase.instance,
        _entitlementChannel = entitlementChannel ??
            const MethodChannel('com.mars6.noexcuse/storekit') {
    WidgetsBinding.instance.addObserver(this);
    _purchaseSubscription = _store.purchaseStream.listen(
      _handlePurchases,
      onError: (Object error) {
        _message = 'The App Store could not complete that request.';
        _busy = false;
        notifyListeners();
      },
    );
    _entitlementTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => refreshEntitlement().then((_) => notifyListeners()),
    );
    load();
  }

  final InAppPurchase _store;
  final MethodChannel _entitlementChannel;
  late final StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;
  late final Timer _entitlementTimer;

  List<ProductDetails> _products = const [];
  final Set<String> _trialEligibleProductIds = {};
  ProductDetails? _selectedProduct;
  bool _loading = true;
  bool _busy = false;
  bool _storeAvailable = false;
  bool _isEntitled = false;
  bool _paywallSkipped = false;
  bool _entitlementChecked = false;
  bool _disposed = false;
  String? _message;

  List<ProductDetails> get products => _products;
  ProductDetails? get selectedProduct => _selectedProduct;
  bool get isLoading => _loading;
  bool get isBusy => _busy;
  bool get isStoreAvailable => _storeAvailable;
  bool get isEntitled => _isEntitled;
  bool get canAccessContent => _isEntitled || _paywallSkipped;
  bool get entitlementChecked => _entitlementChecked;
  String? get message => _message;

  String? trialLabel(ProductDetails? product) =>
      product != null && _trialEligibleProductIds.contains(product.id)
          ? freeTrialLabel(product)
          : null;

  ProductDetails? product(String id) {
    for (final product in _products) {
      if (product.id == id) return product;
    }
    return null;
  }

  Future<void> load() async {
    _loading = true;
    _message = null;
    notifyListeners();

    if (!subscriptionPlatformSupported) {
      _isEntitled = true;
      _entitlementChecked = true;
      _loading = false;
      notifyListeners();
      return;
    }

    try {
      _storeAvailable = await _store.isAvailable();
      if (!_storeAvailable) {
        _products = const [];
        _message = 'The App Store is unavailable right now.';
        await refreshEntitlement();
        return;
      }

      final response = await _store.queryProductDetails(premiumProductIds);
      _products = response.productDetails;
      await _loadTrialEligibility();
      _selectedProduct = product(annualProductId) ??
          (_products.isEmpty ? null : _products.first);
      _message = response.error?.message ??
          (response.notFoundIDs.isEmpty
              ? null
              : 'Subscription products are still being configured.');
      await refreshEntitlement();
    } catch (_) {
      _message = 'The App Store could not be reached. Try again.';
      await refreshEntitlement();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadTrialEligibility() async {
    _trialEligibleProductIds.clear();
    for (final product in _products) {
      if (freeTrialLabel(product) == null) continue;
      if (product is! AppStoreProduct2Details) {
        _trialEligibleProductIds.add(product.id);
        continue;
      }
      try {
        if (await SK2Product.isIntroductoryOfferEligible(product.id)) {
          _trialEligibleProductIds.add(product.id);
        }
      } on PlatformException {
        // Hide the offer if StoreKit cannot confirm eligibility.
      }
    }
  }

  void select(ProductDetails product) {
    if (_busy || product.id == _selectedProduct?.id) return;
    _selectedProduct = product;
    _message = null;
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  void skipPaywall() {
    _paywallSkipped = true;
    notifyListeners();
  }

  Future<bool> buySelected() async {
    final selected = _selectedProduct;
    if (selected == null || _busy) return false;

    _busy = true;
    _message = null;
    notifyListeners();

    try {
      final launched = await _store.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: selected),
      );
      if (!launched) {
        _busy = false;
        _message = 'The purchase sheet could not be opened.';
        notifyListeners();
      }
      return launched;
    } catch (_) {
      _busy = false;
      _message = 'The App Store could not start the purchase.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    if (_busy) return false;
    _busy = true;
    _message = null;
    notifyListeners();

    try {
      await _store.restorePurchases();
      final restored = await refreshEntitlement();
      _message =
          restored ? 'Premium restored.' : 'No active subscription was found.';
      return restored;
    } catch (_) {
      _message = 'Restore failed. Check your connection and try again.';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> refreshEntitlement() async {
    if (!subscriptionPlatformSupported) {
      _isEntitled = true;
      _entitlementChecked = true;
      return true;
    }

    try {
      final ids = await _entitlementChannel.invokeListMethod<String>(
        'currentEntitlements',
      );
      _isEntitled = ids?.any(premiumProductIds.contains) ?? false;
    } on PlatformException {
      // Preserve a previously verified entitlement through transient failures.
    } on MissingPluginException {
      // Preserve a previously verified entitlement through transient failures.
    } finally {
      _entitlementChecked = true;
    }
    return _isEntitled;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    refreshEntitlement().then((_) => notifyListeners());
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases.where(
      (purchase) => premiumProductIds.contains(purchase.productID),
    )) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _busy = true;
          _message = null;
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          try {
            final verified = await refreshEntitlement();
            if (verified && purchase.pendingCompletePurchase) {
              await _store.completePurchase(purchase);
            }
            _message = verified
                ? 'Premium is active.'
                : 'The purchase could not be verified.';
          } catch (_) {
            _message = 'The purchase could not be completed. Try Restore.';
          }
          _busy = false;
          break;
        case PurchaseStatus.error:
          _busy = false;
          _message = purchase.error?.message ??
              'The App Store could not complete the purchase.';
          break;
        case PurchaseStatus.canceled:
          _busy = false;
          _message = null;
          break;
      }
    }
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _entitlementTimer.cancel();
    _purchaseSubscription.cancel();
    super.dispose();
  }
}
