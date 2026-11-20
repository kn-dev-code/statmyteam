import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import '../../models/models.dart';
import '../load_status.dart';
import 'espn_http.dart';
import 'espn_leagues.dart';

/// Everything loaded for one league.
class EspnLeagueData {
  const EspnLeagueData({
    required this.league,
    required this.seasonYear,
    required this.teams,
    required this.players,
    required this.games,
    required this.opponents,
    this.warnings = const [],
  });

  final EspnLeague league;

  /// ESPN season year (the NBA's 2026-27 season is `2027`).
  final int seasonYear;
  final List<Team> teams;
  final List<Player> players;
  final List<GameStats> games;

  /// Schedule opponents outside [teams] (e.g. FCS teams on an FBS schedule),
  /// so results against them can still be labelled.
  final List<Team> opponents;

  /// Parts of the feed that failed while the league as a whole still loaded,
  /// e.g. 3 of 30 rosters. Empty when everything loaded.
  final List<FeedGap> warnings;
}

/// Live teams, rosters, team stats, and schedules for one ESPN league,
/// via ESPN's public site / core APIs (no API key required).
///
/// Load plan (N = teams in the league):
/// scoreboard + standings + team list, then per team: season stats, roster,
/// and schedule. At most [concurrency] teams load at once, so up to
/// `3 * concurrency` requests are in flight.
class EspnLeagueApi {
  EspnLeagueApi(
    this.league, {
    http.Client? client,
    Duration timeout = const Duration(seconds: 20),
    Duration retryDelay = const Duration(milliseconds: 400),
    // Teams in flight. Measured on the 138-team FBS load:
    // 12 → 3.1s, 24 → 2.6s, 48 → 2.6s.
    this.concurrency = 24,
  }) : _http = EspnHttp(
         client ?? http.Client(),
         timeout: timeout,
         retryDelay: retryDelay,
       );

  final EspnLeague league;
  final int concurrency;
  final EspnHttp _http;

  /// Throws when the league's standings or season cannot be loaded, or when
  /// more than half of the rosters fail, rather than returning a hollow
  /// league. Smaller stats / roster / schedule failures are counted in
  /// [EspnLeagueData.warnings] so the UI can say the data is incomplete.
  Future<EspnLeagueData> fetchLeague() async {
    final scoreboardFuture = _soft(
      _http.getJson('${league.siteBase}/scoreboard'),
      'scoreboard',
    );
    final standingsFuture = _http.getJson(league.standingsUrl);
    final teamListFuture = _soft(
      _http.getJson('${league.siteBase}/teams?limit=1000'),
      'team list',
    );

    // Await standings first: it is the only one of the three that can throw,
    // and its error must be observed now, not after the scoreboard settles.
    final standingsJson = await standingsFuture;
    final scoreboard = await scoreboardFuture;
    final standings = _parseStandings(standingsJson);
    if (standings.isEmpty) {
      throw EspnDataException(
        'ESPN returned no ${league.league.label} standings.',
      );
    }
    final colors = _parseTeamColors(await teamListFuture);

    // Never guess the season from the calendar: the NBA's 2026-27 season is
    // `2027`, and a wrong year makes every stats request 404 quietly.
    final seasonYear =
        _seasonYear(scoreboard) ?? _standingsSeason(standingsJson);
    if (seasonYear == null) {
      throw EspnDataException(
        'ESPN did not say which ${league.league.label} season is current.',
      );
    }
    final season = '$seasonYear';

    final failures = <FeedPart, int>{};
    final bundles = await mapWithConcurrency(
      standings,
      concurrency,
      (entry) => _loadTeam(entry, seasonYear: seasonYear, failures: failures),
    );

    final total = bundles.length;
    final failedRosters = failures[FeedPart.rosters] ?? 0;
    if (failedRosters * 2 > total) {
      throw EspnDataException(
        '$failedRosters of $total ${league.league.label} rosters failed to '
        'load.',
      );
    }
    final warnings = [
      for (final part in FeedPart.values)
        if (failures[part] case final count?) FeedGap(part, count, total),
    ];
    if (warnings.isNotEmpty) {
      developer.log(
        '${league.league.label}: failed to load ${warnings.join(', ')}',
        name: 'EspnLeagueApi',
      );
    }

    final teams = <Team>[];
    final players = <Player>[];
    final gamesById = <String, GameStats>{};
    final opponents = <String, Team>{};

    for (final (index, entry) in standings.indexed) {
      final bundle = bundles[index];
      final team = Team(
        id: league.teamId(entry.espnId),
        name: entry.identity.name,
        abbreviation: entry.identity.abbreviation,
        city: entry.identity.city,
        sport: league.sport,
        season: season,
        league: league.league,
        conference: entry.group,
        wins: entry.record.wins,
        losses: entry.record.losses,
        draws: entry.record.ties,
        primaryColor: colors[entry.espnId]?.$1 ?? 0xFF2EE59D,
        secondaryColor: colors[entry.espnId]?.$2 ?? 0xFFFFFFFF,
        seasonStats: league.teamStats(bundle.stats, entry.record),
      );
      teams.add(team);
      players.addAll(_parseRoster(bundle.roster, teamId: team.id));
      _collectGames(
        bundle.schedule,
        season: season,
        into: gamesById,
        opponents: opponents,
      );
    }

    // Team schedule feeds can omit future events; the scoreboard is the
    // canonical current slate, so merge it in to power Upcoming Games.
    _collectGames(
      scoreboard,
      season: season,
      into: gamesById,
      opponents: opponents,
    );

    final teamIds = {for (final t in teams) t.id};
    opponents.removeWhere((id, _) => teamIds.contains(id));

    // A competitor without a team object yields an id that resolves to no
    // team; such games could not be labelled, so leave them out.
    bool known(String id) => teamIds.contains(id) || opponents.containsKey(id);
    gamesById.removeWhere(
      (_, game) => !known(game.homeTeamId) || !known(game.awayTeamId),
    );

    return EspnLeagueData(
      league: league,
      seasonYear: seasonYear,
      teams: teams,
      players: players,
      games: gamesById.values.toList(),
      opponents: opponents.values.toList(),
      warnings: warnings,
    );
  }

