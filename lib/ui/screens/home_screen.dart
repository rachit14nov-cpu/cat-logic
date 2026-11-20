import 'package:flutter/widgets.dart';

import '../../core/ad_pacing.dart';
import '../../core/catalog.dart';
import '../../core/daily.dart';
import '../../data/progress.dart';
import '../../services/app_services.dart';
import '../banner_slot.dart';
import '../chrome.dart';
import '../glyphs.dart';
import 'game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.catalog, required this.progress, required this.services, super.key});

  final LevelCatalog catalog;
  final ProgressData progress;
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final palette = CatTheme.of(context).palette;
    final streak = progress.visibleStreak(DateTime.now());
    final dailyLine = streak == 0 ? "Today's puzzle" : (streak == 1 ? "Today's puzzle · 1-day streak" : "Today's puzzle · $streak-day streak");
    return CatPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          CatMark(size: 92, coat: palette.ink, ink: palette.paper),
          const SizedBox(height: 18),
          Text('Cat Logic', style: TextStyle(color: palette.ink, fontSize: 42, fontWeight: FontWeight.w700, height: 1)),
          const SizedBox(height: 8),
          Text(
            'One cat in every row, column, and region.',
            style: TextStyle(color: palette.muted, fontSize: 16, height: 1.35),
          ),
          const SizedBox(height: 6),
          Text('A calm star-battle by Tinybit Labs.', style: TextStyle(color: palette.muted, fontSize: 14)),
          const Spacer(),
          SoftButton(
            key: const ValueKey('play-button'),
            label: 'Play',
            primary: true,
            onPressed: () => Navigator.of(context).pushNamed('/levels'),
          ),
          const SizedBox(height: 10),
          SoftButton(
            key: const ValueKey('daily-button'),
            label: dailyLine,
            onPressed: () async {
              final now = DateTime.now();
              final replay = progress.lastDailyDate == isoDate(now);
              if (replay) {
                final allowed = await services.ads.showRewarded(RewardReason.secondDailyAttempt);
                if (!allowed || !context.mounted) return;
              }
              if (!context.mounted) return;
              Navigator.of(context).pushNamed(
                '/play',
                arguments: PlayRequest(level: catalog.dailyFor(now), number: 0, daily: true),
              );
            },
          ),
          const SizedBox(height: 10),
          SoftButton(label: 'How to play', onPressed: () => Navigator.of(context).pushNamed('/howto')),
          const SizedBox(height: 10),
          SoftButton(label: 'Settings', onPressed: () => Navigator.of(context).pushNamed('/settings')),
          const SizedBox(height: 12),
          BannerSlot(services: services, surface: AdSurface.menu),
        ],
      ),
    );
  }
}
