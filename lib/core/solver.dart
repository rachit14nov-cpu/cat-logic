import 'puzzle.dart';

/// Counts star-battle solutions and stops once [limit] are found.
///
/// A solution is the column chosen in each row. Cats already obey one-per-row;
/// the search also enforces one-per-column, one-per-region, and no touching.
class Solver {
  static List<List<int>> solutions(
    Puzzle puzzle, {
    int limit = 2,
    List<int>? requiredMarks,
  }) {
    if (limit < 1) return const [];
    final size = puzzle.size;
    final regions = puzzle.regions;
    final usedCol = List<bool>.filled(size, false);
    final usedRegion = List<bool>.filled(size, false);
    final cols = List<int>.filled(size, -1);
    final found = <List<int>>[];

    var forcedCats = 0;
    if (requiredMarks != null) {
      for (var i = 0; i < requiredMarks.length; i++) {
        if (requiredMarks[i] != 2) continue;
        final row = i ~/ size;
        final col = i % size;
        if (cols[row] != -1) return const [];
        final region = regions[i];
        if (usedCol[col] || usedRegion[region]) return const [];
        if (row > 0 && cols[row - 1] != -1 && (col - cols[row - 1]).abs() <= 1) {
          return const [];
        }
        cols[row] = col;
        usedCol[col] = true;
        usedRegion[region] = true;
        forcedCats++;
      }
    }

    bool feasible(int nextRow) {
      var regionSeen = 0;
      for (var row = nextRow; row < size; row++) {
        if (cols[row] != -1) {
          regionSeen |= 1 << regions[row * size + cols[row]];
          continue;
        }
        final prev = row > 0 && cols[row - 1] != -1 ? cols[row - 1] : -99;
        var any = false;
        for (var col = 0; col < size; col++) {
          if (usedCol[col]) continue;
          if (prev != -99 && (col - prev).abs() <= 1) continue;
          final region = regions[row * size + col];
          if (usedRegion[region]) continue;
          if (requiredMarks != null && requiredMarks[row * size + col] == 1) {
            continue;
          }
          any = true;
          regionSeen |= 1 << region;
        }
        if (!any) return false;
      }
      for (var region = 0; region < size; region++) {
        if (!usedRegion[region] && (regionSeen & (1 << region)) == 0) return false;
      }
      return true;
    }

    void search(int row) {
      if (found.length >= limit) return;
      if (row == size) {
        found.add(List<int>.from(cols));
        return;
      }
      if (cols[row] != -1) {
        if (row > 0 && cols[row - 1] != -1 && (cols[row] - cols[row - 1]).abs() <= 1) {
          return;
        }
        search(row + 1);
        return;
      }
      final prev = row == 0 ? -99 : cols[row - 1];
      for (var col = 0; col < size; col++) {
        if (usedCol[col]) continue;
        if (prev != -99 && (col - prev).abs() <= 1) continue;
        final cell = row * size + col;
        if (requiredMarks != null && requiredMarks[cell] == 1) continue;
        final region = regions[cell];
        if (usedRegion[region]) continue;
        usedCol[col] = true;
        usedRegion[region] = true;
        cols[row] = col;
        if (feasible(row + 1)) search(row + 1);
        cols[row] = -1;
        usedCol[col] = false;
        usedRegion[region] = false;
        if (found.length >= limit) return;
      }
    }

    if (forcedCats > 0 && !feasible(0)) return const [];
    search(0);
    return found;
  }

  static int count(Puzzle puzzle, {int limit = 2}) {
    return solutions(puzzle, limit: limit).length;
  }
}
