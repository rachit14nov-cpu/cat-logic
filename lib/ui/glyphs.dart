import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'palettes.dart';

void paintCat(Canvas canvas, Rect rect, Color coat, Color ink) {
  paintCurledCat(canvas, rect, coat: coat, ink: ink, cushion: Color.lerp(coat, const Color(0xFFF6F1E8), 0.62)!);
}

/// A whole-body sleeping cat on a cushion. Used for the store icon and feature art.
void paintCurledCat(Canvas canvas, Rect rect, {required Color coat, required Color ink, required Color cushion}) {
  final pad = Paint()..color = cushion;
  final body = Paint()..color = coat;
  final cushionRect = Rect.fromCenter(
    center: rect.center.translate(0, rect.height * 0.22),
    width: rect.width * 0.78,
    height: rect.height * 0.28,
  );
  canvas.drawRRect(RRect.fromRectAndRadius(cushionRect, Radius.circular(rect.width * 0.14)), pad);
  canvas.drawOval(
    Rect.fromCenter(center: rect.center.translate(-rect.width * 0.02, rect.height * 0.04), width: rect.width * 0.62, height: rect.height * 0.4),
    body,
  );
  final head = rect.center.translate(rect.width * 0.16, -rect.height * 0.08);
  canvas.drawCircle(head, rect.width * 0.2, body);
  final ear = Path()
    ..moveTo(head.dx - rect.width * 0.14, head.dy - rect.width * 0.02)
    ..lineTo(head.dx - rect.width * 0.18, head.dy - rect.width * 0.32)
    ..lineTo(head.dx - rect.width * 0.01, head.dy - rect.width * 0.1)
    ..close()
    ..moveTo(head.dx + rect.width * 0.02, head.dy - rect.width * 0.12)
    ..lineTo(head.dx + rect.width * 0.08, head.dy - rect.width * 0.36)
    ..lineTo(head.dx + rect.width * 0.2, head.dy - rect.width * 0.04)
    ..close();
  canvas.drawPath(ear, body);
  canvas.drawArc(
    Rect.fromCircle(center: rect.center.translate(-rect.width * 0.22, rect.height * 0.02), radius: rect.width * 0.16),
    1.2,
    2.4,
    false,
    Paint()
      ..color = coat
      ..style = PaintingStyle.stroke
      ..strokeWidth = rect.width * 0.09
      ..strokeCap = StrokeCap.round,
  );
  final eye = Paint()
    ..color = ink
    ..strokeWidth = rect.width * 0.028
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  canvas.drawArc(Rect.fromCenter(center: head.translate(-rect.width * 0.07, rect.width * 0.02), width: rect.width * 0.08, height: rect.width * 0.05), 0.2, 2.6, false, eye);
  canvas.drawArc(Rect.fromCenter(center: head.translate(rect.width * 0.07, rect.width * 0.02), width: rect.width * 0.08, height: rect.width * 0.05), 0.3, 2.6, false, eye);
  canvas.drawCircle(head.translate(0, rect.width * 0.08), rect.width * 0.018, Paint()..color = ink);
  }

void paintSparkle(Canvas canvas, Offset center, double radius, Color color) {
  final paint = Paint()
    ..color = color
    ..strokeWidth = radius * 0.22
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(center.translate(0, -radius), center.translate(0, radius), paint);
  canvas.drawLine(center.translate(-radius, 0), center.translate(radius, 0), paint);
  canvas.drawLine(center.translate(-radius * 0.55, -radius * 0.55), center.translate(radius * 0.55, radius * 0.55), paint);
  canvas.drawLine(center.translate(radius * 0.55, -radius * 0.55), center.translate(-radius * 0.55, radius * 0.55), paint);
}

void paintMark(Canvas canvas, Rect rect, Color color, {bool soft = false}) {
  final inset = rect.deflate(rect.width * 0.30);
  final paint = Paint()
    ..color = soft ? color.withValues(alpha: 0.45) : color
    ..strokeWidth = rect.width * (soft ? 0.055 : 0.075)
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  canvas.drawLine(inset.topLeft, inset.bottomRight, paint);
  canvas.drawLine(inset.topRight, inset.bottomLeft, paint);
}

