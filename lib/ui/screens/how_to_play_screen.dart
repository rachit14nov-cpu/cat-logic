import 'package:flutter/widgets.dart';

import '../chrome.dart';
import '../glyphs.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = CatTheme.of(context).palette;
    final rules = [
      ('One each way', 'Place one cat in every row, every column, and every coloured region.'),
      ('No touching', 'Cats cannot touch, not even on a corner.'),
      ('Mark the empties', 'Tap a cell to cross it out. Double-tap to place a cat. Undo is unlimited.'),
      ('Hints explain', 'A hint tells you why a cell is forced or ruled out. It never just reveals a cat.'),
    ];
    return CatPage(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButtonBox(label: 'Back', onPressed: () => Navigator.of(context).pop(), child: backChevron(palette.ink)),
              const SizedBox(width: 12),
              Text('How to play', style: TextStyle(color: palette.ink, fontSize: 28, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: rules.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final rule = rules[index];
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: palette.line),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CatMark(size: 42, coat: palette.looks[index].color, ink: palette.ink),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(rule.$1, style: TextStyle(color: palette.ink, fontWeight: FontWeight.w700, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(rule.$2, style: TextStyle(color: palette.muted, height: 1.35)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
