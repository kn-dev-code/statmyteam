import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../logic/sport_stats.dart';
import '../theme/app_theme.dart';
import 'stats_widgets.dart';

/// Strengths, weaknesses, and a short scouting blurb for one team.
class TeamOutlookCard extends StatelessWidget {
  const TeamOutlookCard({super.key, required this.outlook});

  final TeamOutlook outlook;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return StatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.outlookSummary(outlook),
            style: const TextStyle(height: 1.4, fontSize: 14.5),
          ),
          if (outlook.strengths.isNotEmpty) ...[
            const SizedBox(height: 16),
            _Label(l10n.strengths, icon: Icons.arrow_upward_rounded),
            const SizedBox(height: 8),
            for (final trait in outlook.strengths)
              _TraitTile(trait: trait, outlook: outlook),
          ],
          if (outlook.weaknesses.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Label(l10n.weaknesses, icon: Icons.arrow_downward_rounded),
            const SizedBox(height: 8),
            for (final trait in outlook.weaknesses)
              _TraitTile(trait: trait, outlook: outlook),
          ],
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Row(
        children: [
          Icon(icon, size: 16, color: context.colors.muted),
          const SizedBox(width: 6),
          Text(
            text.toUpperCase(),
            style: TextStyle(
              color: context.colors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _TraitTile extends StatelessWidget {
  const _TraitTile({required this.trait, required this.outlook});

  final TeamTrait trait;
  final TeamOutlook outlook;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = trait.isStrength
        ? context.colors.accent
        : context.colors.danger;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.traitHeadline(trait),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.traitDetailFor(trait, outlook.team),
                  style: TextStyle(color: context.colors.muted, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
