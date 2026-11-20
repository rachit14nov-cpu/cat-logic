import 'dart:io';
import 'dart:typed_data';

import 'package:cat_logic/app.dart';
import 'package:cat_logic/core/ad_pacing.dart';
import 'package:cat_logic/core/catalog.dart';
import 'package:cat_logic/core/solver.dart';
import 'package:cat_logic/data/progress.dart';
import 'package:cat_logic/data/progress_store.dart';
import 'package:cat_logic/services/app_services.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture board, hint sheet, and level select', (tester) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    stderr.writeln('SHOT start');
    final loader = FontLoader('Inter');
    for (final file in ['Inter-Regular.ttf', 'Inter-SemiBold.ttf', 'Inter-Bold.ttf']) {
      final bytes = File('assets/fonts/$file').readAsBytesSync();
      loader.addFont(Future<ByteData>.value(ByteData.sublistView(Uint8List.fromList(bytes))));
    }
    await loader.load();
    final catalog = LevelCatalog.fromJson(
      File('assets/levels/levels.json').readAsStringSync(),
      File('assets/levels/daily.json').readAsStringSync(),
    );
    final completed = {for (final level in catalog.campaign.take(3)) level.id};
    final services = AppServices.noop(DefaultRemoteConfig());

    Future<void> shoot(String name, ProgressData data, Future<void> Function() play) async {
      stderr.writeln('SHOT $name');
      final progress = ProgressController(MemoryProgressStore(), data);
      await tester.pumpWidget(
        CatLogicApp(key: ValueKey(name), progress: progress, catalog: catalog, services: services),
      );
      await tester.pump();
      await play();
      await tester.pump(const Duration(milliseconds: 50));
      final exception = tester.takeException();
      if (exception != null) stderr.writeln('SHOT exception $exception');
      await expectLater(find.byKey(const ValueKey('shot-root')).last, matchesGoldenFile('../../screenshots/$name.png'));
    }

    final light = ProgressData.initial().copyWith(themeMode: 'light', completed: completed);
    final dark = light.copyWith(themeMode: 'dark');
    final beacon = light.copyWith(paletteId: 'beacon', patternsAlways: true);

    await shoot('level_select_light', light, () async {
      await tester.tap(find.byKey(const ValueKey('play-button')));
      await tester.pump(const Duration(milliseconds: 300));
    });
    await shoot('level_select_dark', dark, () async {
      await tester.tap(find.byKey(const ValueKey('play-button')));
      await tester.pump(const Duration(milliseconds: 300));
    });
    await shoot('level_select_beacon', beacon, () async {
      await tester.tap(find.byKey(const ValueKey('play-button')));
      await tester.pump(const Duration(milliseconds: 300));
    });

    Future<void> openBoard(ProgressData data, String name, {bool hint = false}) async {
      await shoot(name, data, () async {
        await tester.tap(find.byKey(const ValueKey('play-button')));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.byKey(const ValueKey('level-1')));
        await tester.pump(const Duration(milliseconds: 300));
        final solution = Solver.solutions(catalog.campaign.first.toPuzzle(), limit: 1).single;
        final key = ValueKey('cell-0-${solution[0]}');
        await tester.tap(find.byKey(key));
        await tester.pump(const Duration(milliseconds: 40));
        await tester.tap(find.byKey(key));
        await tester.pump(const Duration(milliseconds: 50));
        if (hint) {
          await tester.tap(find.byKey(const ValueKey('hint-button')));
          await tester.pump(const Duration(milliseconds: 50));
        }
      });
    }

    await openBoard(light, 'board_light');
    await openBoard(dark, 'board_dark');
    await openBoard(beacon, 'board_beacon');
    await openBoard(light, 'hint_light', hint: true);
    await openBoard(dark, 'hint_dark', hint: true);
    await openBoard(beacon, 'hint_beacon', hint: true);
  }, timeout: const Timeout(Duration(seconds: 90)));
}
