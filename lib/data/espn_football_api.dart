import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';

/// Live NFL data from ESPN's public site / core APIs (no API key required).
class EspnFootballApi {
  EspnFootballApi({http.Client? client, this.timeout = const Duration(seconds: 20)})
      : _client = client ?? http.Client();

  static const _siteBase = 'https://site.api.espn.com/apis/site/v2/sports/football/nfl';
  static const _standingsUrl =
      'https://site.api.espn.com/apis/v2/sports/football/nfl/standings';
  static const _coreBase =
      'https://sports.core.api.espn.com/v2/sports/football/leagues/nfl';

  final http.Client _client;
  final Duration timeout;

  /// Fetches NFL teams, rosters, recent completed games, and season averages.
  Future<({List<Team> teams, List<Player> players, List<GameStats> games})>
      fetchLeague() async {
    final seasonYear = await _currentSeasonYear();
    final season = '$seasonYear';

    final conferenceByTeam = await _conferencesByTeamId();
    final teamSummaries = await _fetchTeamSummaries();

    final teams = <Team>[];
    final players = <Player>[];
    final gamesById = <String, GameStats>{};

    // Load detail + stats + roster + schedule in modest parallel batches.
    const batchSize = 8;
    for (var i = 0; i < teamSummaries.length; i += batchSize) {
      final batch = teamSummaries.skip(i).take(batchSize).toList();
      final results = await Future.wait([
        for (final summary in batch)
          _loadTeamBundle(
            summary: summary,
            season: season,
            seasonYear: seasonYear,
            conference: conferenceByTeam[summary.id] ?? 'NFL',
          ),
      ]);
      for (final result in results) {
        teams.add(result.team);
        players.addAll(result.players);
        for (final game in result.games) {
          gamesById.putIfAbsent(game.id, () => game);
        }
      }
    }

    return (
      teams: teams,
      players: players,
      games: gamesById.values.toList(),
    );
  }

  Future<int> _currentSeasonYear() async {
    final json = await _getJson('$_siteBase/scoreboard');
    final season = json['season'];
    if (season is Map && season['year'] != null) {
      return (season['year'] as num).toInt();
    }
    return DateTime.now().year;
  }

  Future<Map<String, String>> _conferencesByTeamId() async {
    final json = await _getJson(_standingsUrl);
    final map = <String, String>{};
    for (final conf in (json['children'] as List<dynamic>? ?? const [])) {
      final confMap = conf as Map<String, dynamic>;
      final confName = confMap['abbreviation'] as String? ??
          confMap['name'] as String? ??
          'NFL';
      final divisions = confMap['children'] as List<dynamic>?;
      final entries = <dynamic>[];
      if (divisions != null && divisions.isNotEmpty) {
        for (final div in divisions) {
          final divMap = div as Map<String, dynamic>;
          final divName = divMap['name'] as String? ?? confName;
          for (final entry
              in (divMap['standings']?['entries'] as List<dynamic>? ??
                  const [])) {
            final team = (entry as Map<String, dynamic>)['team']
                as Map<String, dynamic>;
            map['${team['id']}'] = divName;
          }
        }
      } else {
        entries.addAll(
          confMap['standings']?['entries'] as List<dynamic>? ?? const [],
        );
        for (final entry in entries) {
          final team =
              (entry as Map<String, dynamic>)['team'] as Map<String, dynamic>;
          map['${team['id']}'] = confName;
        }
      }
    }
    return map;
  }

  Future<List<_TeamSummary>> _fetchTeamSummaries() async {
    final json = await _getJson('$_siteBase/teams?limit=32');
    final sports = json['sports'] as List<dynamic>? ?? const [];
    if (sports.isEmpty) return const [];
    final leagues =
        (sports.first as Map<String, dynamic>)['leagues'] as List<dynamic>? ??
            const [];
    if (leagues.isEmpty) return const [];
    final teams =
        (leagues.first as Map<String, dynamic>)['teams'] as List<dynamic>? ??
            const [];
    return [
      for (final wrapped in teams)
        _TeamSummary.fromJson(
          (wrapped as Map<String, dynamic>)['team'] as Map<String, dynamic>,
        ),
    ];
  }

