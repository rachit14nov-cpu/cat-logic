import 'dart:typed_data';

import 'puzzle.dart';

/// Compact campaign/daily encoding. Region ids are nibbles, then the bytes are gzipped by the loader.
class LevelPack {
  static const campaignMagic = [0x43, 0x4c, 0x43, 0x31]; // CLC1
  static const dailyMagic = [0x43, 0x4c, 0x44, 0x31]; // CLD1

  static Uint8List encode(List<Level> levels, {required bool daily}) {
    final bytes = BytesBuilder(copy: false);
    bytes.add(daily ? dailyMagic : campaignMagic);
    bytes.addByte(levels.length >> 8);
    bytes.addByte(levels.length & 0xff);
    for (final level in levels) {
      if (level.size < 2 || level.size > 15) {
        throw FormatException('size ${level.size} does not fit in a nibble pack');
      }
      bytes.addByte(level.size);
      bytes.addByte(level.difficulty.index);
      var pending = -1;
      for (final region in level.regions) {
        if (region < 0 || region > 15) {
          throw FormatException('region $region does not fit in a nibble');
        }
        if (pending < 0) {
          pending = region;
        } else {
          bytes.addByte((pending << 4) | region);
          pending = -1;
        }
      }
      if (pending >= 0) bytes.addByte(pending << 4);
    }
    return bytes.toBytes();
  }

  static List<Level> decode(List<int> bytes, {required bool daily}) {
    if (bytes.length < 6) {
      throw FormatException('level pack is too short');
    }
    final magic = daily ? dailyMagic : campaignMagic;
    for (var i = 0; i < 4; i++) {
      if (bytes[i] != magic[i]) throw FormatException('unexpected level pack header');
    }
    final count = (bytes[4] << 8) | bytes[5];
    var offset = 6;
    final perSize = <int, int>{};
    final levels = <Level>[];
    for (var index = 0; index < count; index++) {
      if (offset + 2 > bytes.length) throw FormatException('truncated level header');
      final size = bytes[offset++];
      final difficultyIndex = bytes[offset++];
      if (difficultyIndex < 0 || difficultyIndex >= Difficulty.values.length) {
        throw FormatException('bad difficulty $difficultyIndex');
      }
      final cells = size * size;
      final packed = (cells + 1) >> 1;
      if (offset + packed > bytes.length) throw FormatException('truncated region data');
      final regions = <int>[];
      for (var cell = 0; cell < cells; cell++) {
        final byte = bytes[offset + (cell >> 1)];
        regions.add(cell.isEven ? (byte >> 4) & 0xf : byte & 0xf);
      }
      offset += packed;
      final number = (perSize[size] ?? 0) + 1;
      perSize[size] = number;
      final id = daily ? 'd-${number.toString().padLeft(3, '0')}' : '$size-${number.toString().padLeft(3, '0')}';
      levels.add(Level(id: id, size: size, difficulty: Difficulty.values[difficultyIndex], regions: regions));
    }
    return levels;
  }
}
