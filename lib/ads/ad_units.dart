import 'package:flutter/foundation.dart';

/// Release ids are the live AdMob units. Debug builds always use Google's sample units.
abstract final class AdUnits {
  static const releaseAppId = 'ca-app-pub-7274973557636419~7653220075';
  static const testAppId = 'ca-app-pub-3940256099942544~3347511713';

  static const releaseBanner = 'ca-app-pub-7274973557636419/8248563556';
  static const releaseInterstitial = 'ca-app-pub-7274973557636419/1930567214';
  static const releaseRewarded = 'ca-app-pub-7274973557636419/4640491038';

  static const testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const testInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const testRewarded = 'ca-app-pub-3940256099942544/5224354917';

  static bool get useTestIds => kDebugMode;

  static String get banner => useTestIds ? testBanner : releaseBanner;

  static String get interstitial => useTestIds ? testInterstitial : releaseInterstitial;

  static String get rewarded => useTestIds ? testRewarded : releaseRewarded;
}

abstract final class LegalLinks {
  static const privacyPolicy = 'https://tinybitlabs.co/cat-logic/privacy';
  static const dataDeletion = 'https://tinybitlabs.co/cat-logic/delete-data';
  static const supportEmail = 'support@tinybitlabs.co';
}
