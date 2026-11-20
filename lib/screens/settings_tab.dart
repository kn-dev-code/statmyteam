import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../state/settings_scope.dart';
import '../state/stats_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/stats_widgets.dart';

/// Appearance and data-source info, shown as the last tab on the home nav.
class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = SettingsScope.of(context);
    final repo = StatsScope.of(context);

    return Scaffold(
      appBar: PillAppBar(title: l10n.settingsTitle),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            FloatingNavBar.clearance,
          ),
          children: [
            SectionTitle(l10n.appearance, subtitle: l10n.appearanceSubtitle),
            Row(
              children: [
                for (final mode in const [
                  ThemeMode.system,
                  ThemeMode.light,
                  ThemeMode.dark,
                ]) ...[
                  if (mode != ThemeMode.system) const SizedBox(width: 10),
                  Expanded(
                    child: _ModeCard(
                      mode: mode,
                      label: l10n.themeMode(mode.name),
                      selected: settings.themeMode == mode,
                      onTap: () => saveWithFeedback(
                        context,
                        () => settings.setThemeMode(mode),
                        failureMessage: l10n.themeSaveFailed,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SectionTitle(l10n.dataSection),
            StatCard(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: context.colors.surfaceHigh,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      repo.isLive
                          ? Icons.cloud_done_outlined
                          : Icons.science_outlined,
                      color: context.colors.text,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          repo.isLive ? l10n.liveData : l10n.sampleData,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          !repo.isLive
                              ? l10n.settingsSampleOnly
                              : repo.sampleLeagues.isEmpty
                              ? l10n.settingsAllLive
                              : l10n.settingsMixed(
                                  l10n.leagues(repo.liveLeagues),
                                  l10n.leagues(repo.sampleLeagues),
                                  repo.sampleLeagues.length,
                                ),
                          style: TextStyle(
                            color: context.colors.muted,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A selectable card with a miniature preview of the palette it applies.
class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final ThemeMode mode;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget preview(AppPalette p) => DecoratedBox(
      decoration: BoxDecoration(color: p.background),
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 22,
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(5),
              child: Row(
                children: [
                  CircleAvatar(radius: 6, backgroundColor: p.accent),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: p.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Container(
              height: 12,
              decoration: ShapeDecoration(
                color: p.ink,
                shape: const StadiumBorder(),
              ),
            ),
          ],
        ),
      ),
    );

    final Widget swatch = switch (mode) {
      ThemeMode.light => preview(AppPalette.light),
      ThemeMode.dark => preview(AppPalette.dark),
      // Diagonal split: half light, half dark.
      ThemeMode.system => Stack(
        fit: StackFit.expand,
        children: [
          preview(AppPalette.light),
          ClipPath(clipper: _HalfClipper(), child: preview(AppPalette.dark)),
        ],
      ),
    };

    return Semantics(
      button: true,
      selected: selected,
      label: context.l10n.themeSemantics(label),
      excludeSemantics: true,
      child: Material(
        color: context.colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: selected ? context.colors.ink : Colors.transparent,
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(height: 74, child: swatch),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      size: 18,
                      color: selected
                          ? context.colors.ink
                          : context.colors.muted,
                    ),
                    const SizedBox(width: 6),
                    // Three cards share a narrow row; shrink the label
                    // rather than overflow at large text sizes.
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          maxLines: 1,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HalfClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(size.width, 0)
    ..lineTo(size.width, size.height)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
