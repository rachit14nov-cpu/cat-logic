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
    PaletteFamily(id: 'standard', label: 'Standard', colorBlindSafe: false),
    PaletteFamily(id: 'colorblind', label: 'Color-blind', colorBlindSafe: true),
  ];

  static CatPalette resolve(String id, Brightness brightness) {
    final mapped = switch (id) {
      'colorblind' || 'beacon' || 'linen' => 'colorblind',
      _ => 'standard',
    };
    return _all['$mapped-${brightness.name}']!;
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

  const standard = [
    ('terracotta', 0xFFC4623A),
    ('denim', 0xFF6E8CA8),
    ('ochre', 0xFFC6A15A),
    ('teal', 0xFF3E8C84),
    ('sage', 0xFF7FA37A),
    ('sand', 0xFFD7C09A),
    ('clay', 0xFFA86A45),
    ('slate', 0xFF5E7388),
    ('olive', 0xFF8A8F4E),
    ('cocoa', 0xFF8C6850),
  ];
  const standardDark = [
    ('terracotta', 0xFFD47852),
    ('denim', 0xFF8EACC4),
    ('ochre', 0xFFD4B56E),
    ('teal', 0xFF5EAAA2),
    ('sage', 0xFF97B892),
    ('sand', 0xFFE2CBA8),
    ('clay', 0xFFC4845C),
    ('slate', 0xFF7E94A8),
    ('olive', 0xFFA8AD6A),
    ('cocoa', 0xFFB08870),
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
  return [
    pack(
      id: 'standard',
      label: 'Standard',
      safe: false,
      dark: false,
      paper: 0xFFF6F1E8,
      card: 0xFFFFFBF5,
      ink: 0xFF3E342C,
      muted: 0xFF7A6E63,
      accent: 0xFFC4623A,
      line: 0xFFE4D8C8,
      colors: standard,
    ),
    pack(
      id: 'standard',
      label: 'Standard',
      safe: false,
      dark: true,
      paper: 0xFF1C1916,
      card: 0xFF2A241F,
      ink: 0xFFF4EDE4,
      muted: 0xFFB7AA9E,
      accent: 0xFFE08A62,
      line: 0xFF3A332C,
      colors: standardDark,
    ),
    pack(
      id: 'colorblind',
      label: 'Color-blind',
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
      id: 'colorblind',
      label: 'Color-blind',
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
  ];
}
