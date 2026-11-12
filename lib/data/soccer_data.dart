// Fictional MLS clubs used while a live soccer API is not wired in.
import '../models/models.dart';

const soccerSeason = '2026';

Team _t(
  String id,
  String city,
  String name,
  String abbreviation,
  String conference,
  int wins,
  int draws,
  int losses,
  int primary,
  int secondary,
  Map<String, double> stats,
) {
  return Team(
    id: id,
    name: name,
    abbreviation: abbreviation,
    city: city,
    sport: Sport.soccer,
    season: soccerSeason,
    league: League.mls,
    conference: conference,
    wins: wins,
    draws: draws,
    losses: losses,
    primaryColor: primary,
    secondaryColor: secondary,
    seasonStats: stats,
  );
}

final soccerTeams = <Team>[
  _t('mls-pdx', 'Portland', 'Cascades', 'PDX', 'West', 14, 5, 5,
      0xFF1F7A3A, 0xFFE8E8E8, {
    'ppg': 1.92, 'papg': 0.96, 'possession': 0.582, 'shotsPg': 15.4,
    'sogPg': 6.1, 'xg': 1.84, 'xga': 0.98, 'cleanSheetPct': 0.42,
  }),
  _t('mls-sea', 'Seattle', 'Sound', 'SEA', 'West', 12, 6, 6,
      0xFF1A3C6E, 0xFFC9A227, {
    'ppg': 1.58, 'papg': 1.12, 'possession': 0.541, 'shotsPg': 13.6,
    'sogPg': 5.2, 'xg': 1.49, 'xga': 1.14, 'cleanSheetPct': 0.33,
  }),
  _t('mls-atx', 'Austin', 'Antlers', 'ATX', 'West', 9, 7, 8,
      0xFFC45C26, 0xFF1A1A1A, {
    'ppg': 1.33, 'papg': 1.29, 'possession': 0.488, 'shotsPg': 12.1,
    'sogPg': 4.4, 'xg': 1.28, 'xga': 1.31, 'cleanSheetPct': 0.25,
  }),
  _t('mls-nyc', 'New York', 'Harbor', 'NYC', 'East', 13, 6, 5,
      0xFF1C3D7A, 0xFFF2C14E, {
    'ppg': 1.71, 'papg': 1.04, 'possession': 0.556, 'shotsPg': 14.2,
    'sogPg': 5.6, 'xg': 1.62, 'xga': 1.08, 'cleanSheetPct': 0.38,
  }),
  _t('mls-mia', 'Miami', 'Tide', 'MIA', 'East', 10, 5, 9,
      0xFF00A3A1, 0xFFFF6B6B, {
    'ppg': 1.46, 'papg': 1.38, 'possession': 0.512, 'shotsPg': 13.0,
    'sogPg': 4.9, 'xg': 1.41, 'xga': 1.36, 'cleanSheetPct': 0.21,
  }),
  _t('mls-chi', 'Chicago', 'Forge', 'CHI', 'East', 6, 6, 12,
      0xFFB22222, 0xFFE8E8E8, {
    'ppg': 1.04, 'papg': 1.71, 'possession': 0.447, 'shotsPg': 10.6,
    'sogPg': 3.5, 'xg': 1.02, 'xga': 1.68, 'cleanSheetPct': 0.12,
  }),
];

Player _p(
  String teamId,
  String id,
  String first,
  String last,
  String position,
  int number,
  DepthRole role,
  Map<String, double> stats, {
  PlayerStatus status = PlayerStatus.active,
  String? injury,
  required int age,
}) {
  return Player(
    id: '$teamId-$id',
    firstName: first,
    lastName: last,
    teamId: teamId,
    position: position,
    jerseyNumber: number,
    sport: Sport.soccer,
    role: role,
    status: status,
    injuryNote: injury,
    age: age,
    yearsPro: (age - 18).clamp(0, 20),
    seasonStats: stats,
  );
}

const _s = DepthRole.starter;
const _b = DepthRole.backup;

