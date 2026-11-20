import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../logic/sport_stats.dart';
import '../models/models.dart';
import '../state/stats_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/player_stats_loader.dart';
import '../widgets/stats_widgets.dart';

class PlayerDetailScreen extends StatelessWidget {
  const PlayerDetailScreen({super.key, required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final team = StatsScope.of(context).findTeamById(player.teamId);
    if (team == null) {
      // A feed id that no longer resolves: say so instead of crashing.
      return Scaffold(
        appBar: PillAppBar(title: player.fullName),
        body: Center(
          child: Text(
            l10n.playerUnavailable,
            style: TextStyle(color: context.colors.muted),
          ),
        ),
      );
    }
    final stats = SportStats.forPosition(player.sport, player.position);
    final color = teamColor(context, team);

    return Scaffold(
      appBar: PillAppBar(title: player.fullName),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            PlayerSummaryCard(player: player, team: team),
            SectionTitle(l10n.seasonStats),
            PlayerStatsLoader(
              players: [player],
              builder: (context, loaded) {
                final withStats = loaded.single;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StatCard(
                      child: StatGrid(
                        items: [
                          for (final def in stats)
                            (
                              label: l10n.stat(def),
                              value: withStats.seasonStats.containsKey(def.key)
                                  ? l10n.statValue(def, withStats.stat(def.key))
                                  : l10n.noValue,
                            ),
                        ],
                      ),
                    ),
                    SectionTitle(
                      l10n.statProfile,
                      subtitle: l10n.statProfileSubtitle,
                    ),
                    StatCard(
                      child: PlayerStatBarsChart(
                        defs: stats,
                        player: withStats,
                        color: color,
                      ),
                    ),
                  ],
                );
              },
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
    final l10n = context.l10n;
    final color = teamColor(context, team);
    final bio = <(String, String)>[
      (l10n.bioTeam, team.abbreviation),
      if (player.age case final age?) (l10n.bioAge, '$age'),
      if (player.heightLabel case final height?) (l10n.bioHeight, height),
      if (player.weightLbs case final weight?)
        (l10n.bioWeight, l10n.weightLbs(weight)),
      if (player.classYear case final classYear?) (l10n.bioClass, classYear),
      if (player.yearsPro case final years?)
        (l10n.bioExperience, years == 1 ? l10n.rookie : l10n.yearsPro(years)),
      if (player.college case final college?) (l10n.bioCollege, college),
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
            l10n.positionName(player.position),
            style: TextStyle(color: context.colors.muted),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (player.role case final role?) _Tag(l10n.role(role), color),
              if (player.injuryNote != null)
                _Tag(
                  player.injuryNote!,
                  PlayerStatusChip.colorFor(context, player.status),
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
                        style: TextStyle(
                          color: context.colors.muted,
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
