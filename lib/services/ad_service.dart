import '../core/ad_pacing.dart';
import '../core/daily.dart';

abstract class AdService {
  Future<void> init();

  /// True only when a banner creative is actually ready. Menus reserve no gap until then.
  bool hasFilledBanner(AdSurface surface);

  Future<bool> maybeShowInterstitial({
    required int completedLevelNumber,
    required bool midPuzzle,
    required DateTime now,
  });

  Future<bool> showRewarded(RewardReason reason);
}

class NoopAdService implements AdService {
  NoopAdService(this.pacing);

  final AdPacing pacing;
  DateTime? _lastInterstitial;
  int _shownToday = 0;
  String? _shownDay;

  @override
  Future<void> init() async {}

  @override
  bool hasFilledBanner(AdSurface surface) {
    final allowed = pacing.allowBanner(surface);
    return allowed && false;
  }

  @override
  Future<bool> maybeShowInterstitial({
    required int completedLevelNumber,
    required bool midPuzzle,
    required DateTime now,
  }) async {
    final day = isoDate(now);
    if (_shownDay != day) {
      _shownDay = day;
      _shownToday = 0;
    }
    final allowed = pacing.allowInterstitial(
      completedLevelNumber: completedLevelNumber,
      midPuzzle: midPuzzle,
      now: now,
      lastInterstitialAt: _lastInterstitial,
      interstitialsToday: _shownToday,
    );
    if (allowed) {
      // The future ad SDK presents one interstitial here, then records the time.
    }
    return false;
  }

  @override
  Future<bool> showRewarded(RewardReason reason) async {
    if (!pacing.allowRewarded(reason)) return false;
    // The future SDK would grant a hint, an extra heart, or a second daily attempt.
    return false;
  }
}
