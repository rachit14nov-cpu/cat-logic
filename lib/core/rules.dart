import 'puzzle.dart';

class RuleIssue {
  const RuleIssue(this.message, this.cells);

  final String message;
  final List<int> cells;
}

class Assessment {
  const Assessment({
    required this.catsPlaced,
    required this.won,
    required this.issues,
  });

  final int catsPlaced;
  final bool won;
  final List<RuleIssue> issues;

  bool get consistent => issues.isEmpty;
}

Assessment assessCats(Puzzle puzzle, List<int> cats, List<String> regionNames) {
  final size = puzzle.size;
  final issues = <RuleIssue>[];
  final byRow = List.generate(size, (_) => <int>[]);
  final byCol = List.generate(size, (_) => <int>[]);
  final byRegion = List.generate(size, (_) => <int>[]);
  for (final cell in cats) {
    byRow[puzzle.rowOf(cell)].add(cell);
    byCol[puzzle.colOf(cell)].add(cell);
    byRegion[puzzle.regionAt(cell)].add(cell);
  }
  for (var row = 0; row < size; row++) {
    if (byRow[row].length > 1) {
      issues.add(RuleIssue('Row ${row + 1} has two cats.', List<int>.from(byRow[row])));
    }
  }
  for (var col = 0; col < size; col++) {
    if (byCol[col].length > 1) {
      issues.add(RuleIssue('Column ${col + 1} has two cats.', List<int>.from(byCol[col])));
    }
  }
  for (var region = 0; region < size; region++) {
    if (byRegion[region].length > 1) {
      issues.add(
        RuleIssue(
          'The ${regionNames[region]} region has two cats.',
          List<int>.from(byRegion[region]),
        ),
      );
    }
  }
  for (var a = 0; a < cats.length; a++) {
    for (var b = a + 1; b < cats.length; b++) {
      final left = cats[a];
      final right = cats[b];
      if (puzzle.rowOf(left) == puzzle.rowOf(right)) continue;
      if (puzzle.colOf(left) == puzzle.colOf(right)) continue;
      final rowGap = puzzle.rowOf(left) - puzzle.rowOf(right);
      final colGap = puzzle.colOf(left) - puzzle.colOf(right);
      if (rowGap.abs() <= 1 && colGap.abs() <= 1) {
        issues.add(RuleIssue('These cats are touching, even on a corner.', [left, right]));
      }
    }
  }
  final won = cats.length == size && issues.isEmpty;
  return Assessment(catsPlaced: cats.length, won: won, issues: issues);
}
