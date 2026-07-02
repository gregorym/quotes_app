import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../utils/error_handling.dart';

enum AuthEvent { loggedOut, loggedIn, expired, none }

enum AuthState { loading, loaded, error, none }

final subscriptionProvider =
    ChangeNotifierProvider<SubscriptionController>((ref) {
  return SubscriptionController(
    ref,
  );
});

final subscribedProvider = FutureProvider<bool>((ref) async {
  final controller = SubscriptionController(ref);
  return await controller.hasSubscription();
});

class SubscriptionController extends ChangeNotifier {
  SubscriptionController(this.ref);
  final Ref ref;

  bool _isReady = false;
  bool get isReady => _isReady;

  Future<bool> hasSubscription() async {
    try {
      final bool available = await InAppPurchase.instance.isAvailable();
      if (!available) {
        _isReady = false;
        notifyListeners();
        return false;
      }

      final ProductDetailsResponse response =
          await InAppPurchase.instance.queryProductDetails({'premium'});
      _isReady = true;
      notifyListeners();
      return response.productDetails.isNotEmpty;
    } catch (e) {
      debugPrint(ErrorHandling.getErrorMessage(e));
      _isReady = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> buyPremium() async {
    try {
      final bool available = await InAppPurchase.instance.isAvailable();
      if (!available) {
        _isReady = false;
        notifyListeners();
        return false;
      }

      final response =
          await InAppPurchase.instance.queryProductDetails({'premium'});
      if (response.productDetails.isEmpty) {
        _isReady = false;
        notifyListeners();
        return false;
      }

      _isReady = true;
      notifyListeners();
      final purchaseParam =
          PurchaseParam(productDetails: response.productDetails.first);
      return await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
    } catch (e) {
      debugPrint(ErrorHandling.getErrorMessage(e));
      _isReady = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    try {
      final bool available = await InAppPurchase.instance.isAvailable();
      if (!available) {
        _isReady = false;
        notifyListeners();
        return false;
      }

      await InAppPurchase.instance.restorePurchases();
      _isReady = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint(ErrorHandling.getErrorMessage(e));
      _isReady = false;
      notifyListeners();
      return false;
    }
  }

  void checkSubscription() async {
    try {
      final bool available = await InAppPurchase.instance.isAvailable();
      if (!available) {
        _isReady = false;
        notifyListeners();
        return;
      }

      await InAppPurchase.instance.queryProductDetails({'premium'});
      _isReady = true;
    } catch (e) {
      debugPrint(ErrorHandling.getErrorMessage(e));
    }
  }
}
