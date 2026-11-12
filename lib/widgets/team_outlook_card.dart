import 'package:flutter/material.dart';

import '../logic/sport_stats.dart';
import '../theme/app_theme.dart';
import 'stats_widgets.dart';

/// Strengths, weaknesses, and a short scouting blurb for one team.
class TeamOutlookCard extends StatelessWidget {
  const TeamOutlookCard({super.key, required this.outlook});

  final TeamOutlook outlook;

  @override
  Widget build(BuildContext context) {
    return StatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            outlook.summary,
            style: const TextStyle(height: 1.4, fontSize: 14.5),
          ),
          if (outlook.strengths.isNotEmpty) ...[
            const SizedBox(height: 16),
            const _Label('Strengths', icon: Icons.arrow_upward_rounded),
            const SizedBox(height: 8),
            for (final trait in outlook.strengths) _TraitTile(trait: trait),
          ],
          if (outlook.weaknesses.isNotEmpty) ...[
            const SizedBox(height: 12),
            const _Label('Weaknesses', icon: Icons.arrow_downward_rounded),
            const SizedBox(height: 8),
            for (final trait in outlook.weaknesses) _TraitTile(trait: trait),
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
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.muted),
        const SizedBox(width: 6),
        Text(
          text.toUpperCase(),
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}

class _TraitTile extends StatelessWidget {
  const _TraitTile({required this.trait});

  final TeamTrait trait;

  @override
  Widget build(BuildContext context) {
    final color = trait.isStrength ? AppColors.accent : AppColors.danger;
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
                  trait.headline,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  trait.detail,
                  style: TextStyle(color: AppColors.muted, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
