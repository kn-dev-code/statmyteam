import '../../models/models.dart';

/// Stat values from an ESPN `statistics` payload, keyed `category.name`
/// (e.g. `passing.passingYards`). Category-qualified because ESPN reuses
/// stat names across categories (`passing.sacks` vs `defensive.sacks`).
typedef EspnStats = Map<String, double>;

/// How one ESPN league maps onto StatMyTeam's [League] / [Sport] model.
///
/// Everything sport-specific (URL paths, season type, stat mapping, position
/// codes, conference labels) lives here so [EspnLeagueApi] stays generic.
class EspnLeague {
  const EspnLeague._({
    required this.league,
    required this.sport,
    required this.sportPath,
    required this.leaguePath,
    required this.idPrefix,
    required this.regularSeasonType,
    required this.standingsQuery,
    required this.useDivisions,
    required this.teamStats,
    required this.playerStats,
    required this.position,
  });

  final League league;
  final Sport sport;

  /// ESPN path segments, e.g. `football` / `college-football`.
  final String sportPath;
  final String leaguePath;

  /// Prefix for app ids: teams `nfl-12`, players `nfl-p-34`, games `nfl-g-56`.
  /// The NFL prefix matches ids saved by earlier builds (favorites).
  final String idPrefix;

  /// ESPN season-type id for regular-season stats (soccer uses 1, not 2).
  final int regularSeasonType;

  /// Extra query on the standings URL (FBS-only for college football).
  final String standingsQuery;

  /// Label teams by division (e.g. `AFC East`) rather than conference.
  final bool useDivisions;

  /// Maps a team's ESPN stats + standings record onto app team stat keys.
  final Map<String, double> Function(EspnStats stats, EspnRecord record)
      teamStats;

  /// Maps a player's ESPN stats onto app player stat keys.
  final Map<String, double> Function(EspnStats stats) playerStats;

  /// Normalizes an ESPN position abbreviation to the app's position codes.
  final String Function(String espnPosition) position;

  String get siteBase =>
      'https://site.api.espn.com/apis/site/v2/sports/$sportPath/$leaguePath';
  String get standingsUrl =>
      'https://site.api.espn.com/apis/v2/sports/$sportPath/$leaguePath/standings$standingsQuery';
  String get coreBase =>
      'https://sports.core.api.espn.com/v2/sports/$sportPath/leagues/$leaguePath';

  String teamId(String espnId) => '$idPrefix-$espnId';
  String playerId(String espnId) => '$idPrefix-p-$espnId';
  String gameId(String espnId) => '$idPrefix-g-$espnId';

  /// The ESPN athlete id inside an app player id, or null if [playerId]
  /// does not belong to this league.
  String? espnAthleteId(String playerId) {
    final prefix = '$idPrefix-p-';
    return playerId.startsWith(prefix)
        ? playerId.substring(prefix.length)
        : null;
  }

  static const nfl = EspnLeague._(
    league: League.nfl,
    sport: Sport.football,
    sportPath: 'football',
    leaguePath: 'nfl',
    idPrefix: 'nfl',
    regularSeasonType: 2,
    standingsQuery: '?level=3',
    useDivisions: true,
    teamStats: _footballTeamStats,
    playerStats: _footballPlayerStats,
    position: _footballPosition,
  );

  static const ncaaFootball = EspnLeague._(
    league: League.ncaa,
    sport: Sport.football,
    sportPath: 'football',
    leaguePath: 'college-football',
    idPrefix: 'ncaa',
    regularSeasonType: 2,
    // FBS only; all divisions would be 700+ teams.
    standingsQuery: '?group=80',
    useDivisions: false,
    teamStats: _footballTeamStats,
    playerStats: _footballPlayerStats,
    position: _footballPosition,
  );

  static const nba = EspnLeague._(
    league: League.nba,
    sport: Sport.basketball,
    sportPath: 'basketball',
    leaguePath: 'nba',
    idPrefix: 'nba',
    regularSeasonType: 2,
    standingsQuery: '',
    useDivisions: false,
    teamStats: _basketballTeamStats,
    playerStats: _basketballPlayerStats,
    position: _basketballPosition,
  );

  static const mls = EspnLeague._(
    league: League.mls,
    sport: Sport.soccer,
    sportPath: 'soccer',
    leaguePath: 'usa.1',
    idPrefix: 'mls',
    regularSeasonType: 1,
    standingsQuery: '',
    useDivisions: false,
    teamStats: _soccerTeamStats,
    playerStats: _soccerPlayerStats,
    position: _soccerPosition,
  );

