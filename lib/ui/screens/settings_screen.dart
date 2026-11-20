import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../ads/ad_units.dart';
import '../../core/economy.dart';
import '../../data/progress_store.dart';
import '../../services/app_services.dart';
import '../chrome.dart';
import '../palettes.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.progress, required this.services, super.key});

  final ProgressController progress;
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final data = progress.data;
    final palette = CatTheme.of(context).palette;
    return CatPage(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: ListView(
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
          CatToggle(
            label: 'Sound',
            value: data.soundEnabled,
            onChanged: (value) => progress.update(data.copyWith(soundEnabled: value)),
          ),
          CatToggle(
            label: 'Haptics',
            value: data.hapticsEnabled,
            onChanged: (value) => progress.update(data.copyWith(hapticsEnabled: value)),
          ),
          const SizedBox(height: 18),
          Text('Hints', style: TextStyle(color: palette.muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            data.removeAds
                ? '${data.hintBalance} hints saved. Banners and breaks are off. A hint ad is still optional.'
                : '${data.hintBalance} hints saved. A wrong check on a story puzzle spends a heart.',
            style: TextStyle(color: palette.ink, height: 1.35),
          ),
          const SizedBox(height: 8),
          for (final product in StoreCatalog.products)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SoftButton(
                label: '${product.title} · ${services.iap.priceLabel(product.id)}',
                primary: product.removeAds,
                onPressed: () async {
                  final started = await services.iap.purchase(product.id);
                  if (!started && context.mounted) {
                    _note(context, services.iap.storeAvailable ? 'That product is not available yet.' : 'The Play Store is not connected on this device.');
                  }
                },
              ),
            ),
          SoftButton(
            label: 'Restore purchases',
            onPressed: () async {
              await services.iap.restore();
              if (context.mounted) _note(context, 'Looking for previous purchases.');
            },
          ),
          const SizedBox(height: 18),
          Text('Privacy', style: TextStyle(color: palette.muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SoftButton(
            label: 'Privacy policy',
            onPressed: () => launchUrl(Uri.parse(LegalLinks.privacyPolicy), mode: LaunchMode.externalApplication),
          ),
          const SizedBox(height: 8),
          SoftButton(
            label: 'Privacy options',
            onPressed: () async {
              if (!services.ads.privacyOptionsRequired) {
                if (context.mounted) _note(context, 'Privacy options are not required in this region.');
                return;
              }
              await services.ads.showPrivacyOptions();
            },
          ),
          const SizedBox(height: 24),
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

void _note(BuildContext context, String message) {
  final palette = CatTheme.of(context).palette;
  final overlay = Overlay.of(context);
  final entry = OverlayEntry(
    builder: (context) => Positioned(
      left: 24,
      right: 24,
      bottom: 32,
      child: DecoratedBox(
        decoration: BoxDecoration(color: palette.ink, borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text(message, style: TextStyle(color: palette.paper)),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  Future<void>.delayed(const Duration(seconds: 2), entry.remove);
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
