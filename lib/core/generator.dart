import 'dart:math';

import 'deduction.dart';
import 'explain.dart';
import 'puzzle.dart';
import 'solver.dart';

class GeneratedPuzzle {
  GeneratedPuzzle({required this.puzzle, required this.stars, required this.analysis, required this.key});

  final Puzzle puzzle;
  final List<int> stars;
  final Analysis analysis;
  final String key;

  Difficulty get difficulty => analysis.difficulty;
}

/// Builds one logically solvable puzzle, or returns null if this attempt missed.
GeneratedPuzzle? generateOne(
  int size,
  Random random, {
  bool allowContradiction = false,
  int rounds = 5,
}) {
  final stars = randomStarColumns(size, random);
  var regions = growRegions(size, stars, random, random.nextInt(4));
  final attempts = rounds < 12 ? 12 : rounds;
  for (var round = 0; round < attempts; round++) {
    final puzzle = Puzzle(size, regions);
    final analysis = analyzePuzzle(puzzle, allowContradiction: false);
    if (_keeps(puzzle, analysis, stars)) {
      return _pack(puzzle, stars, analysis, regions);
    }
    final found = Solver.solutions(puzzle, limit: 2);
    var moved = false;
    if (found.length >= 2) {
      final alternate = _sameColumns(found[0], stars) ? found[1] : found[0];
      moved = killAlternateSolution(regions, size, stars, alternate, random);
    } else if (found.length == 1 && (allowContradiction || size >= 8)) {
      final deeper = analyzePuzzle(puzzle, allowContradiction: true);
      if (_keeps(puzzle, deeper, stars, alreadyUnique: true)) {
        return _pack(puzzle, stars, deeper, regions);
      }
    }
    if (!moved) moved = mutateRegionBoundary(regions, size, stars, random);
    if (!moved) regions = growRegions(size, stars, random, random.nextInt(4));
  }
  return null;
}

List<int> randomStarColumns(int size, Random random) {
  final columns = List<int>.filled(size, -1);
  final used = List<bool>.filled(size, false);
  bool walk(int row) {
    if (row == size) return true;
    final order = List<int>.generate(size, (index) => index)..shuffle(random);
    final previous = row == 0 ? -99 : columns[row - 1];
    for (final column in order) {
      if (used[column]) continue;
      if (previous != -99 && (column - previous).abs() <= 1) continue;
      used[column] = true;
      columns[row] = column;
      if (walk(row + 1)) return true;
      used[column] = false;
    }
    return false;
  }

  if (!walk(0)) {
    throw StateError('no legal cat placement for size $size');
  }
  return columns;
}