  Future<
      ({
        Team team,
        List<Player> players,
        List<GameStats> games,
      })> _loadTeamBundle({
    required _TeamSummary summary,
    required String season,
    required int seasonYear,
    required String conference,
  }) async {
    final detailFuture = _getJson('$_siteBase/teams/${summary.id}');
    final statsFuture = _getJson(
      '$_coreBase/seasons/$seasonYear/types/2/teams/${summary.id}/statistics',
    );
    final rosterFuture = _getJson('$_siteBase/teams/${summary.id}/roster');
    final scheduleFuture =
        _getJson('$_siteBase/teams/${summary.id}/schedule');

    final detail = await detailFuture;
    final statsJson = await _soft(statsFuture);
    final rosterJson = await _soft(rosterFuture);
    final scheduleJson = await _soft(scheduleFuture);

    final teamJson = detail['team'] as Map<String, dynamic>? ?? const {};
    final recordStats = _recordStats(teamJson);
    final seasonStats = <String, double>{
      ..._seasonStatsFromCore(statsJson),
      if (recordStats['avgPointsFor'] != null)
        'ppg': recordStats['avgPointsFor']!,
      if (recordStats['avgPointsAgainst'] != null)
        'papg': recordStats['avgPointsAgainst']!,
    };

    final standing = teamJson['standingSummary'] as String?;
    final parsedConference = _conferenceFromStanding(standing) ?? conference;

    final team = Team(
      id: 'nfl-${summary.id}',
      name: summary.name,
      abbreviation: summary.abbreviation,
      city: summary.location,
      sport: Sport.football,
      season: season,
      league: League.nfl,
      conference: parsedConference,
      wins: recordStats['wins']?.round() ?? 0,
      losses: recordStats['losses']?.round() ?? 0,
      draws: recordStats['ties']?.round() ?? 0,
      primaryColor: summary.primaryColor,
      secondaryColor: summary.secondaryColor,
      seasonStats: seasonStats,
    );

    final players = _parseRoster(
      rosterJson,
      teamId: team.id,
    );
    final games = _parseSchedule(
      scheduleJson,
      season: season,
    );

    return (team: team, players: players, games: games);
  }

  Map<String, double> _recordStats(Map<String, dynamic> teamJson) {
    final items =
        teamJson['record']?['items'] as List<dynamic>? ?? const [];
    if (items.isEmpty) return const {};
    final total = items.cast<Map<String, dynamic>>().firstWhere(
          (item) => (item['type'] as String?) == 'total',
          orElse: () => items.first as Map<String, dynamic>,
        );
    final out = <String, double>{};
    for (final stat in (total['stats'] as List<dynamic>? ?? const [])) {
      final map = stat as Map<String, dynamic>;
      final name = map['name'] as String?;
      final value = map['value'];
      if (name == null || value is! num) continue;
      out[name] = value.toDouble();
    }
    return out;
  }

  Map<String, double> _seasonStatsFromCore(Map<String, dynamic>? json) {
    if (json == null) return const {};
    final byName = <String, double>{};
    for (final category
        in (json['splits']?['categories'] as List<dynamic>? ?? const [])) {
      for (final stat
          in ((category as Map<String, dynamic>)['stats'] as List<dynamic>? ??
              const [])) {
        final map = stat as Map<String, dynamic>;
        final name = map['name'] as String?;
        final value = map['value'];
        if (name == null || value is! num) continue;
        byName[name] = value.toDouble();
      }
    }

    double? pct(String key) {
      final v = byName[key];
      if (v == null) return null;
      return v > 1 ? v / 100 : v;
    }

    return {
      if (byName['totalPointsPerGame'] != null)
        'ppg': byName['totalPointsPerGame']!,
      if (byName['netYardsPerGame'] != null) 'ypg': byName['netYardsPerGame']!,
      if (byName['passingYardsPerGame'] != null)
        'passYpg': byName['passingYardsPerGame']!,
      if (byName['rushingYardsPerGame'] != null)
        'rushYpg': byName['rushingYardsPerGame']!,
      if (byName['sacks'] != null) 'sacks': byName['sacks']!,
      if (byName['turnOverDifferential'] != null)
        'toDiff': byName['turnOverDifferential']!,
      if (pct('thirdDownConvPct') != null) 'thirdPct': pct('thirdDownConvPct')!,
      if (pct('redzoneTouchdownPct') != null)
        'redZonePct': pct('redzoneTouchdownPct')!,
    };
  }

  List<Player> _parseRoster(
    Map<String, dynamic>? json, {
    required String teamId,
  }) {
    if (json == null) return const [];
    final players = <Player>[];
    for (final group in (json['athletes'] as List<dynamic>? ?? const [])) {
      final items =
          (group as Map<String, dynamic>)['items'] as List<dynamic>? ??
              const [];
      for (final item in items) {
        final map = item as Map<String, dynamic>;
        final position = map['position']?['abbreviation'] as String? ?? 'WR';
        final injuries = map['injuries'] as List<dynamic>? ?? const [];
        final status = _playerStatus(map['status'], injuries);
        final injuryNote = injuries.isEmpty
            ? null
            : (injuries.first as Map<String, dynamic>)['detail'] as String? ??
                (injuries.first as Map<String, dynamic>)['description']
                    as String?;
        final experience = map['experience'];
        final years = experience is Map
            ? (experience['years'] as num?)?.toInt()
            : null;
        final college = map['college'];
        players.add(
          Player(
            id: 'nfl-p-${map['id']}',
            firstName: map['firstName'] as String? ?? '',
            lastName: map['lastName'] as String? ??
                (map['displayName'] as String? ?? 'Player'),
            teamId: teamId,
            position: position,
            jerseyNumber: int.tryParse('${map['jersey'] ?? ''}') ?? 0,
            sport: Sport.football,
            status: status,
            injuryNote: injuryNote,
            age: (map['age'] as num?)?.toInt(),
            heightInches: (map['height'] as num?)?.round(),
            weightLbs: (map['weight'] as num?)?.round(),
            yearsPro: years,
            college: college is Map
                ? college['shortName'] as String? ?? college['name'] as String?
                : null,
            role: _guessRole(position, players
                .where((p) => p.position == position)
                .length),
          ),
        );
      }
    }
    return players;
  }

