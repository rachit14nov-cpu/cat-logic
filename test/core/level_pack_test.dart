import 'dart:io';

import 'package:cat_logic/core/level_pack.dart';
import 'package:cat_logic/core/puzzle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the nibble pack round-trips a board', () {
    final level = Level(
      id: 'ignored',
      size: 5,
      difficulty: Difficulty.cozy,
      regions: List<int>.generate(25, (index) => index % 5),
    );
    final decoded = LevelPack.decode(LevelPack.encode([level], daily: false), daily: false);
    expect(decoded.single.id, '5-001');
    expect(decoded.single.difficulty, Difficulty.cozy);
    expect(decoded.single.regions, level.regions);
    final zipped = gzip.encode(LevelPack.encode([level], daily: true));
    final again = LevelPack.decode(gzip.decode(zipped), daily: true);
    expect(again.single.id, 'd-001');
  });
}