List<int> growRegions(int size, List<int> stars, Random random, int style) {
  final regions = List<int>.filled(size * size, -1);
  final sizes = List<int>.filled(size, 0);
  for (var row = 0; row < size; row++) {
    regions[row * size + stars[row]] = row;
    sizes[row] = 1;
  }
  var assigned = size;

  void claim(int cell, int region) {
    regions[cell] = region;
    sizes[region]++;
    assigned++;
  }

  List<int> openings(int cell) {
    return [for (final next in orthogonalNeighbors(cell, size)) if (regions[next] < 0) next];
  }

  if (style == 0) {
    while (assigned < size * size) {
      final options = <(int, int)>[];
      var best = 1 << 30;
      for (var cell = 0; cell < regions.length; cell++) {
        final region = regions[cell];
        if (region < 0) continue;
        final open = openings(cell);
        if (open.isEmpty) continue;
        final weight = sizes[region];
        if (weight < best) {
          best = weight;
          options.clear();
        }
        if (weight == best) {
          for (final next in open) {
            options.add((next, region));
          }
        }
      }
      if (options.isEmpty) break;
      final pick = options[random.nextInt(options.length)];
      claim(pick.$1, pick.$2);
    }
  } else if (style == 1) {
    final order = List<int>.generate(size, (index) => index)..shuffle(random);
    var remainingRegions = size;
    for (final region in order) {
      final remainingCells = size * size - assigned + sizes[region];
      final base = remainingCells ~/ remainingRegions;
      var target = base + random.nextInt(3) - 1;
      final maxTarget = size * size - assigned + sizes[region] - (remainingRegions - 1);
      if (target < 1) target = 1;
      if (target > maxTarget) target = maxTarget;
      var guard = 0;
      while (sizes[region] < target && guard++ < size * size) {
        final moves = <int>[];
        for (var cell = 0; cell < regions.length; cell++) {
          if (regions[cell] != region) continue;
          moves.addAll(openings(cell));
        }
        if (moves.isEmpty) break;
        claim(moves[random.nextInt(moves.length)], region);
      }
      remainingRegions--;
    }
  } else if (style == 3) {
    final order = List<int>.generate(size, (index) => index)..shuffle(random);
    for (final region in order) {
      final row = region;
      final column = stars[row];
      void walk(int stepRow, int stepCol) {
        var nextRow = row + stepRow;
        var nextCol = column + stepCol;
        while (nextRow >= 0 && nextCol >= 0 && nextRow < size && nextCol < size) {
          final cell = nextRow * size + nextCol;
          if (regions[cell] >= 0 || random.nextDouble() < 0.4) break;
          claim(cell, region);
          nextRow += stepRow;
          nextCol += stepCol;
        }
      }

      walk(0, -1);
      walk(0, 1);
      if (random.nextBool()) walk(-1, 0);
      if (random.nextBool()) walk(1, 0);
    }
  } else {
    final frontier = <int>[for (var row = 0; row < size; row++) row * size + stars[row]];
    while (assigned < size * size && frontier.isNotEmpty) {
      final index = random.nextInt(frontier.length);
      final cell = frontier[index];
      final open = openings(cell);
      if (open.isEmpty) {
        frontier[index] = frontier.last;
        frontier.removeLast();
        continue;
      }
      final next = open[random.nextInt(open.length)];
      claim(next, regions[cell]);
      frontier.add(next);
    }
  }

  while (assigned < size * size) {
    var placed = false;
    for (var cell = 0; cell < regions.length && !placed; cell++) {
      if (regions[cell] >= 0) continue;
      var bestRegion = -1;
      var bestSize = 1 << 30;
      for (final next in orthogonalNeighbors(cell, size)) {
        final region = regions[next];
        if (region < 0 || sizes[region] >= bestSize) continue;
        bestSize = sizes[region];
        bestRegion = region;
      }
      if (bestRegion < 0) continue;
      claim(cell, bestRegion);
      placed = true;
    }
    if (!placed) {
      throw StateError('region growth left a sealed gap');
    }
  }
  return regions;
}

bool killAlternateSolution(
  List<int> regions,
  int size,
  List<int> intended,
  List<int> alternate,
  Random random,
) {
  final reserved = <int>{for (var row = 0; row < size; row++) row * size + intended[row]};
  final cells = <int>[];
  for (var row = 0; row < size; row++) {
    if (alternate[row] == intended[row]) continue;
    final cell = row * size + alternate[row];
    if (!reserved.contains(cell)) cells.add(cell);
  }
  cells.shuffle(random);
  for (final cell in cells) {
    final region = regions[cell];
    final targets = <int>[
      for (final next in orthogonalNeighbors(cell, size))
        if (regions[next] != region) regions[next],
    ]..shuffle(random);
    for (final target in targets.toSet()) {
      if (!_staysConnected(regions, size, region, cell)) continue;
      regions[cell] = target;
      return true;
    }
  }
  return false;
}

