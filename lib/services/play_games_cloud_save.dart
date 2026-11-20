import 'dart:convert';

import 'package:games_services/games_services.dart';

import 'cloud_save_service.dart';

/// Inert until [appId] is the Play Console games app id.
class PlayGamesCloudSave implements CloudSaveService {
  PlayGamesCloudSave(this.appId);

  final String appId;
  static const saveName = 'cat_logic_progress';

  bool get active => appId.trim().isNotEmpty;

  @override
  Future<Map<String, Object?>?> pull() async {
    if (!active) return null;
    try {
      await GamesServices.signIn();
      final raw = await GamesServices.loadGame(name: saveName);
      if (raw == null || raw.isEmpty) return null;
      return Map<String, Object?>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> push(Map<String, Object?> data) async {
    if (!active) return;
    try {
      await GamesServices.signIn();
      await GamesServices.saveGame(data: jsonEncode(data), name: saveName);
    } catch (_) {}
  }
}
