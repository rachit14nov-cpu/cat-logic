import 'dart:math';

import 'package:cat_logic/core/explain.dart';
import 'package:cat_logic/core/generator.dart';
import 'package:cat_logic/core/puzzle.dart';
import 'package:cat_logic/core/solver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generated puzzles are contiguous and have one logical solution', () {
    final random = Random(7);
    for (final size in [5, 6]) {
      GeneratedPuzzle? puzzle;
      for (var attempt = 0; attempt < 80 && puzzle == null; attempt++) {
        puzzle = generateOne(size, random, rounds: 4);
      }
      expect(puzzle, isNotNull, reason: 'size $size produced no puzzle');
      final board = puzzle!.puzzle;
      validateRegionShape(board, stars: puzzle.stars);
      expect(Solver.count(board, limit: 2), 1);
      expect(puzzle.analysis.solved, isTrue);
      expect(puzzle.analysis.solution, puzzle.stars);
      expect(puzzle.analysis.steps, isNotEmpty);
      expect(puzzle.analysis.steps.first.technique, isNot(Technique.conflict));
    }
  });
}
