import 'package:cat_logic/core/deduction.dart';
import 'package:cat_logic/core/explain.dart';
import 'package:cat_logic/core/puzzle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const names = ['orange', 'sage', 'sky', 'lilac', 'butter'];

  test('a region confined to one column explains the elimination', () {
    final puzzle = Puzzle(5, const [
      1, 1, 0, 2, 2, //
      1, 1, 0, 2, 2, //
      1, 3, 0, 2, 2, //
      3, 3, 3, 4, 4, //
      3, 3, 4, 4, 4,
    ]);
    final step = LogicState(puzzle).next(allowContradiction: false);
    expect(step, isNotNull);
    expect(step!.kind, StepKind.regionInColumn);
    expect(step.regionIds, [0]);
    expect(step.cols, [2]);
    expect(step.resultCells, containsAll([3 * 5 + 2, 4 * 5 + 2]));
    expect(
      explainStep(step, names),
      "The orange region only fits in column 3, so the other cells in column 3 can't hold a cat.",
    );
    expect(explainStep(step, names), isNot(contains('Place a cat')));
  });

  test('a row confined to one region clears the rest of that region', () {
    final puzzle = Puzzle(5, const [
      0, 0, 0, 0, 0, //
      0, 1, 1, 2, 2, //
      3, 1, 1, 2, 2, //
      3, 3, 4, 4, 2, //
      3, 3, 4, 4, 4,
    ]);
    final step = LogicState(puzzle).next(allowContradiction: false);
    expect(step, isNotNull);
    expect(step!.kind, StepKind.rowInRegion);
    expect(
      explainStep(step, names),
      "Row 1 can only hold a cat in the orange region, so the rest of that region can't hold a cat.",
    );
  });

  test('every open cell in a region can rule a neighbour out', () {
    final puzzle = Puzzle(4, const [
      0, 0, 1, 2, //
      0, 1, 1, 2, //
      3, 3, 2, 3, //
      3, 2, 3, 3,
    ]);
    final step = LogicState(puzzle).next(allowContradiction: false);
    expect(step!.kind, StepKind.neighbour);
    expect(
      explainStep(step, names),
      "Every possible cat in the orange region conflicts with this cell, so it can't hold a cat.",
    );
  });

  test('two regions sharing two rows eliminate the other cells there', () {
    final puzzle = Puzzle(4, const [
      0, 1, 0, 1, //
      2, 2, 3, 2, //
      2, 3, 3, 3, //
      0, 1, 3, 3,
    ]);
    final state = LogicState(puzzle);
    final steps = <LogicStep>[];
    for (var i = 0; i < 20; i++) {
      final step = state.next(allowContradiction: false);
      if (step == null || step.technique == Technique.conflict) break;
      steps.add(step);
      state.apply(step);
    }
    final subset = steps.where((step) => step.kind == StepKind.regionsInRows);
    expect(subset, isNotEmpty);
    expect(explainStep(subset.first, names), contains("can't hold a cat"));
    expect(explainStep(subset.first, names), contains('orange'));
    expect(explainStep(subset.first, names), contains('sage'));
  });

  test('a what-if removes a cell that leaves a column homeless', () {
    final puzzle = Puzzle(4, const [
      1, 3, 2, 1, //
      0, 1, 0, 2, //
      1, 3, 2, 3, //
      2, 3, 0, 0,
    ]);
    expect(LogicState(puzzle).next(allowContradiction: false), isNull);
    final step = LogicState(puzzle).next(allowContradiction: true);
    expect(step!.technique, Technique.contradiction);
    expect(step.resultCells, [0]);
    expect(explainStep(step, names), contains('If a cat sat here'));
    expect(explainStep(step, names), contains("can't hold a cat"));
    expect(explainStep(step, names), contains('nowhere left'));
  });
}
