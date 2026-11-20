import 'package:flutter/widgets.dart';

enum RegionPattern { dots, stripes, waves, crosshatch, rings, diagonal, plus, specks, grid, dashes }

class RegionLook {
  const RegionLook(this.name, this.color, this.pattern);

  final String name;
  final Color color;
  final RegionPattern pattern;
}

class CatPalette {
  const CatPalette({
    required this.id,
    required this.label,
    required this.brightness,
    required this.colorBlindSafe,
    required this.paper,
    required this.card,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.line,
    required this.looks,
  });

  final String id;
  final String label;
  final Brightness brightness;
  final bool colorBlindSafe;
  final Color paper;
  final Color card;
  final Color ink;
  final Color muted;
  final Color accent;
  final Color line;
  final List<RegionLook> looks;

  bool get dark => brightness == Brightness.dark;
}

class PaletteFamily {
  const PaletteFamily({required this.id, required this.label, required this.colorBlindSafe});

  final String id;
  final String label;
  final bool colorBlindSafe;
}

class CatPalettes {
  static const families = [
    PaletteFamily(id: 'meadow', label: 'Meadow', colorBlindSafe: false),
    PaletteFamily(id: 'tidepool', label: 'Tidepool', colorBlindSafe: false),
    PaletteFamily(id: 'beacon', label: 'Beacon', colorBlindSafe: true),
    PaletteFamily(id: 'linen', label: 'Linen', colorBlindSafe: true),
  ];

  static CatPalette resolve(String id, Brightness brightness) {
    return _all['$id-${brightness.name}'] ?? _all['meadow-${brightness.name}']!;
  }

  static final Map<String, CatPalette> _all = {
    for (final palette in _build()) '${palette.id}-${palette.brightness.name}': palette,
  };
}