List<Player> _roster(
  String teamId, {
  required String gk,
  required String def,
  required String mid,
  required String fwd,
  required String extra,
}) {
  final parts = extra.split(' ');
  return [
    _p(teamId, 'gk', gk.split(' ').first, gk.split(' ').last, 'GK', 1, _s,
        {'gp': 24, 'saves': 68, 'ga': 23, 'cleanSheets': 10, 'savePct': 0.74},
        age: 29),
    _p(teamId, 'def1', def.split(' ').first, def.split(' ').last, 'DEF', 4, _s,
        {'gp': 23, 'tkl': 41, 'int': 28, 'clr': 72, 'passPct': 0.86, 'goals': 1},
        age: 27),
    _p(teamId, 'def2', 'Luis', 'Navarro', 'DEF', 5, _s,
        {'gp': 22, 'tkl': 38, 'int': 24, 'clr': 64, 'passPct': 0.83, 'goals': 0},
        age: 26),
    _p(teamId, 'mid1', mid.split(' ').first, mid.split(' ').last, 'MID', 8, _s,
        {'gp': 24, 'goals': 6, 'ast': 8, 'keyPass': 42, 'passPct': 0.88, 'tkl': 29},
        age: 25),
    _p(teamId, 'mid2', 'Noah', 'Keller', 'MID', 10, _s,
        {'gp': 21, 'goals': 4, 'ast': 5, 'keyPass': 31, 'passPct': 0.84, 'tkl': 22},
        age: 24),
    _p(teamId, 'fwd1', fwd.split(' ').first, fwd.split(' ').last, 'FWD', 9, _s,
        {'gp': 24, 'goals': 14, 'ast': 5, 'shots': 71, 'sog': 32, 'xg': 12.4},
        age: 28),
    _p(teamId, 'fwd2', parts.first, parts.last, 'FWD', 11, _b,
        {'gp': 18, 'goals': 5, 'ast': 3, 'shots': 34, 'sog': 14, 'xg': 4.8},
        age: 23),
  ];
}

final soccerPlayers = <Player>[
  ..._roster('mls-pdx',
      gk: 'Mateo Silva', def: 'Owen Hart', mid: 'Kai Moreau',
      fwd: 'Diego Vargas', extra: 'Finn Okafor'),
  ..._roster('mls-sea',
      gk: 'Lars Holm', def: 'Jamal Reed', mid: 'Soren Park',
      fwd: 'Andre Cole', extra: 'Riku Tanaka'),
  ..._roster('mls-atx',
      gk: 'Pablo Ruiz', def: 'Hector Salas', mid: 'Eli Carter',
      fwd: 'Mateo Cruz', extra: 'Wes Dalton'),
  ..._roster('mls-nyc',
      gk: 'Ivan Petrov', def: 'Chris Holloway', mid: 'Julian Shaw',
      fwd: 'Marco Rossi', extra: 'Cam Ellis'),
  ..._roster('mls-mia',
      gk: 'Rafael Nunez', def: 'Luis Ortega', mid: 'Diego Alvarez',
      fwd: 'Amari Wells', extra: 'Nico Briggs'),
  ..._roster('mls-chi',
      gk: 'Calvin Boone', def: 'Perry Sims', mid: 'Arjun Patel',
      fwd: 'Eli Grant', extra: 'Minh Nguyen'),
];

GameStats _final(
  String home,
  int homeScore,
  String away,
  int awayScore,
  DateTime start,
) {
  return GameStats(
    id: 'mls-$soccerSeason-$away-$home',
    sport: Sport.soccer,
    season: soccerSeason,
    startTime: start,
    homeTeamId: home,
    awayTeamId: away,
    status: GameStatus.completed,
    home: TeamBoxScore(teamId: home, score: homeScore),
    away: TeamBoxScore(teamId: away, score: awayScore),
  );
}

final soccerGames = <GameStats>[
  _final('mls-pdx', 3, 'mls-chi', 0, DateTime.utc(2026, 10, 26, 2)),
  _final('mls-nyc', 2, 'mls-mia', 1, DateTime.utc(2026, 10, 26, 0)),
  _final('mls-sea', 1, 'mls-atx', 1, DateTime.utc(2026, 10, 25, 2)),
  _final('mls-pdx', 2, 'mls-sea', 0, DateTime.utc(2026, 10, 19, 2)),
  _final('mls-nyc', 3, 'mls-chi', 1, DateTime.utc(2026, 10, 19, 0)),
  _final('mls-mia', 2, 'mls-atx', 2, DateTime.utc(2026, 10, 18, 23)),
  _final('mls-pdx', 1, 'mls-nyc', 1, DateTime.utc(2026, 10, 12, 2)),
  _final('mls-sea', 2, 'mls-chi', 0, DateTime.utc(2026, 10, 12, 2)),
  GameStats(
    id: 'mls-$soccerSeason-upcoming-pdx-nyc',
    sport: Sport.soccer,
    season: soccerSeason,
    startTime: DateTime.utc(2026, 11, 22, 1),
    homeTeamId: 'mls-pdx',
    awayTeamId: 'mls-nyc',
    home: const TeamBoxScore(teamId: 'mls-pdx'),
    away: const TeamBoxScore(teamId: 'mls-nyc'),
  ),
];
