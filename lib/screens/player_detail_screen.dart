import 'package:flutter/material.dart';

import '../logic/football_stats.dart';
import '../models/models.dart';
import '../state/stats_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/stats_widgets.dart';

class PlayerDetailScreen extends StatelessWidget {
  const PlayerDetailScreen({super.key, required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    final team = StatsScope.of(context).teamById(player.teamId);
    final stats = FootballStats.forPosition(player.position);
    final color = teamColor(team);

    return Scaffold(
      appBar: PillAppBar(title: player.fullName),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            PlayerSummaryCard(player: player, team: team),
            const SectionTitle('Season stats'),
            StatCard(
              child: StatGrid(
                items: [
                  for (final def in stats)
                    (
                      label: def.label,
                      value: player.seasonStats.containsKey(def.key)
                          ? def.format(player.stat(def.key))
                          : '—',
                    ),
                ],
              ),
            ),
            const SectionTitle(
              'Stat profile',
              subtitle: 'Selected season totals',
            ),
            StatCard(
              child: PlayerStatBarsChart(
                defs: stats,
                player: player,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Identity, role, availability, and bio for one player.
class PlayerSummaryCard extends StatelessWidget {
  const PlayerSummaryCard({
    super.key,
    required this.player,
    required this.team,
    this.compact = false,
  });

  final Player player;
  final Team team;

  /// Narrower layout for side-by-side comparison.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = teamColor(team);
    final bio = <(String, String)>[
      ('Team', team.abbreviation),
      if (player.age != null) ('Age', '${player.age}'),
      if (player.heightLabel != null) ('Height', player.heightLabel!),
      if (player.weightLbs != null) ('Weight', '${player.weightLbs} lb'),
      if (player.classYear != null) ('Class', player.classYear!),
      if (player.yearsPro != null)
        (
          'Experience',
          player.yearsPro == 1 ? 'Rookie' : '${player.yearsPro} yrs',
        ),
      if (player.college != null) ('College', player.college!),
    ];

    return StatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: compact ? 44 : 60,
                height: compact ? 44 : 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Text(
                  '${player.jerseyNumber}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 17 : 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              PlayerStatusChip(status: player.status, compact: compact),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            player.fullName,
            style: TextStyle(
              fontSize: compact ? 16 : 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            FootballStats.positionNames[player.position] ?? player.position,
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (player.role != null) _Tag(player.role!.label, color),
              if (player.injuryNote != null)
                _Tag(
                  player.injuryNote!,
                  PlayerStatusChip.colorFor(player.status),
                ),
            ],
          ),
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            for (final (label, value) in bio)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        value,
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: ShapeDecoration(
        color: color.withValues(alpha: 0.1),
        shape: const StadiumBorder(),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