bool mutateRegionBoundary(List<int> regions, int size, List<int> stars, Random random) {
  final reserved = <int>{for (var row = 0; row < size; row++) row * size + stars[row]};
  final candidates = <int>[];
  for (var cell = 0; cell < regions.length; cell++) {
    if (reserved.contains(cell)) continue;
    final region = regions[cell];
    var border = false;
    for (final next in orthogonalNeighbors(cell, size)) {
      if (regions[next] != region) border = true;
    }
    if (border) candidates.add(cell);
  }
  if (candidates.isEmpty) return false;
  candidates.shuffle(random);
  final tries = candidates.length < 16 ? candidates.length : 16;
  for (var i = 0; i < tries; i++) {
    final cell = candidates[i];
    final region = regions[cell];
    final targets = <int>{
      for (final next in orthogonalNeighbors(cell, size))
        if (regions[next] != region) regions[next],
    }.toList()..shuffle(random);
    for (final target in targets) {
      if (!_staysConnected(regions, size, region, cell)) continue;
      regions[cell] = target;
      return true;
    }
  }
  return false;
}

bool _staysConnected(List<int> regions, int size, int region, int removed) {
  var start = -1;
  var count = 0;
  for (var cell = 0; cell < regions.length; cell++) {
    if (regions[cell] == region && cell != removed) {
      count++;
      start = cell;
    }
  }
  if (count == 0 || start < 0) return false;
  final seen = <int>{start};
  final queue = <int>[start];
  while (queue.isNotEmpty) {
    final current = queue.removeLast();
    for (final next in orthogonalNeighbors(current, size)) {
      if (next == removed || regions[next] != region || !seen.add(next)) continue;
      queue.add(next);
    }
  }
  return seen.length == count;
}

bool _keeps(Puzzle puzzle, Analysis analysis, List<int> stars, {bool alreadyUnique = false}) {
  final solution = analysis.solution;
  if (!analysis.solved || solution == null || !_sameColumns(solution, stars)) return false;
  if (!alreadyUnique && Solver.count(puzzle, limit: 2) != 1) return false;
  validateRegionShape(puzzle, stars: stars);
  return true;
}

GeneratedPuzzle _pack(Puzzle puzzle, List<int> stars, Analysis analysis, List<int> regions) {
  return GeneratedPuzzle(
    puzzle: puzzle,
    stars: List<int>.from(stars),
    analysis: analysis,
    key: symmetryKey(regions, puzzle.size),
  );
}

bool _sameColumns(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) return false;
  }
  return true;
}

String symmetryKey(List<int> regions, int size) {
  var best = _canon(regions);
  var current = List<int>.from(regions);
  for (var turn = 0; turn < 4; turn++) {
    final mirrored = _reflect(current, size);
    for (final variant in [current, mirrored]) {
      final key = _canon(variant);
      if (key.compareTo(best) < 0) best = key;
    }
    current = _rotate(current, size);
  }
  return best;
}

String _canon(List<int> regions) {
  final map = <int, int>{};
  final buffer = StringBuffer();
  for (final region in regions) {
    final id = map.putIfAbsent(region, () => map.length);
    buffer.write(id.toRadixString(16));
  }
  return buffer.toString();
}

List<int> _rotate(List<int> regions, int size) {
  final next = List<int>.filled(regions.length, 0);
  for (var row = 0; row < size; row++) {
    for (var col = 0; col < size; col++) {
      next[col * size + (size - 1 - row)] = regions[row * size + col];
    }
  }
  return next;
}

List<int> _reflect(List<int> regions, int size) {
  final next = List<int>.filled(regions.length, 0);
  for (var row = 0; row < size; row++) {
    for (var col = 0; col < size; col++) {
      next[row * size + (size - 1 - col)] = regions[row * size + col];
    }
  }
  return next;
}

String encodeRegions(List<int> regions) => regions.map((region) => region.toRadixString(16)).join();

List<int> decodeRegions(String encoded) {
  return [for (final unit in encoded.codeUnits) int.parse(String.fromCharCode(unit), radix: 16)];
}
