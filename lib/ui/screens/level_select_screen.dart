import 'package:flutter/widgets.dart';

import '../../core/ad_pacing.dart';
import '../../core/catalog.dart';
import '../../core/puzzle.dart';
import '../../data/progress.dart';
import '../../services/app_services.dart';
import '../banner_slot.dart';
import '../chrome.dart';
import '../glyphs.dart';
import 'game_screen.dart';

class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({required this.catalog, required this.progress, required this.services, super.key});

  final LevelCatalog catalog;
  final ProgressData progress;
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final palette = CatTheme.of(context).palette;
    final groups = <int, List<int>>{};
    for (var index = 0; index < catalog.campaign.length; index++) {
      groups.putIfAbsent(catalog.campaign[index].size, () => []).add(index);
    }
    return CatPage(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButtonBox(
                label: 'Back',
                onPressed: () => Navigator.of(context).pop(),
                child: backChevron(palette.ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Puzzles', style: TextStyle(color: palette.ink, fontSize: 28, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Finish one to open the next. ${progress.completed.length} settled.',
            style: TextStyle(color: palette.muted, fontSize: 14),
          ),
          const SizedBox(height: 8),
          BannerSlot(services: services, surface: AdSurface.levelSelect),
          const SizedBox(height: 8),
          Expanded(
            child: CustomScrollView(
              slivers: [
                for (final size in groups.keys) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                      child: Text(
                        '$size × $size',
                        style: TextStyle(color: palette.ink, fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 76,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    delegate: SliverChildBuilderDelegate((context, local) {
                      final index = groups[size]![local];
                      return _LevelTile(
                        number: index + 1,
                        level: catalog.campaign[index],
                        unlocked: catalog.isUnlocked(index, progress.completed),
                        completed: progress.completed.contains(catalog.campaign[index].id),
                        onOpen: () {
                          Navigator.of(context).pushNamed(
                            '/play',
                            arguments: PlayRequest(level: catalog.campaign[index], number: index + 1, daily: false),
                          );
                        },
                      );
                    }, childCount: groups[size]!.length),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.number,
    required this.level,
    required this.unlocked,
    required this.completed,
    required this.onOpen,
  });

  final int number;
  final Level level;
  final bool unlocked;
  final bool completed;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final palette = CatTheme.of(context).palette;
    final label = completed ? 'Puzzle $number, completed' : (unlocked ? 'Puzzle $number' : 'Puzzle $number, locked');
    return Semantics(
      button: unlocked,
      enabled: unlocked,
      label: label,
      child: GestureDetector(
        key: ValueKey('level-$number'),
        onTap: unlocked ? onOpen : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: completed ? palette.accent.withValues(alpha: 0.18) : palette.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: unlocked ? palette.accent : palette.line, width: completed ? 2 : 1),
          ),
          child: Center(
            child: unlocked
                ? completed
                    ? CustomPaint(
                        size: const Size.square(28),
                        painter: _CheckPainter(palette.accent),
                      )
                    : Text('$number', style: TextStyle(color: palette.ink, fontWeight: FontWeight.w700, fontSize: 16))
                : CustomPaint(size: const Size.square(22), painter: _LockPainter(palette.muted)),
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) => paintCheck(canvas, Offset.zero & size, color);
  @override
  bool shouldRepaint(covariant _CheckPainter oldDelegate) => oldDelegate.color != color;
}

class _LockPainter extends CustomPainter {
  _LockPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) => paintLock(canvas, Offset.zero & size, color);
  @override
  bool shouldRepaint(covariant _LockPainter oldDelegate) => oldDelegate.color != color;
}
