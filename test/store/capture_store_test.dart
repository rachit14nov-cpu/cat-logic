import 'dart:io';
import 'dart:ui' as ui;

import 'package:cat_logic/core/catalog.dart';
import 'package:cat_logic/core/deduction.dart';
import 'package:cat_logic/core/explain.dart';
import 'package:cat_logic/core/puzzle.dart';
import 'package:cat_logic/core/solver.dart';
import 'package:cat_logic/ui/board_view.dart';
import 'package:cat_logic/ui/chrome.dart';
import 'package:cat_logic/ui/glyphs.dart';
import 'package:cat_logic/ui/palettes.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

late CatPalette meadow;
late CatPalette beacon;
late Puzzle five;
late Puzzle seven;
late Puzzle ten;
late Puzzle daily;
late List<CellMark> sevenMarks;
late List<CellMark> fiveMarks;
late List<CellMark> tenMarks;
late List<CellMark> dailyMarks;
late LogicStep step;
late List<String> regionNames;

Future<void> capture(WidgetTester tester, Size size, Widget child, String path) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: OverflowBox(
          minWidth: size.width,
          maxWidth: size.width,
          minHeight: size.height,
          maxHeight: size.height,
          child: MediaQuery(
            data: MediaQueryData(size: size),
            child: DefaultTextStyle(
              style: const TextStyle(decoration: TextDecoration.none, fontFamily: 'Inter', color: Color(0xFF3E342C)),
              child: RepaintBoundary(
                key: const ValueKey('store-frame'),
                child: SizedBox.fromSize(size: size, child: child),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('store-frame')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    File(path).parent.createSync(recursive: true);
    File(path).writeAsBytesSync(data!.buffer.asUint8List());
  });
}

Widget phone({required String caption, String? sub, required Widget scene}) {
  return ColoredBox(
    color: meadow.paper,
    child: Column(
      children: [
        SizedBox(
          height: 384,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 86),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(caption, style: TextStyle(fontFamily: 'Inter', fontSize: 68, fontWeight: FontWeight.w700, color: meadow.ink)),
                ),
                if (sub != null) ...[
                  const SizedBox(height: 12),
                  Text(sub, style: TextStyle(fontFamily: 'Inter', fontSize: 32, color: meadow.muted)),
                ],
              ],
            ),
          ),
        ),
        Expanded(child: scene),
      ],
    ),
  );
}

