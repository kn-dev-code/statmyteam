import 'package:flutter/material.dart';

import '../logic/matchup_projector.dart';
import '../models/models.dart';
import '../screens/matchup_screen.dart';
import '../state/favorites_scope.dart';
import '../state/stats_scope.dart';
import '../theme/app_theme.dart';
import 'app_chrome.dart';
import 'stats_widgets.dart';

/// Projection for two teams using the shared repository.
MatchupProjection projectMatchup(
  BuildContext context,
  Team a,
  Team b, {
  MatchupVenue venue = MatchupVenue.teamAHome,
}) {
  final repo = StatsScope.of(context);
  return MatchupProjector.project(
    teamA: a,
    teamB: b,
    rosterA: repo.rosterFor(a.id),
    rosterB: repo.rosterFor(b.id),
    headToHead: repo.headToHead(a.id, b.id),
    venue: venue,
  );
}

/// Card for a two-team matchup: label pill, bookmark toggle, both crests,
/// the projected score, and win-chance pills along the bottom.
class MatchupCard extends StatelessWidget {
  const MatchupCard({
    super.key,
    required this.teamA,
    required this.teamB,
    this.label = 'Saved matchup',
  });

  final Team teamA;
  final Team teamB;
  final String label;

  @override
  Widget build(BuildContext context) {
    final favorites = FavoritesScope.of(context);
    final saved = favorites.isFavoriteMatchup(teamA.id, teamB.id);
    final p = projectMatchup(context, teamA, teamB);
    final pctA = (p.teamAWinChance * 100).round();
    final pctB = 100 - pctA;

    void open() => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MatchupScreen(teamA: teamA, teamB: teamB),
      ),
    );

    return Material(
      color: AppColors.surface,
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
                  LabelPill(label),
                  const Spacer(),
                  RoundIconButton(
                    tooltip: saved ? 'Remove saved matchup' : 'Save matchup',
                    icon: saved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    size: 48,
                    outlined: true,
                    iconColor: saved ? AppColors.orange : AppColors.ink,
                    onPressed: () =>
                        favorites.toggleMatchup(teamA.id, teamB.id),
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
                          '${p.teamAScore.round()} : ${p.teamBScore.round()}',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
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
                  Expanded(child: _Side(team: teamB)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: MetricPill(
                      label: teamA.abbreviation,
                      value: '$pctA%',
                      valueColor: pctA >= pctB ? AppColors.accent : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: MetricPill(
                      label: 'Win',
                      value: p.favorite.abbreviation,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: MetricPill(
                      label: teamB.abbreviation,
                      value: '$pctB%',
                      valueColor: pctB > pctA ? AppColors.accent : null,
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
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
      ],
    );
  }
}

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

    return Material(
      borderRadius: BorderRadius.circular(AppTheme.radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MatchupScreen(teamA: teamA, teamB: teamB),
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
          child: SizedBox(
            height: 210,
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
                      const Text(
                        'GAME\nPREVIEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          height: 0.98,
                          letterSpacing: -0.5,
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
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.black,
                            ),
                            children: [
                              TextSpan(
                                text: '${p.favorite.abbreviation} $favPct%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const TextSpan(text: ' to win · neutral site'),
                            ],
                          ),
                        ),
                      ),
                    ],
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
          style: TextStyle(
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
          child: const Text(
            'vs',
            style: TextStyle(
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
