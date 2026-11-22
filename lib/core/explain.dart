import 'puzzle.dart';

/// What a deduction step is asking the player to notice.
enum StepKind {
  singleRow,
  singleColumn,
  singleRegion,
  regionInRow,
  regionInColumn,
  rowInRegion,
  columnInRegion,
  regionsInRows,
  regionsInColumns,
  rowsInRegions,
  columnsInRegions,
  neighbour,
  contradiction,
  conflict,
}

enum Technique { single, confinement, neighbour, subset, contradiction, conflict }

/// One human-readable deduction.
class LogicStep {
  const LogicStep({
    required this.kind,
    required this.technique,
    required this.degree,
    required this.regionIds,
    required this.rows,
    required this.cols,
    required this.focusCells,
    required this.resultCells,
    required this.placesCat,
    this.contradictionKind,
    this.contradictionIndex,
    this.contradictionRegion,
  });

  final StepKind kind;
  final Technique technique;
  final int degree;
  final List<int> regionIds;
  final List<int> rows;
  final List<int> cols;
  final List<int> focusCells;
  final List<int> resultCells;
  final bool placesCat;
  final String? contradictionKind;
  final int? contradictionIndex;
  final int? contradictionRegion;

  int get rank {
    switch (technique) {
      case Technique.single:
        return 1;
      case Technique.confinement:
      case Technique.neighbour:
        return 2;
      case Technique.subset:
        return degree >= 3 ? 4 : 3;
      case Technique.contradiction:
        return 4;
      case Technique.conflict:
        return 0;
    }
  }

  String get techniqueLabel => switch (technique) {
    Technique.single => 'Only one spot',
    Technique.confinement => 'Fits in one line',
    Technique.neighbour => 'Touching paws',
    Technique.subset => 'Shared lines',
    Technique.contradiction => 'What if',
    Technique.conflict => 'These marks clash',
  };
}

class Analysis {
  const Analysis({
    required this.solved,
    required this.steps,
    required this.difficulty,
    required this.solution,
  });

  final bool solved;
  final List<LogicStep> steps;
  final Difficulty difficulty;
  final List<int>? solution;
}

String explainStep(LogicStep step, List<String> regionNames) {
  String regionName(int id) => regionNames[id];
  String regionPhrase(List<int> ids) {
    final names = [for (final id in ids) regionName(id)];
    if (names.length == 1) return 'The ${names.single} region';
    return 'The ${joinWords(names)} regions';
  }

  final rows = step.rows;
  final cols = step.cols;
  switch (step.kind) {
    case StepKind.singleRow:
      return 'Row ${rows.single + 1} has only one cell left that can hold a cat.';
    case StepKind.singleColumn:
      return 'Column ${cols.single + 1} has only one cell left that can hold a cat.';
    case StepKind.singleRegion:
      return 'The ${regionName(step.regionIds.single)} region has only one cell left for its cat.';
    case StepKind.regionInRow:
      final row = rows.single + 1;
      return '${cap(regionName(step.regionIds.single))} fits only in row $row, so no other cell in row $row can hold a cat.';
    case StepKind.regionInColumn:
      final column = cols.single + 1;
      return '${cap(regionName(step.regionIds.single))} fits only in column $column, so no other cell in column $column can hold a cat.';
    case StepKind.rowInRegion:
      return 'Row ${rows.single + 1} can only hold a cat in the ${regionName(step.regionIds.single)} region, so the rest of that region can\'t hold a cat.';
    case StepKind.columnInRegion:
      return 'Column ${cols.single + 1} can only hold a cat in the ${regionName(step.regionIds.single)} region, so the rest of that region can\'t hold a cat.';
    case StepKind.regionsInRows:
      return '${regionPhrase(step.regionIds)} only fit in ${numberList('row', rows)}, so other cells in those rows can\'t hold a cat.';
    case StepKind.regionsInColumns:
      return '${regionPhrase(step.regionIds)} only fit in ${numberList('column', cols)}, so other cells in those columns can\'t hold a cat.';
    case StepKind.rowsInRegions:
      return '${cap(numberList('row', rows))} only have room in the ${joinWords([for (final id in step.regionIds) regionName(id)])} regions, so the rest of those regions can\'t hold a cat.';
    case StepKind.columnsInRegions:
      return '${cap(numberList('column', cols))} only have room in the ${joinWords([for (final id in step.regionIds) regionName(id)])} regions, so the rest of those regions can\'t hold a cat.';
    case StepKind.neighbour:
      final where = step.resultCells.length == 1 ? 'this cell' : 'these cells';
      final tail = step.resultCells.length == 1 ? 'it can\'t hold a cat' : 'they can\'t hold a cat';
      return 'Every possible cat in the ${regionName(step.regionIds.single)} region conflicts with $where, so $tail.';
    case StepKind.contradiction:
      return _contradictionSentence(step, regionName);
    case StepKind.conflict:
      return _conflictSentence(step, regionName);
  }
}

String _contradictionSentence(LogicStep step, String Function(int id) regionName) {
  final lead = switch (step.contradictionKind) {
    'row' || 'empty-row' => 'row ${step.contradictionIndex! + 1} would have nowhere left',
    'column' || 'empty-column' => 'column ${step.contradictionIndex! + 1} would have nowhere left',
    'region' || 'empty-region' => 'the ${regionName(step.contradictionRegion!)} region would have nowhere left',
    'touch' => 'it would touch another cat',
    'pigeon' => 'a group of regions would have too few lines left',
    _ => 'the board would run out of room',
  };
  return 'If a cat sat here, $lead. So this cell can\'t hold a cat.';
}

String _conflictSentence(LogicStep step, String Function(int id) regionName) {
  return switch (step.contradictionKind) {
    'row' => 'Row ${step.contradictionIndex! + 1} already has two cats, so one of them has to move.',
    'column' => 'Column ${step.contradictionIndex! + 1} already has two cats, so one of them has to move.',
    'region' => 'The ${regionName(step.contradictionRegion!)} region already has two cats, so one of them has to move.',
    'touch' => 'Two cats are touching, even on a corner, so one of them has to move.',
    'empty-row' => 'Row ${step.contradictionIndex! + 1} has nowhere left for a cat.',
    'empty-column' => 'Column ${step.contradictionIndex! + 1} has nowhere left for a cat.',
    'empty-region' => 'The ${regionName(step.contradictionRegion!)} region has nowhere left for a cat.',
    _ => 'These marks can\'t all be right.',
  };
}

String joinWords(List<String> words) {
  if (words.isEmpty) return '';
  if (words.length == 1) return words.single;
  if (words.length == 2) return '${words[0]} and ${words[1]}';
  return '${words.sublist(0, words.length - 1).join(', ')}, and ${words.last}';
}

String numberList(String noun, List<int> zeroBased) {
  final labels = [for (final value in zeroBased) '${value + 1}'];
  final plural = labels.length != 1;
  final name = plural ? '${noun}s' : noun;
  return '$name ${joinWords(labels)}';
}

String cap(String text) => text.isEmpty ? text : '${text[0].toUpperCase()}${text.substring(1)}';
