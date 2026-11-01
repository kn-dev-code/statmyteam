import 'package:flutter/material.dart';

import '../logic/football_stats.dart';
import '../models/models.dart';
import '../state/stats_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/stats_widgets.dart';

class PlayerDetailScreen extends StatelessWidget {
  const PlayerDetailScreen({super.key, required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    final team = StatsScope.of(context).teamById(player.teamId);
    final stats = FootballStats.forPosition(player.position);

    return Scaffold(
      appBar: AppBar(title: Text(player.fullName)),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            PlayerSummaryCard(player: player, team: team),
            const SectionTitle('Season stats'),
            StatCard(
              child: Column(
                children: [
                  for (final def in stats)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              def.label,
                              style: const TextStyle(color: AppColors.muted),
                            ),
                          ),
                          Text(
                            player.seasonStats.containsKey(def.key)
                                ? def.format(player.stat(def.key))
                                : '—',
                            style:
                                const TextStyle(fontWeight: FontWeight.w800),
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
      if (player.yearsPro != null)
        ('Experience', player.yearsPro == 1 ? 'Rookie' : '${player.yearsPro} yrs'),
      if (player.college != null) ('College', player.college!),
    ];

    return StatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '#${player.jerseyNumber}',
                style: TextStyle(
                  color: color,
                  fontSize: compact ? 22 : 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              PlayerStatusChip(status: player.status, compact: compact),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            player.fullName,
            style: TextStyle(
              fontSize: compact ? 16 : 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            FootballStats.positionNames[player.position] ?? player.position,
            style: const TextStyle(color: AppColors.muted),
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
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
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
