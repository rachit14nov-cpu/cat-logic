import 'package:flutter/services.dart';

import '../core/catalog.dart';

class LevelRepository {
  static Future<LevelCatalog> load() async {
    final campaign = await rootBundle.loadString('assets/levels/levels.json');
    final daily = await rootBundle.loadString('assets/levels/daily.json');
    return LevelCatalog.fromJson(campaign, daily);
  }
}
