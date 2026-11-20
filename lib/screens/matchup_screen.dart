import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../logic/matchup_projector.dart';
import '../logic/sport_stats.dart';
import '../models/models.dart';
import '../state/favorites_scope.dart';
import '../state/stats_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/matchup_card.dart' show projectMatchup;
import '../widgets/stats_widgets.dart';
import '../widgets/team_outlook_card.dart';
import 'player_compare_screen.dart';

/// Two teams side by side with a win projection.
class MatchupScreen extends StatefulWidget {
  const MatchupScreen({
    super.key,
    required this.teamA,
    required this.teamB,
    this.initialVenue = MatchupVenue.teamAHome,
  });

  final Team teamA;
  final Team teamB;

  /// Venue the projection starts with; saved matchups use neutral because
  /// a saved pair does not record which team is at home.
  final MatchupVenue initialVenue;

  @override
  State<MatchupScreen> createState() => _MatchupScreenState();
}

class _MatchupScreenState extends State<MatchupScreen> {
  late MatchupVenue _venue = widget.initialVenue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final repo = StatsScope.of(context);
    final favorites = FavoritesScope.of(context);
    final a = widget.teamA;
    final b = widget.teamB;
    final h2h = repo.headToHead(a.id, b.id);
    final saved = favorites.isFavoriteMatchup(a.id, b.id);
    // Memoized per repository, matchup, and venue.
    final projection = projectMatchup(context, a, b, venue: _venue);

    String outlookSubtitle(Team team) => team.league == null
        ? l10n.outlookSubtitleNoLeague(team.name)
        : l10n.outlookSubtitle(team.name, team.league!.label);

    return Scaffold(
      appBar: PillAppBar(
        title: l10n.matchupTitle(a.abbreviation, b.abbreviation),
        actions: [
          RoundIconButton(
            tooltip: saved ? l10n.removeSavedMatchup : l10n.saveMatchup,
            icon: saved
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            iconColor: saved ? AppColors.orange : context.colors.ink,
            onPressed: () => saveWithFeedback(
              context,
              () => favorites.toggleMatchup(a.id, b.id),
            ),
          ),
        ],
      ),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _PreviewCard(
              projection: projection,
              venue: _venue,
              onVenueChanged: (venue) => setState(() => _venue = venue),
            ),

            // Team stats as a duel grid; better values are green.
            SectionTitle(
              l10n.performance,
              trailing: _Legend(a: a, b: b),
            ),
            StatCard(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 14),
              child: StatDuelGrid(
                defs: SportStats.teamStats(a.sport),
                valuesA: a.seasonStats,
                valuesB: b.seasonStats,
              ),
            ),

            for (final team in [a, b]) ...[
              SectionTitle(
                l10n.outlookTitle(team.abbreviation),
                subtitle: outlookSubtitle(team),
              ),
              TeamOutlookCard(outlook: repo.outlookFor(team)),
            ],

            SectionTitle(
              l10n.projectionDrivers,
              subtitle: l10n.projectionDriversSubtitle,
            ),
            StatCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  for (var i = 0; i < projection.factors.length; i++) ...[
                    if (i > 0) const Divider(indent: 18, endIndent: 18),
                    _FactorTile(factor: projection.factors[i], a: a, b: b),
                  ],
                ],
              ),
            ),

            // Averages from recent completed games, alongside season stats.
            SectionTitle(
              l10n.recentComparison,
              subtitle: l10n.recentComparisonSubtitle(_recentGameCount),
            ),
            StatCard(
              child: _RecentComparison(
                a: a,
                b: b,
                gamesA: repo.recentGames(a.id),
                gamesB: repo.recentGames(b.id),
              ),
            ),

            SectionTitle(
              l10n.recentForm,
              subtitle: l10n.recentFormSubtitle(_recentGameCount),
            ),
            _RecentFormCard(teams: [a, b]),

            SectionTitle(l10n.headToHeadSection),
            StatCard(
              child: h2h.isEmpty
                  ? Text(
                      l10n.noRecentMeetingsLong,
                      style: TextStyle(color: context.colors.muted),
                    )
                  : Column(
                      children: [
                        for (final game in h2h)
                          GameResultTile(game: game, teamId: a.id, opponent: b),
                      ],
                    ),
            ),

            SectionTitle(l10n.injuryReport),
            _InjuryReportCard(teams: [a, b]),
          ],
        ),
      ),
    );
  }
}

