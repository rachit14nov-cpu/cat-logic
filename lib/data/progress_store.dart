import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/cloud_save_service.dart';
import 'progress.dart';

abstract class ProgressStore {
  ProgressData load();

  Future<void> save(ProgressData data);
}

class MemoryProgressStore implements ProgressStore {
  ProgressData data = ProgressData.initial();

  @override
  ProgressData load() => data;

  @override
  Future<void> save(ProgressData value) async {
    data = value;
  }
}

class SharedPreferencesProgressStore implements ProgressStore {
  SharedPreferencesProgressStore(this._preferences);

  final SharedPreferences _preferences;
  static const _key = 'cat_logic_progress_v1';

  @override
  ProgressData load() {
    final raw = _preferences.getString(_key);
    if (raw == null || raw.isEmpty) return ProgressData.initial();
    try {
      return ProgressData.fromJson(Map<String, Object?>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return ProgressData.initial();
    }
  }

  @override
  Future<void> save(ProgressData data) {
    return _preferences.setString(_key, jsonEncode(data.toJson()));
  }
}

class ProgressController extends ChangeNotifier {
  ProgressController(this.store, this.data, {CloudSaveService? cloud}) : _cloud = cloud ?? NoopCloudSaveService();

  final ProgressStore store;
  final CloudSaveService _cloud;
  ProgressData data;

  Future<void> update(ProgressData next) async {
    data = next;
    await store.save(data);
    notifyListeners();
    await _cloud.push(data.toJson());
  }
}
