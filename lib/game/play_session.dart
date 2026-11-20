import '../core/deduction.dart';
import '../core/economy.dart';
import '../core/explain.dart';
import '../core/puzzle.dart';
import '../core/rules.dart';

class PlaySession {
  PlaySession({required this.puzzle, required this.autoMark, this.trackHearts = true, int? hearts})
    : hearts = hearts ?? (trackHearts ? StoreCatalog.heartsPerPuzzle : 0),
      marks = List<CellMark>.filled(puzzle.cellCount, CellMark.empty) {
    clock.start();
  }

  final Puzzle puzzle;
  final bool trackHearts;
  bool autoMark;
  int hearts;
  List<CellMark> marks;
  final List<List<CellMark>> history = [];
  final Stopwatch clock = Stopwatch();
  bool won = false;
  LogicStep? hint;
  String? hintText;
  Assessment? report;

  void tap(int index) {
    if (won) return;
    _remember();
    switch (marks[index]) {
      case CellMark.empty:
        marks[index] = CellMark.playerX;
        _refresh(catsChanged: false);
      case CellMark.playerX:
      case CellMark.keepOpen:
        marks[index] = CellMark.empty;
        _refresh(catsChanged: false);
      case CellMark.autoX:
        marks[index] = CellMark.keepOpen;
        _refresh(catsChanged: false);
      case CellMark.cat:
        marks[index] = CellMark.empty;
        _refresh(catsChanged: true);
    }
  }

  void doubleTap(int index) {
    if (won) return;
    _remember();
    if (marks[index] == CellMark.cat) {
      marks[index] = CellMark.empty;
    } else {
      marks[index] = CellMark.cat;
    }
    _refresh(catsChanged: true);
  }

  void undo() {
    if (history.isEmpty) return;
    marks = history.removeLast();
    hint = null;
    hintText = null;
    report = null;
    _syncWin();
    if (!won) clock.start();
  }

  void restart() {
    if (marks.every((mark) => mark == CellMark.empty) && history.isEmpty) return;
    _remember();
    marks = List<CellMark>.filled(puzzle.cellCount, CellMark.empty);
    hint = null;
    hintText = null;
    report = null;
    won = false;
    if (trackHearts) hearts = StoreCatalog.heartsPerPuzzle;
    clock
      ..reset()
      ..start();
  }

  void showHint(List<String> names) {
    report = null;
    final step = nextDeduction(puzzle, logicMarksFromBoard(marks));
    hint = step;
    hintText = step == null
        ? 'Nothing new from these marks. Undo a guess, or sit with a cell you are sure about.'
        : explainStep(step, names);
  }

  void dismissHint() {
    hint = null;
    hintText = null;
  }

  HeartCheck check(List<String> names) {
    hint = null;
    hintText = null;
    final assessment = assessCats(puzzle, _cats(), names);
    final verdict = judgeCheck(
      trackHearts: trackHearts,
      hearts: hearts,
      won: assessment.won,
      mistake: assessment.issues.isNotEmpty,
    );
    switch (verdict) {
      case HeartCheck.won:
        report = assessment;
        won = true;
        clock.stop();
      case HeartCheck.free:
        report = assessment;
      case HeartCheck.charged:
        hearts -= 1;
        report = assessment;
      case HeartCheck.needsHeart:
        report = null;
    }
    return verdict;
  }

  void refillHeart() {
    hearts = refillHeartCount(hearts);
  }

  void _remember() {
    history.add(List<CellMark>.from(marks));
    hint = null;
    hintText = null;
    report = null;
  }

  void _refresh({required bool catsChanged}) {
    if (catsChanged) {
      for (var index = 0; index < marks.length; index++) {
        if (marks[index] == CellMark.keepOpen) marks[index] = CellMark.empty;
      }
    }
    marks = withAutoMarks(puzzle, marks, enabled: autoMark);
    _syncWin();
  }

  void _syncWin() {
    final cats = _cats();
    if (cats.length != puzzle.size) {
      won = false;
      return;
    }
    final result = assessCats(puzzle, cats, List<String>.filled(puzzle.size, 'region'));
    won = result.won;
    if (won) clock.stop();
  }

  List<int> _cats() {
    return [for (var index = 0; index < marks.length; index++) if (marks[index] == CellMark.cat) index];
  }
}

String formatClock(Duration duration) {
  final minutes = duration.inMinutes.remainder(100);
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