  static const all = [nfl, ncaaFootball, nba, mls];

  /// The league whose ids [playerId] uses, if any.
  static EspnLeague? forPlayerId(String playerId) {
    for (final league in all) {
      if (league.espnAthleteId(playerId) != null) return league;
    }
    return null;
  }
}

/// Season record from ESPN standings.
class EspnRecord {
  const EspnRecord({
    this.wins = 0,
    this.losses = 0,
    this.ties = 0,
    this.pointsFor,
    this.pointsAgainst,
    this.avgPointsFor,
    this.avgPointsAgainst,
  });

  final int wins;
  final int losses;
  final int ties;
  final double? pointsFor;
  final double? pointsAgainst;
  final double? avgPointsFor;
  final double? avgPointsAgainst;

  int get gamesPlayed => wins + losses + ties;

  double? get pointsForPerGame => avgPointsFor ??
      (pointsFor != null && gamesPlayed > 0 ? pointsFor! / gamesPlayed : null);

  double? get pointsAgainstPerGame => avgPointsAgainst ??
      (pointsAgainst != null && gamesPlayed > 0
          ? pointsAgainst! / gamesPlayed
          : null);
}

// ── Stat mapping helpers ───────────────────────────────────────────────────

/// Builds a stat map from `appKey: value` pairs, dropping missing values.
Map<String, double> _pick(Map<String, double?> entries) => {
      for (final MapEntry(:key, :value) in entries.entries)
        if (value != null && value.isFinite) key: value,
    };

/// ESPN reports most percentages on a 0–100 scale; the app stores 0–1.
double? _pct100(double? v) => v == null ? null : v / 100;

double? _perGame(double? total, double? games) =>
    total == null || games == null || games <= 0 ? null : total / games;

// ── Football (NFL + college) ───────────────────────────────────────────────

Map<String, double> _footballTeamStats(EspnStats s, EspnRecord r) => _pick({
      'ppg': s['scoring.totalPointsPerGame'] ?? r.pointsForPerGame,
      'papg': r.pointsAgainstPerGame,
      'ypg': s['passing.netYardsPerGame'],
      'passYpg': s['passing.passingYardsPerGame'],
      'rushYpg': s['rushing.rushingYardsPerGame'],
      'sacks': s['defensive.sacks'],
      'toDiff': s['miscellaneous.turnOverDifferential'],
      'thirdPct': _pct100(s['miscellaneous.thirdDownConvPct']),
      'redZonePct': _pct100(s['miscellaneous.redzoneTouchdownPct']),
    });

Map<String, double> _footballPlayerStats(EspnStats s) {
  final rec = s['receiving.receptions'];
  final recYds = s['receiving.receivingYards'];
  final ypr = s['receiving.yardsPerReception'] ??
      (rec != null && rec > 0 && recYds != null ? recYds / rec : null);
  final hasPassing = (s['passing.passingAttempts'] ?? 0) > 0;
  final hasRushing = (s['rushing.rushingAttempts'] ?? 0) > 0;
  final hasReceiving = (s['receiving.receivingTargets'] ?? rec ?? 0) > 0;
  final hasKicking = (s['kicking.fieldGoalAttempts'] ?? 0) > 0 ||
      (s['kicking.extraPointAttempts'] ?? 0) > 0;

  return _pick({
    'gp': s['general.gamesPlayed'],
    if (hasPassing) ...{
      'compPct': _pct100(s['passing.completionPct']),
      'passYds': s['passing.passingYards'],
      'passTd': s['passing.passingTouchdowns'],
      'intThrown': s['passing.interceptions'],
      'rating': s['passing.QBRating'],
    },
    if (hasRushing) ...{
      'rushAtt': s['rushing.rushingAttempts'],
      'rushYds': s['rushing.rushingYards'],
      'ypc': s['rushing.yardsPerRushAttempt'],
      'rushTd': s['rushing.rushingTouchdowns'],
    },
    'fum': s['general.fumblesLost'],
    if (hasReceiving) ...{
      'tgt': s['receiving.receivingTargets'],
      'rec': rec,
      'recYds': recYds,
      'ypr': ypr,
      'recTd': s['receiving.receivingTouchdowns'],
    },
    'tkl': s['defensive.totalTackles'],
    'sacks': s['defensive.sacks'],
    'tfl': s['defensive.tacklesForLoss'],
    'qbHits': s['defensive.QBHits'],
    'defInt': s['defensiveInterceptions.interceptions'],
    'pd': s['defensive.passesDefended'],
    'ff': s['general.fumblesForced'],
    if (hasKicking) ...{
      'fgm': s['kicking.fieldGoalsMade'],
      'fga': s['kicking.fieldGoalAttempts'],
      'fgPct': _pct100(s['kicking.fieldGoalPct']),
      'long': s['kicking.longFieldGoalMade'],
      'xpPct': _pct100(s['kicking.extraPointPct']),
    },
  });
}

