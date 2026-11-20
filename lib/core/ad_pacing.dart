/// Read-only knobs. A future remote-config SDK replaces [DefaultRemoteConfig].
abstract class RemoteConfig {
  int integer(String key, {required int fallback});

  String string(String key, {required String fallback});

  bool flag(String key, {required bool fallback});
}

class DefaultRemoteConfig implements RemoteConfig {
  DefaultRemoteConfig([this.overrides = const {}]);

  final Map<String, Object> overrides;

  @override
  int integer(String key, {required int fallback}) {
    final value = overrides[key];
    return value is int ? value : fallback;
  }

  @override
  String string(String key, {required String fallback}) {
    final value = overrides[key];
    return value is String ? value : fallback;
  }

  @override
  bool flag(String key, {required bool fallback}) {
    final value = overrides[key];
    return value is bool ? value : fallback;
  }
}

enum AdSurface { menu, levelSelect, game }

enum RewardReason { hint, extraHeart, secondDailyAttempt }

/// Pacing for ads that are not wired up yet.
///
/// Defaults, all overridable through [RemoteConfig]:
/// * no interstitial on levels 1–8, and never mid-puzzle
/// * then one after every 2nd completed level (10, 12, 14, …)
/// * at most one interstitial per 90 seconds, and about 20 per day
/// * rewarded placements: hint, extra heart, second daily attempt
/// * banners only on the menu and the level select
class AdPacing {
  AdPacing(this.remote);

  final RemoteConfig remote;

  static const minLevelKey = 'ads.interstitial.minLevel';
  static const everyKey = 'ads.interstitial.everyCompleted';
  static const intervalKey = 'ads.interstitial.minIntervalMs';
  static const capKey = 'ads.interstitial.dailyCap';
  static const bannerKey = 'ads.banner.surfaces';
  static const rewardedKey = 'ads.rewarded';

  bool allowInterstitial({
    required int completedLevelNumber,
    required bool midPuzzle,
    required DateTime now,
    required DateTime? lastInterstitialAt,
    required int interstitialsToday,
  }) {
    if (midPuzzle) return false;
    final minLevel = remote.integer(minLevelKey, fallback: 9);
    final every = remote.integer(everyKey, fallback: 2);
    final minGap = remote.integer(intervalKey, fallback: 90000);
    final cap = remote.integer(capKey, fallback: 20);
    if (completedLevelNumber < minLevel) return false;
    if (every > 0 && completedLevelNumber % every != 0) return false;
    if (interstitialsToday >= cap) return false;
    if (lastInterstitialAt != null && now.difference(lastInterstitialAt).inMilliseconds < minGap) {
      return false;
    }
    return true;
  }

  bool allowBanner(AdSurface surface) {
    final raw = remote.string(bannerKey, fallback: 'menu,levelSelect');
    return raw.split(',').contains(surface.name);
  }

  bool allowRewarded(RewardReason reason) {
    final raw = remote.string(rewardedKey, fallback: 'hint,extraHeart,secondDailyAttempt');
    return raw.split(',').contains(reason.name);
  }
}
