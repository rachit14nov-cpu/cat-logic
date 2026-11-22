import '../core/ad_pacing.dart';
import 'ad_service.dart';
import 'analytics_service.dart';
import 'cloud_save_service.dart';
import 'iap_service.dart';

class AppServices {
  AppServices({
    required this.ads,
    required this.iap,
    required this.analytics,
    required this.cloud,
    required this.remoteConfig,
  });

  factory AppServices.noop(RemoteConfig remoteConfig) {
    return AppServices(
      ads: NoopAdService(AdPacing(remoteConfig)),
      iap: NoopIapService(),
      analytics: NoopAnalyticsService(),
      cloud: NoopCloudSaveService(),
      remoteConfig: remoteConfig,
    );
  }

  final AdService ads;
  final IapService iap;
  final AnalyticsService analytics;
  final CloudSaveService cloud;
  final RemoteConfig remoteConfig;

  Future<void> prepare() async {
    await ads.init();
    await iap.init();
  }
}
