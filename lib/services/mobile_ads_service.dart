import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ads/ad_units.dart';
import '../core/ad_pacing.dart';
import '../core/daily.dart';
import '../core/economy.dart';
import 'ad_service.dart';
import 'analytics_service.dart';

class MobileAdsService extends ChangeNotifier implements AdService {
  MobileAdsService({required this.pacing, required this.analytics});

  final AdPacing pacing;
  final AnalyticsService analytics;

  bool _ready = false;
  bool _adsRemoved = false;
  int _campaignCompleted = 0;
  bool _privacyOptions = false;
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  final Map<AdSurface, BannerAd> _banners = {};
  final Set<AdSurface> _bannerReady = {};
  DateTime? _lastInterstitial;
  int _shownToday = 0;
  String? _shownDay;

  bool get ready => _ready;

  @override
  bool get privacyOptionsRequired => _privacyOptions;

  @override
  void setAdsRemoved(bool removed) {
    if (_adsRemoved == removed) return;
    _adsRemoved = removed;
    if (removed) {
      for (final banner in _banners.values) {
        banner.dispose();
      }
      _banners.clear();
      _bannerReady.clear();
      notifyListeners();
    }
  }

  @override
  void setCampaignCompleted(int count) {
    if (_campaignCompleted == count) return;
    _campaignCompleted = count;
    _maybeLoadBanners();
    notifyListeners();
  }

  @override
  Future<void> init() async {
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        maxAdContentRating: MaxAdContentRating.pg,
        // The newer age signal only offers child or teen. `no` is the explicit not-child-directed mark.
        // ignore: deprecated_member_use
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.no,
        // ignore: deprecated_member_use
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.no,
      ),
    );
    final updated = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
        if (!updated.isCompleted) updated.complete();
      },
      (error) {
        if (!updated.isCompleted) updated.complete();
      },
    );
    await updated.future;
    final status = await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
    _privacyOptions = status == PrivacyOptionsRequirementStatus.required;
    _ready = await ConsentInformation.instance.canRequestAds();
    if (!_ready) return;
    await MobileAds.instance.initialize();
    _maybeLoadBanners();
    notifyListeners();
  }

  @override
  Future<void> showPrivacyOptions() async {
    final done = Completer<void>();
    await ConsentForm.showPrivacyOptionsForm((_) {
      if (!done.isCompleted) done.complete();
    });
    await done.future;
    _ready = await ConsentInformation.instance.canRequestAds();
    _maybeLoadBanners();
    notifyListeners();
  }

  @override
  bool hasFilledBanner(AdSurface surface) => bannerWidget(surface) != null;

  @override
  Widget? bannerWidget(AdSurface surface) {
    if (!_ready || _adsRemoved || !pacing.allowBanner(surface, completedCampaignLevels: _campaignCompleted)) {
      return null;
    }
    final banner = _banners[surface];
    if (banner == null || !_bannerReady.contains(surface)) return null;
    return SizedBox(width: banner.size.width.toDouble(), height: banner.size.height.toDouble(), child: AdWidget(ad: banner));
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
    final allowed = shouldShowForcedAd(
      removeAds: _adsRemoved,
      pacingAllows: pacing.allowInterstitial(
        completedLevelNumber: completedLevelNumber,
        midPuzzle: midPuzzle,
        now: now,
        lastInterstitialAt: _lastInterstitial,
        interstitialsToday: _shownToday,
      ),
    );
    final ad = _interstitial;
    if (!allowed || !_ready || ad == null) {
      if (allowed && _ready) _loadInterstitial();
      return false;
    }
    final shown = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _lastInterstitial = now;
        _shownToday += 1;
        analytics.logEvent('ad_impression', {'format': 'interstitial'});
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitial = null;
        _loadInterstitial();
        if (!shown.isCompleted) shown.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitial = null;
        _loadInterstitial();
        if (!shown.isCompleted) shown.complete(false);
      },
    );
    await ad.show();
    return shown.future;
  }

  @override
  Future<bool> showRewarded(RewardReason reason, {int? campaignLevel}) async {
    if (!_ready || !pacing.allowRewarded(reason, campaignLevel: campaignLevel)) return false;
    final ad = _rewarded;
    if (ad == null) {
      _loadRewarded();
      return false;
    }
    final earned = Completer<bool>();
    var rewarded = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        analytics.logEvent('ad_impression', {'format': 'rewarded', 'reason': reason.name});
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewarded = null;
        _loadRewarded();
        if (!earned.isCompleted) earned.complete(rewarded);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewarded = null;
        _loadRewarded();
        if (!earned.isCompleted) earned.complete(false);
      },
    );
    await ad.show(
      onUserEarnedReward: (ad, reward) {
        rewarded = true;
        analytics.logEvent('ad_reward', {'reason': reason.name});
      },
    );
    return earned.future;
  }

  void _maybeLoadBanners() {
    if (!_ready || _adsRemoved || _campaignCompleted < AdPacing.openingLevels) return;
    if (!_banners.containsKey(AdSurface.menu)) _loadBanner(AdSurface.menu);
    if (!_banners.containsKey(AdSurface.levelSelect)) _loadBanner(AdSurface.levelSelect);
  }

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: AdUnits.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (error) => _interstitial = null,
      ),
    );
  }

  void _loadRewarded() {
    RewardedAd.load(
      adUnitId: AdUnits.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (error) => _rewarded = null,
      ),
    );
  }

  void _loadBanner(AdSurface surface) {
    final banner = BannerAd(
      adUnitId: AdUnits.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _bannerReady.add(surface);
          analytics.logEvent('ad_impression', {'format': 'banner', 'surface': surface.name});
          notifyListeners();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _banners.remove(surface);
          _bannerReady.remove(surface);
          notifyListeners();
        },
      ),
    );
    _banners[surface] = banner;
    banner.load();
  }

  @override
  void dispose() {
    _interstitial?.dispose();
    _rewarded?.dispose();
    for (final banner in _banners.values) {
      banner.dispose();
    }
    super.dispose();
  }
}
