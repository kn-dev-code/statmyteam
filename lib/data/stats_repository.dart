import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show compute;
import 'package:http/http.dart' as http;

import '../logic/football_stats.dart';
import '../models/models.dart';
import 'basketball_data.dart';
import 'espn/espn_http.dart';
import 'espn/espn_league_api.dart';
import 'espn/espn_leagues.dart';
import 'espn/espn_player_stats.dart';
import 'football_data.dart';
import 'soccer_data.dart';

export 'espn/espn_player_stats.dart' show PlayerStatsSource;

typedef _LeagueSet = ({
  List<Team> teams,
  List<Player> players,
  List<GameStats> games,
});

/// Read-only access to teams, players, and results for the stats screens.
///
/// Use [live] for real data from ESPN; [sampleFootball] stays available for
/// offline / widget tests.
class StatsRepository {
  StatsRepository({
    required List<Team> teams,
    required List<Player> players,
    required List<GameStats> games,
    Set<League> liveLeagues = const {},
    Map<League, String> loadErrors = const {},
    Map<League, String> loadWarnings = const {},
    List<Team> opponents = const [],
    PlayerStatsSource? playerStats,
    this.clock = DateTime.now,
  })  : teams = List.unmodifiable(teams),
        players = List.unmodifiable(players),
        games = List.unmodifiable(
          List<GameStats>.of(games)
            ..sort((a, b) => b.startTime.compareTo(a.startTime)),
        ),
        liveLeagues = Set.unmodifiable(liveLeagues),
        loadErrors = Map.unmodifiable(loadErrors),
        loadWarnings = Map.unmodifiable(loadWarnings),
        _opponents = {for (final t in opponents) t.id: t},
        _statsSource = playerStats;

  /// Fictional NFL, NCAA, NBA, and MLS sample leagues.
  factory StatsRepository.sampleFootball() {
    final sets = [for (final league in _sampleLeagues) _sample(league)];
    return StatsRepository(
      teams: [for (final s in sets) ...s.teams],
      players: [for (final s in sets) ...s.players],
      games: [for (final s in sets) ...s.games],
    );
  }

  static const _sampleLeagues = [
    League.nfl,
    League.ncaa,
    League.nba,
    League.mls,
  ];

  static _LeagueSet _sample(League league) => switch (league) {
        League.nfl => (
            teams: footballTeams,
            players: footballPlayers,
            games: footballGames,
          ),
        League.ncaa => (
            teams: collegeTeams,
            players: collegePlayers,
            games: collegeGames,
          ),
        League.nba => (
            teams: basketballTeams,
            players: basketballPlayers,
            games: basketballGames,
          ),
        League.mls => (
            teams: soccerTeams,
            players: soccerPlayers,
            games: soccerGames,
          ),
        _ => (teams: const [], players: const [], games: const []),
      };

  /// Live NFL, college football (FBS), NBA, and MLS data from ESPN.
  ///
  /// Leagues load in parallel. A league whose feed is down (HTTP errors,
  /// timeouts, missing standings / season, most rosters failing, or taking
  /// longer than [leagueTimeout]) falls back to its sample data on its own,
  /// and the failure is recorded in [loadErrors] so the UI can say which
  /// feed is down; the other leagues stay live. Partial failures in a live
  /// league are recorded in [loadWarnings].
  ///
  /// Anything else (e.g. a parser bug) is rethrown, not masked as sample
  /// data.
  ///
  /// Player season stats are not part of this load; screens fetch them per
  /// player with [withSeasonStats].
  static Future<StatsRepository> live({
    http.Client? client,
    List<EspnLeague> leagues = EspnLeague.all,
    Duration leagueTimeout = const Duration(seconds: 60),
    Duration retryDelay = const Duration(milliseconds: 400),
  }) async {
    final results = await Future.wait([
      for (final league in leagues)
        _loadLeague(
          league,
          client,
          timeout: leagueTimeout,
          retryDelay: retryDelay,
        ),
    ]);

    final teams = <Team>[];
    final players = <Player>[];
    final games = <GameStats>[];
    final opponents = <Team>[];
    final live = <League>{};
    final errors = <League, String>{};
    final warnings = <League, String>{};
    final seasonYears = <League, int>{};

    for (final (index, league) in leagues.indexed) {
      final result = results[index];
      if (result.data case final data?) {
        teams.addAll(data.teams);
        players.addAll(data.players);
        games.addAll(data.games);
        opponents.addAll(data.opponents);
        live.add(league.league);
        seasonYears[league.league] = data.seasonYear;
        if (data.warnings.isNotEmpty) {
          warnings[league.league] =
              'Some data failed to load: ${data.warnings.join(', ')}.';
        }
      } else {
        final sample = _sample(league.league);
        teams.addAll(sample.teams);
        players.addAll(sample.players);
        games.addAll(sample.games);
        errors[league.league] = result.error ?? 'Unknown error';
      }
    }

    return StatsRepository(
      teams: teams,
      players: players,
      games: games,
      opponents: opponents,
      liveLeagues: live,
      loadErrors: errors,
      loadWarnings: warnings,
      // The client stays open for on-demand player stats for the app's life.
      playerStats: live.isEmpty
          ? null
          : EspnPlayerStatsSource(
              client: client ?? http.Client(),
              seasonYears: seasonYears,
              retryDelay: retryDelay,
            ),
    );
  }

