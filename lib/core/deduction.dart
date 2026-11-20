import 'dart:typed_data';

import 'explain.dart';
import 'puzzle.dart';

/// Logical marks: 0 unknown, 1 eliminated, 2 cat.
class LogicState {
  LogicState(this.puzzle) : mark = Uint8List(puzzle.cellCount);

  LogicState.fromMarks(this.puzzle, List<int> marks) : mark = Uint8List.fromList(marks);

  final Puzzle puzzle;
  final Uint8List mark;

  String? failureKind;
  int? failureIndex;
  int? failureRegion;

  int get size => puzzle.size;

  LogicState clone() {
    final copy = LogicState.fromMarks(puzzle, mark);
    copy.failureKind = failureKind;
    copy.failureIndex = failureIndex;
    copy.failureRegion = failureRegion;
    return copy;
  }

  void _fail(String kind, {int? index, int? region}) {
    failureKind = kind;
    failureIndex = index;
    failureRegion = region;
  }

  bool propagate() {
    final size = this.size;
    final regions = puzzle.regions;
    final total = puzzle.cellCount;
    var guard = 0;
    while (guard++ < total + 2) {
      final catAtRow = List<int>.filled(size, -1);
      final catAtCol = List<int>.filled(size, -1);
      final catAtRegion = List<int>.filled(size, -1);
      final cats = <int>[];
      for (var i = 0; i < total; i++) {
        if (mark[i] != 2) continue;
        final row = i ~/ size;
        final col = i % size;
        final region = regions[i];
        if (catAtRow[row] != -1) {
          _fail('row', index: row);
          return false;
        }
        if (catAtCol[col] != -1) {
          _fail('column', index: col);
          return false;
        }
        if (catAtRegion[region] != -1) {
          _fail('region', region: region);
          return false;
        }
        catAtRow[row] = i;
        catAtCol[col] = i;
        catAtRegion[region] = i;
        cats.add(i);
      }
      for (var a = 0; a < cats.length; a++) {
        for (var b = a + 1; b < cats.length; b++) {
          if (_touches(cats[a], cats[b])) {
            _fail('touch');
            return false;
          }
        }
      }
      var changed = false;
      for (final cat in cats) {
        for (var i = 0; i < total; i++) {
          if (i == cat || mark[i] != 0) continue;
          if (_ruledOut(cat, i)) {
            mark[i] = 1;
            changed = true;
          }
        }
      }
      for (var row = 0; row < size; row++) {
        if (catAtRow[row] != -1) continue;
        var any = false;
        for (var col = 0; col < size; col++) {
          if (mark[row * size + col] == 0) any = true;
        }
        if (!any) {
          _fail('empty-row', index: row);
          return false;
        }
      }
      for (var col = 0; col < size; col++) {
        if (catAtCol[col] != -1) continue;
        var any = false;
        for (var row = 0; row < size; row++) {
          if (mark[row * size + col] == 0) any = true;
        }
        if (!any) {
          _fail('empty-column', index: col);
          return false;
        }
      }
      for (var region = 0; region < size; region++) {
        if (catAtRegion[region] != -1) continue;
        var any = false;
        for (var i = 0; i < total; i++) {
          if (regions[i] == region && mark[i] == 0) any = true;
        }
        if (!any) {
          _fail('empty-region', region: region);
          return false;
        }
      }
      if (!changed) return true;
    }
    return true;
  }

  bool _touches(int a, int b) {
    final size = this.size;
    final rowGap = a ~/ size - b ~/ size;
    final colGap = a % size - b % size;
    return rowGap.abs() <= 1 && colGap.abs() <= 1;
  }

  bool _ruledOut(int cat, int other) => ruledOutByCat(puzzle, cat, other);

