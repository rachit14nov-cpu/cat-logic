import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../core/economy.dart';
import 'analytics_service.dart';
import 'iap_service.dart';

typedef PurchaseGrant = Future<void> Function(String productId, {required bool restore});

class PlayBillingService implements IapService {
  PlayBillingService({required this.analytics, required this.onGrant});

  final AnalyticsService analytics;
  final PurchaseGrant onGrant;
  final InAppPurchase _store = InAppPurchase.instance;
  final Map<String, ProductDetails> _products = {};
  final Set<String> _handled = {};
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _available = false;

  @override
  bool get storeAvailable => _available;

  @override
  String priceLabel(String productId) {
    return _products[productId]?.price ?? StoreCatalog.find(productId)?.priceLabel ?? '';
  }

  @override
  Future<void> init() async {
    _subscription ??= _store.purchaseStream.listen(_onPurchases, onError: (Object _) {});
    try {
      _available = await _store.isAvailable();
    } catch (_) {
      _available = false;
    }
    if (!_available) return;
    try {
      final response = await _store.queryProductDetails({for (final product in StoreCatalog.products) product.id});
      for (final product in response.productDetails) {
        _products[product.id] = product;
      }
    } catch (_) {
      _available = false;
    }
  }

  @override
  Future<bool> purchase(String productId) async {
    final product = StoreCatalog.find(productId);
    final details = _products[productId];
    if (product == null || details == null || !_available) return false;
    final param = PurchaseParam(productDetails: details);
    try {
      if (product.consumable) {
        return await _store.buyConsumable(purchaseParam: param);
      }
      return await _store.buyNonConsumable(purchaseParam: param);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> restore() async {
    if (!_available) return;
    try {
      await _store.restorePurchases();
    } catch (_) {}
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      final status = purchase.status;
      if (status != PurchaseStatus.purchased && status != PurchaseStatus.restored) {
        if (purchase.pendingCompletePurchase) {
          await _store.completePurchase(purchase);
        }
        continue;
      }
      final key = purchase.purchaseID ?? '${purchase.productID}:${purchase.transactionDate ?? ''}';
      if (!_handled.add(key)) {
        if (purchase.pendingCompletePurchase) await _store.completePurchase(purchase);
        continue;
      }
      final restore = status == PurchaseStatus.restored;
      await onGrant(purchase.productID, restore: restore);
      await analytics.logEvent('purchase', {'product_id': purchase.productID, 'restore': restore ? '1' : '0'});
      if (purchase.pendingCompletePurchase) {
        await _store.completePurchase(purchase);
      }
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
  }
}