/// How many recent completed games the form and comparison sections use.
const _recentGameCount = 5;

/// Crests, projected score, win probability, venue toggle.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.projection,
    required this.venue,
    required this.onVenueChanged,
  });

  final MatchupProjection projection;
  final MatchupVenue venue;
  final ValueChanged<MatchupVenue> onVenueChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final a = projection.teamA;
    final b = projection.teamB;
    final margin = projection.isPickEm
        ? l10n.marginEven
        : l10n.marginBy(
            projection.favorite.abbreviation,
            l10n.trimmed(projection.spread),
          );

    return StatCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
      child: Column(
        children: [
          Row(
            children: [
              LabelPill(l10n.gamePreview),
              const Spacer(),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: context.colors.border),
                ),
                child: Icon(
                  venue == MatchupVenue.neutral
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
                      l10n.scoreLine(
                        l10n.decimal(projection.teamAScore, 0),
                        l10n.decimal(projection.teamBScore, 0),
                      ),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                    Text(
                      l10n.projected,
                      style: TextStyle(
                        color: context.colors.muted,
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
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.winProbability.toUpperCase(),
                style: TextStyle(
                  color: context.colors.muted,
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
                child: MetricPill(label: l10n.margin, value: margin),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: MetricPill(
                  label: l10n.combined,
                  value: l10n.decimal(projection.projectedTotal, 0),
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
                  label: Text(l10n.venueAt(a.abbreviation)),
                ),
                ButtonSegment(
                  value: MatchupVenue.neutral,
                  label: Text(l10n.venueNeutral),
                ),
                ButtonSegment(
                  value: MatchupVenue.teamBHome,
                  label: Text(l10n.venueAt(b.abbreviation)),
                ),
              ],
              selected: {venue},
              onSelectionChanged: (s) => onVenueChanged(s.first),
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
            label: Text(l10n.comparePlayers),
          ),
        ],
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
          style: TextStyle(color: context.colors.muted, fontSize: 13),
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
    const style = TextStyle(fontWeight: FontWeight.w700, fontSize: 15);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(a.abbreviation, style: style),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            context.l10n.dotSeparator.trim(),
            style: TextStyle(color: context.colors.muted),
          ),
        ),
        Text(b.abbreviation, style: style),
      ],
    );
  }
}

class _FactorTile extends StatelessWidget {
  const _FactorTile({required this.factor, required this.a, required this.b});

