import 'dart:io';

import 'package:cat_logic/core/catalog.dart';
import 'package:cat_logic/core/daily.dart';
import 'package:cat_logic/core/deduction.dart';
import 'package:cat_logic/core/puzzle.dart';
import 'package:cat_logic/core/solver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the bundled packs are large, unique, and solvable', () {
    final catalog = LevelCatalog.fromPacked(
      gzip.decode(File('assets/levels/campaign.bin.gz').readAsBytesSync()),
      gzip.decode(File('assets/levels/daily.bin.gz').readAsBytesSync()),
    );
    expect(catalog.campaign.length, greaterThanOrEqualTo(500));
    expect(catalog.daily.length, greaterThanOrEqualTo(400));

    final seen = <String>{};
    final bySize = <int, int>{};
    for (final level in catalog.campaign) {
      expect(level.size, inInclusiveRange(5, 10));
      expect(seen.add(level.regions.join()), isTrue);
      bySize[level.size] = (bySize[level.size] ?? 0) + 1;
      validateRegionShape(level.toPuzzle());
    }
    for (final size in [5, 6, 7, 8, 9, 10]) {
      expect(bySize[size], greaterThanOrEqualTo(60), reason: 'size $size');
    }

    final dailySeen = <String>{};
    for (final level in catalog.daily) {
      expect(dailySeen.add(level.regions.join()), isTrue);
      expect(seen.contains(level.regions.join()), isFalse);
      validateRegionShape(level.toPuzzle());
    }

    for (final size in [5, 6, 7, 8, 9, 10]) {
      final sample = catalog.campaign.where((level) => level.size == size).take(2);
      for (final level in sample) {
        final puzzle = level.toPuzzle();
        final solutions = Solver.solutions(puzzle, limit: 2);
        expect(solutions, hasLength(1));
        final analysis = analyzePuzzle(puzzle);
        expect(analysis.solved, isTrue);
        expect(analysis.solution, solutions.single);
        expect(analysis.difficulty, level.difficulty);
      }
    }

    final today = DateTime(2026, 11, 20);
    expect(catalog.dailyFor(today).id, catalog.daily[dailyIndex(today, catalog.daily.length)].id);
    expect(catalog.dailyFor(DateTime(2026, 11, 20, 23)).id, catalog.dailyFor(today).id);
  });
}
