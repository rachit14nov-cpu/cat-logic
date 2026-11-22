import 'package:cat_logic/core/puzzle.dart';
import 'package:cat_logic/game/play_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final puzzle = Puzzle(5, List<int>.generate(25, (index) => index ~/ 5));

  test('double-tap places a cat and auto-mark blocks the row', () {
    final session = PlaySession(puzzle: puzzle, autoMark: true);
    session.doubleTap(0);
    expect(session.marks[0], CellMark.cat);
    expect(session.marks[1], CellMark.autoX);
    expect(session.marks[5], CellMark.autoX);
  });

  test('tap marks an x, and undo restores the cell', () {
    final session = PlaySession(puzzle: puzzle, autoMark: true);
    session.tap(2);
    expect(session.marks[2], CellMark.playerX);
    session.undo();
    expect(session.marks[2], CellMark.empty);
    expect(session.history, isEmpty);
  });

  test('auto-mark can be turned off', () {
    final session = PlaySession(puzzle: puzzle, autoMark: false);
    session.doubleTap(0);
    expect(session.marks[1], CellMark.empty);
  });
}