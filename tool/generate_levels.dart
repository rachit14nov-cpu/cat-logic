import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cat_logic/core/generator.dart';
import 'package:cat_logic/core/level_pack.dart';
import 'package:cat_logic/core/puzzle.dart';

/// Deterministic seed for the bundled campaign and daily pool.
const packSeed = 20261120;

const _quota = <int, Map<Difficulty, int>>{
  5: {Difficulty.gentle: 24, Difficulty.cozy: 32, Difficulty.tricky: 16, Difficulty.tangled: 8},
  6: {Difficulty.gentle: 14, Difficulty.cozy: 34, Difficulty.tricky: 26, Difficulty.tangled: 12},
  7: {Difficulty.gentle: 14, Difficulty.cozy: 36, Difficulty.tricky: 30, Difficulty.tangled: 14},
  8: {Difficulty.gentle: 10, Difficulty.cozy: 34, Difficulty.tricky: 32, Difficulty.tangled: 16},
  9: {Difficulty.gentle: 8, Difficulty.cozy: 30, Difficulty.tricky: 30, Difficulty.tangled: 14},
  10: {Difficulty.gentle: 4, Difficulty.cozy: 24, Difficulty.tricky: 28, Difficulty.tangled: 14},
};

const _minimumPerSize = <int, int>{5: 72, 6: 76, 7: 84, 8: 82, 9: 72, 10: 64};

const dailyTarget = 420;

void main(List<String> args) {
  final smoke = args.contains('--smoke');
  final started = DateTime.now();
  final random = Random(packSeed);
  final seen = <String>{};
  final accepted = <int, Map<Difficulty, List<GeneratedPuzzle>>>{
    for (final size in _quota.keys) size: {for (final difficulty in Difficulty.values) difficulty: <GeneratedPuzzle>[]},
  };
  final overflow = <int, List<GeneratedPuzzle>>{for (final size in _quota.keys) size: <GeneratedPuzzle>[]};

  if (smoke) {
    for (final size in _quota.keys) {
      var hits = 0;
      var attempts = 0;
      final byDifficulty = <Difficulty, int>{for (final difficulty in Difficulty.values) difficulty: 0};
      while (hits < 3 && attempts < 400) {
        attempts++;
        final puzzle = generateOne(size, random, allowContradiction: hits == 2, rounds: 4);
        if (puzzle == null || !seen.add(puzzle.key)) continue;
        hits++;
        byDifficulty[puzzle.difficulty] = byDifficulty[puzzle.difficulty]! + 1;
      }
      stdout.writeln('smoke $size: $hits kept from $attempts attempts $byDifficulty');
    }
    return;
  }

  final attemptBudget = <int, int>{5: 5000, 6: 6000, 7: 8000, 8: 9000, 9: 10000, 10: 12000};
  for (final size in [5, 6, 7, 8, 9, 10]) {
    var attempts = 0;
    final budget = attemptBudget[size]!;
    while (attempts < budget && !_sizeSatisfied(accepted, overflow, size)) {
      attempts++;
      final needRare = _needs(accepted, size, Difficulty.tangled) || _needs(accepted, size, Difficulty.tricky);
      final puzzle = generateOne(size, random, allowContradiction: needRare && attempts.isEven, rounds: 4);
      if (puzzle == null || !seen.add(puzzle.key)) continue;
      if (size == 5 &&
          puzzle.difficulty != Difficulty.gentle &&
          accepted[5]![Difficulty.gentle]!.length < 16 &&
          attempts < 1200) {
        continue;
      }
      _keep(accepted, overflow, puzzle);
      if (attempts % 250 == 0) {
        stdout.writeln('size $size attempts $attempts ${_counts(accepted, overflow, size)}');
      }
    }
    stdout.writeln('size $size done after $attempts ${_counts(accepted, overflow, size)}');
    if (_total(accepted, overflow, size) < _minimumPerSize[size]!) {
      stderr.writeln('Short on ${size}x$size: ${_total(accepted, overflow, size)}.');
    }
  }

  var kept = 0;
  for (final size in [5, 6, 7, 8, 9, 10]) {
    kept += _total(accepted, overflow, size);
  }
  var filler = 0;
  while (kept < 520 && filler < 6000) {
    filler++;
    final size = [5, 6, 7, 8, 9, 10][filler % 6];
    final puzzle = generateOne(size, random, rounds: 4);
    if (puzzle == null || !seen.add(puzzle.key)) continue;
    accepted[size]![puzzle.difficulty]!.add(puzzle);
    kept++;
  }
  if (filler > 0) stdout.writeln('filler added puzzles, campaign now $kept');

  final selected = <GeneratedPuzzle>[];
  for (final size in [5, 6, 7, 8, 9, 10]) {
    for (final difficulty in Difficulty.values) {
      selected.addAll(accepted[size]![difficulty]!);
    }
    selected.addAll(overflow[size]!);
  }
  selected.sort((a, b) {
    final curve = _curve(a).compareTo(_curve(b));
    if (curve != 0) return curve;
    final steps = a.analysis.steps.length.compareTo(b.analysis.steps.length);
    if (steps != 0) return steps;
    return a.key.compareTo(b.key);
  });
  final easiest = selected.where((puzzle) => puzzle.puzzle.size == 5 && puzzle.difficulty == Difficulty.gentle).toList()
    ..sort((a, b) => a.analysis.steps.length.compareTo(b.analysis.steps.length));
  final lead = easiest.take(8).toList();
  final rest = selected.where((puzzle) => !lead.contains(puzzle)).toList();
  final ordered = [...lead, ...rest];

  final perSizeCount = <int, int>{};
  final levels = <Level>[];
  for (final puzzle in ordered) {
    final size = puzzle.puzzle.size;
    final number = (perSizeCount[size] ?? 0) + 1;
    perSizeCount[size] = number;
    levels.add(
      Level(
        id: '$size-${number.toString().padLeft(3, '0')}',
        size: size,
        difficulty: puzzle.difficulty,
        regions: puzzle.puzzle.regions,
      ),
    );
  }

  final daily = <Level>[];
  final dailySizes = [6, 7, 7, 8, 8, 8, 9, 9, 10, 6, 7, 5];
  var dailyAttempts = 0;
  while (daily.length < dailyTarget && dailyAttempts < 40000) {
    dailyAttempts++;
    final size = dailySizes[dailyAttempts % dailySizes.length];
    final puzzle = generateOne(size, random, allowContradiction: dailyAttempts.isEven, rounds: 3);
    if (puzzle == null || !seen.add(puzzle.key)) continue;
    final number = daily.length + 1;
    daily.add(
      Level(
        id: 'd-${number.toString().padLeft(3, '0')}',
        size: size,
        difficulty: puzzle.difficulty,
        regions: puzzle.puzzle.regions,
      ),
    );
    if (daily.length % 40 == 0) {
      stdout.writeln('daily ${daily.length} after $dailyAttempts attempts');
    }
  }
  if (daily.length < dailyTarget) {
    stderr.writeln('Daily pool stopped at ${daily.length}.');
    exitCode = 1;
    return;
  }

  final meta = _meta(levels);
  final directory = Directory('assets/levels');
  directory.createSync(recursive: true);
  File('assets/levels/campaign.bin.gz').writeAsBytesSync(gzip.encode(LevelPack.encode(levels, daily: false)));
  File('assets/levels/daily.bin.gz').writeAsBytesSync(gzip.encode(LevelPack.encode(daily, daily: true)));
  const encoder = JsonEncoder.withIndent('  ');
  final elapsed = DateTime.now().difference(started);
  stdout.writeln('Wrote ${levels.length} campaign levels and ${daily.length} daily puzzles in ${elapsed.inSeconds}s.');
  stdout.writeln(encoder.convert(meta));
}

