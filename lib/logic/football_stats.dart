import '../models/models.dart';

/// How a stat is labelled, formatted, and which direction is "better".
class StatDef {
  const StatDef(
    this.key,
    this.label, {
    this.decimals = 0,
    this.isPercent = false,
    this.higherIsBetter = true,
    this.signed = false,
  });

  final String key;
  final String label;
  final int decimals;

  /// Stored as 0–1, shown as a percentage.
  final bool isPercent;
  final bool higherIsBetter;

  /// Show a leading `+` on positive values (e.g. turnover differential).
  final bool signed;

  String format(double value) {
    if (isPercent) return '${(value * 100).toStringAsFixed(decimals)}%';
    final text = value.toStringAsFixed(decimals);
    return signed && value > 0 ? '+$text' : text;
  }
}

/// Position groupings used for roster sections and player comparison.
enum PositionGroup {
  quarterback('QB', 'Quarterbacks', {'QB'}),
  runningBack('RB', 'Running backs', {'RB'}),
  receiver('WR / TE', 'Receivers', {'WR', 'TE'}),
  frontSeven('Front 7', 'Front seven', {'DE', 'DT', 'LB'}),
  secondary('DB', 'Secondary', {'CB', 'S'}),
  specialTeams('K', 'Special teams', {'K', 'P'});

  const PositionGroup(this.shortLabel, this.label, this.positions);

  final String shortLabel;
  final String label;
  final Set<String> positions;

  static PositionGroup of(String position) => PositionGroup.values.firstWhere(
        (group) => group.positions.contains(position),
        orElse: () => PositionGroup.specialTeams,
      );
}

class FootballStats {
  FootballStats._();

  /// Team-level season stats, in display order.
  static const teamStats = <StatDef>[
    StatDef('ppg', 'Points / game', decimals: 1),
    StatDef('papg', 'Points allowed / game', decimals: 1, higherIsBetter: false),
    StatDef('ypg', 'Yards / game', decimals: 1),
    StatDef('passYpg', 'Pass yards / game', decimals: 1),
    StatDef('rushYpg', 'Rush yards / game', decimals: 1),
    StatDef('yapg', 'Yards allowed / game', decimals: 1, higherIsBetter: false),
    StatDef('toDiff', 'Turnover differential', signed: true),
    StatDef('sacks', 'Sacks'),
    StatDef('thirdPct', '3rd-down conversion', decimals: 1, isPercent: true),
    StatDef('redZonePct', 'Red-zone TD rate', decimals: 1, isPercent: true),
  ];

  static const _playerStats = <String, StatDef>{
    'gp': StatDef('gp', 'Games played'),
    // Passing
    'compPct': StatDef('compPct', 'Completion %', decimals: 1, isPercent: true),
    'passYds': StatDef('passYds', 'Pass yards'),
    'passTd': StatDef('passTd', 'Pass TD'),
    'intThrown':
        StatDef('intThrown', 'Interceptions thrown', higherIsBetter: false),
    'rating': StatDef('rating', 'Passer rating', decimals: 1),
    // Rushing
    'rushAtt': StatDef('rushAtt', 'Carries'),
    'rushYds': StatDef('rushYds', 'Rush yards'),
    'ypc': StatDef('ypc', 'Yards / carry', decimals: 1),
    'rushTd': StatDef('rushTd', 'Rush TD'),
    'fum': StatDef('fum', 'Fumbles lost', higherIsBetter: false),
    // Receiving
    'tgt': StatDef('tgt', 'Targets'),
    'rec': StatDef('rec', 'Receptions'),
    'recYds': StatDef('recYds', 'Receiving yards'),
    'ypr': StatDef('ypr', 'Yards / catch', decimals: 1),
    'recTd': StatDef('recTd', 'Receiving TD'),
    // Defense
    'tkl': StatDef('tkl', 'Tackles'),
    'sacks': StatDef('sacks', 'Sacks', decimals: 1),
    'tfl': StatDef('tfl', 'Tackles for loss'),
    'qbHits': StatDef('qbHits', 'QB hits'),
    'defInt': StatDef('defInt', 'Interceptions'),
    'pd': StatDef('pd', 'Passes defended'),
    'ff': StatDef('ff', 'Forced fumbles'),
    // Kicking
    'fgm': StatDef('fgm', 'Field goals made'),
    'fga': StatDef('fga', 'Field goals attempted'),
    'fgPct': StatDef('fgPct', 'Field goal %', decimals: 1, isPercent: true),
    'long': StatDef('long', 'Longest FG'),
    'xpPct': StatDef('xpPct', 'Extra point %', decimals: 1, isPercent: true),
  };

  static const _keysByPosition = <String, List<String>>{
    'QB': ['gp', 'compPct', 'passYds', 'passTd', 'intThrown', 'rating', 'rushYds', 'rushTd'],
    'RB': ['gp', 'rushAtt', 'rushYds', 'ypc', 'rushTd', 'rec', 'recYds', 'fum'],
    'WR': ['gp', 'tgt', 'rec', 'recYds', 'ypr', 'recTd'],
    'TE': ['gp', 'tgt', 'rec', 'recYds', 'ypr', 'recTd'],
    'DE': ['gp', 'tkl', 'sacks', 'tfl', 'qbHits', 'ff'],
    'DT': ['gp', 'tkl', 'sacks', 'tfl', 'qbHits', 'ff'],
    'LB': ['gp', 'tkl', 'sacks', 'tfl', 'defInt', 'pd', 'ff'],
    'CB': ['gp', 'tkl', 'defInt', 'pd', 'ff'],
    'S': ['gp', 'tkl', 'defInt', 'pd', 'ff'],
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

  static const positionNames = <String, String>{
    'QB': 'Quarterback',
    'RB': 'Running back',
    'WR': 'Wide receiver',
    'TE': 'Tight end',
    'DE': 'Defensive end',
    'DT': 'Defensive tackle',
    'LB': 'Linebacker',
    'CB': 'Cornerback',
    'S': 'Safety',
    'K': 'Kicker',
    'P': 'Punter',
  };
}
