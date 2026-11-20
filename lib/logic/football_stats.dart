import '../models/models.dart';

/// How a stat is formatted and which direction is "better". Values are
/// displayed with `AppLocalizations.statValue`, which formats them for the
/// current locale.
///
/// [labelKey] names the stat's display label; the UI resolves it through
/// localization (`AppLocalizations.statLabel`). Unknown keys display as-is.
class StatDef {
  const StatDef(
    this.key,
    this.labelKey, {
    this.decimals = 0,
    this.isPercent = false,
    this.higherIsBetter = true,
    this.signed = false,
  });

  final String key;
  final String labelKey;
  final int decimals;

  /// Stored as 0–1, shown as a percentage.
  final bool isPercent;
  final bool higherIsBetter;

  /// Show a leading `+` on positive values (e.g. turnover differential).
  final bool signed;
}

/// Position groupings used for roster sections and player comparison.
/// Display names come from localization (`positionGroupName`).
enum PositionGroup {
  quarterback({'QB'}),
  runningBack({'RB', 'FB'}),
  receiver({'WR', 'TE'}),
  offensiveLine({'OL'}),
  frontSeven({'DE', 'DT', 'DL', 'LB'}),
  secondary({'CB', 'S', 'DB'}),
  specialTeams({'K', 'P', 'LS'});

  const PositionGroup(this.positions);

  final Set<String> positions;

  /// Groups with stats worth comparing. Offensive linemen are listed on
  /// rosters, but no per-player stats are published for them.
  static List<PositionGroup> get comparable => [
    for (final group in values)
      if (group != offensiveLine) group,
  ];

  static PositionGroup of(String position) => PositionGroup.values.firstWhere(
    (group) => group.positions.contains(position),
    orElse: () => PositionGroup.specialTeams,
  );
}

class FootballStats {
  FootballStats._();

  /// Team-level season stats, in display order.
  static const teamStats = <StatDef>[
    StatDef('ppg', 'pointsPerGame', decimals: 1),
    StatDef('papg', 'pointsAllowedPerGame', decimals: 1, higherIsBetter: false),
    StatDef('ypg', 'yardsPerGame', decimals: 1),
    StatDef('passYpg', 'passYardsPerGame', decimals: 1),
    StatDef('rushYpg', 'rushYardsPerGame', decimals: 1),
    StatDef('yapg', 'yardsAllowedPerGame', decimals: 1, higherIsBetter: false),
    StatDef('toDiff', 'turnoverDifferential', signed: true),
    StatDef('sacks', 'sacks'),
    StatDef('thirdPct', 'thirdDownConversion', decimals: 1, isPercent: true),
    StatDef('redZonePct', 'redZoneTdRate', decimals: 1, isPercent: true),
  ];

  static const _playerStats = <String, StatDef>{
    'gp': StatDef('gp', 'gamesPlayed'),
    // Passing
    'compPct': StatDef(
      'compPct',
      'completionPct',
      decimals: 1,
      isPercent: true,
    ),
    'passYds': StatDef('passYds', 'passYards'),
    'passTd': StatDef('passTd', 'passTd'),
    'intThrown': StatDef(
      'intThrown',
      'interceptionsThrown',
      higherIsBetter: false,
    ),
    'rating': StatDef('rating', 'passerRating', decimals: 1),
    // Rushing
    'rushAtt': StatDef('rushAtt', 'carries'),
    'rushYds': StatDef('rushYds', 'rushYards'),
    'ypc': StatDef('ypc', 'yardsPerCarry', decimals: 1),
    'rushTd': StatDef('rushTd', 'rushTd'),
    'fum': StatDef('fum', 'fumblesLost', higherIsBetter: false),
    // Receiving
    'tgt': StatDef('tgt', 'targets'),
    'rec': StatDef('rec', 'receptions'),
    'recYds': StatDef('recYds', 'receivingYards'),
    'ypr': StatDef('ypr', 'yardsPerCatch', decimals: 1),
    'recTd': StatDef('recTd', 'receivingTd'),
    // Defense
    'tkl': StatDef('tkl', 'tackles'),
    'sacks': StatDef('sacks', 'sacks', decimals: 1),
    'tfl': StatDef('tfl', 'tacklesForLoss'),
    'qbHits': StatDef('qbHits', 'qbHits'),
    'defInt': StatDef('defInt', 'interceptions'),
    'pd': StatDef('pd', 'passesDefended'),
    'ff': StatDef('ff', 'forcedFumbles'),
    // Kicking
    'fgm': StatDef('fgm', 'fieldGoalsMade'),
    'fga': StatDef('fga', 'fieldGoalsAttempted'),
    'fgPct': StatDef('fgPct', 'fieldGoalPct', decimals: 1, isPercent: true),
    'long': StatDef('long', 'longestFg'),
    'xpPct': StatDef('xpPct', 'extraPointPct', decimals: 1, isPercent: true),
  };

  static const _keysByPosition = <String, List<String>>{
    'QB': [
      'gp',
      'compPct',
      'passYds',
      'passTd',
      'intThrown',
      'rating',
      'rushYds',
      'rushTd',
    ],
    'RB': ['gp', 'rushAtt', 'rushYds', 'ypc', 'rushTd', 'rec', 'recYds', 'fum'],
    'FB': ['gp', 'rushAtt', 'rushYds', 'ypc', 'rushTd', 'rec', 'recYds', 'fum'],
    'WR': ['gp', 'tgt', 'rec', 'recYds', 'ypr', 'recTd'],
    'TE': ['gp', 'tgt', 'rec', 'recYds', 'ypr', 'recTd'],
    'DE': ['gp', 'tkl', 'sacks', 'tfl', 'qbHits', 'ff'],
    'DT': ['gp', 'tkl', 'sacks', 'tfl', 'qbHits', 'ff'],
    'DL': ['gp', 'tkl', 'sacks', 'tfl', 'qbHits', 'ff'],
    'LB': ['gp', 'tkl', 'sacks', 'tfl', 'defInt', 'pd', 'ff'],
    'CB': ['gp', 'tkl', 'defInt', 'pd', 'ff'],
    'S': ['gp', 'tkl', 'defInt', 'pd', 'ff'],
    'DB': ['gp', 'tkl', 'defInt', 'pd', 'ff'],
    'K': ['gp', 'fgm', 'fga', 'fgPct', 'long', 'xpPct'],
  };

  static StatDef playerStat(String key) =>
      _playerStats[key] ?? StatDef(key, key);

  /// Stat lines worth showing for a player at [position].
  static List<StatDef> forPosition(String position) => [
    for (final key in _keysByPosition[position] ?? const ['gp'])
      playerStat(key),
  ];

  /// Stats shared by both players first, then anything only one of them has.
  static List<StatDef> forComparison(Player a, Player b) {
    final keys = <String>[
      ...?_keysByPosition[a.position],
      for (final key in _keysByPosition[b.position] ?? const <String>[])
        if (!(_keysByPosition[a.position]?.contains(key) ?? false)) key,
    ];
    return [for (final key in keys) playerStat(key)];
  }
}