void paintPattern(Canvas canvas, Rect rect, RegionPattern pattern, Color color) {
  final paint = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(1, rect.width * 0.035)
    ..strokeCap = StrokeCap.round;
  final fill = Paint()
    ..color = color
    ..style = PaintingStyle.fill;
  switch (pattern) {
    case RegionPattern.dots:
      final step = rect.width / 3.2;
      for (var y = rect.top + step; y < rect.bottom; y += step) {
        for (var x = rect.left + step; x < rect.right; x += step) {
          canvas.drawCircle(Offset(x, y), rect.width * 0.035, fill);
        }
      }
    case RegionPattern.stripes:
      final step = rect.height / 4;
      for (var y = rect.top + step * 0.7; y < rect.bottom; y += step) {
        canvas.drawLine(Offset(rect.left + 4, y), Offset(rect.right - 4, y), paint);
      }
    case RegionPattern.waves:
      final path = Path();
      final mid = rect.center.dy;
      path.moveTo(rect.left + 3, mid);
      path.cubicTo(rect.left + rect.width * 0.3, mid - rect.height * 0.18, rect.left + rect.width * 0.7, mid + rect.height * 0.18, rect.right - 3, mid);
      canvas.drawPath(path, paint);
    case RegionPattern.crosshatch:
      canvas.drawLine(rect.topLeft.translate(6, 6), rect.bottomRight.translate(-6, -6), paint);
      canvas.drawLine(rect.topRight.translate(-6, 6), rect.bottomLeft.translate(6, -6), paint);
    case RegionPattern.rings:
      canvas.drawCircle(rect.center, rect.width * 0.18, paint);
    case RegionPattern.diagonal:
      final step = rect.width / 3;
      for (var i = -2; i < 5; i++) {
        final start = Offset(rect.left + i * step, rect.top + 4);
        canvas.drawLine(start, start.translate(rect.width * 0.45, rect.height * 0.7), paint);
      }
    case RegionPattern.plus:
      final arm = rect.width * 0.12;
      canvas.drawLine(rect.center.translate(-arm, 0), rect.center.translate(arm, 0), paint);
      canvas.drawLine(rect.center.translate(0, -arm), rect.center.translate(0, arm), paint);
    case RegionPattern.specks:
      final spots = [
        const Offset(0.3, 0.32),
        const Offset(0.62, 0.28),
        const Offset(0.48, 0.58),
        const Offset(0.72, 0.66),
      ];
      for (final spot in spots) {
        canvas.drawCircle(rect.topLeft + Offset(rect.width * spot.dx, rect.height * spot.dy), rect.width * 0.03, fill);
      }
    case RegionPattern.grid:
      canvas.drawLine(Offset(rect.center.dx, rect.top + 5), Offset(rect.center.dx, rect.bottom - 5), paint);
      canvas.drawLine(Offset(rect.left + 5, rect.center.dy), Offset(rect.right - 5, rect.center.dy), paint);
    case RegionPattern.dashes:
      final y = rect.center.dy;
      final dash = rect.width * 0.16;
      final gap = rect.width * 0.08;
      var x = rect.left + 6.0;
      while (x + dash < rect.right - 4) {
        canvas.drawLine(Offset(x, y), Offset(x + dash, y), paint);
        x += dash + gap;
      }
  }
}

void paintLock(Canvas canvas, Rect rect, Color color) {
  final fill = Paint()..color = color;
  final stroke = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(1.6, rect.width * 0.1)
    ..strokeCap = StrokeCap.round;
  final body = Rect.fromCenter(
    center: rect.center.translate(0, rect.height * 0.16),
    width: rect.width * 0.62,
    height: rect.height * 0.42,
  );
  canvas.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(rect.width * 0.1)), fill);
  canvas.drawArc(
    Rect.fromCenter(center: body.topCenter, width: rect.width * 0.36, height: rect.height * 0.42),
    math.pi,
    math.pi,
    false,
    stroke,
  );
}

void paintCheck(Canvas canvas, Rect rect, Color color) {
  final paint = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(1.6, rect.width * 0.12)
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final path = Path()
    ..moveTo(rect.left + rect.width * 0.22, rect.top + rect.height * 0.52)
    ..lineTo(rect.left + rect.width * 0.42, rect.top + rect.height * 0.72)
    ..lineTo(rect.left + rect.width * 0.78, rect.top + rect.height * 0.30);
  canvas.drawPath(path, paint);
}

void paintChevron(Canvas canvas, Rect rect, Color color, {bool forward = false}) {
  final paint = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(1.8, rect.width * 0.12)
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final path = Path();
  if (forward) {
    path
      ..moveTo(rect.left + rect.width * 0.38, rect.top + rect.height * 0.22)
      ..lineTo(rect.left + rect.width * 0.66, rect.center.dy)
      ..lineTo(rect.left + rect.width * 0.38, rect.top + rect.height * 0.78);
  } else {
    path
      ..moveTo(rect.left + rect.width * 0.62, rect.top + rect.height * 0.22)
      ..lineTo(rect.left + rect.width * 0.34, rect.center.dy)
      ..lineTo(rect.left + rect.width * 0.62, rect.top + rect.height * 0.78);
  }
  canvas.drawPath(path, paint);
}

class CatMark extends StatelessWidget {
  const CatMark({required this.size, required this.coat, required this.ink, super.key});

  final double size;
  final Color coat;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _MarkPainter(coat, ink),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.coat, this.ink);

  final Color coat;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    paintCat(canvas, Offset.zero & size, coat, ink);
  }

  @override
  bool shouldRepaint(covariant _MarkPainter oldDelegate) => oldDelegate.coat != coat || oldDelegate.ink != ink;
}
