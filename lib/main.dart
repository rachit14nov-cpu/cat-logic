import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/ad_pacing.dart';
import 'data/level_repository.dart';
import 'data/progress.dart';
import 'data/progress_store.dart';
import 'data/save_merge.dart';
import 'firebase/firebase_bootstrap.dart';
import 'services/analytics_service.dart';
import 'services/app_services.dart';
import 'services/mobile_ads_service.dart';
import 'services/play_billing_service.dart';
import 'services/play_games_cloud_save.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseOn = await FirebaseBootstrap.start();
  final remote = firebaseOn ? await FirebaseRemoteConfigSource.load() : DefaultRemoteConfig();
  final analytics = firebaseOn ? FirebaseAnalyticsService() : NoopAnalyticsService();
  final preferences = await SharedPreferences.getInstance();
  final store = SharedPreferencesProgressStore(preferences);
  final cloud = PlayGamesCloudSave(await _asset('config/play_games_app_id.txt'));
  final progress = ProgressController(store, store.load(), cloud: cloud);
  final pulled = await cloud.pull();
  final merged = mergeProgress(progress.data, pulled == null ? null : ProgressData.fromJson(pulled));
  if (!_sameSave(progress.data, merged)) {
    await progress.update(merged);
  }
  final services = AppServices(
    ads: MobileAdsService(pacing: AdPacing(remote), analytics: analytics),
    iap: PlayBillingService(
      analytics: analytics,
      onGrant: (productId, {required bool restore}) {
        return progress.update(progress.data.applyProduct(productId, restore: restore));
      },
    ),
    analytics: analytics,
    cloud: cloud,
    remoteConfig: remote,
  );
  await services.prepare();
  final catalog = await LevelRepository.load();
  runApp(CatLogicApp(progress: progress, catalog: catalog, services: services));
}

Future<String> _asset(String path) async {
  try {
    return (await rootBundle.loadString(path)).trim();
  } catch (_) {
    return '';
  }
}

bool _sameSave(ProgressData left, ProgressData right) {
  return left.hintBalance == right.hintBalance &&
      left.removeAds == right.removeAds &&
      left.completed.length == right.completed.length &&
      left.dailyStreak == right.dailyStreak &&
      left.lastDailyDate == right.lastDailyDate;
}
