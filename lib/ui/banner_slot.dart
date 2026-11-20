import 'package:flutter/widgets.dart';

import '../core/ad_pacing.dart';
import '../services/app_services.dart';
import 'chrome.dart';

/// Collapses until a future ad SDK reports a filled banner.
class BannerSlot extends StatelessWidget {
  const BannerSlot({required this.services, required this.surface, super.key});

  final AppServices services;
  final AdSurface surface;

  @override
  Widget build(BuildContext context) {
    if (!services.ads.hasFilledBanner(surface)) return const SizedBox.shrink();
    final palette = CatTheme.of(context).palette;
    return SizedBox(
      height: 52,
      child: ColoredBox(
        color: palette.card,
        child: Center(child: Text('Banner', style: TextStyle(color: palette.muted))),
      ),
    );
  }
}