  DepthRole _guessRole(String position, int alreadyOnRosterAtPosition) {
    if (alreadyOnRosterAtPosition == 0) return DepthRole.starter;
    if (alreadyOnRosterAtPosition < 3) return DepthRole.rotation;
    return DepthRole.backup;
  }

  PlayerStatus _playerStatus(
    dynamic status,
    List<dynamic> injuries,
  ) {
    final type = status is Map ? status['type'] as String? : null;
    if (type != null) {
      final lower = type.toLowerCase();
      if (lower.contains('injured') || lower == 'ir') {
        return PlayerStatus.injuredReserve;
      }
      if (lower.contains('out')) return PlayerStatus.out;
      if (lower.contains('question')) return PlayerStatus.questionable;
    }
    if (injuries.isNotEmpty) {
      final first = injuries.first as Map<String, dynamic>;
      final statusText =
          '${first['status'] ?? first['type'] ?? ''}'.toLowerCase();
      if (statusText.contains('out') || statusText.contains('injured')) {
        return PlayerStatus.out;
      }
      return PlayerStatus.questionable;
    }
    return PlayerStatus.active;
  }

  List<GameStats> _parseSchedule(
    Map<String, dynamic>? json, {
    required String season,
  }) {
    if (json == null) return const [];
    final games = <GameStats>[];
    for (final event in (json['events'] as List<dynamic>? ?? const [])) {
      final eventMap = event as Map<String, dynamic>;
      final competitions =
          eventMap['competitions'] as List<dynamic>? ?? const [];
      if (competitions.isEmpty) continue;
      final comp = competitions.first as Map<String, dynamic>;
      final statusName =
          comp['status']?['type']?['name'] as String? ?? '';
      final completed =
          comp['status']?['type']?['completed'] == true ||
              statusName == 'STATUS_FINAL';
      if (!completed) continue;

      final competitors =
          comp['competitors'] as List<dynamic>? ?? const [];
      Map<String, dynamic>? home;
      Map<String, dynamic>? away;
      for (final c in competitors) {
        final map = c as Map<String, dynamic>;
        if (map['homeAway'] == 'home') {
          home = map;
        } else {
          away = map;
        }
      }
      if (home == null || away == null) continue;

      int? scoreOf(Map<String, dynamic> competitor) {
        final score = competitor['score'];
        if (score is Map && score['value'] is num) {
          return (score['value'] as num).round();
        }
        if (score is String) return int.tryParse(score);
        if (score is num) return score.round();
        return null;
      }

      final homeId = 'nfl-${home['team']?['id'] ?? home['id']}';
      final awayId = 'nfl-${away['team']?['id'] ?? away['id']}';
      final venue = comp['venue']?['fullName'] as String?;
      final start = DateTime.tryParse(eventMap['date'] as String? ?? '') ??
          DateTime.tryParse(comp['date'] as String? ?? '') ??
          DateTime.now();

      games.add(
        GameStats(
          id: 'nfl-g-${eventMap['id']}',
          sport: Sport.football,
          season: season,
          startTime: start.toUtc(),
          homeTeamId: homeId,
          awayTeamId: awayId,
          home: TeamBoxScore(teamId: homeId, score: scoreOf(home)),
          away: TeamBoxScore(teamId: awayId, score: scoreOf(away)),
          venue: venue,
          status: GameStatus.completed,
        ),
      );
    }
    return games;
  }

  String? _conferenceFromStanding(String? standingSummary) {
    if (standingSummary == null) return null;
    final match = RegExp(r'in\s+(.+)$').firstMatch(standingSummary);
    return match?.group(1)?.trim();
  }

  Future<Map<String, dynamic>?> _soft(Future<Map<String, dynamic>> future) async {
    try {
      return await future;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _getJson(String url) async {
    final response = await _client.get(Uri.parse(url)).timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('ESPN request failed (${response.statusCode}): $url');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Unexpected ESPN payload for $url');
    }
    return decoded;
  }

  void close() => _client.close();
}

class _TeamSummary {
  const _TeamSummary({
    required this.id,
    required this.name,
    required this.abbreviation,
    required this.location,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final String id;
  final String name;
  final String abbreviation;
  final String location;
  final int primaryColor;
  final int secondaryColor;

  factory _TeamSummary.fromJson(Map<String, dynamic> json) {
    return _TeamSummary(
      id: '${json['id']}',
      name: json['name'] as String? ??
          json['shortDisplayName'] as String? ??
          'Team',
      abbreviation: json['abbreviation'] as String? ?? 'TM',
      location: json['location'] as String? ?? '',
      primaryColor: _parseColor(json['color'] as String?, 0xFF2EE59D),
      secondaryColor:
          _parseColor(json['alternateColor'] as String?, 0xFFFFFFFF),
    );
  }

  static int _parseColor(String? hex, int fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return fallback;
    return cleaned.length <= 6 ? 0xFF000000 | value : value;
  }
}
