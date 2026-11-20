import 'dart:convert';

import 'daily.dart';
import 'generator.dart';
import 'puzzle.dart';

class LevelCatalog {
  LevelCatalog({required this.campaign, required this.daily, required this.meta});

  final List<Level> campaign;
  final List<Level> daily;
  final Map<String, Object?> meta;

  Level levelById(String id) {
    return campaign.firstWhere((level) => level.id == id);
  }

  int indexOf(String id) {
    return campaign.indexWhere((level) => level.id == id);
  }

  Level dailyFor(DateTime date) {
    if (daily.isEmpty) {
      throw StateError('the daily pool is empty');
    }
    return daily[dailyIndex(date, daily.length)];
  }

  bool isUnlocked(int index, Set<String> completed) {
    if (index <= 0) return true;
    if (index >= campaign.length) return false;
    return completed.contains(campaign[index - 1].id);
  }

  factory LevelCatalog.fromJson(String campaignJson, String dailyJson) {
    final campaignMap = _objectMap(jsonDecode(campaignJson));
    final dailyMap = _objectMap(jsonDecode(dailyJson));
    return LevelCatalog(
      campaign: [for (final entry in _objectList(campaignMap['levels'])) _level(entry)],
      daily: [for (final entry in _objectList(dailyMap['puzzles'])) _level(entry)],
      meta: campaignMap['meta'] == null ? <String, Object?>{} : _objectMap(campaignMap['meta']),
    );
  }
}

Map<String, Object?> _objectMap(Object? value) {
  return Map<String, Object?>.from(value! as Map);
}

List<Map<String, Object?>> _objectList(Object? value) {
  return [for (final entry in value! as List) _objectMap(entry)];
}

Level _level(Map<String, Object?> json) {
  final size = (json['size']! as num).toInt();
  final encoded = json['regions']! as String;
  final regions = decodeRegions(encoded);
  return Level(
    id: json['id']! as String,
    size: size,
    difficulty: Difficulty.values.byName(json['difficulty']! as String),
    regions: regions,
  );
}

Map<String, Object?> campaignDocument({
  required int seed,
  required List<Level> levels,
  required Map<String, Object?> meta,
}) {
  return {
    'version': 1,
    'seed': seed,
    'meta': meta,
    'levels': [for (final level in levels) levelDocument(level)],
  };
}

Map<String, Object?> dailyDocument({required int seed, required String epoch, required List<Level> puzzles}) {
  return {
    'version': 1,
    'seed': seed,
    'epoch': epoch,
    'puzzles': [for (final level in puzzles) levelDocument(level)],
  };
}

Map<String, Object?> levelDocument(Level level) {
  return {
    'id': level.id,
    'size': level.size,
    'difficulty': level.difficulty.name,
    'regions': encodeRegions(level.regions),
  };
}
