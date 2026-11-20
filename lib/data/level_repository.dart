import 'dart:io';

import 'package:flutter/services.dart';

import '../core/catalog.dart';

class LevelRepository {
  static Future<LevelCatalog> load() async {
    final campaign = await rootBundle.load('assets/levels/campaign.bin.gz');
    final daily = await rootBundle.load('assets/levels/daily.bin.gz');
    return LevelCatalog.fromPacked(
      gzip.decode(campaign.buffer.asUint8List(campaign.offsetInBytes, campaign.lengthInBytes)),
      gzip.decode(daily.buffer.asUint8List(daily.offsetInBytes, daily.lengthInBytes)),
    );
  }
}
