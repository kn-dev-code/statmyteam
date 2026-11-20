import 'dart:math' as math;

import '../models/models.dart';

/// Where the game is played, relative to team A.
enum MatchupVenue { teamAHome, teamBHome, neutral }

/// What a [MatchupFactor] measures.
enum FactorKind {
  record,
  scoringMargin,

  /// Football: yards per game.
  offense,

  /// Football: yards allowed per game.
  defense,

  /// Football and basketball: turnover differential.
  turnovers,

  /// Basketball: field goal percentage.
  shooting,

  /// Basketball: rebounds per game.
  rebounding,

  /// Soccer: expected goals per game.
  chanceCreation,

  /// Soccer: expected goals against per game.
  chancePrevention,

  venue,
  availability,
  headToHead,
}

/// One reason the projection leans a certain way. Carries the numbers
/// behind it; the UI turns them into localized text.
class MatchupFactor {
  const MatchupFactor({
    required this.kind,
    this.favors,
    this.valueA,
    this.valueB,
    this.missingA = const [],
    this.missingB = const [],
    this.winsA = 0,
    this.winsB = 0,
    this.meetings = 0,
  });

  final FactorKind kind;

  /// The team this factor helps, or null when it is even.
  final Team? favors;

  /// Each side's number for stat-comparison kinds. For [FactorKind.venue],
  /// [valueA] is the home edge as a 0–1 win-chance bonus.
  final double? valueA;
  final double? valueB;

  /// Starters who are not fully available ([FactorKind.availability]).
  final List<Player> missingA;
  final List<Player> missingB;

  /// Head-to-head wins over the last [meetings] games.
  final int winsA;
  final int winsB;
  final int meetings;
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

  /// Below this the game is a toss-up ("pick'em").
  bool get isPickEm => spread < 0.5;

  double get projectedTotal => teamAScore + teamBScore;
}

/// How scores in one sport translate into win chances.
class SportModel {
  const SportModel({
    required this.pythagoreanExponent,
    required this.winChancePerPoint,
    required this.homeFieldEdge,
    required this.maxMargin,
  });

  /// Exponent for the Pythagorean win rate (points for vs against).
  final double pythagoreanExponent;

  /// Win-chance change per point (or goal) of projected margin near even.
  final double winChancePerPoint;

  /// Win-chance bonus for playing at home.
  final double homeFieldEdge;

  /// Largest projected margin, in points (or goals).
  final double maxMargin;

  static const football = SportModel(
    pythagoreanExponent: 2.37,
    winChancePerPoint: 0.03,
    homeFieldEdge: 0.03,
    maxMargin: 21,
  );

  /// NBA: Pythagorean exponent about 14, about 3% per point near even, and
  /// home court worth about two points.
  static const basketball = SportModel(
    pythagoreanExponent: 14,
    winChancePerPoint: 0.03,
    homeFieldEdge: 0.06,
    maxMargin: 25,
  );

  /// Soccer is low scoring, so each goal moves the chance much more.
  static const soccer = SportModel(
    pythagoreanExponent: 1.3,
    winChancePerPoint: 0.2,
    homeFieldEdge: 0.05,
    maxMargin: 3,
  );

  static SportModel of(Sport sport) => switch (sport) {
    Sport.basketball => basketball,
    Sport.soccer => soccer,
    _ => football,
  };
}

/// Projects a matchup from season stats, venue, and availability.
///
/// Steps:
/// 1. Team strength = 50% actual win rate + 50% Pythagorean win rate (from
///    points scored vs allowed, with a per-sport exponent). This damps lucky
///    records. The result is pulled [sampleRegression] of the way toward
///    .500 because a partial season is a small sample.
/// 2. Log5 turns the two strengths into a head-to-head chance.
/// 3. Home field adds the sport's [SportModel.homeFieldEdge]; a neutral
///    site adds nothing.
/// 4. Missing starters subtract: a starting QB is worth [qbImpact], any other
///    starter [starterImpact]. Questionable players count half.
/// 5. Projected scores blend each offense with the opposing defense; the
///    margin is set from the win chance ([SportModel.winChancePerPoint]).
///
/// Stat factors are listed only when both teams report the stat, so a sport
/// never shows another sport's numbers (such as yards for NBA teams).
class MatchupProjector {
  MatchupProjector._();

  /// The football home edge (see [SportModel.homeFieldEdge] for others).
  static const homeFieldEdge = 0.03;
  static const qbImpact = 0.06;
  static const starterImpact = 0.012;
  static const sampleRegression = 0.25;

