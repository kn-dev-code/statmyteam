import '../logic/football_stats.dart';
import '../models/models.dart';
import 'football_data.dart';

/// Read-only access to teams, players, and results for the stats screens.
///
/// Backed by the fictional sample league for now; swap the constructor
/// arguments for API results later without touching the UI.
class StatsRepository {
  StatsRepository({
    required List<Team> teams,
    required List<Player> players,
    required List<GameStats> games,
  })  : teams = List.unmodifiable(teams),
        players = List.unmodifiable(players),
        games = List.unmodifiable(
          List<GameStats>.of(games)
            ..sort((a, b) => b.startTime.compareTo(a.startTime)),
        );

  factory StatsRepository.sampleFootball() => StatsRepository(
        teams: footballTeams,
        players: footballPlayers,
        games: footballGames,
      );

  final List<Team> teams;
  final List<Player> players;

  /// Newest first.
  final List<GameStats> games;

  Team teamById(String id) => teams.firstWhere((team) => team.id == id);

  /// Conference name → teams, best record first.
  Map<String, List<Team>> get teamsByConference {
    final map = <String, List<Team>>{};
    for (final team in teams) {
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
}