Widget board(
  Puzzle puzzle,
  List<CellMark> marks, {
  Set<int> focus = const {},
  Set<int> emphasis = const {},
  Set<int> dim = const {},
  bool patterns = false,
  CatPalette? palette,
}) {
  final theme = palette ?? meadow;
  return CatTheme(
    palette: theme,
    patterns: patterns || theme.colorBlindSafe,
    child: BoardView(
      puzzle: puzzle,
      marks: marks,
      palette: theme,
      patterns: patterns || theme.colorBlindSafe,
      focus: focus,
      emphasis: emphasis,
      dim: dim,
      onTap: (_) {},
      onDoubleTap: (_) {},
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final loader = FontLoader('Inter');
    for (final file in ['Inter-Regular.ttf', 'Inter-SemiBold.ttf', 'Inter-Bold.ttf']) {
      final bytes = File('assets/fonts/$file').readAsBytesSync();
      loader.addFont(Future<ByteData>.value(ByteData.sublistView(Uint8List.fromList(bytes))));
    }
    await loader.load();
    final catalog = LevelCatalog.fromPacked(
      gzip.decode(File('assets/levels/campaign.bin.gz').readAsBytesSync()),
      gzip.decode(File('assets/levels/daily.bin.gz').readAsBytesSync()),
    );
    meadow = CatPalettes.resolve('meadow', Brightness.light);
    beacon = CatPalettes.resolve('beacon', Brightness.light);
    Puzzle sized(int size) => catalog.campaign.firstWhere((level) => level.size == size).toPuzzle();
    five = sized(5);
    seven = sized(7);
    ten = sized(10);
    daily = catalog.daily.first.toPuzzle();
    List<CellMark> placed(Puzzle puzzle, int count) {
      final cats = Solver.solutions(puzzle, limit: 1).single;
      final marks = List<CellMark>.filled(puzzle.cellCount, CellMark.empty);
      for (var row = 0; row < count && row < cats.length; row++) {
        marks[row * puzzle.size + cats[row]] = CellMark.cat;
      }
      return withAutoMarks(puzzle, marks, enabled: true);
    }

    sevenMarks = placed(seven, 3);
    fiveMarks = placed(five, 2);
    tenMarks = placed(ten, 4);
    dailyMarks = placed(daily, 2);
    step = nextDeduction(seven, List<int>.filled(seven.cellCount, 0))!;
    regionNames = [for (final look in meadow.looks) look.name];
  });

  testWidgets('01 fair ads', (tester) async {
    await capture(
      tester,
      const Size(1080, 1920),
      phone(
        caption: 'Fair ads. Never mid-puzzle.',
        scene: Stack(
          children: [
            Padding(padding: const EdgeInsets.fromLTRB(60, 0, 60, 96), child: board(seven, sevenMarks)),
            Positioned(right: 60, bottom: 96, child: _Badge(text: 'No ads mid-puzzle', palette: meadow)),
          ],
        ),
      ),
      'store/phone/01-fair-ads.png',
    );
  });

  testWidgets('02 one cat per row', (tester) async {
    final row = {for (var column = 0; column < 5; column++) column};
    await capture(
      tester,
      const Size(1080, 1920),
      phone(
        caption: 'One cat per row',
        scene: Stack(
          children: [
            Padding(padding: const EdgeInsets.fromLTRB(60, 0, 60, 160), child: board(five, placedOne(five), emphasis: row)),
            Positioned(
              left: 60,
              right: 60,
              bottom: 96,
              child: _Badge(text: 'Also one per column and region. No touching, even diagonally.', palette: meadow),
            ),
          ],
        ),
      ),
      'store/phone/02-one-cat-per-row.png',
    );
  });

  testWidgets('03 pure logic', (tester) async {
    await capture(
      tester,
      const Size(1080, 1920),
      phone(
        caption: 'Pure logic, no guessing',
        sub: 'Every puzzle has one solution',
        scene: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(60, 0, 60, 180),
              child: board(seven, _catIn(seven, step.focusCells.isEmpty ? step.resultCells : step.focusCells)),
            ),
            const Positioned(
              left: 60,
              right: 60,
              bottom: 96,
              child: _Callout(text: 'Only one cell, so the cat goes here'),
            ),
          ],
        ),
      ),
      'store/phone/03-pure-logic.png',
    );
  });

  testWidgets('04 hints', (tester) async {
    final puzzle = Puzzle(5, const [
      1, 1, 0, 2, 2, //
      1, 1, 0, 2, 2, //
      1, 3, 0, 2, 2, //
      3, 3, 3, 4, 4, //
      3, 3, 4, 4, 4,
    ]);
    final hint = LogicState(puzzle).next(allowContradiction: false)!;
    await capture(
      tester,
      const Size(1080, 1920),
      phone(
        caption: 'Hints that explain why',
        scene: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(60, 0, 60, 12),
                child: board(
                  puzzle,
                  List<CellMark>.filled(puzzle.cellCount, CellMark.empty),
                  focus: hint.focusCells.toSet(),
                  dim: hint.resultCells.toSet(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(60, 0, 60, 96),
              child: DecoratedBox(
                decoration: BoxDecoration(color: meadow.card, borderRadius: BorderRadius.circular(28), border: Border.all(color: meadow.line)),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hint', style: TextStyle(fontFamily: 'Inter', color: meadow.accent, fontWeight: FontWeight.w700, fontSize: 22)),
                      const SizedBox(height: 8),
                      Text(explainStep(hint, regionNames), style: TextStyle(fontFamily: 'Inter', fontSize: 32, height: 1.3, color: meadow.ink)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      'store/phone/04-hints.png',
    );
  });

  testWidgets('05 daily', (tester) async {
    await capture(
      tester,
      const Size(1080, 1920),
      phone(
        caption: 'A new puzzle daily',
        scene: Padding(
          padding: const EdgeInsets.fromLTRB(60, 0, 60, 96),
          child: Column(
            children: [
              const Text("Today's puzzle", style: TextStyle(fontFamily: 'Inter', fontSize: 36, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _CalendarStrip(palette: meadow),
              const SizedBox(height: 12),
              const _StreakLine(),
              const SizedBox(height: 16),
              Expanded(child: board(daily, dailyMarks)),
            ],
          ),
        ),
      ),
      'store/phone/05-daily.png',
    );
  });

  testWidgets('06 sizes', (tester) async {
    await capture(
      tester,
      const Size(1080, 1920),
      phone(
        caption: '500+ puzzles, 5x5 to 10x10',
        scene: Padding(
          padding: const EdgeInsets.fromLTRB(60, 0, 60, 96),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: const Offset(-180, 40),
                child: Transform.rotate(angle: -0.16, child: SizedBox(width: 640, height: 640, child: board(five, fiveMarks))),
              ),
              Transform.translate(
                offset: const Offset(20, -20),
                child: Transform.rotate(angle: 0.02, child: SizedBox(width: 720, height: 720, child: board(seven, sevenMarks))),
              ),
              Transform.translate(
                offset: const Offset(200, 30),
                child: Transform.rotate(angle: 0.14, child: SizedBox(width: 820, height: 820, child: board(ten, tenMarks))),
              ),
            ],
          ),
        ),
      ),
      'store/phone/06-sizes.png',
    );
  });

  testWidgets('07 color blind', (tester) async {
    await capture(
      tester,
      const Size(1080, 1920),
      phone(
        caption: 'Color-blind friendly mode',
        scene: Padding(
          padding: const EdgeInsets.fromLTRB(60, 0, 60, 96),
          child: Row(
            children: [
              Expanded(child: _LabeledBoard(label: 'Standard', child: board(five, fiveMarks))),
              const SizedBox(width: 24),
              Expanded(child: _LabeledBoard(label: 'Color-blind', child: board(five, fiveMarks, patterns: true, palette: beacon))),
            ],
          ),
        ),
      ),
      'store/phone/07-color-blind.png',
    );
  });

  testWidgets('08 offline', (tester) async {
    await capture(
      tester,
      const Size(1080, 1920),
      phone(
        caption: 'Play offline, anywhere',
        scene: const Padding(
          padding: EdgeInsets.fromLTRB(60, 0, 60, 96),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 680, height: 680, child: CustomPaint(painter: _IconPainter())),
              SizedBox(height: 28),
              _OfflineChip(),
            ],
          ),
        ),
      ),
      'store/phone/08-offline.png',
    );
  });

  testWidgets('feature graphic and icon', (tester) async {
    await capture(tester, const Size(1024, 500), const _FeatureGraphic(), 'store/feature-graphic.png');
  });

  testWidgets('icon 512', (tester) async {
    await capture(tester, const Size(512, 512), const CustomPaint(painter: _IconPainter()), 'store/icon-512.png');
    File('android/app/src/main/res/drawable/ic_launcher_art.png').writeAsBytesSync(File('store/icon-512.png').readAsBytesSync());
  });

  for (final size in [48, 72, 96, 144, 192]) {
    final folder = switch (size) {
      48 => 'mipmap-mdpi',
      72 => 'mipmap-hdpi',
      96 => 'mipmap-xhdpi',
      144 => 'mipmap-xxhdpi',
      _ => 'mipmap-xxxhdpi',
    };
    testWidgets('android icon $size', (tester) async {
      await capture(tester, Size.square(size.toDouble()), const CustomPaint(painter: _IconPainter()), 'android/app/src/main/res/$folder/ic_launcher.png');
    });
  }

  final iosIcons = Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset').listSync().whereType<File>().where((file) => file.path.endsWith('.png'));
  for (final file in iosIcons) {
    testWidgets('ios icon ${file.uri.pathSegments.last}', (tester) async {
      final width = ByteData.sublistView(file.readAsBytesSync()).getUint32(16);
      await capture(tester, Size.square(width.toDouble()), const CustomPaint(painter: _IconPainter()), file.path);
    });
  }
}