  void close() => _http.client.close();

  // ── Per-team requests ────────────────────────────────────────────────────

  Future<_TeamBundle> _loadTeam(
    _StandingEntry entry, {
    required int seasonYear,
    required Map<FeedPart, int> failures,
  }) async {
    final id = entry.espnId;
    Future<Map<String, dynamic>?> part(String url, FeedPart kind) async {
      final json = await _soft(_http.getJson(url), 'team $id ${kind.name}');
      if (json == null) failures.update(kind, (n) => n + 1, ifAbsent: () => 1);
      return json;
    }

    final results = await Future.wait([
      part(
        '${league.coreBase}/seasons/$seasonYear/types/'
        '${league.regularSeasonType}/teams/$id/statistics',
        FeedPart.teamStats,
      ),
      part('${league.siteBase}/teams/$id/roster', FeedPart.rosters),
      part('${league.siteBase}/teams/$id/schedule', FeedPart.schedules),
    ]);
    return _TeamBundle(
      stats: parseEspnStats(results[0]),
      roster: results[1],
      schedule: results[2],
    );
  }

  // ── Standings ────────────────────────────────────────────────────────────

  List<_StandingEntry> _parseStandings(Map<String, dynamic> json) {
    final out = <_StandingEntry>[];
    final seen = <String>{};

    void visit(Map<String, dynamic> node, String? conferenceLabel) {
      final label = conferenceLabel ?? _groupLabel(node);
      final entries = _list(_map(node['standings'])?['entries']);
      for (final entry in entries ?? const []) {
        if (entry is! Map) continue;
        final team = entry['team'];
        if (team is! Map<String, dynamic>) continue;
        final id = '${team['id']}';
        if (!seen.add(id)) continue;
        out.add(
          _StandingEntry(
            espnId: id,
            identity: _TeamIdentity.fromJson(team),
            group: league.useDivisions ? (_str(node['name']) ?? label) : label,
            record: _parseRecord(_list(entry['stats'])),
          ),
        );
      }
      for (final child in (_list(node['children']) ?? const [])) {
        if (child is Map<String, dynamic>) visit(child, label);
      }
    }

    for (final child in (_list(json['children']) ?? const [])) {
      if (child is Map<String, dynamic>) visit(child, null);
    }
    return out;
  }