  static Future<EspnLeagueData> _fetchLeagueInBackground(
    EspnLeague league,
  ) async {
    final api = EspnLeagueApi(league);
    try {
      return await api.fetchLeague();
    } finally {
      api.close();
    }
  }

  /// Failures that mean "this feed is down right now", as opposed to bugs.
  static bool _isFeedFailure(Object error) =>
      error is EspnRequestException ||
      error is EspnDataException ||
      error is TimeoutException ||
      error is http.ClientException ||
      error is FormatException;

  static Future<({EspnLeagueData? data, String? error})> _loadLeague(
    EspnLeague league,
    http.Client? client, {
    required Duration timeout,
    required Duration retryDelay,
  }) async {
    try {
      // Fetch + parse each league on a background isolate: it keeps the UI
      // thread free (13k+ college players is a lot of JSON) and lets leagues
      // parse in parallel. An injected client (tests) can't cross isolates.
      final load = client == null
          ? compute(_fetchLeagueInBackground, league)
          : EspnLeagueApi(league, client: client, retryDelay: retryDelay)
              .fetchLeague();
      // One slow league must not hold the whole app on the loading screen.
      final data = await load.timeout(
        timeout,
        onTimeout: () => throw TimeoutException(
          'Live ${league.league.label} data took longer than '
          '${timeout.inSeconds}s.',
          timeout,
        ),
      );
      return (data: data, error: null);
    } catch (error, stack) {
      if (!_isFeedFailure(error)) rethrow;
      developer.log(
        'Live ${league.league.label} load failed; using sample data',
        name: 'StatsRepository',
        error: error,
        stackTrace: stack,
      );
      return (data: null, error: '$error');
    }
  }

  final List<Team> teams;
  final List<Player> players;

  /// Leagues whose data came from ESPN rather than the sample pack.
  final Set<League> liveLeagues;

  /// Leagues whose live load failed (and now show sample data), with why.
  final Map<League, String> loadErrors;

  /// Live leagues where part of the feed failed (some rosters, team stats,
  /// or schedules are missing), with what failed.
  final Map<League, String> loadWarnings;

  /// Newest first.
  final List<GameStats> games;

  /// Teams that only appear as schedule opponents (e.g. FCS teams on an FBS
  /// schedule): resolvable by id, but not listed in [teams].
  final Map<String, Team> _opponents;

  final PlayerStatsSource? _statsSource;

  /// Time source for [emptyStatsTtl]; injectable for tests.
  final DateTime Function() clock;

  final Map<String, Future<Player>> _statsRequests = {};
  final Map<String, Player> _statsLoaded = {};
  final Map<String, DateTime> _emptyStatsAt = {};

  /// An empty stats result may be transient (a call-up, a feed lag), so it
  /// is only trusted for this long before being fetched again.
  static const emptyStatsTtl = Duration(minutes: 10);

  /// True when at least one league is live.
  bool get isLive => liveLeagues.isNotEmpty;

  /// Leagues that have teams but are showing sample data.
  List<League> get sampleLeagues => [
        for (final league in leagues)
          if (!liveLeagues.contains(league)) league,
      ];

  /// [player] with season stats, if they are already available.
  Player? loadedSeasonStats(Player player) {
    if (player.seasonStats.isNotEmpty) return player;
    if (_statsLoaded[player.id] case final loaded?) {
      final emptyAt = _emptyStatsAt[player.id];
      if (emptyAt == null || clock().difference(emptyAt) < emptyStatsTtl) {
        return loaded;
      }
      _statsLoaded.remove(player.id);
      _emptyStatsAt.remove(player.id);
    }
    // Nothing to fetch: what we have is all there is.
    if (!(_statsSource?.supports(player) ?? false)) return player;
    return null;
  }