List<CellMark> _catIn(Puzzle puzzle, List<int> cells) {
  final marks = List<CellMark>.filled(puzzle.cellCount, CellMark.empty);
  if (cells.isNotEmpty) marks[cells.first] = CellMark.cat;
  return withAutoMarks(puzzle, marks, enabled: true);
}

List<CellMark> placedOne(Puzzle puzzle) {
  final cats = Solver.solutions(puzzle, limit: 1).single;
  final marks = List<CellMark>.filled(puzzle.cellCount, CellMark.empty);
  marks[cats[0]] = CellMark.cat;
  return withAutoMarks(puzzle, marks, enabled: true);
}

class _Callout extends StatelessWidget {
  const _Callout({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: const Color(0xFF3E342C), borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Inter', fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFFF6F1E8))),
      ),
    );
  }
}

class _StreakLine extends StatelessWidget {
  const _StreakLine();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CustomPaint(size: Size.square(28), painter: _FlamePainter(color: Color(0xFFC4623A))),
        SizedBox(width: 10),
        Text('3-day streak', style: TextStyle(fontFamily: 'Inter', fontSize: 32, fontWeight: FontWeight.w700, color: Color(0xFF3E342C))),
      ],
    );
  }
}

class _OfflineChip extends StatelessWidget {
  const _OfflineChip();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4D8C8), width: 2),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        child: Text('Offline', style: TextStyle(fontFamily: 'Inter', fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF3E342C))),
      ),
    );
  }
}

