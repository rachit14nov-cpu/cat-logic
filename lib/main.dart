import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/ad_pacing.dart';
import 'data/level_repository.dart';
import 'data/progress_store.dart';
import 'services/app_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final store = SharedPreferencesProgressStore(preferences);
  final progress = ProgressController(store, store.load());
  final catalog = await LevelRepository.load();
  final services = AppServices.noop(DefaultRemoteConfig());
  await services.prepare();
  final pulled = await services.cloud.pull();
  if (pulled != null && pulled.isNotEmpty) {
    await services.analytics.logEvent('cloud_save_present');
  }
  runApp(CatLogicApp(progress: progress, catalog: catalog, services: services));
}
