import 'package:flutter/widgets.dart';

import '../core/ad_pacing.dart';

abstract class AdService {
  Future<void> init();

  /// True only when a banner creative is actually ready. Menus reserve no gap until then.
  bool hasFilledBanner(AdSurface surface);

  Widget? bannerWidget(AdSurface surface);

  void setAdsRemoved(bool removed);

  /// Finished campaign puzzles. Banners and forced breaks stay off until this reaches 8.
  void setCampaignCompleted(int count);

  bool get privacyOptionsRequired;

  Future<void> showPrivacyOptions();

  Future<bool> maybeShowInterstitial({
    required int completedLevelNumber,
    required bool midPuzzle,
    required DateTime now,
  });

  Future<bool> showRewarded(RewardReason reason, {int? campaignLevel});
}

class NoopAdService implements AdService {
  NoopAdService(this.pacing);

  final AdPacing pacing;
  bool adsRemoved = false;
  int campaignCompleted = AdPacing.openingLevels;

  @override
  Future<void> init() async {}

  @override
  void setCampaignCompleted(int count) => campaignCompleted = count;

  @override
  bool hasFilledBanner(AdSurface surface) => false;

  @override
  Widget? bannerWidget(AdSurface surface) => null;

  @override
  void setAdsRemoved(bool removed) => adsRemoved = removed;

  @override
  bool get privacyOptionsRequired => false;

  @override
  Future<void> showPrivacyOptions() async {}

  @override
  Future<bool> maybeShowInterstitial({
    required int completedLevelNumber,
    required bool midPuzzle,
    required DateTime now,
  }) async {
    if (adsRemoved || midPuzzle) return false;
    return pacing.allowInterstitial(
      completedLevelNumber: completedLevelNumber,
      midPuzzle: midPuzzle,
      now: now,
      lastInterstitialAt: null,
      interstitialsToday: 0,
    ) &&
        false;
  }

  @override
  Future<bool> showRewarded(RewardReason reason, {int? campaignLevel}) async {
    if (!pacing.allowRewarded(reason, campaignLevel: campaignLevel, completedCampaignLevels: campaignCompleted)) {
      return false;
    }
    return false;
  }
}
