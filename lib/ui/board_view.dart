import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../core/puzzle.dart';
import 'glyphs.dart';
import 'palettes.dart';

class BoardMetrics {
  BoardMetrics({required this.side, required this.size});

  final double side;
  final int size;

  double get inset => math.min(28, side * 0.08);

  double get gap => math.max(2.5, (side - inset) * 0.012);

  double get cell => (side - inset - gap * (size + 1)) / size;

  Rect cellRect(int row, int column) {
    return Rect.fromLTWH(
      inset + gap + column * (cell + gap),
      inset + gap + row * (cell + gap),
      cell,
      cell,
    );
  }
}

class BoardView extends StatelessWidget {
  const BoardView({
    required this.puzzle,
    required this.marks,
    required this.palette,
    required this.patterns,
    required this.onTap,
    required this.onDoubleTap,
    this.focus = const {},
    this.emphasis = const {},
    super.key,
  });

  final Puzzle puzzle;
  final List<CellMark> marks;
  final CatPalette palette;
  final bool patterns;
  final void Function(int index) onTap;
  final void Function(int index) onDoubleTap;
  final Set<int> focus;
  final Set<int> emphasis;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth, constraints.maxHeight);
        final metrics = BoardMetrics(side: side, size: puzzle.size);
        return Center(
          child: SizedBox.square(
            dimension: side,
            child: Stack(
              children: [
                CustomPaint(
                  size: Size.square(side),
                  painter: _BoardPainter(
                    puzzle: puzzle,
                    marks: marks,
                    palette: palette,
                    patterns: patterns,
                    focus: focus,
                    emphasis: emphasis,
                    metrics: metrics,
                  ),
                ),
                for (var row = 0; row < puzzle.size; row++)
                  for (var column = 0; column < puzzle.size; column++)
                    _cellTarget(metrics, row, column),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _cellTarget(BoardMetrics metrics, int row, int column) {
    final index = puzzle.index(row, column);
    final rect = metrics.cellRect(row, column);
    final region = palette.looks[puzzle.regionAt(index)].name;
    final state = switch (marks[index]) {
      CellMark.cat => 'cat',
      CellMark.playerX || CellMark.autoX => 'marked off',
      CellMark.empty || CellMark.keepOpen => 'empty',
    };
    return Positioned.fromRect(
      rect: rect,
      child: Semantics(
        button: true,
        label: 'Row ${row + 1}, column ${column + 1}, $region region, $state',
        child: GestureDetector(
          key: ValueKey('cell-$row-$column'),
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap(index),
          onDoubleTap: () => onDoubleTap(index),
        ),
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter({
    required this.puzzle,
    required this.marks,
    required this.palette,
    required this.patterns,
    required this.focus,
    required this.emphasis,
    required this.metrics,
  });

  final Puzzle puzzle;
  final List<CellMark> marks;
  final CatPalette palette;
  final bool patterns;
  final Set<int> focus;
  final Set<int> emphasis;
  final BoardMetrics metrics;

  @override
  void paint(Canvas canvas, Size size) {
    final numberStyle = TextStyle(
      fontFamily: 'Inter',
      color: palette.muted,
      fontSize: math.max(11, metrics.inset * 0.46),
      fontWeight: FontWeight.w600,
    );
    for (var line = 0; line < puzzle.size; line++) {
      _label(canvas, '${line + 1}', Rect.fromLTWH(0, metrics.cellRect(line, 0).top, metrics.inset, metrics.cell), numberStyle);
      _label(canvas, '${line + 1}', Rect.fromLTWH(metrics.cellRect(0, line).left, 0, metrics.cell, metrics.inset), numberStyle);
    }
    for (var index = 0; index < puzzle.cellCount; index++) {
      final rect = metrics.cellRect(puzzle.rowOf(index), puzzle.colOf(index));
      final look = palette.looks[puzzle.regionAt(index)];
      final radius = Radius.circular(math.min(10, rect.width * 0.18));
      final rrect = RRect.fromRectAndRadius(rect, radius);
      canvas.drawRRect(rrect, Paint()..color = look.color);
      if (patterns) {
        canvas.save();
        canvas.clipRRect(rrect);
        final ink = look.color.computeLuminance() > 0.55 ? const Color(0x66000000) : const Color(0x66FFFFFF);
        paintPattern(canvas, rect.deflate(rect.width * 0.08), look.pattern, ink);
        canvas.restore();
      }
      final light = look.color.computeLuminance() > 0.62;
      final markColor = light ? palette.ink : const Color(0xFFF8F4EE);
      final catCoat = light ? palette.ink : const Color(0xFFF8F4EE);
      final catInk = light ? palette.paper : palette.ink;
      switch (marks[index]) {
        case CellMark.cat:
          paintCat(canvas, rect.deflate(rect.width * 0.12), catCoat, catInk);
        case CellMark.playerX:
          paintMark(canvas, rect, markColor);
        case CellMark.autoX:
          paintMark(canvas, rect, markColor, soft: true);
        case CellMark.empty:
        case CellMark.keepOpen:
          break;
      }
      if (focus.contains(index)) {
        canvas.drawRRect(
          rrect,
          Paint()
            ..color = palette.accent.withValues(alpha: 0.9)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
      if (emphasis.contains(index)) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.deflate(1.5), radius),
          Paint()
            ..color = palette.accent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.5,
        );
      }
    }
  }

  void _label(Canvas canvas, String text, Rect rect, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width);
    painter.paint(canvas, rect.center - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) {
    return oldDelegate.marks != marks ||
        oldDelegate.focus != focus ||
        oldDelegate.emphasis != emphasis ||
        oldDelegate.palette != palette ||
        oldDelegate.patterns != patterns;
  }
}
