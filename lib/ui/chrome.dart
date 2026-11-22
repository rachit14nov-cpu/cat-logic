import 'package:flutter/widgets.dart';

import 'glyphs.dart';
import 'palettes.dart';

class CatTheme extends InheritedWidget {
  const CatTheme({required this.palette, required this.patterns, required super.child, super.key});

  final CatPalette palette;
  final bool patterns;

  static CatTheme of(BuildContext context) {
    final theme = context.dependOnInheritedWidgetOfExactType<CatTheme>();
    assert(theme != null, 'CatTheme missing');
    return theme!;
  }

  @override
  bool updateShouldNotify(CatTheme oldWidget) => oldWidget.palette != palette || oldWidget.patterns != patterns;
}

class CatPage extends StatelessWidget {
  const CatPage({required this.child, this.padding = const EdgeInsets.symmetric(horizontal: 20), super.key});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final palette = CatTheme.of(context).palette;
    return RepaintBoundary(
      key: const ValueKey('shot-root'),
      child: ColoredBox(
        color: palette.paper,
        child: SafeArea(
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class SoftButton extends StatelessWidget {
  const SoftButton({
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.expand = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final palette = CatTheme.of(context).palette;
    final enabled = onPressed != null;
    final background = primary ? palette.accent : palette.card;
    final foreground = primary ? _onAccent(palette) : palette.ink;
    final button = Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        onTap: onPressed,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: enabled ? background : background.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(18),
            border: primary ? null : Border.all(color: palette.line),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: foreground, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
    if (!expand) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}

Color _onAccent(CatPalette palette) {
  return palette.accent.computeLuminance() > 0.6 ? palette.ink : const Color(0xFFFFFBF7);
}

class IconButtonBox extends StatelessWidget {
  const IconButtonBox({required this.label, required this.child, required this.onPressed, super.key});

  final String label;
  final Widget child;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = CatTheme.of(context).palette;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: GestureDetector(
        onTap: onPressed,
        child: Opacity(
          opacity: onPressed == null ? 0.35 : 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.line),
            ),
            child: SizedBox(width: 48, height: 48, child: Center(child: child)),
          ),
        ),
      ),
    );
  }
}

class DrawnIcon extends StatelessWidget {
  const DrawnIcon({required this.painter, this.size = 22, super.key});

  final void Function(Canvas canvas, Rect rect, Color color) painter;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = CatTheme.of(context).palette.ink;
    return CustomPaint(
      size: Size.square(size),
      painter: _CallbackPainter(painter, color),
    );
  }
}

class _CallbackPainter extends CustomPainter {
  _CallbackPainter(this.painter, this.color);

  final void Function(Canvas canvas, Rect rect, Color color) painter;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) => painter(canvas, Offset.zero & size, color);

  @override
  bool shouldRepaint(covariant _CallbackPainter oldDelegate) => oldDelegate.color != color;
}

class CatToggle extends StatelessWidget {
  const CatToggle({required this.label, required this.value, required this.onChanged, super.key});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = CatTheme.of(context).palette;
    return Semantics(
      toggled: value,
      button: true,
      label: label,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(label, style: TextStyle(color: palette.ink, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 52,
                height: 32,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: value ? palette.accent : palette.line,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Align(
                  alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(color: palette.card, borderRadius: BorderRadius.circular(13)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChoiceRow extends StatelessWidget {
  const ChoiceRow({required this.options, required this.selected, required this.onSelected, super.key});

  final List<(String, String)> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = CatTheme.of(context).palette;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          GestureDetector(
            onTap: () => onSelected(option.$1),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: option.$1 == selected ? palette.accent : palette.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: option.$1 == selected ? palette.accent : palette.line),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Text(
                  option.$2,
                  style: TextStyle(
                    color: option.$1 == selected ? _onAccent(palette) : palette.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

Widget backChevron(Color color) {
  return CustomPaint(
    size: const Size.square(22),
    painter: _CallbackPainter(paintChevron, color),
  );
}