  LogicStep? next({bool allowContradiction = true}) {
    if (!propagate()) return _conflictStep();
    final single = _single();
    if (single != null) return single;
    final confined = _lineSubsets(maxDegree: 1);
    if (confined != null) return confined;
    final neighbour = _neighbour();
    if (neighbour != null) return neighbour;
    final subset = _lineSubsets(minDegree: 2);
    if (subset != null) return subset;
    if (!allowContradiction) return null;
    return _contradiction();
  }

  void apply(LogicStep step) {
    if (step.placesCat) {
      for (final cell in step.resultCells) {
        mark[cell] = 2;
      }
    } else {
      for (final cell in step.resultCells) {
        if (mark[cell] == 0) mark[cell] = 1;
      }
    }
  }

  bool get solved {
    final size = this.size;
    var cats = 0;
    for (var i = 0; i < mark.length; i++) {
      if (mark[i] == 2) cats++;
      if (mark[i] == 0) return false;
    }
    if (cats != size) return false;
    final cols = solutionCols();
    if (cols == null) return false;
    for (var row = 1; row < size; row++) {
      if ((cols[row] - cols[row - 1]).abs() <= 1) return false;
    }
    return true;
  }

  List<int>? solutionCols() {
    final size = this.size;
    final cols = List<int>.filled(size, -1);
    for (var i = 0; i < mark.length; i++) {
      if (mark[i] != 2) continue;
      final row = i ~/ size;
      if (cols[row] != -1) return null;
      cols[row] = i % size;
    }
    if (cols.contains(-1)) return null;
    return cols;
  }

  LogicStep _conflictStep() {
    return LogicStep(
      kind: StepKind.conflict,
      technique: Technique.conflict,
      degree: 1,
      regionIds: failureRegion == null ? const [] : [failureRegion!],
      rows: failureKind == 'row' || failureKind == 'empty-row' ? [failureIndex!] : const [],
      cols: failureKind == 'column' || failureKind == 'empty-column' ? [failureIndex!] : const [],
      focusCells: _focusForFailure(),
      resultCells: const [],
      placesCat: false,
      contradictionKind: failureKind,
      contradictionIndex: failureIndex,
      contradictionRegion: failureRegion,
    );
  }

  List<int> _focusForFailure() {
    if (failureKind == 'touch') {
      final cats = <int>[];
      for (var i = 0; i < mark.length; i++) {
        if (mark[i] == 2) cats.add(i);
      }
      for (var a = 0; a < cats.length; a++) {
        for (var b = a + 1; b < cats.length; b++) {
          if (_touches(cats[a], cats[b])) return [cats[a], cats[b]];
        }
      }
    }
    if (failureKind == 'row' && failureIndex != null) {
      return [
        for (var col = 0; col < size; col++)
          if (mark[failureIndex! * size + col] == 2) failureIndex! * size + col,
      ];
    }
    if (failureKind == 'column' && failureIndex != null) {
      return [
        for (var row = 0; row < size; row++)
          if (mark[row * size + failureIndex!] == 2) row * size + failureIndex!,
      ];
    }
    if (failureRegion != null) {
      return [for (var i = 0; i < mark.length; i++) if (puzzle.regions[i] == failureRegion) i];
    }
    return const [];
  }

  LogicStep? _single() {
    final size = this.size;
    for (var row = 0; row < size; row++) {
      if (_lineHasCat(row: row)) continue;
      final cells = _unknownsInRow(row);
      if (cells.length == 1) {
        return LogicStep(
          kind: StepKind.singleRow,
          technique: Technique.single,
          degree: 1,
          regionIds: [puzzle.regions[cells.single]],
          rows: [row],
          cols: [cells.single % size],
          focusCells: cells,
          resultCells: cells,
          placesCat: true,
        );
      }
    }
    for (var col = 0; col < size; col++) {
      if (_lineHasCat(col: col)) continue;
      final cells = _unknownsInCol(col);
      if (cells.length == 1) {
        return LogicStep(
          kind: StepKind.singleColumn,
          technique: Technique.single,
          degree: 1,
          regionIds: [puzzle.regions[cells.single]],
          rows: [cells.single ~/ size],
          cols: [col],
          focusCells: cells,
          resultCells: cells,
          placesCat: true,
        );
      }
    }
    for (var region = 0; region < size; region++) {
      if (_regionHasCat(region)) continue;
      final cells = _unknownsInRegion(region);
      if (cells.length == 1) {
        return LogicStep(
          kind: StepKind.singleRegion,
          technique: Technique.single,
          degree: 1,
          regionIds: [region],
          rows: [cells.single ~/ size],
          cols: [cells.single % size],
          focusCells: cells,
          resultCells: cells,
          placesCat: true,
        );
      }
    }
    return null;
  }

