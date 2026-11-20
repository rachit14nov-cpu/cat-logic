import 'package:cat_logic/core/puzzle.dart';
import 'package:cat_logic/data/progress.dart';
import 'package:cat_logic/data/progress_store.dart';
import 'package:cat_logic/services/app_services.dart';
import 'package:cat_logic/ui/chrome.dart';
import 'package:cat_logic/ui/palettes.dart';
import 'package:cat_logic/ui/screens/game_screen.dart';
import 'package:cat_logic/core/ad_pacing.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a hint explains a confined region instead of only naming a cell', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final level = Level(
      id: 'sample',
      size: 5,
      difficulty: Difficulty.gentle,
      regions: const [
        1, 1, 0, 2, 2, //
        1, 1, 0, 2, 2, //
        1, 3, 0, 2, 2, //
        3, 3, 3, 4, 4, //
        3, 3, 4, 4, 4,
      ],
    );
    final progress = ProgressController(MemoryProgressStore(), ProgressData.initial());
    await tester.pumpWidget(
      _host(
        GameScreen(
          request: PlayRequest(level: level, number: 1, daily: false),
          progress: progress,
          services: AppServices.noop(DefaultRemoteConfig()),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('hint-button')));
    await tester.pump();
    expect(find.byKey(const ValueKey('hint-sheet')), findsOneWidget);
    expect(
      find.text("The orange region only fits in column 3, so the other cells in column 3 can't hold a cat."),
      findsOneWidget,
    );
    expect(find.textContaining('Place a cat at'), findsNothing);
  });

  testWidgets('using a hint still lets the daily streak grow', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final level = Level(
      id: 'daily-sample',
      size: 4,
      difficulty: Difficulty.gentle,
      regions: List<int>.generate(16, (index) => index % 4),
    );
    final store = MemoryProgressStore();
    final progress = ProgressController(
      store,
      const ProgressData(
        completed: {},
        bestMs: {},
        autoMark: true,
        paletteId: 'meadow',
        themeMode: 'light',
        patternsAlways: false,
        dailyStreak: 4,
        lastDailyDate: '2026-11-19',
        dailyBestMs: {},
      ),
    );
    await tester.pumpWidget(
      _host(
        GameScreen(
          request: PlayRequest(level: level, number: 0, daily: true),
          progress: progress,
          services: AppServices.noop(DefaultRemoteConfig()),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('hint-button')));
    await tester.pump();
    expect(find.byKey(const ValueKey('hint-sheet')), findsOneWidget);
    expect(progress.data.dailyStreak, 4, reason: 'a hint must not touch the streak');
    expect(progress.data.lastDailyDate, '2026-11-19');

    await progress.update(progress.data.completeDaily(DateTime(2026, 11, 20), 12000));
    expect(progress.data.dailyStreak, 5);
    expect(progress.data.lastDailyDate, '2026-11-20');
  });
}

Widget _host(Widget child) {
  final palette = CatPalettes.resolve('meadow', Brightness.light);
  return CatTheme(
    palette: palette,
    patterns: false,
    child: WidgetsApp(
      color: const Color(0xFFC4623A),
      onGenerateRoute: (settings) {
        return PageRouteBuilder<void>(
          settings: settings,
          pageBuilder: (context, animation, secondary) => child,
        );
      },
    ),
  );
}
