import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../data/progress_store.dart';
import '../chrome.dart';
import '../palettes.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.progress, super.key});

  final ProgressController progress;

  @override
  Widget build(BuildContext context) {
    final data = progress.data;
    final palette = CatTheme.of(context).palette;
    return CatPage(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButtonBox(label: 'Back', onPressed: () => Navigator.of(context).pop(), child: backChevron(palette.ink)),
              const SizedBox(width: 12),
              Text('Settings', style: TextStyle(color: palette.ink, fontSize: 28, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 18),
          Text('Appearance', style: TextStyle(color: palette.muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ChoiceRow(
            options: const [('system', 'System'), ('light', 'Light'), ('dark', 'Dark')],
            selected: data.themeMode,
            onSelected: (mode) => progress.update(data.copyWith(themeMode: mode)),
          ),
          const SizedBox(height: 18),
          Text('Palette', style: TextStyle(color: palette.muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final family in CatPalettes.families)
            _PaletteChoice(
              family: family,
              selected: data.paletteId == family.id,
              onTap: () => progress.update(data.copyWith(paletteId: family.id)),
            ),
          const SizedBox(height: 8),
          CatToggle(
            label: 'Show region patterns',
            value: data.patternsAlways,
            onChanged: (value) => progress.update(data.copyWith(patternsAlways: value)),
          ),
          CatToggle(
            label: 'Auto-mark blocked cells',
            value: data.autoMark,
            onChanged: (value) => progress.update(data.copyWith(autoMark: value)),
          ),
          const Spacer(),
          Text('Cat Logic', style: TextStyle(color: palette.ink, fontWeight: FontWeight.w700, fontSize: 16)),
          Text('Cat Logic: Star Battle Puzzle', style: TextStyle(color: palette.muted)),
          const SizedBox(height: 4),
          Text('Tinybit Labs', style: TextStyle(color: palette.ink, fontWeight: FontWeight.w600)),
          FutureBuilder<String>(
            future: rootBundle.loadString('config/application_id.txt'),
            builder: (context, snapshot) {
              final id = snapshot.data?.trim();
              if (id == null || id.isEmpty) return const SizedBox.shrink();
              return Text(id, style: TextStyle(color: palette.muted, fontSize: 13));
            },
          ),
        ],
      ),
    );
  }
}

class _PaletteChoice extends StatelessWidget {
  const _PaletteChoice({required this.family, required this.selected, required this.onTap});

  final PaletteFamily family;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final current = CatTheme.of(context).palette;
    final preview = CatPalettes.resolve(family.id, current.brightness);
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: current.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? current.accent : current.line, width: selected ? 2 : 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    family.colorBlindSafe ? '${family.label} · patterns' : family.label,
                    style: TextStyle(color: current.ink, fontWeight: FontWeight.w600),
                  ),
                ),
                for (final look in preview.looks.take(6))
                  Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(color: look.color, borderRadius: BorderRadius.circular(5)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
