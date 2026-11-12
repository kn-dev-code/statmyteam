import '../models/models.dart';
import 'football_stats.dart';

export 'football_stats.dart' show StatDef;

/// Team-level stat lines, position labels, and strength/weakness copy
/// for each sport StatMyTeam can compare.
class SportStats {
  SportStats._();

  static const basketballTeamStats = <StatDef>[
    StatDef('ppg', 'Points / game', decimals: 1),
    StatDef('papg', 'Points allowed / game', decimals: 1, higherIsBetter: false),
    StatDef('rpg', 'Rebounds / game', decimals: 1),
    StatDef('apg', 'Assists / game', decimals: 1),
    StatDef('spg', 'Steals / game', decimals: 1),
    StatDef('bpg', 'Blocks / game', decimals: 1),
    StatDef('fgPct', 'Field goal %', decimals: 1, isPercent: true),
    StatDef('threePct', 'Three-point %', decimals: 1, isPercent: true),
    StatDef('toDiff', 'Turnover differential', signed: true),
  ];

  static const soccerTeamStats = <StatDef>[
    StatDef('ppg', 'Goals / game', decimals: 2),
    StatDef('papg', 'Goals allowed / game', decimals: 2, higherIsBetter: false),
    StatDef('possession', 'Possession', decimals: 1, isPercent: true),
    StatDef('shotsPg', 'Shots / game', decimals: 1),
    StatDef('sogPg', 'Shots on target / game', decimals: 1),
    StatDef('xg', 'Expected goals', decimals: 2),
    StatDef('xga', 'Expected goals against', decimals: 2, higherIsBetter: false),
    StatDef('cleanSheetPct', 'Clean sheet rate', decimals: 1, isPercent: true),
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
  };

  static const _soccerPlayerKeys = <String, List<String>>{
    'GK': ['gp', 'saves', 'ga', 'cleanSheets', 'savePct'],
    'DEF': ['gp', 'tkl', 'int', 'clr', 'passPct', 'goals'],
    'MID': ['gp', 'goals', 'ast', 'keyPass', 'passPct', 'tkl'],
    'FWD': ['gp', 'goals', 'ast', 'shots', 'sog', 'xg'],
  };

  static const _extraPlayerStats = <String, StatDef>{
    'pts': StatDef('pts', 'Points', decimals: 1),
    'reb': StatDef('reb', 'Rebounds', decimals: 1),
    'ast': StatDef('ast', 'Assists', decimals: 1),
    'stl': StatDef('stl', 'Steals', decimals: 1),
    'blk': StatDef('blk', 'Blocks', decimals: 1),
    'tov': StatDef('tov', 'Turnovers', decimals: 1, higherIsBetter: false),
    'saves': StatDef('saves', 'Saves'),
    'ga': StatDef('ga', 'Goals allowed', higherIsBetter: false),
    'cleanSheets': StatDef('cleanSheets', 'Clean sheets'),
    'savePct': StatDef('savePct', 'Save %', decimals: 1, isPercent: true),
    'int': StatDef('int', 'Interceptions'),
    'clr': StatDef('clr', 'Clearances'),
    'passPct': StatDef('passPct', 'Pass %', decimals: 1, isPercent: true),
    'goals': StatDef('goals', 'Goals'),
    'keyPass': StatDef('keyPass', 'Key passes'),
    'shots': StatDef('shots', 'Shots'),
    'sog': StatDef('sog', 'Shots on target'),
    'xg': StatDef('xg', 'Expected goals', decimals: 1),
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

  static String positionName(Sport sport, String position) => switch (sport) {
        Sport.basketball => switch (position) {
            'PG' => 'Point guard',
            'SG' => 'Shooting guard',
            'SF' => 'Small forward',
            'PF' => 'Power forward',
            'C' => 'Center',
            _ => position,
          },
        Sport.soccer => switch (position) {
            'GK' => 'Goalkeeper',
            'DEF' => 'Defender',
            'MID' => 'Midfielder',
            'FWD' => 'Forward',
            _ => position,
          },
        _ => FootballStats.positionNames[position] ?? position,
      };

  static const _copy = <String, (String strength, String weakness)>{
    'ppg': ('Explosive offense', 'Struggles to score'),
    'papg': ('Stingy defense', 'Leaks points'),
    'ypg': ('Moves the chains', 'Stalled offense'),
    'passYpg': ('Aerial attack', 'Limited passing game'),
    'rushYpg': ('Physical run game', 'Can\'t run the ball'),
    'yapg': ('Stout defense', 'Gives up yards'),
    'toDiff': ('Wins the turnover battle', 'Gives the ball away'),
    'sacks': ('Gets after the passer', 'Rarely pressures the QB'),
    'thirdPct': ('Converts on schedule', 'Stalls on third down'),
    'redZonePct': ('Finishes drives', 'Settles for field goals'),
    'rpg': ('Dominates the glass', 'Loses the rebound battle'),
    'apg': ('Unselfish ball movement', 'Isolation-heavy offense'),
    'spg': ('Creates turnovers', 'Passive on the ball'),
    'bpg': ('Protects the rim', 'Gives up easy looks'),
    'fgPct': ('Efficient shooting', 'Cold from the field'),
    'threePct': ('Lights out from three', 'Struggles from deep'),
    'possession': ('Controls the ball', 'Chases the game'),
    'shotsPg': ('Creates chances', 'Rarely tests the keeper'),
    'sogPg': ('Gets shots on target', 'Wayward finishing'),
    'xg': ('Creates high-quality chances', 'Low expected goals'),
    'xga': ('Limits quality chances against', 'Concedes dangerous looks'),
    'cleanSheetPct': ('Keeps clean sheets', 'Rarely shuts teams out'),
  };
}

/// One standout (or lacking) season trait versus league peers.
class TeamTrait {
  const TeamTrait({
    required this.def,
    required this.headline,
    required this.detail,
    required this.isStrength,
    required this.rank,
    required this.of,
  });

