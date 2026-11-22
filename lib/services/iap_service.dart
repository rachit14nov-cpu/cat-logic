import '../core/economy.dart';

abstract class IapService {
  Future<void> init();

  Future<bool> purchase(String productId);

  Future<void> restore();

  bool get storeAvailable;

  String priceLabel(String productId);
}

class NoopIapService implements IapService {
  @override
  Future<void> init() async {}

  @override
  Future<bool> purchase(String productId) async => false;

  @override
  Future<void> restore() async {}

  @override
  bool get storeAvailable => false;

  @override
  String priceLabel(String productId) => StoreCatalog.find(productId)?.priceLabel ?? '';
}