  static double pythagorean(Team team) {
    final pf = team.stat('ppg');
    final pa = team.stat('papg');
    if (pf <= 0 && pa <= 0) return 0.5;
    final exponent = SportModel.of(team.sport).pythagoreanExponent;
    final a = math.pow(pf, exponent);
    final b = math.pow(pa, exponent);
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
    final model = SportModel.of(teamA.sport);
    final strengthA = strength(teamA);
    final strengthB = strength(teamB);
    final venueEdge = switch (venue) {
      MatchupVenue.teamAHome => model.homeFieldEdge,
      MatchupVenue.teamBHome => -model.homeFieldEdge,
      MatchupVenue.neutral => 0.0,
    };
    final penaltyA = availabilityPenalty(rosterA);
    final penaltyB = availabilityPenalty(rosterB);

    final chance =
        (log5(strengthA, strengthB) + venueEdge - penaltyA + penaltyB).clamp(
          0.03,
          0.97,
        );

    final expectedA = (teamA.stat('ppg') + teamB.stat('papg')) / 2;
    final expectedB = (teamB.stat('ppg') + teamA.stat('papg')) / 2;
    final total = expectedA + expectedB;
    final margin = ((chance - 0.5) / model.winChancePerPoint).clamp(
      -model.maxMargin,
      model.maxMargin,
    );

    bool both(String key) =>
        teamA.seasonStats.containsKey(key) &&
        teamB.seasonStats.containsKey(key);

    MatchupFactor? stat(
      FactorKind kind,
      String key, {
      bool higherIsBetter = true,
    }) => both(key)
        ? _compare(
            kind,
            teamA,
            teamB,
            teamA.stat(key),
            teamB.stat(key),
            higherIsBetter: higherIsBetter,
          )
        : null;

    double marginOf(Team t) => t.stat('ppg') - t.stat('papg');

    return MatchupProjection(
      teamA: teamA,
      teamB: teamB,
      venue: venue,
      teamAWinChance: chance,
      teamAScore: math.max(0, total / 2 + margin / 2),
      teamBScore: math.max(0, total / 2 - margin / 2),
      factors: [
        _compare(
          FactorKind.record,
          teamA,
          teamB,
          teamA.winPercentage,
          teamB.winPercentage,
        ),
        if (both('ppg') && both('papg'))
          _compare(
            FactorKind.scoringMargin,
            teamA,
            teamB,
            marginOf(teamA),
            marginOf(teamB),
          ),
        ?stat(FactorKind.offense, 'ypg'),
        ?stat(FactorKind.defense, 'yapg', higherIsBetter: false),
        ?stat(FactorKind.shooting, 'fgPct'),
        ?stat(FactorKind.rebounding, 'rpg'),
        ?stat(FactorKind.chanceCreation, 'xg'),
        ?stat(FactorKind.chancePrevention, 'xga', higherIsBetter: false),
        ?stat(FactorKind.turnovers, 'toDiff'),
        _venueFactor(teamA, teamB, venue, model),
        _availabilityFactor(teamA, teamB, rosterA, rosterB, penaltyA, penaltyB),
        _headToHeadFactor(teamA, teamB, headToHead),
      ],
    );
  }

  static const _epsilon = 0.0001;

  static MatchupFactor _compare(
    FactorKind kind,
    Team a,
    Team b,
    double valueA,
    double valueB, {
    bool higherIsBetter = true,
  }) {
    final Team? favors;
    if ((valueA - valueB).abs() < _epsilon) {
      favors = null;
    } else {
      favors = (valueA > valueB) == higherIsBetter ? a : b;
    }
    return MatchupFactor(
      kind: kind,
      favors: favors,
      valueA: valueA,
      valueB: valueB,
    );
  }

  static MatchupFactor _venueFactor(
    Team a,
    Team b,
    MatchupVenue venue,
    SportModel model,
  ) => MatchupFactor(
    kind: FactorKind.venue,
    valueA: venue == MatchupVenue.neutral ? 0 : model.homeFieldEdge,
    favors: switch (venue) {
      MatchupVenue.neutral => null,
      MatchupVenue.teamAHome => a,
      MatchupVenue.teamBHome => b,
    },
  );

  static MatchupFactor _availabilityFactor(
    Team a,
    Team b,
    List<Player> rosterA,
    List<Player> rosterB,
    double penaltyA,
    double penaltyB,
  ) {
    List<Player> missing(List<Player> roster) => [
      for (final p in roster)
        if (p.isStarter && p.status != PlayerStatus.active) p,
    ];

    return MatchupFactor(
      kind: FactorKind.availability,
      missingA: missing(rosterA),
      missingB: missing(rosterB),
      favors: (penaltyA - penaltyB).abs() < _epsilon
          ? null
          : (penaltyA < penaltyB ? a : b),
    );
  }

  static MatchupFactor _headToHeadFactor(
    Team a,
    Team b,
    List<GameStats> games,
  ) {
    final winsA = games.where((g) => g.winnerTeamId == a.id).length;
    final winsB = games.where((g) => g.winnerTeamId == b.id).length;
    return MatchupFactor(
      kind: FactorKind.headToHead,
      winsA: winsA,
      winsB: winsB,
      meetings: games.length,
      favors: winsA == winsB ? null : (winsA > winsB ? a : b),
    );
  }
}