  final StatDef def;
  final String headline;
  final String detail;
  final bool isStrength;
  final int rank;
  final int of;
}

/// Strengths and weaknesses derived from how a team ranks in its league.
class TeamOutlook {
  const TeamOutlook({
    required this.team,
    required this.strengths,
    required this.weaknesses,
    required this.summary,
  });

  final Team team;
  final List<TeamTrait> strengths;
  final List<TeamTrait> weaknesses;
  final String summary;

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
        summary:
            'Not enough league data yet to grade ${team.displayName} against peers.',
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
      final scored = [
        for (final peer in group) (team: peer, value: peer.stat(def.key)),
      ]..sort((a, b) => def.higherIsBetter
          ? b.value.compareTo(a.value)
          : a.value.compareTo(b.value));

      final rank = scored.indexWhere((row) => row.team.id == team.id) + 1;
      if (rank == 0) continue;
      final value = team.stat(def.key);
      final mean = scored.fold<double>(0, (sum, row) => sum + row.value) /
          scored.length;
      final betterThanMean =
          def.higherIsBetter ? value > mean : value < mean;
      final copy = SportStats._copy[def.key];
      final of = scored.length;

      if (rank <= cutoff && betterThanMean) {
        strengths.add(TeamTrait(
          def: def,
          headline: copy?.$1 ?? 'Above average ${def.label.toLowerCase()}',
          detail: '${def.format(value)} · $rank${_ordinal(rank)} of $of '
              'in ${team.league?.label ?? 'the league'}',
          isStrength: true,
          rank: rank,
          of: of,
        ));
      } else if (rank > of - cutoff && !betterThanMean) {
        weaknesses.add(TeamTrait(
          def: def,
          headline: copy?.$2 ?? 'Below average ${def.label.toLowerCase()}',
          detail: '${def.format(value)} · $rank${_ordinal(rank)} of $of '
              'in ${team.league?.label ?? 'the league'}',
          isStrength: false,
          rank: rank,
          of: of,
        ));
      }
    }

    strengths.sort((a, b) => a.rank.compareTo(b.rank));
    weaknesses.sort((a, b) => b.rank.compareTo(a.rank));

    return TeamOutlook(
      team: team,
      strengths: strengths.take(3).toList(),
      weaknesses: weaknesses.take(3).toList(),
      summary: _summary(team, strengths, weaknesses),
    );
  }

  static String _summary(
    Team team,
    List<TeamTrait> strengths,
    List<TeamTrait> weaknesses,
  ) {
    if (strengths.isEmpty && weaknesses.isEmpty) {
      return '${team.displayName} grades out as a middle-of-the-pack '
          '${team.league?.label ?? ''} club this season — no stat '
          'stands far above or below the league.';
    }
    final buffer = StringBuffer(team.displayName);
    if (strengths.isNotEmpty) {
      buffer.write(' is strongest in ${strengths.first.headline.toLowerCase()}');
      if (strengths.length > 1) {
        buffer.write(' and ${strengths[1].headline.toLowerCase()}');
      }
      buffer.write('.');
    } else {
      buffer.write(' does not have a clear statistical edge this season.');
    }
    if (weaknesses.isNotEmpty) {
      buffer.write(' The main concern is ${weaknesses.first.headline.toLowerCase()}');
      buffer.write(' (${weaknesses.first.detail.split(' · ').first}).');
    }
    return buffer.toString();
  }
}

String _ordinal(int n) {
  if (n % 100 >= 11 && n % 100 <= 13) return 'th';
  return switch (n % 10) {
    1 => 'st',
    2 => 'nd',
    3 => 'rd',
    _ => 'th',
  };
}