String _footballPosition(String p) => switch (p) {
      'PK' => 'K',
      'NT' => 'DT',
      'OLB' || 'ILB' || 'MLB' => 'LB',
      'EDGE' => 'DE',
      'SS' || 'FS' => 'S',
      'OT' || 'T' || 'G' || 'OG' || 'C' => 'OL',
      _ => p,
    };

// ── Basketball ─────────────────────────────────────────────────────────────

Map<String, double> _basketballTeamStats(EspnStats s, EspnRecord r) => _pick({
      'ppg': s['offensive.avgPoints'] ?? r.pointsForPerGame,
      'papg': r.pointsAgainstPerGame,
      'rpg': s['general.avgRebounds'],
      'apg': s['offensive.avgAssists'],
      'spg': s['defensive.avgSteals'],
      'bpg': s['defensive.avgBlocks'],
      'fgPct': _pct100(s['offensive.fieldGoalPct']),
      'threePct': _pct100(s['offensive.threePointFieldGoalPct']),
    });

Map<String, double> _basketballPlayerStats(EspnStats s) => _pick({
      'gp': s['general.gamesPlayed'],
      'pts': s['offensive.avgPoints'],
      'reb': s['general.avgRebounds'],
      'ast': s['offensive.avgAssists'],
      'fgPct': _pct100(s['offensive.fieldGoalPct']),
      'threePct': _pct100(s['offensive.threePointFieldGoalPct']),
      'stl': s['defensive.avgSteals'],
      'blk': s['defensive.avgBlocks'],
      'tov': s['offensive.avgTurnovers'],
    });

/// ESPN rosters use G / F / C (sometimes G-F, F-C); keep the primary one.
String _basketballPosition(String p) => p.split('-').first;

// ── Soccer ─────────────────────────────────────────────────────────────────

Map<String, double> _soccerTeamStats(EspnStats s, EspnRecord r) {
  final gp = s['general.appearances'] ??
      (r.gamesPlayed > 0 ? r.gamesPlayed.toDouble() : null);
  return _pick({
    'ppg': s['offensive.avgGoals'] ?? r.pointsForPerGame,
    'papg': s['goalKeeping.avgGoalsConceded'] ?? r.pointsAgainstPerGame,
    'possession': _pct100(s['offensive.possessionPct']),
    'shotsPg': _perGame(s['offensive.totalShots'], gp),
    'sogPg': _perGame(s['offensive.shotsOnTarget'], gp),
    'xg': s['offensive.avgExpectedGoals'],
    'xga': s['goalKeeping.avgExpectedGoalsConceded'],
    'cleanSheetPct': _perGame(s['goalKeeping.cleanSheet'], gp),
  });
}

Map<String, double> _soccerPlayerStats(EspnStats s) {
  final saves = s['goalKeeping.saves'];
  final faced = s['goalKeeping.shotsFaced'];
  final isKeeper = (faced ?? 0) > 0;
  return _pick({
    'gp': s['general.appearances'],
    'goals': s['offensive.totalGoals'],
    'ast': s['offensive.goalAssists'],
    'keyPass': s['offensive.shotAssists'],
    'shots': s['offensive.totalShots'],
    'sog': s['offensive.shotsOnTarget'],
    // Soccer passPct is already 0–1, unlike the other ESPN percentages.
    'passPct': s['general.passPct'],
    'tkl': s['defensive.totalTackles'],
    'int': s['defensive.interceptions'],
    'clr': s['defensive.totalClearance'],
    if (isKeeper) ...{
      'saves': saves,
      'ga': s['goalKeeping.goalsConceded'],
      'cleanSheets': s['goalKeeping.cleanSheet'],
      'savePct': saves == null ? null : saves / faced!,
    },
  });
}

String _soccerPosition(String p) => switch (p) {
      'G' || 'GK' => 'GK',
      'D' || 'DEF' => 'DEF',
      'M' || 'MID' => 'MID',
      'F' || 'FWD' => 'FWD',
      _ => p,
    };