  /// Short conference label: `SEC`, `East`, `AFC`.
  String _groupLabel(Map<String, dynamic> node) {
    final abbreviation = _str(node['abbreviation']);
    final shortName = _str(node['shortName']);
    final name = _str(node['name']) ?? league.league.label;
    // College abbreviations are slugs like `big12`; prefer the short name.
    if (league.league.isAmateur) return shortName ?? name;
    return abbreviation ?? shortName ?? name;
  }

  EspnRecord _parseRecord(List<dynamic>? stats) {
    final values = <String, double>{};
    for (final stat in stats ?? const []) {
      if (stat is! Map) continue;
      final name = stat['name'];
      final type = stat['type'];
      final value = stat['value'];
      // Split records (home / away / conference) repeat the same names with
      // prefixed types like `homerecord_wins`; keep the overall ones.
      if (name is! String || value is! num) continue;
      if (type is String && type.contains('_')) continue;
      values.putIfAbsent(name, () => value.toDouble());
    }
    return EspnRecord(
      wins: values['wins']?.round() ?? 0,
      losses: values['losses']?.round() ?? 0,
      ties: values['ties']?.round() ?? 0,
      pointsFor: values['pointsFor'],
      pointsAgainst: values['pointsAgainst'],
      avgPointsFor: values['avgPointsFor'],
      avgPointsAgainst: values['avgPointsAgainst'],
    );
  }

  int? _seasonYear(Map<String, dynamic>? scoreboard) {
    final season = scoreboard?['season'];
    if (season is Map && season['year'] is num) {
      return (season['year'] as num).toInt();
    }
    final leagues = scoreboard?['leagues'];
    if (leagues is List && leagues.isNotEmpty) {
      final year = _map(_map(leagues.first)?['season'])?['year'];
      if (year is num) return year.toInt();
    }
    return null;
  }

  /// Fallback season source: each standings group carries `season`.
  int? _standingsSeason(Map<String, dynamic> json) {
    int? visit(Object? node) {
      if (node is! Map) return null;
      final standings = node['standings'];
      if (standings is Map && standings['season'] is num) {
        return (standings['season'] as num).toInt();
      }
      final children = node['children'];
      if (children is! List) return null;
      for (final child in children) {
        if (visit(child) case final year?) return year;
      }
      return null;
    }

    return visit(json);
  }

  /// Team colors are cosmetic and the team list is optional, so an
  /// unexpected shape yields no colors rather than failing the league.
  Map<String, (int, int)> _parseTeamColors(Map<String, dynamic>? json) {
    final out = <String, (int, int)>{};
    final sports = json?['sports'];
    if (sports is! List || sports.isEmpty || sports.first is! Map) return out;
    final leagues = (sports.first as Map)['leagues'];
    if (leagues is! List || leagues.isEmpty || leagues.first is! Map) {
      return out;
    }
    final teams = (leagues.first as Map)['teams'];
    if (teams is! List) return out;
    for (final wrapped in teams.whereType<Map<dynamic, dynamic>>()) {
      final team = wrapped['team'];
      if (team is! Map) continue;
      final color = team['color'];
      final alternate = team['alternateColor'];
      out['${team['id']}'] = (
        _parseColor(color is String ? color : null, 0xFF2EE59D),
        _parseColor(alternate is String ? alternate : null, 0xFFFFFFFF),
      );
    }
    return out;
  }

  // ── Rosters ──────────────────────────────────────────────────────────────

