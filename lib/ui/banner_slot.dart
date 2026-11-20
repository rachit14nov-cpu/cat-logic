import 'package:flutter/widgets.dart';

import '../core/ad_pacing.dart';
import '../services/app_services.dart';

/// Collapses until a future ad SDK reports a filled banner.
class BannerSlot extends StatelessWidget {
  const BannerSlot({required this.services, required this.surface, super.key});

  final AppServices services;
  final AdSurface surface;

  @override
  Widget build(BuildContext context) {
    final ads = services.ads;
    if (ads is Listenable) {
      final listenable = ads as Listenable;
      return ListenableBuilder(
        listenable: listenable,
        builder: (context, _) => ads.bannerWidget(surface) ?? const SizedBox.shrink(),
      );
    }
    return ads.bannerWidget(surface) ?? const SizedBox.shrink();
  }
}
