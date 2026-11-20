import 'package:flutter/widgets.dart';

import 'core/catalog.dart';
import 'data/progress_store.dart';
import 'services/app_services.dart';
import 'ui/chrome.dart';
import 'ui/palettes.dart';
import 'ui/screens/game_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/how_to_play_screen.dart';
import 'ui/screens/level_select_screen.dart';
import 'ui/screens/settings_screen.dart';

class CatLogicApp extends StatelessWidget {
  const CatLogicApp({required this.progress, required this.catalog, required this.services, super.key});

  final ProgressController progress;
  final LevelCatalog catalog;
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: progress,
      builder: (context, _) {
        return WidgetsApp(
          title: 'Cat Logic',
          color: const Color(0xFFC4623A),
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            final platform = View.of(context).platformDispatcher.platformBrightness;
            final mode = progress.data.themeMode;
            final brightness = switch (mode) {
              'light' => Brightness.light,
              'dark' => Brightness.dark,
              _ => platform,
            };
            final palette = CatPalettes.resolve(progress.data.paletteId, brightness);
            final patterns = progress.data.patternsAlways || palette.colorBlindSafe;
            return CatTheme(
              palette: palette,
              patterns: patterns,
              child: DefaultTextStyle(
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: palette.ink,
                  fontSize: 16,
                  decoration: TextDecoration.none,
                ),
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
          onGenerateRoute: _route,
        );
      },
    );
  }

  Route<dynamic> _route(RouteSettings settings) {
    final page = switch (settings.name) {
      '/levels' => LevelSelectScreen(catalog: catalog, progress: progress.data, services: services),
      '/play' => _game(settings.arguments),
      '/settings' => SettingsScreen(progress: progress),
      '/howto' => const HowToPlayScreen(),
      _ => HomeScreen(catalog: catalog, progress: progress.data, services: services),
    };
    return PageRouteBuilder<dynamic>(
      settings: settings,
      pageBuilder: (context, animation, secondary) => page,
      transitionDuration: const Duration(milliseconds: 180),
      transitionsBuilder: (context, animation, secondary, child) => FadeTransition(opacity: animation, child: child),
    );
  }

  Widget _game(Object? arguments) {
    final request = arguments is PlayRequest
        ? arguments
        : PlayRequest(level: catalog.campaign.first, number: 1, daily: false);
    if (request.daily) {
      final today = catalog.dailyFor(DateTime.now());
      return GameScreen(
        request: PlayRequest(level: today, number: 0, daily: true),
        progress: progress,
        services: services,
      );
    }
    final index = catalog.indexOf(request.level.id);
    final safeIndex = index < 0 ? 0 : index;
    final level = catalog.campaign[safeIndex];
    final next = safeIndex + 1 < catalog.campaign.length ? catalog.campaign[safeIndex + 1] : null;
    return GameScreen(
      request: PlayRequest(level: level, number: safeIndex + 1, daily: false, next: next),
      progress: progress,
      services: services,
    );
  }
}