List<CatPalette> _build() {
  const patterns = RegionPattern.values;
  List<RegionLook> looks(List<(String, int)> colors) {
    return [
      for (var i = 0; i < colors.length; i++) RegionLook(colors[i].$1, Color(colors[i].$2), patterns[i]),
    ];
  }

  CatPalette pack({
    required String id,
    required String label,
    required bool safe,
    required bool dark,
    required int paper,
    required int card,
    required int ink,
    required int muted,
    required int accent,
    required int line,
    required List<(String, int)> colors,
  }) {
    return CatPalette(
      id: id,
      label: label,
      brightness: dark ? Brightness.dark : Brightness.light,
      colorBlindSafe: safe,
      paper: Color(paper),
      card: Color(card),
      ink: Color(ink),
      muted: Color(muted),
      accent: Color(accent),
      line: Color(line),
      looks: looks(colors),
    );
  }

  const meadow = [
    ('orange', 0xFFF0A05A),
    ('sage', 0xFF8FB58A),
    ('sky', 0xFF8EB7D6),
    ('lilac', 0xFFC7B0D6),
    ('butter', 0xFFE6D48A),
    ('rose', 0xFFE7A8B5),
    ('mint', 0xFF9FCFC3),
    ('pebble', 0xFFD2C0AE),
    ('coral', 0xFFE39284),
    ('mist', 0xFFA9B4C9),
  ];
  const meadowDark = [
    ('orange', 0xFFE39A55),
    ('sage', 0xFF7EAA78),
    ('sky', 0xFF7EABC9),
    ('lilac', 0xFFB9A0CC),
    ('butter', 0xFFD4C27A),
    ('rose', 0xFFD996A6),
    ('mint', 0xFF8FC0B4),
    ('pebble', 0xFFC2B09E),
    ('coral', 0xFFD48476),
    ('mist', 0xFF98A4BA),
  ];
  const tide = [
    ('foam', 0xFFF2E3C6),
    ('kelp', 0xFF6E9A86),
    ('lagoon', 0xFF6AA8B5),
    ('sand', 0xFFE2C39A),
    ('shell', 0xFFE7B7A4),
    ('cove', 0xFF5E7C91),
    ('blossom', 0xFFC98B8B),
    ('glass', 0xFFA9CBB7),
    ('drift', 0xFFC4B49A),
    ('slate', 0xFF7E8C9A),
  ];
  const tideDark = [
    ('foam', 0xFFE6D2AE),
    ('kelp', 0xFF7FB39A),
    ('lagoon', 0xFF7EC0CC),
    ('sand', 0xFFD4B48A),
    ('shell', 0xFFE0A896),
    ('cove', 0xFF8AA6B8),
    ('blossom', 0xFFD7A0A0),
    ('glass', 0xFFB7D6C6),
    ('drift', 0xFFD2C2A8),
    ('slate', 0xFFAEBBC6),
  ];
  const beacon = [
    ('ink', 0xFF222222),
    ('gold', 0xFFE69F00),
    ('sky', 0xFF56B4E9),
    ('green', 0xFF009E73),
    ('yellow', 0xFFF0E442),
    ('blue', 0xFF0072B2),
    ('vermilion', 0xFFD55E00),
    ('purple', 0xFFCC79A7),
    ('gray', 0xFF6E6E6E),
    ('umber', 0xFF8A6A12),
  ];
  const beaconDark = [
    ('ink', 0xFFE8E8E8),
    ('gold', 0xFFE69F00),
    ('sky', 0xFF7EC8F0),
    ('green', 0xFF3CB89A),
    ('yellow', 0xFFF0E442),
    ('blue', 0xFF6BA3E0),
    ('vermilion', 0xFFE07A45),
    ('purple', 0xFFE09BC4),
    ('gray', 0xFFB0B0B0),
    ('umber', 0xFFE0C36A),
  ];
  const linen = [
    ('navy', 0xFF1F4E79),
    ('orange', 0xFFE67E22),
    ('black', 0xFF1A1A1A),
    ('yellow', 0xFFF4D35E),
    ('cyan', 0xFF2EC4B6),
    ('red', 0xFFC44536),
    ('teal', 0xFF1B7F7A),
    ('magenta', 0xFFB84A86),
    ('olive', 0xFF6B8F3C),
    ('brown', 0xFF8D6A4A),
  ];
  const linenDark = [
    ('navy', 0xFF8FB4D6),
    ('orange', 0xFFF0A15A),
    ('black', 0xFFF2F2F2),
    ('yellow', 0xFFF6E28A),
    ('cyan', 0xFF7FE0D6),
    ('red', 0xFFE07A6E),
    ('teal', 0xFF6FCFC6),
    ('magenta', 0xFFE39BC4),
    ('olive', 0xFFB7D48A),
    ('brown', 0xFFD2B497),
  ];

  return [
    pack(
      id: 'meadow',
      label: 'Meadow',
      safe: false,
      dark: false,
      paper: 0xFFF6F1E8,
      card: 0xFFFFFBF5,
      ink: 0xFF3E342C,
      muted: 0xFF7A6E63,
      accent: 0xFFC4623A,
      line: 0xFFE4D8C8,
      colors: meadow,
    ),
    pack(
      id: 'meadow',
      label: 'Meadow',
      safe: false,
      dark: true,
      paper: 0xFF1C1916,
      card: 0xFF2A241F,
      ink: 0xFFF4EDE4,
      muted: 0xFFB7AA9E,
      accent: 0xFFF0A57A,
      line: 0xFF3A332C,
      colors: meadowDark,
    ),
    pack(
      id: 'tidepool',
      label: 'Tidepool',
      safe: false,
      dark: false,
      paper: 0xFFF3F6F4,
      card: 0xFFFBFFFC,
      ink: 0xFF24312E,
      muted: 0xFF5E736C,
      accent: 0xFF3E7C78,
      line: 0xFFD5E2DC,
      colors: tide,
    ),
    pack(
      id: 'tidepool',
      label: 'Tidepool',
      safe: false,
      dark: true,
      paper: 0xFF14201E,
      card: 0xFF1E2C29,
      ink: 0xFFE7F3EF,
      muted: 0xFFA9C2BA,
      accent: 0xFF8FD0C6,
      line: 0xFF2C403C,
      colors: tideDark,
    ),
    pack(
      id: 'beacon',
      label: 'Beacon',
      safe: true,
      dark: false,
      paper: 0xFFF7F5F2,
      card: 0xFFFFFFFF,
      ink: 0xFF1A1A1A,
      muted: 0xFF4A4A4A,
      accent: 0xFF0072B2,
      line: 0xFFD9D4CC,
      colors: beacon,
    ),
    pack(
      id: 'beacon',
      label: 'Beacon',
      safe: true,
      dark: true,
      paper: 0xFF121212,
      card: 0xFF1E1E1E,
      ink: 0xFFF5F5F5,
      muted: 0xFFC8C8C8,
      accent: 0xFF7EC8F0,
      line: 0xFF333333,
      colors: beaconDark,
    ),
    pack(
      id: 'linen',
      label: 'Linen',
      safe: true,
      dark: false,
      paper: 0xFFFBF7F0,
      card: 0xFFFFFFFF,
      ink: 0xFF1C1C1C,
      muted: 0xFF4E4A45,
      accent: 0xFF1F4E79,
      line: 0xFFE6DDD0,
      colors: linen,
    ),
    pack(
      id: 'linen',
      label: 'Linen',
      safe: true,
      dark: true,
      paper: 0xFF161411,
      card: 0xFF241F1A,
      ink: 0xFFF7F1E8,
      muted: 0xFFD0C6BA,
      accent: 0xFFF0A15A,
      line: 0xFF3A332C,
      colors: linenDark,
    ),
  ];
}
