import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:flutter/services.dart';

import '../../core/ad_pacing.dart';
import '../../core/daily.dart';
import '../../core/economy.dart';
import '../../core/puzzle.dart';
import '../../data/progress.dart';
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
  bool _earlyHint = false;
  int _tutorialStep = 0;

  static const _tutorial = [
    ('Place a cat', 'Double-tap an empty cell to set a cat down.'),
    ('Cross a cell out', 'Tap a cell you know is empty. Undo takes it back.'),
    ('The one rule', 'One cat in every row, column, and region. Cats cannot touch, even on a corner.'),
  ];

  bool get _showTutorial => !widget.request.daily && widget.request.number == 1 && !widget.progress.data.tutorialSeen;

  bool get _earlyCampaign => !widget.request.daily && widget.request.number <= AdPacing.openingLevels;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final puzzle = widget.request.level.toPuzzle();
    final saved = widget.progress.data.resume;
    final restore = !widget.request.daily && saved != null && saved.levelId == widget.request.level.id && saved.marks.length == puzzle.cellCount;
    _session = PlaySession(
      puzzle: puzzle,
      autoMark: widget.progress.data.autoMark,
      trackHearts: !widget.request.daily,
      restored: restore
          ? [for (final mark in saved.marks) mark >= 0 && mark < CellMark.values.length ? CellMark.values[mark] : CellMark.empty]
          : null,
      carriedMs: restore ? saved.elapsedMs : 0,
      hearts: restore ? saved.hearts : null,
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
    unawaited(_persistBoard());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _session.clock.stop();
      unawaited(_persistBoard());
    } else if (state == AppLifecycleState.resumed && !_session.won) {
      _session.clock.start();
    }
  }

  List<String> _names(CatPalette palette) => [for (final look in palette.looks) look.name];

  Future<void> _recordWin() async {
    if (_recorded || !_session.won) return;
    _recorded = true;
    final elapsed = _session.elapsedMilliseconds;
    final request = widget.request;
    final finished = request.daily
        ? widget.progress.data.completeDaily(DateTime.now(), elapsed)
        : widget.progress.data.completeLevel(request.level.id, elapsed);
    final next = widget.progress.data.resume?.levelId == request.level.id ? finished.copyWith(clearResume: true) : finished;
    await widget.progress.update(next);
    await widget.services.analytics.logEvent(request.daily ? 'daily_complete' : 'level_complete', {
      'id': request.level.id,
      'ms': elapsed,
    });
    await widget.services.ads.maybeShowInterstitial(
      completedLevelNumber: request.number,
      midPuzzle: false,
      now: DateTime.now(),
      daily: request.daily,
    );
    if (mounted) setState(() {});
  }

  Future<void> _onCheck(List<String> names) async {
    final verdict = _session.check(names);
    final wasWon = _session.won;
    setState(() => _needsHeart = verdict == HeartCheck.needsHeart);
    if (verdict == HeartCheck.charged || verdict == HeartCheck.needsHeart) {
      await _feedback();
    }
    if (verdict == HeartCheck.won) await _feedback(win: true);
    if (wasWon) unawaited(_recordWin());
  }

  Future<void> _onHint(List<String> names) async {
    if (hintAccess(widget.progress.data.hintBalance) == HintAccess.spendWallet) {
      await widget.progress.update(widget.progress.data.spendHint());
      setState(() => _session.showHint(names));
      await widget.services.analytics.logEvent('hint_used', {'source': 'wallet'});
      return;
    }
    if (!widget.request.daily && widget.request.number <= AdPacing.openingLevels) {
      setState(() => _earlyHint = true);
      return;
    }
    setState(() => _needsAdHint = true);
  }

  Future<void> _watchHint(List<String> names) async {
    final granted = await widget.services.ads.showRewarded(
      RewardReason.hint,
      campaignLevel: widget.request.daily ? null : widget.request.number,
    );
    if (!granted || !mounted) return;
    setState(() {
      _needsAdHint = false;
      _session.showHint(names);
    });
    await widget.services.analytics.logEvent('hint_used', {'source': 'rewarded'});
  }

  Future<void> _watchHeart() async {
    final granted = await widget.services.ads.showRewarded(
      RewardReason.extraHeart,
      campaignLevel: widget.request.daily ? null : widget.request.number,
    );
    if (!granted || !mounted) return;
    setState(() {
      _session.refillHeart();
      _needsHeart = false;
    });
  }

  Future<void> _persistBoard() async {
    final request = widget.request;
    if (request.daily) return;
    final data = widget.progress.data;
    if (_session.won) {
      if (data.resume?.levelId == request.level.id) {
        await widget.progress.update(data.copyWith(clearResume: true));
      }
      return;
    }
    final marks = [for (final mark in _session.marks) mark.index];
    if (marks.every((mark) => mark == CellMark.empty.index)) return;
    await widget.progress.update(
      widget.progress.data.copyWith(
        resume: BoardResume(
          levelId: request.level.id,
          marks: marks,
          elapsedMs: _session.elapsedMilliseconds,
          hearts: _session.hearts,
        ),
      ),
    );
  }

  Future<void> _feedback({bool win = false}) async {
    final data = widget.progress.data;
    if (data.hapticsEnabled) {
      await (win ? HapticFeedback.lightImpact() : HapticFeedback.selectionClick());
    }
    if (data.soundEnabled) {
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
    final dim = _session.hint?.resultCells.toSet() ?? <int>{};
    final emphasis = <int>{for (final issue in _session.report?.issues ?? const []) ...issue.cells};
    final streak = request.daily ? widget.progress.data.visibleStreak(DateTime.now()) : 0;
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
                    formatClock(_session.elapsed),
                    style: TextStyle(color: palette.ink, fontSize: 20, fontWeight: FontWeight.w700, fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                ],
              ),
              if (request.daily) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    CustomPaint(size: const Size.square(18), painter: _FlamePainter(color: palette.accent)),
                    const SizedBox(width: 8),
                    Text(
                      streak == 1 ? '1-day streak' : '$streak-day streak',
                      style: TextStyle(color: palette.ink, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
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
                  dim: dim,
                  onTap: (index) => _mutate(() => _session.tap(index)),
                  onDoubleTap: (index) {
                    final before = _session.marks[index];
                    _mutate(() => _session.doubleTap(index));
                    if (before != CellMark.cat && _session.marks[index] == CellMark.cat) {
                      unawaited(_feedback());
                    }
                  },
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
              body: _earlyCampaign
                  ? 'A wrong check uses a heart. Ads stay off through puzzle 8, so undo and look again.'
                  : 'A wrong check uses a heart. Watch a short ad to get one back, or undo and keep looking.',
              action: _earlyCampaign ? 'Got it' : 'Get a heart',
              onAction: _earlyCampaign ? null : _watchHeart,
              onClose: () => setState(() => _needsHeart = false),
            ),
          if (_earlyHint)
            _sheet(
              palette: palette,
              eyebrow: 'Hint',
              body: 'The hint wallet is empty. A short optional ad can unlock one after puzzle 8.',
              onClose: () => setState(() => _earlyHint = false),
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
          if (_showTutorial) _tutorialCard(palette),
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

  Widget _tutorialCard(CatPalette palette) {
    final step = _tutorial[_tutorialStep.clamp(0, _tutorial.length - 1)];
    final last = _tutorialStep >= _tutorial.length - 1;
    return Positioned.fill(
      child: ColoredBox(
        color: palette.ink.withValues(alpha: 0.2),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: DecoratedBox(
              key: const ValueKey('tutorial-card'),
              decoration: BoxDecoration(color: palette.card, borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Puzzle 1 · ${_tutorialStep + 1} of ${_tutorial.length}', style: TextStyle(color: palette.accent, fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 8),
                    Text(step.$1, style: TextStyle(color: palette.ink, fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(step.$2, style: TextStyle(color: palette.muted, height: 1.35)),
                    const SizedBox(height: 14),
                    SoftButton(
                      label: last ? 'Start' : 'Next',
                      primary: true,
                      onPressed: () async {
                        if (!last) {
                          setState(() => _tutorialStep++);
                          return;
                        }
                        await widget.progress.update(widget.progress.data.copyWith(tutorialSeen: true));
                        if (mounted) setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _winCard(CatPalette palette) {
    final request = widget.request;
    final elapsed = _session.elapsedMilliseconds;
    final best = request.daily
        ? widget.progress.data.dailyBestMs[isoDate(DateTime.now())]
        : widget.progress.data.bestMs[request.level.id];
    final streak = request.daily ? widget.progress.data.visibleStreak(DateTime.now()) : null;
    return Positioned.fill(
      child: ColoredBox(
        color: palette.ink.withValues(alpha: 0.28),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.92, end: 1),
            duration: const Duration(milliseconds: 220),
            builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
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
      ),
    );
  }
}

class _FlamePainter extends CustomPainter {
  _FlamePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.05)
      ..quadraticBezierTo(size.width * 0.95, size.height * 0.45, size.width * 0.72, size.height * 0.78)
      ..quadraticBezierTo(size.width * 0.5, size.height * 1.05, size.width * 0.28, size.height * 0.78)
      ..quadraticBezierTo(size.width * 0.05, size.height * 0.45, size.width * 0.5, size.height * 0.05)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FlamePainter oldDelegate) => oldDelegate.color != color;
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