  List<Player> _parseRoster(
    Map<String, dynamic>? json, {
    required String teamId,
  }) {
    if (json == null) return const [];
    // Football rosters are grouped ({position, items: [...]}); basketball and
    // soccer rosters are a flat athlete list.
    final athletes = <Map<String, dynamic>>[];
    for (final entry in (_list(json['athletes']) ?? const [])) {
      if (entry is! Map<String, dynamic>) continue;
      final items = entry['items'];
      if (items is List) {
        athletes.addAll(items.whereType<Map<String, dynamic>>());
      } else {
        athletes.add(entry);
      }
    }

    final countByPosition = <String, int>{};
    final players = <Player>[];
    for (final map in athletes) {
      final rawPosition = _str(_map(map['position'])?['abbreviation']) ?? '';
      final position = league.position(rawPosition);
      final injuries = _list(map['injuries']) ?? const [];
      final experience = map['experience'];
      final college = map['college'];
      final depth = countByPosition[position] ?? 0;
      countByPosition[position] = depth + 1;

      players.add(
        Player(
          id: league.playerId('${map['id']}'),
          firstName: _str(map['firstName']) ?? '',
          lastName:
              _str(map['lastName']) ?? (_str(map['displayName']) ?? 'Player'),
          teamId: teamId,
          position: position,
          jerseyNumber: int.tryParse('${map['jersey'] ?? ''}') ?? 0,
          sport: league.sport,
          status: _playerStatus(map['status'], injuries),
          injuryNote: _injuryNote(injuries),
          age: (_num(map['age']))?.toInt(),
          heightInches: (_num(map['height']))?.round(),
          weightLbs: (_num(map['weight']))?.round(),
          yearsPro: !league.league.isAmateur && experience is Map
              ? (_num(experience['years']))?.toInt()
              : null,
          classYear: league.league.isAmateur && experience is Map
              ? _str(experience['displayValue'])
              : null,
          college: college is Map
              ? _str(college['shortName']) ?? _str(college['name'])
              : null,
          // ESPN does not publish depth charts here; roster order is the
          // best available signal.
          role: depth == 0
              ? DepthRole.starter
              : depth < 3
              ? DepthRole.rotation
              : DepthRole.backup,
        ),
      );
    }
    return players;
  }

  String? _injuryNote(List<dynamic> injuries) {
    if (injuries.isEmpty || injuries.first is! Map) return null;
    final first = injuries.first as Map;
    return _str(first['detail']) ?? _str(first['description']);
  }

  PlayerStatus _playerStatus(dynamic status, List<dynamic> injuries) {
    final type = status is Map ? _str(status['type']) : null;
    if (type != null) {
      final lower = type.toLowerCase();
      if (lower.contains('injured') || lower == 'ir') {
        return PlayerStatus.injuredReserve;
      }
      if (lower.contains('out')) return PlayerStatus.out;
      if (lower.contains('question')) return PlayerStatus.questionable;
    }
    if (injuries.isNotEmpty && injuries.first is Map) {
      final first = injuries.first as Map;
      final text = '${first['status'] ?? first['type'] ?? ''}'.toLowerCase();
      if (text.contains('out') || text.contains('injured')) {
        return PlayerStatus.out;
      }
      return PlayerStatus.questionable;
    }
    return PlayerStatus.active;
  }

  // ── Schedules / scoreboard ───────────────────────────────────────────────

  void _collectGames(
    Map<String, dynamic>? json, {
    required String season,
    required Map<String, GameStats> into,
    required Map<String, Team> opponents,
  }) {
    if (json == null) return;
    final now = DateTime.now();
    for (final event in (_list(json['events']) ?? const [])) {
      if (event is! Map<String, dynamic>) continue;
      final competitions = _list(event['competitions']) ?? const [];
      if (competitions.isEmpty || competitions.first is! Map) continue;
      final comp = competitions.first as Map<String, dynamic>;
      final statusType = _map(_map(comp['status'])?['type']) ?? const {};
      final statusName = _str(statusType['name']) ?? '';
      final statusState = _str(statusType['state']) ?? '';
      final completed =
          statusType['completed'] == true || statusName == 'STATUS_FINAL';
      final live =
          statusState == 'in' ||
          statusName == 'STATUS_IN_PROGRESS' ||
          statusName == 'STATUS_HALFTIME';
      if (statusName == 'STATUS_POSTPONED' || statusName == 'STATUS_CANCELED') {
        continue;
      }

      Map<String, dynamic>? home;
      Map<String, dynamic>? away;
      for (final c in (_list(comp['competitors']) ?? const [])) {
        if (c is! Map<String, dynamic>) continue;
        if (c['homeAway'] == 'home') {
          home = c;
        } else {
          away = c;
        }
      }
      if (home == null || away == null) continue;

      final start =
          DateTime.tryParse(_str(event['date']) ?? '') ??
          DateTime.tryParse(_str(comp['date']) ?? '');
      if (start == null) continue;
      if (!completed && !live && !start.isAfter(now)) continue;

      final homeId = _competitorTeamId(home, opponents);
      final awayId = _competitorTeamId(away, opponents);
      final id = league.gameId('${event['id']}');
      into.putIfAbsent(
        id,
        () => GameStats(
          id: id,
          sport: league.sport,
          season: season,
          startTime: start.toUtc(),
          homeTeamId: homeId,
          awayTeamId: awayId,
          home: TeamBoxScore(teamId: homeId, score: _score(home!)),
          away: TeamBoxScore(teamId: awayId, score: _score(away!)),
          venue: _str(_map(comp['venue'])?['fullName']),
          status: completed
              ? GameStatus.completed
              : (live ? GameStatus.live : GameStatus.scheduled),
        ),
      );
    }
  }