  LogicStep? _neighbour() {
    final size = this.size;
    final total = puzzle.cellCount;
    for (var region = 0; region < size; region++) {
      if (_regionHasCat(region)) continue;
      final candidates = _unknownsInRegion(region);
      if (candidates.length < 2) continue;
      final banned = List<bool>.filled(total, true);
      for (final candidate in candidates) {
        final attacks = List<bool>.filled(total, false);
        for (var i = 0; i < total; i++) {
          if (i != candidate && _ruledOut(candidate, i)) attacks[i] = true;
        }
        for (var i = 0; i < total; i++) {
          if (!attacks[i]) banned[i] = false;
        }
      }
      final eliminated = <int>[];
      for (var i = 0; i < total; i++) {
        if (banned[i] && mark[i] == 0) eliminated.add(i);
      }
      if (eliminated.isEmpty) continue;
      return LogicStep(
        kind: StepKind.neighbour,
        technique: Technique.neighbour,
        degree: 1,
        regionIds: [region],
        rows: [for (final cell in candidates) cell ~/ size],
        cols: [for (final cell in candidates) cell % size],
        focusCells: candidates,
        resultCells: eliminated,
        placesCat: false,
      );
    }
    return null;
  }

  LogicStep? _lineSubsets({int minDegree = 1, int? maxDegree}) {
    final size = this.size;
    final rowBits = List<int>.filled(size, 0);
    final colBits = List<int>.filled(size, 0);
    final unsolvedRegions = <int>[];
    for (var region = 0; region < size; region++) {
      if (_regionHasCat(region)) continue;
      unsolvedRegions.add(region);
      for (final cell in _unknownsInRegion(region)) {
        rowBits[region] |= 1 << (cell ~/ size);
        colBits[region] |= 1 << (cell % size);
      }
    }
    final unsolvedRows = <int>[for (var row = 0; row < size; row++) if (!_lineHasCat(row: row)) row];
    final unsolvedCols = <int>[for (var col = 0; col < size; col++) if (!_lineHasCat(col: col)) col];
    final maxK = maxDegree ?? (size - 1);
    final limit = [
      unsolvedRegions.length,
      unsolvedRows.length,
      unsolvedCols.length,
      maxK,
    ].reduce((a, b) => a < b ? a : b);
    for (var k = minDegree; k <= limit; k++) {
      final byRegionRows = _regionsCoverLines(
        items: unsolvedRegions,
        degree: k,
        lineBits: rowBits,
        horizontal: true,
      );
      if (byRegionRows != null) return byRegionRows;
      final byRegionCols = _regionsCoverLines(
        items: unsolvedRegions,
        degree: k,
        lineBits: colBits,
        horizontal: false,
      );
      if (byRegionCols != null) return byRegionCols;
      final byRows = _linesCoverRegions(lines: unsolvedRows, degree: k, horizontal: true);
      if (byRows != null) return byRows;
      final byCols = _linesCoverRegions(lines: unsolvedCols, degree: k, horizontal: false);
      if (byCols != null) return byCols;
    }
    return null;
  }

