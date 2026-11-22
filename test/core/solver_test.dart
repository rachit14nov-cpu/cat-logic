import 'package:cat_logic/core/puzzle.dart';
import 'package:cat_logic/core/solver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a board with one region has no solution', () {
    final puzzle = Puzzle(4, List<int>.filled(16, 0));
    expect(Solver.count(puzzle, limit: 2), 0);
  });

  test('row regions have more than one solution and the search stops at 2', () {
    final regions = [for (var cell = 0; cell < 16; cell++) cell ~/ 4];
    final found = Solver.solutions(Puzzle(4, regions), limit: 2);
    expect(found, hasLength(2));
    for (final columns in found) {
      expect(columns.toSet(), hasLength(4));
      for (var row = 1; row < 4; row++) {
        expect((columns[row] - columns[row - 1]).abs(), greaterThan(1));
      }
    }
  });

  test('single-cell regions force the remaining cat', () {
    const columns = [1, 3, 0, 2];
    final regions = List<int>.filled(16, 0);
    regions[1 * 4 + 3] = 1;
    regions[2 * 4 + 0] = 2;
    regions[3 * 4 + 2] = 3;
    final solutions = Solver.solutions(Puzzle(4, regions), limit: 2);
    expect(solutions, [columns]);
  });
}
