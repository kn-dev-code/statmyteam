import 'package:flutter/material.dart';

import '../logic/football_stats.dart';
import '../logic/matchup_projector.dart';
import '../models/models.dart';
import '../state/stats_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/stats_widgets.dart';
import 'player_compare_screen.dart';

/// Two teams side by side with a win projection.
class MatchupScreen extends StatefulWidget {
  const MatchupScreen({super.key, required this.teamA, required this.teamB});

  final Team teamA;
  final Team teamB;

  @override
  State<MatchupScreen> createState() => _MatchupScreenState();
}

class _MatchupScreenState extends State<MatchupScreen> {
  MatchupVenue _venue = MatchupVenue.teamAHome;

  @override
  Widget build(BuildContext context) {
    final repo = StatsScope.of(context);
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
      appBar: AppBar(title: Text('${a.abbreviation} vs ${b.abbreviation}')),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            // ── Header + projection ────────────────────────────────────
            StatCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _TeamHeader(team: a)),
                      const Text(
                        'VS',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Expanded(child: _TeamHeader(team: b)),
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
                    teamAChance: projection.teamAWinChance,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _Metric(
                        label: 'Projected score',
                        value:
                            '${projection.teamAScore.round()}–${projection.teamBScore.round()}',
                      ),
                      _Metric(label: 'Spread', value: projection.spreadLabel),
                      _Metric(
                        label: 'Total',
                        value: projection.projectedTotal.toStringAsFixed(1),
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
                          setState(() => _venue = s.first),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PlayerCompareScreen(teamA: a, teamB: b),
                ),
              ),
              icon: const Icon(Icons.people_alt_outlined),
              label: const Text('Compare players'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),

            // ── Why ────────────────────────────────────────────────────
            const SectionTitle(
              'What drives the projection',
              subtitle: 'Season form, scoring margin, venue, and who is out',
            ),
            StatCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  for (final factor in projection.factors)
                    _FactorTile(factor: factor),
                ],
              ),
            ),

            // ── Stat by stat ───────────────────────────────────────────
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

            // ── Form + history ─────────────────────────────────────────
            const SectionTitle('Recent form', subtitle: 'Last 5, newest first'),
            StatCard(
              child: Column(
                children: [
                  for (final team in [a, b])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          TeamBadge(team: team, size: 30),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              team.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
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
            const SectionTitle('Head-to-head'),
            StatCard(
              child: h2h.isEmpty
                  ? const Text(
                      'These teams have not met in the last two seasons.',
                      style: TextStyle(color: AppColors.muted),
                    )
                  : Column(
                      children: [
                        for (final game in h2h)
                          GameResultTile(game: game, teamId: a.id, opponent: b),
                      ],
                    ),
            ),

            // ── Injuries ───────────────────────────────────────────────
            const SectionTitle('Injury report'),
            StatCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        padding: EdgeInsets.only(bottom: 10),
                        child: Text(
                          'No players listed',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ),
                    for (final p in repo.injuryReport(team.id))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${p.position} ${p.fullName}'
                                '${p.injuryNote == null ? '' : ' · ${p.injuryNote}'}',
                              ),
                            ),
                            PlayerStatusChip(status: p.status, compact: true),
                          ],
                        ),
                      ),
                    if (team == a) const SizedBox(height: 10),
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

class _TeamHeader extends StatelessWidget {
  const _TeamHeader({required this.team});

  final Team team;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TeamBadge(team: team, size: 56),
        const SizedBox(height: 8),
        Text(
          team.displayName,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        Text(
          team.record,
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ColumnHeads extends StatelessWidget {
  const _ColumnHeads({required this.a, required this.b});

  final Team a;
  final Team b;

  @override
  Widget build(BuildContext context) {
    TextStyle style(Team t) => TextStyle(
          color: teamColor(t),
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(a.abbreviation, style: style(a)),
          const Spacer(),
          Text(b.abbreviation, style: style(b)),
        ],
      ),
    );
  }
}

class _FactorTile extends StatelessWidget {
  const _FactorTile({required this.factor});

  final MatchupFactor factor;

  @override
  Widget build(BuildContext context) {
    final favors = factor.favors;
    return ListTile(
      dense: true,
      title: Text(
        factor.title,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
      ),
      subtitle: Text(
        factor.detail,
        style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: teamColor(favors).withValues(alpha: 0.16),
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
