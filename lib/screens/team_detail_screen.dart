import 'package:flutter/material.dart';

import '../logic/football_stats.dart';
import '../models/models.dart';
import '../state/favorites_scope.dart';
import '../state/stats_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
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
    final favorites = FavoritesScope.of(context);
    final color = teamColor(team);
    final roster = repo.rosterFor(team.id);
    final injuries = repo.injuryReport(team.id);
    final recent = repo.recentGames(team.id);
    final isFavorite = favorites.isFavorite(team.id);

    return Scaffold(
      appBar: PillAppBar(
        title: team.displayName,
        actions: [
          RoundIconButton(
            tooltip: isFavorite ? 'Remove favorite' : 'Add favorite',
            icon: isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
            iconColor: isFavorite ? AppColors.orange : AppColors.ink,
            onPressed: () => favorites.toggle(team.id),
          ),
        ],
      ),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            StatCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TeamBadge(team: team, size: 72),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              team.displayName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                            Text(
                              [
                                if (team.league != null) team.league!.label,
                                if (team.conference != null)
                                  '${team.conference} Conference',
                                '${team.season} season',
                              ].join(' · '),
                              style: TextStyle(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  StatGrid(
                    crossAxisCount: 3,
                    items: [
                      (label: 'Record', value: team.record),
                      (
                        label: 'Win %',
                        value: '${(team.winPercentage * 100).round()}%',
                      ),
                      (
                        label: 'Pt diff / g',
                        value: _signed(team.stat('ppg') - team.stat('papg')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'LAST 5',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FormStrip(teamId: team.id, games: recent),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => TeamSelectScreen(
                          mode: TeamSelectMode.matchup,
                          preselected: team,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.compare_arrows_rounded),
                    label: const Text('Compare against another team'),
                  ),
                ],
              ),
            ),
            const SectionTitle('Season stats'),
            StatCard(
              child: StatGrid(
                items: [
                  for (final def in FootballStats.teamStats)
                    (label: def.label, value: def.format(team.stat(def.key))),
                ],
              ),
            ),
            const SectionTitle(
              'Scoring trend',
              subtitle: 'Points scored in recent games',
            ),
            StatCard(
              child: RecentFormChart(
                teamId: team.id,
                games: recent,
                color: color,
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
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [for (final p in injuries) _PlayerTile(player: p)],
                ),
              ),
            const SectionTitle('Roster', subtitle: 'Tap a player for details'),
            for (final group in PositionGroup.values)
              if (roster.any((p) => group.positions.contains(p.position))) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
                  child: Text(
                    group.label.toUpperCase(),
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                StatCard(
                  padding: const EdgeInsets.symmetric(vertical: 6),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          shape: BoxShape.circle,
        ),
        child: Text(
          '${player.jerseyNumber}',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
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
        style: TextStyle(color: AppColors.muted, fontSize: 12),
      ),
      trailing: PlayerStatusChip(status: player.status, compact: true),
    );
  }
}