  String _competitorTeamId(
    Map<String, dynamic> competitor,
    Map<String, Team> opponents,
  ) {
    final team = competitor['team'];
    final espnId = team is Map
        ? team['id'] ?? competitor['id']
        : competitor['id'];
    final id = league.teamId('$espnId');
    if (team is Map<String, dynamic> && !opponents.containsKey(id)) {
      final identity = _TeamIdentity.fromJson(team);
      opponents[id] = Team(
        id: id,
        name: identity.name,
        abbreviation: identity.abbreviation,
        city: identity.city,
        sport: league.sport,
        season: '',
        league: league.league,
        primaryColor: _parseColor(_str(team['color']), 0xFF8A8F98),
        secondaryColor: _parseColor(_str(team['alternateColor']), 0xFFFFFFFF),
      );
    }
    return id;
  }

  int? _score(Map<String, dynamic> competitor) {
    final score = competitor['score'];
    if (score is Map && score['value'] is num) {
      return (score['value'] as num).round();
    }
    if (score is String) return int.tryParse(score);
    if (score is num) return score.round();
    return null;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> _soft(
    Future<Map<String, dynamic>> future,
    String what,
  ) async {
    try {
      return await future;
    } catch (error, stack) {
      developer.log(
        '${league.league.label}: $what failed; skipping',
        name: 'EspnLeagueApi',
        error: error,
        stackTrace: stack,
      );
      return null;
    }
  }
}

class _StandingEntry {
  const _StandingEntry({
    required this.espnId,
    required this.identity,
    required this.group,
    required this.record,
  });

  final String espnId;
  final _TeamIdentity identity;
  final String group;
  final EspnRecord record;
}

class _TeamBundle {
  const _TeamBundle({required this.stats, this.roster, this.schedule});

  final EspnStats stats;
  final Map<String, dynamic>? roster;
  final Map<String, dynamic>? schedule;
}

/// City / nickname split. Soccer clubs come back with `location == name`
/// ("Atlanta United FC"), so the short name stands in for the city there.
class _TeamIdentity {
  const _TeamIdentity(this.city, this.name, this.abbreviation);

  final String city;
  final String name;
  final String abbreviation;

  factory _TeamIdentity.fromJson(Map<String, dynamic> json) {
    final location = _str(json['location']) ?? '';
    final name =
        _str(json['name']) ??
        _str(json['nickname']) ??
        _str(json['shortDisplayName']) ??
        'Team';
    final city = location == name
        ? _str(json['shortDisplayName']) ?? location
        : location;
    return _TeamIdentity(city, name, _str(json['abbreviation']) ?? 'TM');
  }
}

int _parseColor(String? hex, int fallback) {
  if (hex == null || hex.isEmpty) return fallback;
  final cleaned = hex.replaceFirst('#', '');
  final value = int.tryParse(cleaned, radix: 16);
  if (value == null) return fallback;
  return cleaned.length <= 6 ? 0xFF000000 | value : value;
}

// Type-safe JSON readers: a field with an unexpected type reads as absent
// instead of throwing a TypeError that would take down the whole load.
String? _str(Object? value) => value is String ? value : null;
num? _num(Object? value) => value is num ? value : null;
List<dynamic>? _list(Object? value) => value is List ? value : null;
Map<dynamic, dynamic>? _map(Object? value) => value is Map ? value : null;
