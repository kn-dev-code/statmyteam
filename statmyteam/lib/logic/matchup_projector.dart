import 'dart:math' as math;

import '../models/models.dart';

/// Where the game is played, relative to team A.
enum MatchupVenue {
  teamAHome,
  teamBHome,
  neutral;
}

/// One reason the projection leans a certain way.
class MatchupFactor {
  const MatchupFactor({
    required this.title,
    required this.detail,
    this.favors,
  });

  final String title;
  final String detail;

  /// The team this factor helps, or null when it is even.
  final Team? favors;
}

class MatchupProjection {
  const MatchupProjection({
    required this.teamA,
    required this.teamB,
    required this.venue,
    required this.teamAWinChance,
    required this.teamAScore,
    required this.teamBScore,
    required this.factors,
  });

  final Team teamA;
  final Team teamB;
  final MatchupVenue venue;

  /// Probability team A wins, 0–1.
  final double teamAWinChance;
  final double teamAScore;
  final double teamBScore;
  final List<MatchupFactor> factors;

  double get teamBWinChance => 1 - teamAWinChance;

  Team get favorite => teamAWinChance >= 0.5 ? teamA : teamB;

  double get favoriteWinChance => math.max(teamAWinChance, teamBWinChance);

  /// Projected margin for the favorite, rounded to the nearest half point.
  double get spread =>
      ((teamAScore - teamBScore).abs() * 2).roundToDouble() / 2;

  String get spreadLabel {
    if (spread < 0.5) return "Pick'em";
    final points = spread == spread.roundToDouble()
        ? spread.toStringAsFixed(0)
        : spread.toStringAsFixed(1);
    return '${favorite.abbreviation} -$points';
  }

  double get projectedTotal => teamAScore + teamBScore;
}

/// Projects a football matchup from season stats, venue, and availability.
///
/// Steps:
/// 1. Team strength = 50% actual win rate + 50% Pythagorean win rate (from
///    points scored vs allowed, exponent 2.37). This damps lucky records.
///    The result is pulled [sampleRegression] of the way toward .500 because
///    a partial season is a small sample.
/// 2. Log5 turns the two strengths into a head-to-head chance.
/// 3. Home field adds [homeFieldEdge]; a neutral site adds nothing.
/// 4. Missing starters subtract: a starting QB is worth [qbImpact], any other
///    starter [starterImpact]. Questionable players count half.
/// 5. Projected points blend each offense with the opposing defense; the
///    margin is set from the win chance (~3% per point near even).
class MatchupProjector {
  MatchupProjector._();

  static const homeFieldEdge = 0.03;
  static const qbImpact = 0.06;
  static const starterImpact = 0.012;
  static const pythagoreanExponent = 2.37;
  static const winChancePerPoint = 0.03;
  static const sampleRegression = 0.25;

  static double pythagorean(Team team) {
    final pf = team.stat('ppg');
    final pa = team.stat('papg');
    if (pf <= 0 && pa <= 0) return 0.5;
    final a = math.pow(pf, pythagoreanExponent);
    final b = math.pow(pa, pythagoreanExponent);
    return a / (a + b);
  }

  static double strength(Team team) {
    final hasPoints = team.seasonStats.containsKey('ppg');
    final blended = hasPoints
        ? 0.5 * team.winPercentage + 0.5 * pythagorean(team)
        : team.winPercentage;
    final regressed = 0.5 + (1 - sampleRegression) * (blended - 0.5);
    return regressed.clamp(0.05, 0.95);
  }

  static double log5(double p, double q) {
    final denominator = p + q - 2 * p * q;
    return denominator == 0 ? 0.5 : (p - p * q) / denominator;
  }

  /// Win-probability lost to absences on this roster.
  static double availabilityPenalty(List<Player> roster) {
    var penalty = 0.0;
    for (final player in roster) {
      if (!player.isStarter) continue;
      final weight = player.position == 'QB' ? qbImpact : starterImpact;
      if (player.status.isUnavailable) {
        penalty += weight;
      } else if (player.status == PlayerStatus.questionable) {
        penalty += weight / 2;
      }
    }
    return penalty;
  }