  LogicStep? _regionsCoverLines({
    required List<int> items,
    required int degree,
    required List<int> lineBits,
    required bool horizontal,
  }) {
    LogicStep? found;
    _combinations(items, degree, (subset) {
      if (found != null) return true;
      var union = 0;
      for (final region in subset) {
        union |= lineBits[region];
      }
      final lines = _bits(union);
      if (lines.length < degree) {
        _fail('pigeon');
        found = _conflictStep();
        return true;
      }
      if (lines.length != degree) return false;
      final chosen = {for (final region in subset) region};
      final eliminated = <int>[];
      final focus = <int>[];
      for (final region in subset) {
        focus.addAll(_unknownsInRegion(region));
      }
      for (final line in lines) {
        for (var other = 0; other < size; other++) {
          final cell = horizontal ? line * size + other : other * size + line;
          if (mark[cell] != 0) continue;
          if (chosen.contains(puzzle.regions[cell])) continue;
          eliminated.add(cell);
        }
      }
      if (eliminated.isEmpty) return false;
      final ids = List<int>.from(subset);
      found = LogicStep(
        kind: _regionLineKind(horizontal: horizontal, degree: degree),
        technique: degree == 1 ? Technique.confinement : Technique.subset,
        degree: degree,
        regionIds: ids,
        rows: horizontal ? lines : const [],
        cols: horizontal ? const [] : lines,
        focusCells: focus,
        resultCells: eliminated,
        placesCat: false,
      );
      return true;
    });
    return found;
  }

  LogicStep? _linesCoverRegions({
    required List<int> lines,
    required int degree,
    required bool horizontal,
  }) {
    LogicStep? found;
    _combinations(lines, degree, (subset) {
      if (found != null) return true;
      final lineSet = subset.toSet();
      final regions = <int>{};
      final focus = <int>[];
      for (final line in subset) {
        for (var other = 0; other < size; other++) {
          final cell = horizontal ? line * size + other : other * size + line;
          if (mark[cell] != 0) continue;
          regions.add(puzzle.regions[cell]);
          focus.add(cell);
        }
      }
      if (regions.length < degree) {
        _fail('pigeon');
        found = _conflictStep();
        return true;
      }
      if (regions.length != degree) return false;
      final eliminated = <int>[];
      for (final region in regions) {
        for (final cell in _unknownsInRegion(region)) {
          final line = horizontal ? cell ~/ size : cell % size;
          if (!lineSet.contains(line)) eliminated.add(cell);
        }
      }
      if (eliminated.isEmpty) return false;
      final ids = regions.toList()..sort();
      final lineList = List<int>.from(subset);
      found = LogicStep(
        kind: _lineRegionKind(horizontal: horizontal, degree: degree),
        technique: degree == 1 ? Technique.confinement : Technique.subset,
        degree: degree,
        regionIds: ids,
        rows: horizontal ? lineList : const [],
        cols: horizontal ? const [] : lineList,
        focusCells: focus,
        resultCells: eliminated,
        placesCat: false,
      );
      return true;
    });
    return found;
  }

  StepKind _regionLineKind({required bool horizontal, required int degree}) {
    if (degree == 1) {
      return horizontal ? StepKind.regionInRow : StepKind.regionInColumn;
    }
    return horizontal ? StepKind.regionsInRows : StepKind.regionsInColumns;
  }

  StepKind _lineRegionKind({required bool horizontal, required int degree}) {
    if (degree == 1) {
      return horizontal ? StepKind.rowInRegion : StepKind.columnInRegion;
    }
    return horizontal ? StepKind.rowsInRegions : StepKind.columnsInRegions;
  }

  LogicStep? _contradiction() {
    final unknowns = <int>[for (var i = 0; i < mark.length; i++) if (mark[i] == 0) i];
    for (final cell in unknowns) {
      final probe = clone();
      probe.mark[cell] = 2;
      final failed = probe._solveEasy();
      if (!failed) continue;
      return LogicStep(
        kind: StepKind.contradiction,
        technique: Technique.contradiction,
        degree: 1,
        regionIds: [puzzle.regions[cell]],
        rows: [cell ~/ size],
        cols: [cell % size],
        focusCells: probe._focusForFailure(),
        resultCells: [cell],
        placesCat: false,
        contradictionKind: probe.failureKind,
        contradictionIndex: probe.failureIndex,
        contradictionRegion: probe.failureRegion,
      );
    }
    return null;
  }

