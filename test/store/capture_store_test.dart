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

Widget board(Puzzle puzzle, List<CellMark> marks, {Set<int> focus = const {}, Set<int> emphasis = const {}, bool patterns = false, CatPalette? palette}) {
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
            Padding(padding: const EdgeInsets.fromLTRB(48, 12, 48, 48), child: board(seven, sevenMarks)),
            Positioned(right: 72, bottom: 72, child: _Badge(text: 'No ads during play', palette: meadow)),
          ],
        ),
      ),
      'store/phone/01-fair-ads.png',
    );
  });

  testWidgets('02 one cat per row', (tester) async {
    final row = {for (var column = 0; column < 5; column++) column};
    final column = {for (var rowIndex = 0; rowIndex < 5; rowIndex++) rowIndex * 5 + 2};
    final regionId = five.regions[0];
    final region = {for (var index = 0; index < five.cellCount; index++) if (five.regions[index] == regionId) index};
    await capture(
      tester,
      const Size(1080, 1920),
      phone(
        caption: 'One cat per row',
        scene: Stack(
          children: [
            Padding(padding: const EdgeInsets.fromLTRB(72, 24, 72, 160), child: board(five, placedOne(five), emphasis: row, focus: {...column, ...region})),
            Positioned(left: 72, right: 72, bottom: 48, child: _Badge(text: 'No touching, even diagonally', palette: meadow)),
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
        scene: Padding(
          padding: const EdgeInsets.fromLTRB(48, 12, 48, 48),
          child: board(seven, List<CellMark>.filled(seven.cellCount, CellMark.empty), focus: step.focusCells.toSet(), emphasis: step.resultCells.toSet()),
        ),
      ),
      'store/phone/03-pure-logic.png',
    );
  });

  testWidgets('04 hints', (tester) async {
    await capture(
      tester,
      const Size(1080, 1920),
      phone(
        caption: 'Hints that explain why',
        scene: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(48, 8, 48, 8),
                child: board(seven, List<CellMark>.filled(seven.cellCount, CellMark.empty), focus: step.focusCells.toSet(), emphasis: step.resultCells.toSet()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(36, 0, 36, 36),
              child: DecoratedBox(
                decoration: BoxDecoration(color: meadow.card, borderRadius: BorderRadius.circular(28), border: Border.all(color: meadow.line)),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Text(explainStep(step, regionNames), style: TextStyle(fontFamily: 'Inter', fontSize: 32, height: 1.3, color: meadow.ink)),
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
          padding: const EdgeInsets.fromLTRB(48, 8, 48, 36),
          child: Column(
            children: [
              _CalendarStrip(palette: meadow),
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
        scene: Stack(
          alignment: Alignment.center,
          children: [
            _LevelFanBackground(palette: meadow),
            Padding(
              padding: const EdgeInsets.only(top: 220),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(width: 240, height: 240, child: board(five, fiveMarks)),
                  const SizedBox(width: 18),
                  SizedBox(width: 300, height: 300, child: board(seven, sevenMarks)),
                  const SizedBox(width: 18),
                  SizedBox(width: 360, height: 360, child: board(ten, tenMarks)),
                ],
              ),
            ),
          ],
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
        caption: 'Color-blind friendly modes',
        scene: Padding(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 36),
          child: Row(
            children: [
              Expanded(child: _LabeledBoard(label: 'Meadow', child: board(five, fiveMarks))),
              const SizedBox(width: 16),
              Expanded(child: _LabeledBoard(label: 'Beacon', child: board(five, fiveMarks, patterns: true, palette: beacon))),
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
        caption: 'Offline play, cloud save',
        scene: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 460, height: 460, child: CustomPaint(painter: _IconPainter())),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Badge(text: 'Offline', palette: meadow),
                const SizedBox(width: 16),
                _Badge(text: 'Play Games', palette: meadow),
              ],
            ),
            const SizedBox(height: 28),
            DecoratedBox(
              decoration: BoxDecoration(color: meadow.ink, borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                child: Text('Progress synced', style: TextStyle(fontFamily: 'Inter', fontSize: 32, fontWeight: FontWeight.w600, color: meadow.paper)),
              ),
            ),
          ],
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

List<CellMark> placedOne(Puzzle puzzle) {
  final cats = Solver.solutions(puzzle, limit: 1).single;
  final marks = List<CellMark>.filled(puzzle.cellCount, CellMark.empty);
  marks[cats[0]] = CellMark.cat;
  return withAutoMarks(puzzle, marks, enabled: true);
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
        const SizedBox(width: 8),
        Text('3', style: TextStyle(fontFamily: 'Inter', fontSize: 36, fontWeight: FontWeight.w700, color: palette.accent)),
      ],
    );
  }
}

class _LevelFanBackground extends StatelessWidget {
  const _LevelFanBackground({required this.palette});

  final CatPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Puzzles', style: TextStyle(fontFamily: 'Inter', fontSize: 36, fontWeight: FontWeight.w700, color: palette.ink)),
          Text('5 × 5', style: TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w700, color: palette.muted)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var number = 1; number <= 18; number++)
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: number < 8 ? palette.accent : palette.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: palette.line),
                  ),
                  child: Text(
                    '$number',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w700, color: number < 8 ? palette.card : palette.ink),
                  ),
                ),
            ],
          ),
        ],
      ),
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
            right: 70,
            top: 70,
            child: Transform.rotate(
              angle: -0.18,
              child: Container(
                width: 560,
                height: 340,
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
              style: TextStyle(fontFamily: 'Inter', fontSize: 84, fontWeight: FontWeight.w700, color: ink, decoration: TextDecoration.none),
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
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFF6F1E8));
    final sage = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.16, size.width * 0.8, size.height * 0.7),
      Radius.circular(size.width * 0.16),
    );
    canvas.drawRRect(sage, Paint()..color = const Color(0xFF8FB58A));
    paintCurledCat(
      canvas,
      Rect.fromLTWH(size.width * 0.12, size.height * 0.14, size.width * 0.76, size.height * 0.7),
      coat: const Color(0xFFC4623A),
      ink: const Color(0xFF3E342C),
      cushion: const Color(0xFFE7D3BE),
    );
    paintSparkle(canvas, Offset(size.width * 0.74, size.height * 0.2), size.width * 0.045, const Color(0xFFF6F1E8));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
