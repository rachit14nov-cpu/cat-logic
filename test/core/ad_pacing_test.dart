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
  });
}