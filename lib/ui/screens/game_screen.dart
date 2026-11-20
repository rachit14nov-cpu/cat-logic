import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:flutter/services.dart';

import '../../core/ad_pacing.dart';
import '../../core/daily.dart';
import '../../core/economy.dart';
import '../../core/puzzle.dart';
import '../../data/progress_store.dart';
import '../../game/play_session.dart';
import '../../services/app_services.dart';
import '../board_view.dart';
import '../chrome.dart';
import '../glyphs.dart';
import '../palettes.dart';

class PlayRequest {
  const PlayRequest({required this.level, required this.number, required this.daily, this.next});

  final Level level;
  final int number;
  final bool daily;
  final Level? next;
}

class GameScreen extends StatefulWidget {
  const GameScreen({
    required this.request,
    required this.progress,
    required this.services,
    super.key,
  });

  final PlayRequest request;
  final ProgressController progress;
  final AppServices services;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late PlaySession _session;
  Timer? _ticker;
  bool _recorded = false;
  bool _needsHeart = false;
  bool _needsAdHint = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _session = PlaySession(
      puzzle: widget.request.level.toPuzzle(),
      autoMark: widget.progress.data.autoMark,
      trackHearts: !widget.request.daily,
    );
    widget.services.analytics.logEvent('level_start', {
      'id': widget.request.level.id,
      'daily': widget.request.daily ? '1' : '0',
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_session.won) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _session.clock.stop();
    } else if (state == AppLifecycleState.resumed && !_session.won) {
      _session.clock.start();
    }
  }

  List<String> _names(CatPalette palette) => [for (final look in palette.looks) look.name];

  Future<void> _recordWin() async {
    if (_recorded || !_session.won) return;
    _recorded = true;
    final elapsed = _session.clock.elapsedMilliseconds;
    final request = widget.request;
    final next = request.daily
        ? widget.progress.data.completeDaily(DateTime.now(), elapsed)
        : widget.progress.data.completeLevel(request.level.id, elapsed);
    await widget.progress.update(next);
    await widget.services.analytics.logEvent(request.daily ? 'daily_complete' : 'level_complete', {
      'id': request.level.id,
      'ms': elapsed,
    });
    if (!request.daily) {
      await widget.services.ads.maybeShowInterstitial(
        completedLevelNumber: request.number,
        midPuzzle: false,
        now: DateTime.now(),
      );
    }
    if (mounted) setState(() {});
  }

  Future<void> _onCheck(List<String> names) async {
    final verdict = _session.check(names);
    final wasWon = _session.won;
    setState(() => _needsHeart = verdict == HeartCheck.needsHeart);
    if (verdict == HeartCheck.charged || verdict == HeartCheck.needsHeart) {
      await _feedback(gentle: false);
    }
    if (wasWon) unawaited(_recordWin());
  }

  Future<void> _onHint(List<String> names) async {
    if (hintAccess(widget.progress.data.hintBalance) == HintAccess.spendWallet) {
      await widget.progress.update(widget.progress.data.spendHint());
      setState(() => _session.showHint(names));
      await widget.services.analytics.logEvent('hint_used', {'source': 'wallet'});
      return;
    }
    setState(() => _needsAdHint = true);
  }

  Future<void> _watchHint(List<String> names) async {
    final granted = await widget.services.ads.showRewarded(RewardReason.hint);
    if (!granted || !mounted) return;
    setState(() {
      _needsAdHint = false;
      _session.showHint(names);
    });
    await widget.services.analytics.logEvent('hint_used', {'source': 'rewarded'});
  }

  Future<void> _watchHeart() async {
    final granted = await widget.services.ads.showRewarded(RewardReason.extraHeart);
    if (!granted || !mounted) return;
    setState(() {
      _session.refillHeart();
      _needsHeart = false;
    });
  }

  Future<void> _feedback({required bool gentle}) async {
    final data = widget.progress.data;
    if (data.hapticsEnabled) {
      await HapticFeedback.selectionClick();
    }
    if (data.soundEnabled && !gentle) {
      await SystemSound.play(SystemSoundType.click);
    }
  }

  void _mutate(void Function() change) {
    final wasWon = _session.won;
    setState(change);
    if (!wasWon && _session.won) unawaited(_recordWin());
  }

  @override
  Widget build(BuildContext context) {
    final theme = CatTheme.of(context);
    final palette = theme.palette;
    final names = _names(palette);
    final request = widget.request;
    final title = request.daily ? "Today's puzzle" : 'Puzzle ${request.number}';
    final focus = _session.hint?.focusCells.toSet() ?? <int>{};
    final emphasis = <int>{...?_session.hint?.resultCells, for (final issue in _session.report?.issues ?? const []) ...issue.cells};
    return CatPage(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Stack(
        children: [
          Column(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: TextStyle(color: palette.ink, fontSize: 22, fontWeight: FontWeight.w700)),
                        Text(
                          '${request.level.size}×${request.level.size} · ${request.level.difficulty.label}',
                          style: TextStyle(color: palette.muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatClock(_session.clock.elapsed),
                    style: TextStyle(color: palette.ink, fontSize: 20, fontWeight: FontWeight.w700, fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                ],
              ),
              if (!request.daily) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (var heart = 0; heart < StoreCatalog.heartsPerPuzzle; heart++)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: CustomPaint(
                          size: const Size.square(18),
                          painter: _HeartPainter(filled: heart < _session.hearts, color: palette.accent),
                        ),
                      ),
                    const Spacer(),
                    Text(
                      '${widget.progress.data.hintBalance} hints',
                      style: TextStyle(color: palette.muted, fontSize: 13),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Expanded(
                child: BoardView(
                  puzzle: _session.puzzle,
                  marks: _session.marks,
                  palette: palette,
                  patterns: theme.patterns,
                  focus: focus,
                  emphasis: emphasis,
                  onTap: (index) => _mutate(() => _session.tap(index)),
                  onDoubleTap: (index) => _mutate(() => _session.doubleTap(index)),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SoftButton(
                      key: const ValueKey('undo-button'),
                      label: 'Undo',
                      expand: true,
                      onPressed: _session.history.isEmpty ? null : () => _mutate(_session.undo),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SoftButton(
                      key: const ValueKey('check-button'),
                      label: 'Check',
                      onPressed: () => _onCheck(names),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SoftButton(
                      key: const ValueKey('hint-button'),
                      label: 'Hint',
                      primary: true,
                      onPressed: () => _onHint(names),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_needsHeart)
            _sheet(
              palette: palette,
              eyebrow: 'Out of hearts',
              body: 'A wrong check uses a heart. Watch a short ad to get one back, or undo and keep looking.',
              action: 'Get a heart',
              onAction: _watchHeart,
              onClose: () => setState(() => _needsHeart = false),
            ),
          if (_needsAdHint)
            _sheet(
              palette: palette,
              eyebrow: 'Hint',
              body: 'The hint wallet is empty. A short ad unlocks this one. Buying hints in Settings skips the ad.',
              action: 'Watch ad',
              onAction: () => _watchHint(names),
              onClose: () => setState(() => _needsAdHint = false),
            ),
          if (_session.hintText != null)
            _sheet(
              palette: palette,
              eyebrow: _session.hint?.techniqueLabel ?? 'Hint',
              body: _session.hintText!,
              onClose: () => setState(_session.dismissHint),
            ),
          if (_session.report != null && !_session.won)
            _sheet(
              palette: palette,
              eyebrow: 'Check',
              body: _reportText(),
              onClose: () => setState(() => _session.report = null),
            ),
          if (_session.won) _winCard(palette),
        ],
      ),
    );
  }

  String _reportText() {
    final report = _session.report!;
    if (report.issues.isNotEmpty) {
      return report.issues.map((issue) => issue.message).join('\n');
    }
    final left = _session.puzzle.size - report.catsPlaced;
    if (left == 0) return 'Every cat is in place.';
    final noun = left == 1 ? 'cat' : 'cats';
    return 'So far, so cosy. $left $noun still to place.';
  }

  Widget _sheet({
    required CatPalette palette,
    required String eyebrow,
    required String body,
    required VoidCallback onClose,
    String action = 'Got it',
    VoidCallback? onAction,
  }) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: DecoratedBox(
        key: const ValueKey('hint-sheet'),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: palette.line),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(eyebrow, style: TextStyle(color: palette.accent, fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 160),
                child: SingleChildScrollView(
                  child: Text(body, style: TextStyle(color: palette.ink, fontSize: 16, height: 1.35)),
                ),
              ),
              const SizedBox(height: 12),
              SoftButton(label: action, onPressed: onAction ?? onClose, expand: false),
              if (onAction != null) ...[
                const SizedBox(height: 8),
                SoftButton(label: 'Not now', onPressed: onClose, expand: false),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _winCard(CatPalette palette) {
    final request = widget.request;
    final elapsed = _session.clock.elapsedMilliseconds;
    final best = request.daily
        ? widget.progress.data.dailyBestMs[isoDate(DateTime.now())]
        : widget.progress.data.bestMs[request.level.id];
    final streak = request.daily ? widget.progress.data.visibleStreak(DateTime.now()) : null;
    return Positioned.fill(
      child: ColoredBox(
        color: palette.ink.withValues(alpha: 0.28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: DecoratedBox(
              decoration: BoxDecoration(color: palette.card, borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CatMark(size: 72, coat: palette.ink, ink: palette.card),
                    const SizedBox(height: 8),
                    Text(
                      request.daily ? 'Today is done' : 'All settled',
                      style: TextStyle(color: palette.ink, fontSize: 26, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Time ${formatClock(Duration(milliseconds: elapsed))}',
                      style: TextStyle(color: palette.muted, fontSize: 16),
                    ),
                    if (best != null)
                      Text('Best ${formatClock(Duration(milliseconds: best))}', style: TextStyle(color: palette.muted, fontSize: 16)),
                    if (streak != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        streak == 1 ? '1-day streak' : '$streak-day streak',
                        key: const ValueKey('daily-streak'),
                        style: TextStyle(color: palette.accent, fontWeight: FontWeight.w700),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (!request.daily && request.next != null)
                      SoftButton(
                        label: 'Next puzzle',
                        primary: true,
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed(
                            '/play',
                            arguments: PlayRequest(level: request.next!, number: request.number + 1, daily: false),
                          );
                        },
                      ),
                    const SizedBox(height: 8),
                    SoftButton(label: request.daily ? 'Back home' : 'Puzzle list', onPressed: () => Navigator.of(context).pop()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeartPainter extends CustomPainter {
  _HeartPainter({required this.filled, required this.color});

  final bool filled;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = filled ? color : color.withValues(alpha: 0.25)
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.86)
      ..cubicTo(size.width * 0.02, size.height * 0.48, size.width * 0.08, size.height * 0.08, size.width * 0.32, size.height * 0.18)
      ..cubicTo(size.width * 0.42, size.height * 0.22, size.width * 0.48, size.height * 0.32, size.width * 0.5, size.height * 0.4)
      ..cubicTo(size.width * 0.52, size.height * 0.32, size.width * 0.58, size.height * 0.22, size.width * 0.68, size.height * 0.18)
      ..cubicTo(size.width * 0.92, size.height * 0.08, size.width * 0.98, size.height * 0.48, size.width * 0.5, size.height * 0.86)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HeartPainter oldDelegate) => oldDelegate.filled != filled || oldDelegate.color != color;
}
