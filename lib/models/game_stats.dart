import 'json_codec.dart';
import 'sport.dart';

enum GameStatus { scheduled, live, completed }

/// Team-level box for a single game.
class TeamBoxScore {
  const TeamBoxScore({
    required this.teamId,
    this.score,
    this.stats = const {},
  });

  final String teamId;
  final int? score;
  final Map<String, double> stats;

  TeamBoxScore copyWith({
    String? teamId,
    int? score,
    Map<String, double>? stats,
  }) {
    return TeamBoxScore(
      teamId: teamId ?? this.teamId,
      score: score ?? this.score,
      stats: stats ?? this.stats,
    );
  }

  Map<String, dynamic> toJson() => {
        'teamId': teamId,
        'score': score,
        'stats': stats,
      };

  factory TeamBoxScore.fromJson(Map<String, dynamic> json) {
    return TeamBoxScore(
      teamId: json['teamId'] as String,
      score: json['score'] == null ? null : asInt(json['score']),
      stats: asDoubleMap(json['stats']),
    );
  }
}

/// Player-level line for a single game.
class PlayerBoxScore {
  const PlayerBoxScore({
    required this.playerId,
    this.minutes,
    this.stats = const {},
  });

  final String playerId;
  final int? minutes;
  final Map<String, double> stats;

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        'minutes': minutes,
        'stats': stats,
      };

  factory PlayerBoxScore.fromJson(Map<String, dynamic> json) {
    return PlayerBoxScore(
      playerId: json['playerId'] as String,
      minutes: json['minutes'] == null ? null : asInt(json['minutes']),
      stats: asDoubleMap(json['stats']),
    );
  }
}

/// One contest: matchup, status, team scores, and player lines.
class GameStats {
  const GameStats({
    required this.id,
    required this.sport,
    required this.season,
    required this.startTime,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.home,
    required this.away,
    this.venue,
    this.status = GameStatus.scheduled,
    this.playerBoxScores = const [],
  });

  final String id;
  final Sport sport;
  final String season;
  final DateTime startTime;
  final String homeTeamId;
  final String awayTeamId;
  final TeamBoxScore home;
  final TeamBoxScore away;
  final String? venue;
  final GameStatus status;
  final List<PlayerBoxScore> playerBoxScores;

  bool get isFinal => status == GameStatus.completed;

  String? get winnerTeamId {
    if (!isFinal || home.score == null || away.score == null) return null;
    if (home.score == away.score) return null;
    return home.score! > away.score! ? homeTeamId : awayTeamId;
  }

  PlayerBoxScore? lineForPlayer(String playerId) {
    for (final line in playerBoxScores) {
      if (line.playerId == playerId) return line;
    }
    return null;
  }

  GameStats copyWith({
    String? id,
    Sport? sport,
    String? season,
    DateTime? startTime,
    String? homeTeamId,
    String? awayTeamId,
    TeamBoxScore? home,
    TeamBoxScore? away,
    String? venue,
    GameStatus? status,
    List<PlayerBoxScore>? playerBoxScores,
  }) {
    return GameStats(
      id: id ?? this.id,
      sport: sport ?? this.sport,
      season: season ?? this.season,
      startTime: startTime ?? this.startTime,
      homeTeamId: homeTeamId ?? this.homeTeamId,
      awayTeamId: awayTeamId ?? this.awayTeamId,
      home: home ?? this.home,
      away: away ?? this.away,
      venue: venue ?? this.venue,
      status: status ?? this.status,
      playerBoxScores: playerBoxScores ?? this.playerBoxScores,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sport': sport.name,
        'season': season,
        'startTime': startTime.toIso8601String(),
        'homeTeamId': homeTeamId,
        'awayTeamId': awayTeamId,
        'home': home.toJson(),
        'away': away.toJson(),
        'venue': venue,
        'status': status.name,
        'playerBoxScores':
            playerBoxScores.map((line) => line.toJson()).toList(),
      };

  factory GameStats.fromJson(Map<String, dynamic> json) {
    return GameStats(
      id: json['id'] as String,
      sport: Sport.values.byName(json['sport'] as String),
      season: json['season'] as String,
      startTime: asDateTime(json['startTime']),
      homeTeamId: json['homeTeamId'] as String,
      awayTeamId: json['awayTeamId'] as String,
      home: TeamBoxScore.fromJson(json['home'] as Map<String, dynamic>),
      away: TeamBoxScore.fromJson(json['away'] as Map<String, dynamic>),
      venue: json['venue'] as String?,
      status: GameStatus.values.byName(json['status'] as String),
      playerBoxScores: [
        for (final line in (json['playerBoxScores'] as List<dynamic>? ?? const []))
          PlayerBoxScore.fromJson(line as Map<String, dynamic>),
      ],
    );
  }

  @override
  bool operator ==(Object other) => other is GameStats && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'GameStats($awayTeamId @ $homeTeamId)';
}
