import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import '../core/ad_pacing.dart';
import '../services/analytics_service.dart';

/// Starts Firebase only when google-services.json was applied at build time.
class FirebaseBootstrap {
  static bool enabled = false;

  static Future<bool> start() async {
    try {
      await Firebase.initializeApp();
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
      enabled = true;
      return true;
    } catch (_) {
      enabled = false;
      return false;
    }
  }
}

class FirebaseAnalyticsService implements AnalyticsService {
  @override
  Future<void> logEvent(String name, [Map<String, Object>? params]) async {
    if (!FirebaseBootstrap.enabled) return;
    try {
      await FirebaseAnalytics.instance.logEvent(name: name, parameters: params);
    } catch (_) {}
  }
}

class FirebaseRemoteConfigSource implements RemoteConfig {
  FirebaseRemoteConfigSource(this._remote);

  final FirebaseRemoteConfig _remote;

  static Future<RemoteConfig> load() async {
    final remote = FirebaseRemoteConfig.instance;
    await remote.setConfigSettings(
      RemoteConfigSettings(fetchTimeout: const Duration(seconds: 8), minimumFetchInterval: const Duration(hours: 1)),
    );
    await remote.setDefaults(<String, dynamic>{
      AdPacing.minLevelKey: 9,
      AdPacing.everyKey: 2,
      AdPacing.intervalKey: 90000,
      AdPacing.capKey: 20,
      AdPacing.bannerKey: 'menu,levelSelect',
      AdPacing.rewardedKey: 'hint,extraHeart,secondDailyAttempt',
    });
    try {
      await remote.fetchAndActivate();
    } catch (_) {}
    return FirebaseRemoteConfigSource(remote);
  }

  @override
  int integer(String key, {required int fallback}) {
    try {
      return _remote.getInt(key);
    } catch (_) {
      return fallback;
    }
  }

  @override
  String string(String key, {required String fallback}) {
    try {
      final value = _remote.getString(key);
      return value.isEmpty ? fallback : value;
    } catch (_) {
      return fallback;
    }
  }

  @override
  bool flag(String key, {required bool fallback}) {
    try {
      return _remote.getBool(key);
    } catch (_) {
      return fallback;
    }
  }
}