  /// [player] with season stats filled in, fetching them if needed.
  ///
  /// Concurrent requests for the same player share one fetch, and results
  /// are cached (empty results only for [emptyStatsTtl]). A failed fetch is
  /// not cached, so calling again retries.
  Future<Player> withSeasonStats(Player player) {
    final loaded = loadedSeasonStats(player);
    if (loaded != null) return Future.value(loaded);
    final source = _statsSource!;
    return _statsRequests.putIfAbsent(player.id, () async {
      try {
        final stats = await source.seasonStats(player);
        if (stats.isEmpty) {
          _emptyStatsAt[player.id] = clock();
        } else {
          _emptyStatsAt.remove(player.id);
        }
        return _statsLoaded[player.id] = player.copyWith(seasonStats: stats);
      } finally {
        _statsRequests.remove(player.id);
      }
    });
  }

  /// Returns the team for [id], or `null` when it is not in the dataset.
  Team? findTeamById(String id) {
    for (final team in teams) {
      if (team.id == id) return team;
    }
    return _opponents[id];
  }

  /// Same as [findTeamById], but throws a clear [StateError] when missing.
  Team teamById(String id) {
    final team = findTeamById(id);
    if (team == null) {
      throw StateError('Unknown team id: $id');
    }
    return team;
  }

  /// Sports that have at least one team, in [Sport] order.
  List<Sport> get sports => [
        for (final sport in Sport.values)
          if (teams.any((t) => t.sport == sport)) sport,
      ];

  /// Leagues that have at least one team, in [League] order.
  List<League> get leagues => leaguesFor();

  /// Leagues that have at least one team, optionally limited to [sport].
  List<League> leaguesFor([Sport? sport]) => [
        for (final league in League.values)
          if (teams.any(
            (t) => t.league == league && (sport == null || t.sport == sport),
          ))
            league,
      ];

  /// Same-league clubs used to grade strengths and weaknesses.
  List<Team> peersOf(Team team) => [
        for (final peer in teams)
          if (peer.sport == team.sport && peer.league == team.league) peer,
      ];

  /// Conference name → teams in [league], best record first.
  Map<String, List<Team>> teamsByConference(League league, {Sport? sport}) {
    final map = <String, List<Team>>{};
    for (final team in teams.where(
      (t) => t.league == league && (sport == null || t.sport == sport),
    )) {
      map.putIfAbsent(team.conference ?? 'Independent', () => []).add(team);
    }
    for (final list in map.values) {
      list.sort((a, b) => b.winPercentage.compareTo(a.winPercentage));
    }
    return map;
  }

  /// Roster ordered by position group, then starters before backups.
  List<Player> rosterFor(String teamId) {
    final roster = players.where((p) => p.teamId == teamId).toList();
    roster.sort((a, b) {
      final group = PositionGroup.of(a.position).index
          .compareTo(PositionGroup.of(b.position).index);
      if (group != 0) return group;
      return (a.role?.index ?? 9).compareTo(b.role?.index ?? 9);
    });
    return roster;
  }

  List<Player> rosterInGroup(String teamId, PositionGroup group) => [
        for (final p in rosterFor(teamId))
          if (group.positions.contains(p.position)) p,
      ];

  /// Players listed as questionable, out, or on injured reserve.
  List<Player> injuryReport(String teamId) => [
        for (final p in rosterFor(teamId))
          if (p.status != PlayerStatus.active) p,
      ];

  /// Most recent completed games for a team, newest first.
  List<GameStats> recentGames(String teamId, {int limit = 5}) => games
      .where((g) =>
          g.isFinal && (g.homeTeamId == teamId || g.awayTeamId == teamId))
      .take(limit)
      .toList();

  /// Completed meetings between two teams, newest first.
  List<GameStats> headToHead(String a, String b) => games
      .where((g) =>
          g.isFinal &&
          ((g.homeTeamId == a && g.awayTeamId == b) ||
              (g.homeTeamId == b && g.awayTeamId == a)))
      .toList();

  /// Scheduled games that have not started yet, earliest first.
  List<GameStats> upcomingGames({
    Sport? sport,
    League? league,
    DateTime? now,
  }) {
    final cutoff = (now ?? DateTime.now()).toUtc();
    final teamsById = {for (final team in teams) team.id: team};
    final upcoming = games.where((game) {
      if (game.status != GameStatus.scheduled ||
          !game.startTime.isAfter(cutoff) ||
          (sport != null && game.sport != sport)) {
        return false;
      }
      final home = teamsById[game.homeTeamId];
      final away = teamsById[game.awayTeamId];
      if (home == null || away == null) return false;
      return league == null || (home.league == league && away.league == league);
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return upcoming;
  }
}