  static MatchupProjection project({
    required Team teamA,
    required Team teamB,
    List<Player> rosterA = const [],
    List<Player> rosterB = const [],
    List<GameStats> headToHead = const [],
    MatchupVenue venue = MatchupVenue.teamAHome,
  }) {
    final strengthA = strength(teamA);
    final strengthB = strength(teamB);
    final venueEdge = switch (venue) {
      MatchupVenue.teamAHome => homeFieldEdge,
      MatchupVenue.teamBHome => -homeFieldEdge,
      MatchupVenue.neutral => 0.0,
    };
    final penaltyA = availabilityPenalty(rosterA);
    final penaltyB = availabilityPenalty(rosterB);

    final chance = (log5(strengthA, strengthB) + venueEdge - penaltyA + penaltyB)
        .clamp(0.03, 0.97);

    final expectedA = (teamA.stat('ppg') + teamB.stat('papg')) / 2;
    final expectedB = (teamB.stat('ppg') + teamA.stat('papg')) / 2;
    final total = expectedA + expectedB;
    final margin = ((chance - 0.5) / winChancePerPoint).clamp(-21.0, 21.0);

    return MatchupProjection(
      teamA: teamA,
      teamB: teamB,
      venue: venue,
      teamAWinChance: chance,
      teamAScore: math.max(0, total / 2 + margin / 2),
      teamBScore: math.max(0, total / 2 - margin / 2),
      factors: [
        _compare(
          'Record',
          teamA,
          teamB,
          teamA.winPercentage,
          teamB.winPercentage,
          '${teamA.abbreviation} ${teamA.record} vs '
              '${teamB.abbreviation} ${teamB.record}',
        ),
        _compare(
          'Scoring margin',
          teamA,
          teamB,
          teamA.stat('ppg') - teamA.stat('papg'),
          teamB.stat('ppg') - teamB.stat('papg'),
          '${_signed(teamA.stat('ppg') - teamA.stat('papg'))} vs '
              '${_signed(teamB.stat('ppg') - teamB.stat('papg'))} points per game',
        ),
        _compare(
          'Offense',
          teamA,
          teamB,
          teamA.stat('ypg'),
          teamB.stat('ypg'),
          '${teamA.stat('ypg').toStringAsFixed(1)} vs '
              '${teamB.stat('ypg').toStringAsFixed(1)} yards per game',
        ),
        _compare(
          'Defense',
          teamA,
          teamB,
          -teamA.stat('yapg'),
          -teamB.stat('yapg'),
          '${teamA.stat('yapg').toStringAsFixed(1)} vs '
              '${teamB.stat('yapg').toStringAsFixed(1)} yards allowed per game',
        ),
        _compare(
          'Turnovers',
          teamA,
          teamB,
          teamA.stat('toDiff'),
          teamB.stat('toDiff'),
          '${_signed(teamA.stat('toDiff'), 0)} vs '
              '${_signed(teamB.stat('toDiff'), 0)} turnover differential',
        ),
        _venueFactor(teamA, teamB, venue),
        _availabilityFactor(teamA, teamB, rosterA, rosterB, penaltyA, penaltyB),
        _headToHeadFactor(teamA, teamB, headToHead),
      ],
    );
  }

  static MatchupFactor _compare(
    String title,
    Team a,
    Team b,
    double valueA,
    double valueB,
    String detail,
  ) {
    const epsilon = 0.0001;
    final favors = (valueA - valueB).abs() < epsilon
        ? null
        : (valueA > valueB ? a : b);
    return MatchupFactor(title: title, detail: detail, favors: favors);
  }

  static MatchupFactor _venueFactor(Team a, Team b, MatchupVenue venue) {
    return switch (venue) {
      MatchupVenue.neutral => const MatchupFactor(
          title: 'Venue',
          detail: 'Neutral site, no home-field edge',
        ),
      MatchupVenue.teamAHome => MatchupFactor(
          title: 'Venue',
          detail: '${a.city} home field, worth about 3%',
          favors: a,
        ),
      MatchupVenue.teamBHome => MatchupFactor(
          title: 'Venue',
          detail: '${b.city} home field, worth about 3%',
          favors: b,
        ),
    };
  }

  static MatchupFactor _availabilityFactor(
    Team a,
    Team b,
    List<Player> rosterA,
    List<Player> rosterB,
    double penaltyA,
    double penaltyB,
  ) {
    String missing(Team team, List<Player> roster) {
      final names = [
        for (final p in roster)
          if (p.isStarter && p.status != PlayerStatus.active)
            '${p.position} ${p.lastName} (${p.status.shortLabel})',
      ];
      return names.isEmpty
          ? '${team.abbreviation} healthy'
          : '${team.abbreviation}: ${names.join(', ')}';
    }

    const epsilon = 0.0001;
    return MatchupFactor(
      title: 'Availability',
      detail: '${missing(a, rosterA)} · ${missing(b, rosterB)}',
      favors: (penaltyA - penaltyB).abs() < epsilon
          ? null
          : (penaltyA < penaltyB ? a : b),
    );
  }

  static MatchupFactor _headToHeadFactor(
    Team a,
    Team b,
    List<GameStats> games,
  ) {
    if (games.isEmpty) {
      return const MatchupFactor(
        title: 'Head-to-head',
        detail: 'No recent meetings',
      );
    }
    final winsA = games.where((g) => g.winnerTeamId == a.id).length;
    final winsB = games.where((g) => g.winnerTeamId == b.id).length;
    return MatchupFactor(
      title: 'Head-to-head',
      detail: '${a.abbreviation} $winsA–$winsB ${b.abbreviation} in the last '
          '${games.length} meeting${games.length == 1 ? '' : 's'} '
          '(context only, not weighted)',
      favors: winsA == winsB ? null : (winsA > winsB ? a : b),
    );
  }

  static String _signed(double value, [int decimals = 1]) {
    final text = value.toStringAsFixed(decimals);
    return value > 0 ? '+$text' : text;
  }
}
