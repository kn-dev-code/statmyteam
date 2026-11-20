import 'package:flutter/material.dart';

import '../data/stats_repository.dart';
import '../l10n/l10n.dart';
import '../logic/matchup_projector.dart';
import '../models/models.dart';
import '../screens/matchup_screen.dart';
import '../state/favorites_scope.dart';
import '../state/stats_scope.dart';
import '../theme/app_theme.dart';
import 'app_chrome.dart';
import 'stats_widgets.dart';

/// Projections memoized per repository: the inputs (rosters, results) are
/// immutable for a repository's lifetime, so each matchup and venue is
/// computed once instead of on every build.
final _projections =
    Expando<Map<(String, String, MatchupVenue), MatchupProjection>>();

/// Projection for two teams using the shared repository.
MatchupProjection projectMatchup(
  BuildContext context,
  Team a,
  Team b, {
  MatchupVenue venue = MatchupVenue.teamAHome,
}) {
  final repo = StatsScope.of(context);
  final cache = _projections[repo] ??= {};
  return cache.putIfAbsent((
    a.id,
    b.id,
    venue,
  ), () => _project(repo, a, b, venue));
}

MatchupProjection _project(
  StatsRepository repo,
  Team a,
  Team b,
  MatchupVenue venue,
) => MatchupProjector.project(
  teamA: a,
  teamB: b,
  rosterA: repo.rosterFor(a.id),
  rosterB: repo.rosterFor(b.id),
  headToHead: repo.headToHead(a.id, b.id),
  venue: venue,
);

/// Card for a two-team matchup: label pill, bookmark toggle, both crests,
/// the projected score, and win-chance pills along the bottom.
class MatchupCard extends StatelessWidget {
  const MatchupCard({
    super.key,
    required this.teamA,
    required this.teamB,
    this.label,
  });

  final Team teamA;
  final Team teamB;

  /// Corner label; defaults to "Saved matchup".
  final String? label;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final favorites = FavoritesScope.of(context);
    final saved = favorites.isFavoriteMatchup(teamA.id, teamB.id);
    // Saved pairs have no home team, so show (and open) a neutral site.
    final p = projectMatchup(
      context,
      teamA,
      teamB,
      venue: MatchupVenue.neutral,
    );
    final pctA = (p.teamAWinChance * 100).round();
    final pctB = 100 - pctA;

