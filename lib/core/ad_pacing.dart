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
/// * no ads anywhere until 8 campaign puzzles are finished, including a second daily play
/// * no interstitial mid-puzzle; after that, one between every 2nd finished puzzle (10, 12, …)
/// * at most one interstitial per 90 seconds, and about 20 per day
/// * rewarded hints and hearts are opt-in, and only after those 8 puzzles
/// * banners only on the menu and the level select, and only after those 8 puzzles
class AdPacing {
  AdPacing(this.remote);

  final RemoteConfig remote;

  static const openingLevels = 8;

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

  bool allowBanner(AdSurface surface, {int completedCampaignLevels = openingLevels}) {
    if (completedCampaignLevels < openingLevels) return false;
    final raw = remote.string(bannerKey, fallback: 'menu,levelSelect');
    return raw.split(',').contains(surface.name);
  }

  bool allowRewarded(RewardReason reason, {int? campaignLevel, int completedCampaignLevels = openingLevels}) {
    if (completedCampaignLevels < openingLevels) return false;
    if (campaignLevel != null && campaignLevel <= openingLevels) return false;
    final raw = remote.string(rewardedKey, fallback: 'hint,extraHeart,secondDailyAttempt');
    return raw.split(',').contains(reason.name);
  }
}
