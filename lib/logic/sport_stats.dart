import '../models/models.dart';
import 'football_stats.dart';

export 'football_stats.dart' show StatDef;

/// Team-level stat lines and per-position player stats for each sport
/// StatMyTeam can compare. Display text (labels, position names, trait
/// copy) is localized in the UI layer.
class SportStats {
  SportStats._();

  static const basketballTeamStats = <StatDef>[
    StatDef('ppg', 'pointsPerGame', decimals: 1),
    StatDef('papg', 'pointsAllowedPerGame', decimals: 1, higherIsBetter: false),
    StatDef('rpg', 'reboundsPerGame', decimals: 1),
    StatDef('apg', 'assistsPerGame', decimals: 1),
    StatDef('spg', 'stealsPerGame', decimals: 1),
    StatDef('bpg', 'blocksPerGame', decimals: 1),
    StatDef('fgPct', 'fieldGoalPct', decimals: 1, isPercent: true),
    StatDef('threePct', 'threePointPct', decimals: 1, isPercent: true),
    StatDef('toDiff', 'turnoverDifferential', signed: true),
  ];

  static const soccerTeamStats = <StatDef>[
    StatDef('ppg', 'goalsPerGame', decimals: 2),
    StatDef('papg', 'goalsAllowedPerGame', decimals: 2, higherIsBetter: false),
    StatDef('possession', 'possession', decimals: 1, isPercent: true),
    StatDef('shotsPg', 'shotsPerGame', decimals: 1),
    StatDef('sogPg', 'shotsOnTargetPerGame', decimals: 1),
    StatDef('xg', 'expectedGoals', decimals: 2),
    StatDef('xga', 'expectedGoalsAgainst', decimals: 2, higherIsBetter: false),
    StatDef('cleanSheetPct', 'cleanSheetRate', decimals: 1, isPercent: true),
  ];

  static List<StatDef> teamStats(Sport sport) => switch (sport) {
    Sport.basketball => basketballTeamStats,
    Sport.soccer => soccerTeamStats,
    _ => FootballStats.teamStats,
  };

  static const _basketballPlayerKeys = <String, List<String>>{
    'PG': ['gp', 'pts', 'ast', 'reb', 'fgPct', 'threePct', 'stl', 'tov'],
    'SG': ['gp', 'pts', 'reb', 'ast', 'fgPct', 'threePct', 'stl', 'tov'],
    'SF': ['gp', 'pts', 'reb', 'ast', 'fgPct', 'threePct', 'stl', 'blk'],
    'PF': ['gp', 'pts', 'reb', 'ast', 'fgPct', 'blk', 'stl'],
    'C': ['gp', 'pts', 'reb', 'ast', 'fgPct', 'blk', 'stl'],
    // ESPN rosters only distinguish guard / forward.
    'G': ['gp', 'pts', 'ast', 'reb', 'fgPct', 'threePct', 'stl', 'tov'],
    'F': ['gp', 'pts', 'reb', 'ast', 'fgPct', 'threePct', 'stl', 'blk'],
  };

  static const _soccerPlayerKeys = <String, List<String>>{
    'GK': ['gp', 'saves', 'ga', 'cleanSheets', 'savePct'],
    'DEF': ['gp', 'tkl', 'int', 'clr', 'passPct', 'goals'],
    'MID': ['gp', 'goals', 'ast', 'keyPass', 'passPct', 'tkl'],
    'FWD': ['gp', 'goals', 'ast', 'shots', 'sog', 'xg'],
  };

  static const _extraPlayerStats = <String, StatDef>{
    'pts': StatDef('pts', 'points', decimals: 1),
    'reb': StatDef('reb', 'rebounds', decimals: 1),
    'ast': StatDef('ast', 'assists', decimals: 1),
    'stl': StatDef('stl', 'steals', decimals: 1),
    'blk': StatDef('blk', 'blocks', decimals: 1),
    'threePct': StatDef(
      'threePct',
      'threePointPct',
      decimals: 1,
      isPercent: true,
    ),
    'tov': StatDef('tov', 'turnovers', decimals: 1, higherIsBetter: false),
    'saves': StatDef('saves', 'saves'),
    'ga': StatDef('ga', 'goalsAllowed', higherIsBetter: false),
    'cleanSheets': StatDef('cleanSheets', 'cleanSheets'),
    'savePct': StatDef('savePct', 'savePct', decimals: 1, isPercent: true),
    'int': StatDef('int', 'interceptions'),
    'clr': StatDef('clr', 'clearances'),
    'passPct': StatDef('passPct', 'passPct', decimals: 1, isPercent: true),
    'goals': StatDef('goals', 'goals'),
    'keyPass': StatDef('keyPass', 'keyPasses'),
    'shots': StatDef('shots', 'shots'),
    'sog': StatDef('sog', 'shotsOnTarget'),
    'xg': StatDef('xg', 'expectedGoals', decimals: 1),
  };