bool _needs(Map<int, Map<Difficulty, List<GeneratedPuzzle>>> accepted, int size, Difficulty difficulty) {
  return accepted[size]![difficulty]!.length < _quota[size]![difficulty]!;
}

bool _sizeSatisfied(
  Map<int, Map<Difficulty, List<GeneratedPuzzle>>> accepted,
  Map<int, List<GeneratedPuzzle>> overflow,
  int size,
) {
  for (final difficulty in Difficulty.values) {
    if (_needs(accepted, size, difficulty)) return false;
  }
  return true;
}

int _total(
  Map<int, Map<Difficulty, List<GeneratedPuzzle>>> accepted,
  Map<int, List<GeneratedPuzzle>> overflow,
  int size,
) {
  var total = overflow[size]!.length;
  for (final difficulty in Difficulty.values) {
    total += accepted[size]![difficulty]!.length;
  }
  return total;
}

void _keep(
  Map<int, Map<Difficulty, List<GeneratedPuzzle>>> accepted,
  Map<int, List<GeneratedPuzzle>> overflow,
  GeneratedPuzzle puzzle,
) {
  final size = puzzle.puzzle.size;
  final bucket = accepted[size]![puzzle.difficulty]!;
  final cap = _quota[size]![puzzle.difficulty]!;
  if (bucket.length < cap) bucket.add(puzzle);
}

String _counts(
  Map<int, Map<Difficulty, List<GeneratedPuzzle>>> accepted,
  Map<int, List<GeneratedPuzzle>> overflow,
  int size,
) {
  final parts = [for (final difficulty in Difficulty.values) '${difficulty.name}=${accepted[size]![difficulty]!.length}'];
  return '${parts.join(' ')} overflow=${overflow[size]!.length}';
}

int _curve(GeneratedPuzzle puzzle) => (puzzle.puzzle.size - 5) * 3 + puzzle.difficulty.index;

Map<String, Object?> _meta(List<Level> levels) {
  final bySize = <String, int>{};
  final byDifficulty = <String, int>{};
  final bySizeAndDifficulty = <String, Map<String, int>>{};
  for (final level in levels) {
    final sizeKey = '${level.size}';
    bySize[sizeKey] = (bySize[sizeKey] ?? 0) + 1;
    byDifficulty[level.difficulty.name] = (byDifficulty[level.difficulty.name] ?? 0) + 1;
    final row = bySizeAndDifficulty.putIfAbsent(sizeKey, () => {});
    row[level.difficulty.name] = (row[level.difficulty.name] ?? 0) + 1;
  }
  return {
    'campaign': levels.length,
    'bySize': bySize,
    'byDifficulty': byDifficulty,
    'bySizeAndDifficulty': bySizeAndDifficulty,
  };
}
