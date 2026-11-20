/// A star-battle board: an N×N grid split into N orthogonally connected regions.
///
/// Region ids are `0 .. size - 1`. Cell `row * size + col` stores its region.
class Puzzle {
  Puzzle(this.size, List<int> regions) : regions = List<int>.unmodifiable(regions) {
    if (size < 2) {
      throw ArgumentError.value(size, 'size', 'must be at least 2');
    }
    if (regions.length != size * size) {
      throw ArgumentError('expected ${size * size} region cells, got ${regions.length}');
    }
  }

  final int size;
  final List<int> regions;

  int get cellCount => size * size;

  int index(int row, int col) => row * size + col;

  int rowOf(int index) => index ~/ size;

  int colOf(int index) => index % size;

  int regionAt(int index) => regions[index];
}

/// How hard a puzzle is, from the strongest technique a logical solve needed.
enum Difficulty {
  gentle,
  cozy,
  tricky,
  tangled;

  static Difficulty fromRank(int rank) {
    if (rank <= 1) return Difficulty.gentle;
    if (rank == 2) return Difficulty.cozy;
    if (rank == 3) return Difficulty.tricky;
    return Difficulty.tangled;
  }

  String get label => switch (this) {
    Difficulty.gentle => 'Gentle',
    Difficulty.cozy => 'Cozy',
    Difficulty.tricky => 'Tricky',
    Difficulty.tangled => 'Tangled',
  };
}

/// One bundled puzzle.
class Level {
  const Level({
    required this.id,
    required this.size,
    required this.difficulty,
    required this.regions,
  });

  final String id;
  final int size;
  final Difficulty difficulty;
  final List<int> regions;

  Puzzle toPuzzle() => Puzzle(size, regions);
}

enum CellMark { empty, playerX, autoX, cat, keepOpen }

/// Cells a placed cat forbids: its row, column, region, and every touching cell.
bool ruledOutByCat(Puzzle puzzle, int cat, int other) {
  if (cat == other) return false;
  final size = puzzle.size;
  final catRow = cat ~/ size;
  final catCol = cat % size;
  final row = other ~/ size;
  final col = other % size;
  if (catRow == row || catCol == col) return true;
  if (puzzle.regions[cat] == puzzle.regions[other]) return true;
  final rowGap = catRow - row;
  final colGap = catCol - col;
  return rowGap.abs() <= 1 && colGap.abs() <= 1;
}

/// Rebuilds automatic X marks from the cats currently on the board.
List<CellMark> withAutoMarks(
  Puzzle puzzle,
  List<CellMark> marks, {
  required bool enabled,
}) {
  final next = List<CellMark>.from(marks);
  for (var i = 0; i < next.length; i++) {
    if (next[i] == CellMark.autoX) next[i] = CellMark.empty;
  }
  if (!enabled) return next;
  final cats = <int>[];
  for (var i = 0; i < next.length; i++) {
    if (next[i] == CellMark.cat) cats.add(i);
  }
  for (final cat in cats) {
    for (var i = 0; i < next.length; i++) {
      if (next[i] != CellMark.empty) continue;
      if (ruledOutByCat(puzzle, cat, i)) next[i] = CellMark.autoX;
    }
  }
  return next;
}

/// Orthogonal neighbours that stay on the board.
Iterable<int> orthogonalNeighbors(int index, int size) sync* {
  final row = index ~/ size;
  final col = index % size;
  if (row > 0) yield index - size;
  if (row + 1 < size) yield index + size;
  if (col > 0) yield index - 1;
  if (col + 1 < size) yield index + 1;
}

bool sameOrthogonalRegion(List<int> regions, int size, int region) {
  final cells = <int>[];
  for (var i = 0; i < regions.length; i++) {
    if (regions[i] == region) cells.add(i);
  }
  if (cells.isEmpty) return false;
  final seen = <int>{cells.first};
  final queue = <int>[cells.first];
  while (queue.isNotEmpty) {
    final current = queue.removeLast();
    for (final next in orthogonalNeighbors(current, size)) {
      if (regions[next] != region || !seen.add(next)) continue;
      queue.add(next);
    }
  }
  return seen.length == cells.length;
}

/// Shape checks shared by the generator and the tests.
void validateRegionShape(Puzzle puzzle, {List<int>? stars}) {
  final size = puzzle.size;
  final seen = List<bool>.filled(size, false);
  final counts = List<int>.filled(size, 0);
  for (final region in puzzle.regions) {
    if (region < 0 || region >= size) {
      throw StateError('region id $region is outside 0..${size - 1}');
    }
    seen[region] = true;
    counts[region]++;
  }
  for (var region = 0; region < size; region++) {
    if (!seen[region] || counts[region] == 0) {
      throw StateError('region $region is missing');
    }
    if (!sameOrthogonalRegion(puzzle.regions, size, region)) {
      throw StateError('region $region is not orthogonally connected');
    }
  }
  if (stars != null) {
    if (stars.length != size) {
      throw StateError('expected $size stars');
    }
    final usedCols = <int>{};
    final usedRegions = <int>{};
    for (var row = 0; row < size; row++) {
      final col = stars[row];
      if (col < 0 || col >= size || !usedCols.add(col)) {
        throw StateError('stars are not one per column');
      }
      if (row > 0 && (col - stars[row - 1]).abs() <= 1) {
        throw StateError('stars touch between rows ${row - 1} and $row');
      }
      final region = puzzle.regions[row * size + col];
      if (!usedRegions.add(region)) {
        throw StateError('two stars share region $region');
      }
    }
  }
}