  bool _solveEasy() {
    for (var guard = 0; guard < puzzle.cellCount * 2; guard++) {
      if (!propagate()) return true;
      if (solved) return false;
      final step = _single() ?? _lineSubsets(maxDegree: 1) ?? _neighbour() ?? _lineSubsets(minDegree: 2);
      if (step == null) return false;
      if (step.technique == Technique.conflict) return true;
      apply(step);
    }
    return false;
  }

  bool _lineHasCat({int? row, int? col}) {
    if (row != null) {
      for (var c = 0; c < size; c++) {
        if (mark[row * size + c] == 2) return true;
      }
    } else {
      for (var r = 0; r < size; r++) {
        if (mark[r * size + col!] == 2) return true;
      }
    }
    return false;
  }

  bool _regionHasCat(int region) {
    for (var i = 0; i < mark.length; i++) {
      if (puzzle.regions[i] == region && mark[i] == 2) return true;
    }
    return false;
  }

  List<int> _unknownsInRow(int row) {
    return [for (var col = 0; col < size; col++) if (mark[row * size + col] == 0) row * size + col];
  }

  List<int> _unknownsInCol(int col) {
    return [for (var row = 0; row < size; row++) if (mark[row * size + col] == 0) row * size + col];
  }

  List<int> _unknownsInRegion(int region) {
    return [for (var i = 0; i < mark.length; i++) if (puzzle.regions[i] == region && mark[i] == 0) i];
  }

  List<int> _bits(int mask) {
    final values = <int>[];
    var bit = 0;
    var rest = mask;
    while (rest != 0) {
      if ((rest & 1) == 1) values.add(bit);
      rest >>= 1;
      bit++;
    }
    return values;
  }

  void _combinations(List<int> items, int degree, bool Function(List<int> subset) body) {
    if (degree <= 0 || degree > items.length) return;
    final buffer = List<int>.filled(degree, 0);
    var stop = false;
    void walk(int start, int depth) {
      if (stop) return;
      if (depth == degree) {
        final copy = List<int>.from(buffer);
        if (body(copy)) stop = true;
        return;
      }
      for (var i = start; i <= items.length - (degree - depth); i++) {
        buffer[depth] = items[i];
        walk(i + 1, depth + 1);
        if (stop) return;
      }
    }

    walk(0, 0);
  }
}

Analysis analyzePuzzle(Puzzle puzzle, {bool allowContradiction = true}) {
  final state = LogicState(puzzle);
  final steps = <LogicStep>[];
  var rank = 0;
  for (var guard = 0; guard < puzzle.cellCount * 3; guard++) {
    if (state.solved) break;
    final step = state.next(allowContradiction: allowContradiction);
    if (step == null || step.technique == Technique.conflict) break;
    state.apply(step);
    steps.add(step);
    if (step.rank > rank) rank = step.rank;
  }
  final solved = state.solved;
  return Analysis(
    solved: solved,
    steps: steps,
    difficulty: Difficulty.fromRank(rank == 0 && solved ? 1 : rank),
    solution: solved ? state.solutionCols() : null,
  );
}

LogicStep? nextDeduction(Puzzle puzzle, List<int> marks, {bool allowContradiction = true}) {
  final state = LogicState.fromMarks(puzzle, marks);
  return state.next(allowContradiction: allowContradiction);
}

List<int> logicMarksFromBoard(List<CellMark> marks) {
  return [
    for (final mark in marks)
      switch (mark) {
        CellMark.cat => 2,
        CellMark.playerX || CellMark.autoX => 1,
        CellMark.empty || CellMark.keepOpen => 0,
      },
  ];
}
