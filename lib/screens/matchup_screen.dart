
import 'package:flutter/material.dart';

import '../logic/football_stats.dart';
import '../logic/matchup_projector.dart';
import '../models/models.dart';
import '../state/stats_scope.dart';
import '../state/favorites_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/stats_widgets.dart';
import 'player_compare_screen.dart';

/// Two teams side by side with a win projection.
class MatchupScreen extends StatefulWidget {
  const MatchupScreen({
    super.key,
    required this.teamA,
    required this.teamB,
  });

  final Team teamA;
  final Team teamB;

  @override
  State<MatchupScreen> createState() =>
      _MatchupScreenState();
}

class _MatchupScreenState extends State<MatchupScreen> {
  MatchupVenue _venue = MatchupVenue.teamAHome;

  @override
  Widget build(BuildContext context) {
    final repo = StatsScope.of(context);
    final favorites = FavoritesScope.of(context);
    final a = widget.teamA;
    final b = widget.teamB;
    final colorA = teamColor(a);
    final colorB = teamColor(b);
    final h2h = repo.headToHead(a.id, b.id);

    final projection = MatchupProjector.project(
      teamA: a,
      teamB: b,
      rosterA: repo.rosterFor(a.id),
      rosterB: repo.rosterFor(b.id),
      headToHead: h2h,
      venue: _venue,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${a.abbreviation} vs ${b.abbreviation}',
        ),
        actions: [
          IconButton(
            tooltip: favorites.isFavoriteMatchup(
              a.id,
              b.id,
            )
                ? 'Remove saved matchup'
                : 'Save matchup',
            icon: Icon(
              favorites.isFavoriteMatchup(a.id, b.id)
                  ? Icons.bookmark
                  : Icons.bookmark_border,
            ),
            onPressed: () =>
                favorites.toggleMatchup(a.id, b.id),
          ),
        ],
      ),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            4,
            20,
            32,
          ),
          children: [
            // HEADER AND PROJECTION
            StatCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _TeamHeader(team: a),
                      ),
                      const Text(
                        'VS',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Expanded(
                        child: _TeamHeader(team: b),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'WIN PROBABILITY',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  WinProbabilityBar(
                    teamA: a,
                    teamB: b,
                    teamAChance:
                        projection.teamAWinChance,
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      _Metric(
                        label: 'Projected score',
                        value:
                            '${projection.teamAScore.round()}–${projection.teamBScore.round()}',
                      ),
                      _Metric(
                        label: 'Spread',
                        value: projection.spreadLabel,
                      ),
                      _Metric(
                        label: 'Total',
                        value: projection.projectedTotal
                            .toStringAsFixed(1),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<MatchupVenue>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: MatchupVenue.teamAHome,
                          label: Text('@ ${a.abbreviation}'),
                        ),
                        const ButtonSegment(
                          value: MatchupVenue.neutral,
                          label: Text('Neutral'),
                        ),
                        ButtonSegment(
                          value: MatchupVenue.teamBHome,
                          label: Text('@ ${b.abbreviation}'),
                        ),
                      ],
                      selected: {_venue},
                      onSelectionChanged: (s) =>
                          setState(
                            () => _venue = s.first,
                          ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PlayerCompareScreen(
                    teamA: a,
                    teamB: b,
                  ),
                ),
              ),
              icon: const Icon(
                Icons.people_alt_outlined,
              ),
              label: const Text('Compare players'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            // PROJECTION FACTORS
            const SectionTitle(
              'What drives the projection',
              subtitle:
                  'Season form, scoring margin, venue, and who is out',
            ),

            StatCard(
              padding: const EdgeInsets.symmetric(
                vertical: 6,
              ),
              child: Column(
                children: [
                  for (final factor in projection.factors)
                    _FactorTile(factor: factor),
                ],
              ),
            ),

            // EXISTING TEAM STATISTICS
            const SectionTitle('Team stats'),

            StatCard(
              child: Column(
                children: [
                  _ColumnHeads(a: a, b: b),
                  for (final def in FootballStats.teamStats)
                    StatCompareRow(
                      def: def,
                      valueA: a.seasonStats[def.key],
                      valueB: b.seasonStats[def.key],
                      colorA: colorA,
                      colorB: colorB,
                    ),
                ],
              ),
            ),

            // NEW FEATURE: RECENT GAME COMPARISON
            const SectionTitle(
              'Recent-game comparison',
              subtitle:
                  'Average over up to 5 completed games per team',
            ),

            StatCard(
              child: _RecentComparison(
                a: a,
                b: b,
                gamesA: repo.recentGames(a.id),
                gamesB: repo.recentGames(b.id),
              ),
            ),

            // EXISTING RECENT FORM
            const SectionTitle(
              'Recent form',
              subtitle: 'Last 5, newest first',
            ),

            StatCard(
              child: Column(
                children: [
                  for (final team in [a, b])
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          TeamBadge(
                            team: team,
                            size: 30,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              team.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          FormStrip(
                            teamId: team.id,
                            games: repo.recentGames(team.id),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // HEAD TO HEAD HISTORY
            const SectionTitle('Head-to-head'),

            StatCard(
              child: h2h.isEmpty
                  ? const Text(
                      'These teams have not met in the last two seasons.',
                      style: TextStyle(
                        color: AppColors.muted,
                      ),
                    )
                  : Column(
                      children: [
                        for (final game in h2h)
                          GameResultTile(
                            game: game,
                            teamId: a.id,
                            opponent: b,
                          ),
                      ],
                    ),
            ),

            // INJURY REPORT
            const SectionTitle('Injury report'),

            StatCard(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  for (final team in [a, b]) ...[
                    Text(
                      team.name,
                      style: TextStyle(
                        color: teamColor(team),
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 4),

                    if (repo.injuryReport(team.id).isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(
                          bottom: 10,
                        ),
                        child: Text(
                          'No players listed',
                          style: TextStyle(
                            color: AppColors.muted,
                          ),
                        ),
                      ),

                    for (final p
                        in repo.injuryReport(team.id))
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${p.position} ${p.fullName}'
                                '${p.injuryNote == null ? '' : ' · ${p.injuryNote}'}',
                              ),
                            ),
                            PlayerStatusChip(
                              status: p.status,
                              compact: true,
                            ),
                          ],
                        ),
                      ),

                    if (team == a)
                      const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// TEAM HEADER
class _TeamHeader extends StatelessWidget {
  const _TeamHeader({
    required this.team,
  });

  final Team team;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TeamBadge(
          team: team,
          size: 56,
        ),
        const SizedBox(height: 8),
        Text(
          team.displayName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          team.record,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

// PROJECTION METRIC
class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// TEAM COLUMN HEADINGS
class _ColumnHeads extends StatelessWidget {
  const _ColumnHeads({
    required this.a,
    required this.b,
  });

  final Team a;
  final Team b;

  @override
  Widget build(BuildContext context) {
    TextStyle style(Team team) => TextStyle(
          color: teamColor(team),
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        );

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 4,
      ),
      child: Row(
        children: [
          Text(
            a.abbreviation,
            style: style(a),
          ),
          const Spacer(),
          Text(
            b.abbreviation,
            style: style(b),
          ),
        ],
      ),
    );
  }
}

// MATCHUP PROJECTION FACTOR
class _FactorTile extends StatelessWidget {
  const _FactorTile({
    required this.factor,
  });

  final MatchupFactor factor;

  @override
  Widget build(BuildContext context) {
    final favors = factor.favors;

    return ListTile(
      dense: true,
      title: Text(
        factor.title,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        factor.detail,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 12.5,
        ),
      ),
      trailing: favors == null
          ? const Text(
              'EVEN',
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            )
          : Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: teamColor(favors).withValues(
                  alpha: 0.16,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                favors.abbreviation,
                style: TextStyle(
                  color: teamColor(favors),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
    );
  }
}

// IMPLEMENTATION 2:
// COMPARE RECENT GAME PERFORMANCE
class _RecentComparison extends StatelessWidget {
  const _RecentComparison({
    required this.a,
    required this.b,
    required this.gamesA,
    required this.gamesB,
  });

  final Team a;
  final Team b;
  final List<GameStats> gamesA;
  final List<GameStats> gamesB;

  // Use the five most recent completed games.
  List<GameStats> _completedGames(
    List<GameStats> games,
  ) {
    final completed = games
        .where((game) =>
            game.isFinal &&
            game.home.score != null &&
            game.away.score != null)
        .toList();

    completed.sort(
      (x, y) =>
          y.startTime.compareTo(x.startTime),
    );

    return completed.take(5).toList();
  }

  // Calculate a team's average for a selected metric.
  double? _average(
    List<GameStats> games,
    String teamId,
    int metric,
  ) {
    var sum = 0.0;
    var count = 0;

    for (final game in games) {
      if (game.homeTeamId != teamId &&
          game.awayTeamId != teamId) {
        continue;
      }

      final isHome = game.homeTeamId == teamId;

      final scored = isHome
          ? game.home.score!
          : game.away.score!;

      final allowed = isHome
          ? game.away.score!
          : game.home.score!;

      if (metric == 0) {
        sum += scored;
      } else if (metric == 1) {
        sum += allowed;
      } else {
        sum += scored - allowed;
      }

      count++;
    }

    return count == 0 ? null : sum / count;
  }

  @override
  Widget build(BuildContext context) {
    final recentA = _completedGames(gamesA);
    final recentB = _completedGames(gamesB);

    if (recentA.isEmpty && recentB.isEmpty) {
      return const Text(
        'No completed games available for these teams.',
        style: TextStyle(
          color: AppColors.muted,
        ),
      );
    }

    const labels = [
      'Points scored / game',
      'Points allowed / game',
      'Scoring margin / game',
    ];

    return Column(
      children: [
        _ColumnHeads(a: a, b: b),

        for (final metric in [0, 1, 2])
          StatCompareRow(
            def: StatDef(
              'recent_$metric',
              labels[metric],
              decimals: 1,
              higherIsBetter: metric != 1,
              signed: metric == 2,
            ),
            valueA: _average(
              recentA,
              a.id,
              metric,
            ),
            valueB: _average(
              recentB,
              b.id,
              metric,
            ),
            colorA: teamColor(a),
            colorB: teamColor(b),
          ),

        const SizedBox(height: 8),

        Text(
          '${a.abbreviation}: ${recentA.length} games · '
          '${b.abbreviation}: ${recentB.length} games',
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
