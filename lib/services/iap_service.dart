abstract class IapService {
  Future<void> init();

  Future<bool> purchase(String productId);

  Future<void> restore();
}

abstract final class IapProducts {
  static const removeAds = 'remove_ads';
}

class NoopIapService implements IapService {
  @override
  Future<void> init() async {}

  @override
  Future<bool> purchase(String productId) async => false;

  @override
  Future<void> restore() async {}
}
