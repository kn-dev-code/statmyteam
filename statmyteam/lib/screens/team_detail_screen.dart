import 'package:flutter/material.dart';

import '../logic/football_stats.dart';
import '../models/models.dart';
import '../state/stats_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/stats_widgets.dart';
import 'player_detail_screen.dart';
import 'team_select_screen.dart';

/// One team's season: headline numbers, stats, form, injuries, roster.
class TeamDetailScreen extends StatelessWidget {
  const TeamDetailScreen({super.key, required this.team});

  final Team team;

  @override
  Widget build(BuildContext context) {
    final repo = StatsScope.of(context);
    final color = teamColor(team);
    final roster = repo.rosterFor(team.id);
    final injuries = repo.injuryReport(team.id);
    final recent = repo.recentGames(team.id);

    return Scaffold(
      appBar: AppBar(title: Text(team.displayName)),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            StatCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TeamBadge(team: team, size: 60),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              team.displayName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              [
                                if (team.league != null) team.league!.label,
                                '${team.conference} Conference',
                                '${team.season} season',
                              ].join(' · '),
                              style: const TextStyle(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _Headline(label: 'Record', value: team.record, color: color),
                      _Headline(
                        label: 'Win %',
                        value: '${(team.winPercentage * 100).round()}%',
                      ),
                      _Headline(
                        label: 'Pt diff / g',
                        value: _signed(team.stat('ppg') - team.stat('papg')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Last 5',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  FormStrip(teamId: team.id, games: recent),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TeamSelectScreen(
                    mode: TeamSelectMode.matchup,
                    preselected: team,
                  ),
                ),
              ),
              icon: const Icon(Icons.compare_arrows),
              label: const Text('Compare against another team'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SectionTitle('Season stats'),
            StatCard(
              child: Column(
                children: [
                  for (final def in FootballStats.teamStats)
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
                            def.format(team.stat(def.key)),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SectionTitle('Recent results'),
            StatCard(
              child: Column(
                children: [
                  for (final game in recent)
                    GameResultTile(
                      game: game,
                      teamId: team.id,
                      opponent: repo.teamById(
                        game.homeTeamId == team.id
                            ? game.awayTeamId
                            : game.homeTeamId,
                      ),
                    ),
                ],
              ),
            ),
            SectionTitle(
              'Injury report',
              subtitle: injuries.isEmpty
                  ? 'Everyone is available'
                  : '${injuries.length} player${injuries.length == 1 ? '' : 's'} '
                      'listed',
            ),
            if (injuries.isNotEmpty)
              StatCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    for (final p in injuries) _PlayerTile(player: p),
                  ],
                ),
              ),
            const SectionTitle('Roster', subtitle: 'Tap a player for details'),
            for (final group in PositionGroup.values)
              if (roster.any((p) => group.positions.contains(p.position))) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
                  child: Text(
                    group.label.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                StatCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      for (final p in roster)
                        if (group.positions.contains(p.position))
                          _PlayerTile(player: p),
                    ],
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }

  static String _signed(double v) {
    final text = v.toStringAsFixed(1);
    return v > 0 ? '+$text' : text;
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: color ?? AppColors.text,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PlayerDetailScreen(player: player),
        ),
      ),
      leading: SizedBox(
        width: 44,
        child: Text(
          '#${player.jerseyNumber}',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: AppColors.muted,
          ),
        ),
      ),
      title: Text(
        player.fullName,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        [
          player.position,
          player.role?.label,
          if (player.injuryNote != null) player.injuryNote,
        ].whereType<String>().join(' · '),
        style: const TextStyle(color: AppColors.muted, fontSize: 12),
      ),
      trailing: PlayerStatusChip(status: player.status, compact: true),
    );
  }
}
