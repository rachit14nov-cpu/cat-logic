import '../core/daily.dart';

class ProgressData {
  const ProgressData({
    required this.completed,
    required this.bestMs,
    required this.autoMark,
    required this.paletteId,
    required this.themeMode,
    required this.patternsAlways,
    required this.dailyStreak,
    required this.lastDailyDate,
    required this.dailyBestMs,
  });

  factory ProgressData.initial() {
    return const ProgressData(
      completed: {},
      bestMs: {},
      autoMark: true,
      paletteId: 'meadow',
      themeMode: 'system',
      patternsAlways: false,
      dailyStreak: 0,
      lastDailyDate: null,
      dailyBestMs: {},
    );
  }

  final Set<String> completed;
  final Map<String, int> bestMs;
  final bool autoMark;
  final String paletteId;
  final String themeMode;
  final bool patternsAlways;
  final int dailyStreak;
  final String? lastDailyDate;
  final Map<String, int> dailyBestMs;

  DailyStreak get streak => DailyStreak(count: dailyStreak, lastCompleted: lastDailyDate);

  int visibleStreak(DateTime now) => streak.visibleOn(now);

  ProgressData completeLevel(String id, int elapsedMs) {
    final best = Map<String, int>.from(bestMs);
    final previous = best[id];
    if (previous == null || elapsedMs < previous) best[id] = elapsedMs;
    return copyWith(completed: {...completed, id}, bestMs: best);
  }

  /// Recording a finish never looks at hint use. A hint cannot change the streak.
  ProgressData completeDaily(DateTime now, int elapsedMs) {
    final next = streak.recordCompletion(now);
    final best = Map<String, int>.from(dailyBestMs);
    final key = isoDate(now);
    final previous = best[key];
    if (previous == null || elapsedMs < previous) best[key] = elapsedMs;
    return copyWith(
      dailyStreak: next.count,
      lastDailyDate: next.lastCompleted,
      dailyBestMs: best,
    );
  }

  ProgressData copyWith({
    Set<String>? completed,
    Map<String, int>? bestMs,
    bool? autoMark,
    String? paletteId,
    String? themeMode,
    bool? patternsAlways,
    int? dailyStreak,
    String? lastDailyDate,
    Map<String, int>? dailyBestMs,
    bool clearDailyDate = false,
  }) {
    return ProgressData(
      completed: completed ?? this.completed,
      bestMs: bestMs ?? this.bestMs,
      autoMark: autoMark ?? this.autoMark,
      paletteId: paletteId ?? this.paletteId,
      themeMode: themeMode ?? this.themeMode,
      patternsAlways: patternsAlways ?? this.patternsAlways,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      lastDailyDate: clearDailyDate ? null : lastDailyDate ?? this.lastDailyDate,
      dailyBestMs: dailyBestMs ?? this.dailyBestMs,
    );
  }

  Map<String, Object?> toJson() {
    final done = completed.toList()..sort();
    return {
      'completed': done,
      'bestMs': bestMs,
      'autoMark': autoMark,
      'paletteId': paletteId,
      'themeMode': themeMode,
      'patternsAlways': patternsAlways,
      'dailyStreak': dailyStreak,
      'lastDailyDate': lastDailyDate,
      'dailyBestMs': dailyBestMs,
    };
  }

  factory ProgressData.fromJson(Map<String, Object?> json) {
    Set<String> strings(Object? value) {
      if (value is! List) return {};
      return {for (final entry in value) entry.toString()};
    }

    Map<String, int> times(Object? value) {
      if (value is! Map) return {};
      final out = <String, int>{};
      value.forEach((key, raw) {
        if (raw is num) out[key.toString()] = raw.toInt();
      });
      return out;
    }

    final initial = ProgressData.initial();
    return ProgressData(
      completed: strings(json['completed']),
      bestMs: times(json['bestMs']),
      autoMark: json['autoMark'] as bool? ?? initial.autoMark,
      paletteId: json['paletteId'] as String? ?? initial.paletteId,
      themeMode: json['themeMode'] as String? ?? initial.themeMode,
      patternsAlways: json['patternsAlways'] as bool? ?? false,
      dailyStreak: (json['dailyStreak'] as num?)?.toInt() ?? 0,
      lastDailyDate: json['lastDailyDate'] as String?,
      dailyBestMs: times(json['dailyBestMs']),
    );
  }
}