class _FlamePainter extends CustomPainter {
  const _FlamePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.5, 0)
      ..quadraticBezierTo(size.width, size.height * 0.45, size.width * 0.72, size.height * 0.78)
      ..quadraticBezierTo(size.width * 0.5, size.height, size.width * 0.28, size.height * 0.78)
      ..quadraticBezierTo(0, size.height * 0.45, size.width * 0.5, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _FlamePainter oldDelegate) => oldDelegate.color != color;
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.palette});

  final String text;
  final CatPalette palette;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: palette.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: palette.line, width: 2)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        child: Text(text, style: TextStyle(fontFamily: 'Inter', fontSize: 28, fontWeight: FontWeight.w700, color: palette.ink)),
      ),
    );
  }
}

class _CalendarStrip extends StatelessWidget {
  const _CalendarStrip({required this.palette});

  final CatPalette palette;

  @override
  Widget build(BuildContext context) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      children: [
        for (var index = 0; index < days.length; index++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: index == 4 ? palette.accent : palette.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: palette.line),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    days[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: index == 4 ? palette.card : palette.ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
    );
  }
}

class _LabeledBoard extends StatelessWidget {
  const _LabeledBoard({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 28, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Expanded(child: child),
      ],
    );
  }
}

class _FeatureGraphic extends StatelessWidget {
  const _FeatureGraphic();

  @override
  Widget build(BuildContext context) {
    const cream = Color(0xFFF6F1E8);
    const ink = Color(0xFF3E342C);
    const sage = Color(0xFF8FB58A);
    return ColoredBox(
      color: cream,
      child: Stack(
        children: [
          Positioned(
            left: 560,
            top: 80,
            child: Transform.rotate(
              angle: -0.18,
              child: Container(
                width: 400,
                height: 320,
                decoration: BoxDecoration(color: sage, borderRadius: BorderRadius.circular(36)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    _MiniCat(coat: Color(0xFFC4623A)),
                    _MiniCat(coat: Color(0xFF8EB7D6)),
                    _MiniCat(coat: Color(0xFFE6D48A)),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            left: 86,
            top: 170,
            child: Text(
              'Cat Logic',
              style: TextStyle(fontFamily: 'Inter', fontSize: 72, fontWeight: FontWeight.w700, color: ink, decoration: TextDecoration.none),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCat extends StatelessWidget {
  const _MiniCat({required this.coat});

  final Color coat;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size.square(120),
      painter: _MiniCatPainter(coat),
    );
  }
}

class _MiniCatPainter extends CustomPainter {
  _MiniCatPainter(this.coat);

  final Color coat;

  @override
  void paint(Canvas canvas, Size size) {
    paintCurledCat(canvas, Offset.zero & size, coat: coat, ink: const Color(0xFF3E342C), cushion: const Color(0xFFE7D3BE));
  }

  @override
  bool shouldRepaint(covariant _MiniCatPainter oldDelegate) => oldDelegate.coat != coat;
}

class _IconPainter extends CustomPainter {
  const _IconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF8FB58A));
    paintCurledCat(
      canvas,
      Rect.fromLTWH(size.width * 0.1, size.height * 0.08, size.width * 0.8, size.height * 0.8),
      coat: const Color(0xFFC4623A),
      ink: const Color(0xFF3E342C),
      cushion: const Color(0xFFE7D3BE),
    );
    paintSparkle(canvas, Offset(size.width * 0.78, size.height * 0.16), size.width * 0.07, const Color(0xFFF6F1E8));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
