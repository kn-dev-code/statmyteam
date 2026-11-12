import '../logic/football_stats.dart';
import '../models/models.dart';
import 'espn_football_api.dart';
import 'football_data.dart';

/// Read-only access to teams, players, and results for the stats screens.
///
/// Prefer [liveFootball] for real NFL data from ESPN; [sampleFootball] stays
/// available for offline / widget tests.
class StatsRepository {
  StatsRepository({
    required List<Team> teams,
    required List<Player> players,
    required List<GameStats> games,
    this.isLive = false,
    this.loadError,
  })  : teams = List.unmodifiable(teams),
        players = List.unmodifiable(players),
        games = List.unmodifiable(
          List<GameStats>.of(games)
            ..sort((a, b) => b.startTime.compareTo(a.startTime)),
        );

  /// Fictional NFL and NCAA sample leagues.
  factory StatsRepository.sampleFootball() => StatsRepository(
        teams: [...footballTeams, ...collegeTeams],
        players: [...footballPlayers, ...collegePlayers],
        games: [...footballGames, ...collegeGames],
      );

  /// Live NFL from ESPN, plus the sample NCAA set so college browsing still works.
  ///
  /// Falls back to [sampleFootball] if the network request fails.
  static Future<StatsRepository> liveFootball({EspnFootballApi? api}) async {
    final client = api ?? EspnFootballApi();
    try {
      final live = await client.fetchLeague();
      return StatsRepository(
        teams: [...live.teams, ...collegeTeams],
        players: [...live.players, ...collegePlayers],
        games: [...live.games, ...collegeGames],
        isLive: true,
      );
    } catch (error) {
      return StatsRepository(
        teams: [...footballTeams, ...collegeTeams],
        players: [...footballPlayers, ...collegePlayers],
        games: [...footballGames, ...collegeGames],
        isLive: false,
        loadError: '$error',
      );
    } finally {
      if (api == null) client.close();
    }
  }

  final List<Team> teams;
  final List<Player> players;

  /// True when NFL data came from ESPN rather than the sample pack.
  final bool isLive;

  /// Populated when a live load failed and sample data was used instead.
  final String? loadError;

  /// Newest first.
  final List<GameStats> games;

  Team teamById(String id) => teams.firstWhere((team) => team.id == id);

  /// Leagues that have at least one team, in [League] order.
  List<League> get leagues => [
        for (final league in League.values)
          if (teams.any((t) => t.league == league)) league,
      ];

  /// Conference name → teams in [league], best record first.
  Map<String, List<Team>> teamsByConference(League league) {
    final map = <String, List<Team>>{};
    for (final team in teams.where((t) => t.league == league)) {
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
