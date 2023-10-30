import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      final err = ErrorHandling.getErrorMessage(e);
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

      final ProductDetailsResponse response =
          await InAppPurchase.instance.queryProductDetails({'premium'});
      _isReady = true;
    } catch (e) {
      final err = ErrorHandling.getErrorMessage(e);
    }
  }
}
