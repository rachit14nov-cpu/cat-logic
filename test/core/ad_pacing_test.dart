import 'package:cat_logic/core/ad_pacing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final pacing = AdPacing(DefaultRemoteConfig());
  final now = DateTime(2026, 11, 20, 12);

  bool allow(int level, {bool midPuzzle = false, DateTime? last, int today = 0}) {
    return pacing.allowInterstitial(
      completedLevelNumber: level,
      midPuzzle: midPuzzle,
      now: now,
      lastInterstitialAt: last,
      interstitialsToday: today,
    );
  }

  test('interstitials skip the opening levels, mid-puzzle, and odd finishes', () {
    for (var level = 1; level <= 8; level++) {
      expect(allow(level), isFalse, reason: 'level $level');
    }
    expect(allow(9), isFalse);
    expect(allow(10), isTrue);
    expect(allow(11), isFalse);
    expect(allow(12), isTrue);
    expect(allow(10, midPuzzle: true), isFalse);
  });

  test('interstitials respect the 90 second gap and the daily cap', () {
    expect(allow(10, last: now.subtract(const Duration(seconds: 89))), isFalse);
    expect(allow(10, last: now.subtract(const Duration(seconds: 90))), isTrue);
    expect(allow(10, today: 20), isFalse);
    expect(allow(10, today: 19), isTrue);
  });

  test('banners stay on the menu and level select, rewards match the planned slots', () {
    expect(pacing.allowBanner(AdSurface.menu), isTrue);
    expect(pacing.allowBanner(AdSurface.levelSelect), isTrue);
    expect(pacing.allowBanner(AdSurface.game), isFalse);
    expect(pacing.allowRewarded(RewardReason.hint), isTrue);
    expect(pacing.allowRewarded(RewardReason.extraHeart), isTrue);
    expect(pacing.allowRewarded(RewardReason.secondDailyAttempt), isTrue);
    expect(pacing.allowBanner(AdSurface.menu, completedCampaignLevels: 7), isFalse);
    expect(pacing.allowBanner(AdSurface.menu, completedCampaignLevels: 8), isTrue);
    expect(pacing.allowRewarded(RewardReason.hint, campaignLevel: 3), isFalse);
    expect(pacing.allowRewarded(RewardReason.extraHeart, campaignLevel: 8), isFalse);
    expect(pacing.allowRewarded(RewardReason.hint, campaignLevel: 9), isTrue);
    expect(pacing.allowRewarded(RewardReason.secondDailyAttempt, completedCampaignLevels: 7), isFalse);
    expect(pacing.allowRewarded(RewardReason.secondDailyAttempt, completedCampaignLevels: 8), isTrue);
    expect(
      pacing.allowInterstitial(
        completedLevelNumber: 10,
        midPuzzle: false,
        now: now,
        lastInterstitialAt: null,
        interstitialsToday: 0,
        finishedCampaignCount: 7,
      ),
      isFalse,
    );
    expect(
      pacing.interstitialAfterWin(
        daily: true,
        removeAds: false,
        finishedCampaignCount: 20,
        puzzleNumber: 12,
        midPuzzle: false,
        now: now,
        lastInterstitialAt: null,
        interstitialsToday: 0,
      ),
      isFalse,
    );
    expect(
      pacing.interstitialAfterWin(
        daily: false,
        removeAds: true,
        finishedCampaignCount: 20,
        puzzleNumber: 12,
        midPuzzle: false,
        now: now,
        lastInterstitialAt: null,
        interstitialsToday: 0,
      ),
      isFalse,
    );
    expect(pacing.menuBannerVisible(removeAds: true, finishedCampaignCount: 20, surface: AdSurface.menu), isFalse);
    expect(pacing.menuBannerVisible(removeAds: true, finishedCampaignCount: 20, surface: AdSurface.levelSelect), isFalse);
    expect(pacing.menuBannerVisible(removeAds: false, finishedCampaignCount: 20, surface: AdSurface.menu), isTrue);
    expect(pacing.menuBannerVisible(removeAds: false, finishedCampaignCount: 20, surface: AdSurface.game), isFalse);
    expect(pacing.menuBannerVisible(removeAds: false, finishedCampaignCount: 3, surface: AdSurface.levelSelect), isFalse);
  });
}