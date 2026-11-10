import 'package:flutter/material.dart';

import '../logic/football_stats.dart';
import '../logic/matchup_projector.dart';
import '../models/models.dart';
import '../state/favorites_scope.dart';
import '../state/stats_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
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
    final favorites = FavoritesScope.of(context);
    final a = widget.teamA;
    final b = widget.teamB;
    final h2h = repo.headToHead(a.id, b.id);
    final saved = favorites.isFavoriteMatchup(a.id, b.id);

    final projection = MatchupProjector.project(
      teamA: a,
      teamB: b,
      rosterA: repo.rosterFor(a.id),
      rosterB: repo.rosterFor(b.id),
      headToHead: h2h,
      venue: _venue,
    );

    final margin = projection.spread < 0.5
        ? 'Even'
        : '${projection.favorite.abbreviation} by '
              '${_trim(projection.spread)}';

    return Scaffold(
      appBar: PillAppBar(
        title: '${a.abbreviation} vs ${b.abbreviation}',
        actions: [
          RoundIconButton(
            tooltip: saved ? 'Remove saved matchup' : 'Save matchup',
            icon: saved
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            iconColor: saved ? AppColors.orange : AppColors.ink,
            onPressed: () => favorites.toggleMatchup(a.id, b.id),
          ),
        ],
      ),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // Crests, projected score, and win probability.
            StatCard(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      const LabelPill('Game preview'),
                      const Spacer(),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Icon(
                          _venue == MatchupVenue.neutral
                              ? Icons.public_rounded
                              : Icons.stadium_outlined,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _TeamHeader(team: a)),
                      Padding(
                        padding: const EdgeInsets.only(top: 26),
                        child: Column(
                          children: [
                            Text(
                              '${projection.teamAScore.round()} : '
                              '${projection.teamBScore.round()}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.6,
                              ),
                            ),
                            Text(
                              'Projected',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(child: _TeamHeader(team: b)),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Align(
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
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: WinProbabilityBar(
                      teamA: a,
                      teamB: b,
                      teamAChance: projection.teamAWinChance,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: MetricPill(label: 'Margin', value: margin),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: MetricPill(
                          label: 'Combined',
                          value: projection.projectedTotal.toStringAsFixed(0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PlayerCompareScreen(teamA: a, teamB: b),
                      ),
                    ),
                    icon: const Icon(Icons.people_alt_outlined),
                    label: const Text('Compare players'),
                  ),
                ],
              ),
            ),

            // Team stats as a duel grid; better values are green.
            SectionTitle(
              'Performance',
              trailing: _Legend(a: a, b: b),
            ),
            StatCard(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 14),
              child: StatDuelGrid(
                defs: FootballStats.teamStats,
                valuesA: a.seasonStats,
                valuesB: b.seasonStats,
              ),
            ),

            const SectionTitle(
              'What drives the projection',
              subtitle: 'Season form, scoring margin, venue, and who is out',
            ),
            StatCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  for (var i = 0; i < projection.factors.length; i++) ...[
                    if (i > 0) const Divider(indent: 18, endIndent: 18),
                    _FactorTile(factor: projection.factors[i]),
                  ],
                ],
              ),
            ),

            const SectionTitle('Recent form', subtitle: 'Last 5, newest first'),
            StatCard(
              child: Column(
                children: [
                  for (final team in [a, b])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          TeamBadge(team: team, size: 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              team.name,
                              overflow: TextOverflow.ellipsis,
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

            const SectionTitle('Head-to-head'),
            StatCard(
              child: h2h.isEmpty
                  ? Text(
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

            const SectionTitle('Injury report'),
            StatCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final team in [a, b]) ...[
                    Row(
                      children: [
                        TeamBadge(team: team, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          team.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (repo.injuryReport(team.id).isEmpty)
                      Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Text(
                          'No players listed',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ),
                    for (final p in repo.injuryReport(team.id))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${p.position}  ',
                                      style: TextStyle(
                                        color: AppColors.muted,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    TextSpan(text: p.fullName),
                                    if (p.injuryNote != null)
                                      TextSpan(
                                        text: ' · ${p.injuryNote}',
                                        style: TextStyle(
                                          color: AppColors.muted,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            PlayerStatusChip(status: p.status, compact: true),
                          ],
                        ),
                      ),
                    if (team == a) ...[
                      const SizedBox(height: 6),
                      const Divider(),
                      const SizedBox(height: 10),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

class _TeamHeader extends StatelessWidget {
  const _TeamHeader({required this.team});

  final Team team;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TeamBadge(team: team, size: 86),
        const SizedBox(height: 10),
        Text(
          '${team.city}\n${team.name}'.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          team.record,
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
      ],
    );
  }
}

/// "POR · AUS" key so the left/right values in the duel grid read clearly.
class _Legend extends StatelessWidget {
  const _Legend({required this.a, required this.b});

  final Team a;
  final Team b;

  @override
  Widget build(BuildContext context) {
    TextStyle style = const TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 15,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(a.abbreviation, style: style),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Text('·', style: TextStyle(color: AppColors.muted)),
        ),
        Text(b.abbreviation, style: style),
      ],
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 18),
      title: Text(
        factor.title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
      subtitle: Text(
        factor.detail,
        style: TextStyle(color: AppColors.muted, fontSize: 12.5),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: ShapeDecoration(
          color: favors == null ? AppColors.surfaceHigh : AppColors.accent,
          shape: const StadiumBorder(),
        ),
        child: Text(
          favors?.abbreviation ?? 'EVEN',
          style: TextStyle(
            color: favors == null ? AppColors.muted : AppColors.onAccent,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
