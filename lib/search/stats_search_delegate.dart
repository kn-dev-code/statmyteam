import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/stats_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/stats_widgets.dart';
import '../screens/player_detail_screen.dart';
import '../screens/team_detail_screen.dart';

/// Quick lookup across teams and players from any AppBar search action.
class StatsSearchDelegate extends SearchDelegate<void> {
  StatsSearchDelegate();

  @override
  String get searchFieldLabel => 'Search teams or players';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: InputBorder.none,
        hintStyle: TextStyle(color: AppColors.muted),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          tooltip: 'Clear',
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _Results(query: query);

  @override
  Widget buildSuggestions(BuildContext context) => _Results(query: query);
}

class _Results extends StatelessWidget {
  const _Results({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final repo = StatsScope.of(context);
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return Center(
        child: Text(
          'Type a team or player name',
          style: TextStyle(color: AppColors.muted),
        ),
      );
    }

    final teams = repo.teams.where((team) {
      return team.displayName.toLowerCase().contains(q) ||
          team.abbreviation.toLowerCase().contains(q) ||
          team.city.toLowerCase().contains(q) ||
          team.name.toLowerCase().contains(q);
    }).toList();

    final players = repo.players
        .where((player) {
          return player.fullName.toLowerCase().contains(q) ||
              player.lastName.toLowerCase().contains(q) ||
              '#${player.jerseyNumber}'.contains(q);
        })
        .take(40)
        .toList();

    if (teams.isEmpty && players.isEmpty) {
      return Center(
        child: Text(
          'No matches for "$query"',
          style: TextStyle(color: AppColors.muted),
        ),
      );
    }

    return ContentWidth(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          if (teams.isNotEmpty) ...[
            const SectionTitle('Teams'),
            StatCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  for (final team in teams)
                    ListTile(
                      leading: TeamBadge(team: team, size: 42),
                      title: Text(
                        team.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${team.record} · ${team.conference ?? team.league?.label ?? ''}',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => TeamDetailScreen(team: team),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
          if (players.isNotEmpty) ...[
            const SectionTitle('Players'),
            StatCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  for (final player in players)
                    _PlayerResultTile(player: player),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlayerResultTile extends StatelessWidget {
  const _PlayerResultTile({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    Team? team;
    try {
      team = StatsScope.of(context).teamById(player.teamId);
    } catch (_) {
      team = null;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.surfaceHigh,
        child: Text(
          player.position,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ),
      title: Text(
        player.fullName,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        [
          '#${player.jerseyNumber}',
          if (team != null) team.abbreviation,
        ].join(' · '),
        style: TextStyle(color: AppColors.muted, fontSize: 12),
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PlayerDetailScreen(player: player),
          ),
        );
      },
    );
  }
}