    void open() => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MatchupScreen(
          teamA: teamA,
          teamB: teamB,
          initialVenue: MatchupVenue.neutral,
        ),
      ),
    );

    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: open,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            children: [
              Row(
                children: [
                  LabelPill(label ?? l10n.savedMatchupLabel),
                  const Spacer(),
                  RoundIconButton(
                    tooltip: saved ? l10n.removeSavedMatchup : l10n.saveMatchup,
                    icon: saved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    size: 48,
                    outlined: true,
                    iconColor: saved ? AppColors.orange : context.colors.ink,
                    onPressed: () => saveWithFeedback(
                      context,
                      () => favorites.toggleMatchup(teamA.id, teamB.id),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _Side(team: teamA)),
                  Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: Column(
                      children: [
                        Text(
                          l10n.scoreLine(
                            l10n.decimal(p.teamAScore, 0),
                            l10n.decimal(p.teamBScore, 0),
                          ),
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
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
                  Expanded(child: _Side(team: teamB)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: MetricPill(
                      label: teamA.abbreviation,
                      value: l10n.percent(pctA / 100),
                      valueColor: pctA >= pctB ? context.colors.accent : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: MetricPill(
                      label: l10n.winLabel,
                      value: p.favorite.abbreviation,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: MetricPill(
                      label: teamB.abbreviation,
                      value: l10n.percent(pctB / 100),
                      valueColor: pctB > pctA ? context.colors.accent : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({required this.team});

  final Team team;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TeamBadge(team: team, size: 78),
        const SizedBox(height: 10),
        Text(
          '${team.city}\n${team.name}'.toUpperCase(),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
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

/// Width of the overlapping team badges in the banner corner.
const _badgeClearance = 112.0;

/// Green gradient banner highlighting one matchup, in place of a promo hero.
class FeaturedMatchupBanner extends StatelessWidget {
  const FeaturedMatchupBanner({
    super.key,
    required this.teamA,
    required this.teamB,
    required this.eyebrow,
  });

  final Team teamA;
  final Team teamB;
  final String eyebrow;

  @override
  Widget build(BuildContext context) {
    final p = projectMatchup(
      context,
      teamA,
      teamB,
      venue: MatchupVenue.neutral,
    );
    final favPct = (p.favoriteWinChance * 100).round();
    final l10n = context.l10n;
    final chance = l10n.favoriteChance(p.favorite.abbreviation, favPct);
    final toWin = l10n.favoriteToWinNeutral(chance);
    final chanceAt = toWin.indexOf(chance);

    return Material(
      borderRadius: BorderRadius.circular(AppTheme.radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MatchupScreen(
              teamA: teamA,
              teamB: teamB,
              initialVenue: MatchupVenue.neutral,
            ),
          ),
        ),
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.heroStart, AppColors.heroEnd],
            ),
          ),
          // At least 210 tall, but grows with large text instead of
          // overflowing.
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 210),
            child: Stack(
              children: [
                // Decorative field stripes and an oversized ball.
                Positioned.fill(
                  child: CustomPaint(painter: _FieldLinesPainter()),
                ),
                Positioned(
                  right: -36,
                  bottom: -40,
                  child: Transform.rotate(
                    angle: -0.5,
                    child: Icon(
                      Icons.sports_football,
                      size: 210,
                      color: Colors.white.withValues(alpha: 0.13),
                    ),
                  ),
                ),
                Positioned(
                  right: 18,
                  top: 18,
                  child: Row(
                    children: [
                      TeamBadge(team: teamA, size: 52),
                      Transform.translate(
                        offset: const Offset(-10, 0),
                        child: TeamBadge(team: teamB, size: 52),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                  // IntrinsicHeight lets the Spacer push the pills to the
                  // bottom while the banner sizes to its content.
                  child: IntrinsicHeight(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 210 - 42),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Right padding keeps the text clear of the team
                          // badges drawn in the top-right corner.
                          Padding(
                            padding: const EdgeInsets.only(
                              right: _badgeClearance,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  eyebrow.toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.gamePreviewHero.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                    height: 0.98,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          _VsPill(a: teamA, b: teamB),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: const ShapeDecoration(
                              color: Colors.white,
                              shape: StadiumBorder(),
                            ),
                            child: Text.rich(
                              TextSpan(
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.black,
                                ),
                                // Bold the "AUS 64%" part wherever the locale
                                // puts it in the sentence.
                                children: chanceAt < 0
                                    ? [TextSpan(text: toWin)]
                                    : [
                                        TextSpan(
                                          text: toWin.substring(0, chanceAt),
                                        ),
                                        TextSpan(
                                          text: chance,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        TextSpan(
                                          text: toWin.substring(
                                            chanceAt + chance.length,
                                          ),
                                        ),
                                      ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VsPill extends StatelessWidget {
  const _VsPill({required this.a, required this.b});

  final Team a;
  final Team b;

  @override
  Widget build(BuildContext context) {
    Widget side(Team t) => Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: const ShapeDecoration(
          color: AppColors.orange,
          shape: StadiumBorder(),
        ),
        child: Text(
          t.name.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.black,
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        side(a),
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Text(
            context.l10n.versusLower,
            style: const TextStyle(
              color: AppColors.black,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
        side(b),
      ],
    );
  }
}

class _FieldLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 2;
    for (var x = size.width * 0.45; x < size.width; x += 34) {
      canvas.drawLine(Offset(x, 0), Offset(x - 40, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