  final MatchupFactor factor;
  final Team a;
  final Team b;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final favors = factor.favors;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18),
      title: Text(
        l10n.factorName(factor),
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
      subtitle: Text(
        l10n.factorDetail(factor, a, b),
        style: TextStyle(color: context.colors.muted, fontSize: 12.5),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: ShapeDecoration(
          color: favors == null
              ? context.colors.surfaceHigh
              : context.colors.accent,
          shape: const StadiumBorder(),
        ),
        child: Text(
          favors?.abbreviation ?? l10n.factorEven,
          style: TextStyle(
            color: favors == null
                ? context.colors.muted
                : context.colors.onAccent,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

/// Last few results for each team as W/L chips.
class _RecentFormCard extends StatelessWidget {
  const _RecentFormCard({required this.teams});

  final List<Team> teams;

  @override
  Widget build(BuildContext context) {
    final repo = StatsScope.of(context);
    return StatCard(
      child: Column(
        children: [
          for (final team in teams)
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
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  FormStrip(
                    teamId: team.id,
                    games: repo.recentGames(team.id, limit: _recentGameCount),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Questionable / out players for each team.
class _InjuryReportCard extends StatelessWidget {
  const _InjuryReportCard({required this.teams});

  final List<Team> teams;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final repo = StatsScope.of(context);
    return StatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (index, team) in teams.indexed) ...[
            if (index > 0) ...[
              const SizedBox(height: 6),
              const Divider(),
              const SizedBox(height: 10),
            ],
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
            if (repo.injuryReport(team.id) case final injuries
                when injuries.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  l10n.noPlayersListed,
                  style: TextStyle(color: context.colors.muted),
                ),
              )
            else
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
                                  color: context.colors.muted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(text: p.fullName),
                              if (p.injuryNote != null)
                                TextSpan(
                                  text: '${l10n.dotSeparator}${p.injuryNote}',
                                  style: TextStyle(color: context.colors.muted),
                                ),
                            ],
                          ),
                        ),
                      ),
                      PlayerStatusChip(status: p.status, compact: true),
                    ],
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

enum _RecentMetric {
  scored('recentScored'),
  allowed('recentAllowed'),
  margin('recentMargin');

  const _RecentMetric(this.labelKey);

  final String labelKey;
}

/// Compares each team's averages over its most recent completed games.
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

  /// The most recent completed games with a final score.
  List<GameStats> _completedGames(List<GameStats> games) {
    final completed =
        games
            .where(
              (game) =>
                  game.isFinal &&
                  game.home.score != null &&
                  game.away.score != null,
            )
            .toList()
          ..sort((x, y) => y.startTime.compareTo(x.startTime));
    return completed.take(_recentGameCount).toList();
  }

  /// A team's per-game average for [metric], or null with no games.
  double? _average(List<GameStats> games, String teamId, _RecentMetric metric) {
    var sum = 0.0;
    var count = 0;
    for (final game in games) {
      if (game.homeTeamId != teamId && game.awayTeamId != teamId) continue;
      final isHome = game.homeTeamId == teamId;
      final scored = isHome ? game.home.score! : game.away.score!;
      final allowed = isHome ? game.away.score! : game.home.score!;
      sum += switch (metric) {
        _RecentMetric.scored => scored,
        _RecentMetric.allowed => allowed,
        _RecentMetric.margin => scored - allowed,
      };
      count++;
    }
    return count == 0 ? null : sum / count;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final recentA = _completedGames(gamesA);
    final recentB = _completedGames(gamesB);

    if (recentA.isEmpty && recentB.isEmpty) {
      return Text(
        l10n.noCompletedGames,
        style: TextStyle(color: context.colors.muted),
      );
    }

    final headStyle = TextStyle(
      color: context.colors.text,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.3,
    );
    final colorA = teamColor(context, a);
    final colorB = teamColor(context, b);

    return Column(
      children: [
        Row(
          children: [
            TeamBadge(team: a, size: 28),
            const SizedBox(width: 8),
            Text(a.abbreviation, style: headStyle),
            const Spacer(),
            Text(b.abbreviation, style: headStyle),
            const SizedBox(width: 8),
            TeamBadge(team: b, size: 28),
          ],
        ),
        const SizedBox(height: 4),
        for (final metric in _RecentMetric.values)
          StatCompareRow(
            def: StatDef(
              'recent_${metric.name}',
              metric.labelKey,
              decimals: 1,
              higherIsBetter: metric != _RecentMetric.allowed,
              signed: metric == _RecentMetric.margin,
            ),
            valueA: _average(recentA, a.id, metric),
            valueB: _average(recentB, b.id, metric),
            colorA: colorA,
            colorB: colorB,
          ),
        const SizedBox(height: 8),
        Text(
          l10n.recentGamesCount(
            a.abbreviation,
            recentA.length,
            b.abbreviation,
            recentB.length,
          ),
          style: TextStyle(color: context.colors.muted, fontSize: 12),
        ),
      ],
    );
  }
}