  static StatDef playerStat(String key) =>
      _extraPlayerStats[key] ?? FootballStats.playerStat(key);

  static List<StatDef> forPosition(Sport sport, String position) {
    final keys = switch (sport) {
      Sport.basketball => _basketballPlayerKeys[position],
      Sport.soccer => _soccerPlayerKeys[position],
      _ => null,
    };
    if (keys == null) return FootballStats.forPosition(position);
    return [for (final key in keys) playerStat(key)];
  }

  static List<StatDef> forComparison(Player a, Player b) {
    if (a.sport == Sport.football && b.sport == Sport.football) {
      return FootballStats.forComparison(a, b);
    }
    final seen = <String>{};
    return [
      for (final def in [
        ...forPosition(a.sport, a.position),
        ...forPosition(b.sport, b.position),
      ])
        if (seen.add(def.key)) def,
    ];
  }

  /// Team stat keys that have hand-written strength / weakness copy
  /// (`traitStrength` / `traitWeakness` in the ARB files). Other stats fall
  /// back to "Above / Below average `stat`".
  static const traitCopyKeys = {
    'ppg',
    'papg',
    'ypg',
    'passYpg',
    'rushYpg',
    'yapg',
    'toDiff',
    'sacks',
    'thirdPct',
    'redZonePct',
    'rpg',
    'apg',
    'spg',
    'bpg',
    'fgPct',
    'threePct',
    'possession',
    'shotsPg',
    'sogPg',
    'xg',
    'xga',
    'cleanSheetPct',
  };
}

/// One standout (or lacking) season trait versus league peers.
class TeamTrait {
  const TeamTrait({
    required this.def,
    required this.value,
    required this.isStrength,
    required this.rank,
    required this.of,
  });

  final StatDef def;

  /// The team's value for [def].
  final double value;
  final bool isStrength;

  /// 1-based rank among [of] league peers.
  final int rank;
  final int of;
}

/// Strengths and weaknesses derived from how a team ranks in its league.
class TeamOutlook {
  const TeamOutlook({
    required this.team,
    required this.strengths,
    required this.weaknesses,
    this.graded = true,
  });

  final Team team;
  final List<TeamTrait> strengths;
  final List<TeamTrait> weaknesses;

  /// False when the league has too few teams to grade against.
  final bool graded;

  /// Ranks [team] against [peers] (same sport and league) on each team stat.
  ///
  /// A stat is a strength when the team is in the top ~30% and better than
  /// average; a weakness when it is in the bottom ~30% and worse than average.
  factory TeamOutlook.analyze(Team team, List<Team> peers) {
    final group = [
      for (final peer in peers)
        if (peer.sport == team.sport && peer.league == team.league) peer,
    ];
    if (group.length < 2) {
      return TeamOutlook(
        team: team,
        strengths: const [],
        weaknesses: const [],
        graded: false,
      );
    }

    final defs = [
      for (final def in SportStats.teamStats(team.sport))
        if (group.any((t) => t.seasonStats.containsKey(def.key))) def,
    ];

    final cutoff = (group.length * 0.3).ceil().clamp(1, group.length);
    final strengths = <TeamTrait>[];
    final weaknesses = <TeamTrait>[];

    for (final def in defs) {
      final scored =
          [for (final peer in group) (team: peer, value: peer.stat(def.key))]
            ..sort(
              (a, b) => def.higherIsBetter
                  ? b.value.compareTo(a.value)
                  : a.value.compareTo(b.value),
            );

      final rank = scored.indexWhere((row) => row.team.id == team.id) + 1;
      if (rank == 0) continue;
      final value = team.stat(def.key);
      final mean =
          scored.fold<double>(0, (sum, row) => sum + row.value) / scored.length;
      final betterThanMean = def.higherIsBetter ? value > mean : value < mean;
      final of = scored.length;

      if (rank <= cutoff && betterThanMean) {
        strengths.add(
          TeamTrait(
            def: def,
            value: value,
            isStrength: true,
            rank: rank,
            of: of,
          ),
        );
      } else if (rank > of - cutoff && !betterThanMean) {
        weaknesses.add(
          TeamTrait(
            def: def,
            value: value,
            isStrength: false,
            rank: rank,
            of: of,
          ),
        );
      }
    }

    strengths.sort((a, b) => a.rank.compareTo(b.rank));
    weaknesses.sort((a, b) => b.rank.compareTo(a.rank));

    return TeamOutlook(
      team: team,
      strengths: strengths.take(3).toList(),
      weaknesses: weaknesses.take(3).toList(),
    );
  }
}
