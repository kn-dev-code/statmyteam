import 'package:flutter/material.dart';

import '../data/stats_repository.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import '../screens/player_detail_screen.dart';
import '../screens/team_detail_screen.dart';
import '../state/stats_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/stats_widgets.dart';

/// Quick lookup across teams and players from any AppBar search action.
class StatsSearchDelegate extends SearchDelegate<void> {
  StatsSearchDelegate({required String hint}) : super(searchFieldLabel: hint);

  /// Opens search with the localized hint text.
  static void open(BuildContext context) => showSearch(
    context: context,
    delegate: StatsSearchDelegate(hint: context.l10n.searchHint),
  );

  @override
  ThemeData appBarTheme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: context.colors.surface,
        foregroundColor: context.colors.text,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: InputBorder.none,
        hintStyle: TextStyle(color: context.colors.muted),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          tooltip: context.l10n.clear,
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      tooltip: context.l10n.back,
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _Results(query: query);

  @override
  Widget buildSuggestions(BuildContext context) => _Results(query: query);
}

/// Lower-cased, whitespace-normalized names, built once per repository so
/// each keystroke is a plain substring scan instead of 13k+ regex runs.
class _SearchIndex {
  _SearchIndex(StatsRepository repo)
    : teams = [
        for (final team in repo.teams)
          (
            team: team,
            keys: [
              team.displayName,
              team.abbreviation,
              team.city,
              team.name,
            ].map((s) => s.toLowerCase()).toList(),
          ),
      ],
      players = [
        for (final player in repo.players)
          (player: player, name: normalize(player.fullName)),
      ];

  static final _spaces = RegExp(r'\s+');
  static final _jersey = RegExp(r'^#?(\d+)$');
  static final _cache = Expando<_SearchIndex>();

  static _SearchIndex of(StatsRepository repo) =>
      _cache[repo] ??= _SearchIndex(repo);

  /// Lower case with runs of whitespace collapsed, so "Jordan   Vance"
  /// matches "Jordan Vance".
  static String normalize(String s) =>
      s.toLowerCase().replaceAll(_spaces, ' ').trim();

  final List<({Team team, List<String> keys})> teams;
  final List<({Player player, String name})> players;

  static const maxPlayers = 40;

  /// Teams shown at once; a short query can match 100+ college teams.
  static const maxTeams = 25;

  List<Team> searchTeams(String q) => [
    for (final entry in teams)
      if (entry.keys.any((key) => key.contains(q))) entry.team,
  ];

  /// Up to [maxPlayers] matches; "#1" and "1" are exact jersey searches.
  List<Player> searchPlayers(String q) {
    final jersey = int.tryParse(_jersey.firstMatch(q)?.group(1) ?? '');
    final results = <Player>[];
    for (final entry in players) {
      final match = jersey != null
          ? entry.player.jerseyNumber == jersey
          : entry.name.contains(q);
      if (!match) continue;
      results.add(entry.player);
      if (results.length == maxPlayers) break;
    }
    return results;
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final repo = StatsScope.of(context);
    final q = _SearchIndex.normalize(query);
    if (q.isEmpty) {
      return Center(
        child: Text(
          l10n.searchPrompt,
          style: TextStyle(color: context.colors.muted),
        ),
      );
    }

    final index = _SearchIndex.of(repo);
    final allTeams = index.searchTeams(q);
    final teams = allTeams.take(_SearchIndex.maxTeams).toList();
    final hiddenTeams = allTeams.length - teams.length;
    final players = index.searchPlayers(q);

    if (allTeams.isEmpty && players.isEmpty) {
      return Center(
        child: Text(
          l10n.noMatches(query),
          style: TextStyle(color: context.colors.muted),
        ),
      );
    }

    return ContentWidth(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          if (teams.isNotEmpty) ...[
            SectionTitle(l10n.teamsSection),
            StatCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  for (final team in teams) _TeamResultTile(team: team),
                  if (hiddenTeams > 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Text(
                        l10n.moreTeams(hiddenTeams),
                        style: TextStyle(color: context.colors.muted),
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (players.isNotEmpty) ...[
            SectionTitle(l10n.playersSection),
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

class _TeamResultTile extends StatelessWidget {
  const _TeamResultTile({required this.team});

  final Team team;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: TeamBadge(team: team, size: 42),
      title: Text(
        team.displayName,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        [
          team.record,
          ?(team.conference ?? team.league?.label),
        ].join(context.l10n.dotSeparator),
        style: TextStyle(color: context.colors.muted, fontSize: 12),
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => TeamDetailScreen(team: team)),
      ),
    );
  }
}

class _PlayerResultTile extends StatelessWidget {
  const _PlayerResultTile({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    final team = StatsScope.of(context).findTeamById(player.teamId);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: context.colors.surfaceHigh,
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
          context.l10n.jerseyNumber(player.jerseyNumber),
          ?team?.abbreviation,
        ].join(context.l10n.dotSeparator),
        style: TextStyle(color: context.colors.muted, fontSize: 12),
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PlayerDetailScreen(player: player),
        ),
      ),
    );
  }
}
