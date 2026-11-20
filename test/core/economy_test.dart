import 'package:cat_logic/core/economy.dart';
import 'package:cat_logic/data/progress.dart';
import 'package:cat_logic/data/save_merge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hint packs add hints and a restore does not grant them again', () {
    final start = ProgressData.initial();
    final bought = start.applyProduct(StoreCatalog.hintsSmall, restore: false);
    expect(bought.hintBalance, StoreCatalog.startingHints + 5);
    final restored = bought.applyProduct(StoreCatalog.hintsMedium, restore: true);
    expect(restored.hintBalance, bought.hintBalance);
  });

  test('the starter bundle removes ads once and adds ten hints', () {
    final first = ProgressData.initial().applyProduct(StoreCatalog.starterBundle, restore: false);
    expect(first.removeAds, isTrue);
    expect(first.hintBalance, StoreCatalog.startingHints + 10);
    final again = first.applyProduct(StoreCatalog.starterBundle, restore: true);
    expect(again.hintBalance, first.hintBalance);
    expect(again.removeAds, isTrue);
  });

  test('a wrong check spends a heart and an empty heart meter asks for an ad', () {
    expect(judgeCheck(trackHearts: true, hearts: 3, won: false, mistake: false), HeartCheck.free);
    expect(judgeCheck(trackHearts: true, hearts: 3, won: false, mistake: true), HeartCheck.charged);
    expect(judgeCheck(trackHearts: true, hearts: 0, won: false, mistake: true), HeartCheck.needsHeart);
    expect(judgeCheck(trackHearts: true, hearts: 0, won: true, mistake: false), HeartCheck.won);
    expect(judgeCheck(trackHearts: false, hearts: 0, won: false, mistake: true), HeartCheck.free);
    expect(refillHeartCount(0), 1);
    expect(refillHeartCount(3), 3);
  });

  test('an empty hint wallet asks for an ad and remove-ads skips forced breaks', () {
    expect(hintAccess(2), HintAccess.spendWallet);
    expect(hintAccess(0), HintAccess.watchAd);
    expect(shouldShowForcedAd(removeAds: true, pacingAllows: true), isFalse);
    expect(shouldShowForcedAd(removeAds: false, pacingAllows: true), isTrue);
    expect(shouldShowForcedAd(removeAds: false, pacingAllows: false), isFalse);
  });

  test('cloud merge keeps purchases, the larger wallet, and every finish', () {
    final local = ProgressData.initial().copyWith(completed: {'5-001'}, hintBalance: 1, removeAds: true);
    final cloud = ProgressData.initial().copyWith(
      completed: {'5-002'},
      hintBalance: 8,
      dailyStreak: 4,
      lastDailyDate: '2026-11-19',
    );
    final merged = mergeProgress(local, cloud);
    expect(merged.completed, {'5-001', '5-002'});
    expect(merged.hintBalance, 8);
    expect(merged.removeAds, isTrue);
    expect(merged.dailyStreak, 4);
  });
}
