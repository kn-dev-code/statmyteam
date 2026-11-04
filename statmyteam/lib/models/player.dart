import 'json_codec.dart';
import 'sport.dart';

/// A player attached to a [Team], with sport-agnostic season statistics.
class Player {
  const Player({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.teamId,
    required this.position,
    required this.jerseyNumber,
    required this.sport,
    this.seasonStats = const {},
  });

  final String id;
  final String firstName;
  final String lastName;
  final String teamId;
  final String position;
  final int jerseyNumber;
  final Sport sport;

  /// Season averages or totals keyed by stat code, e.g. `ppg`, `rpg`, `apg`.
  /// Keeping this as a map lets the same model expand to other sports.
  final Map<String, double> seasonStats;

  String get fullName => '$firstName $lastName';

  String get shortLabel => '#$jerseyNumber $fullName';

  double stat(String key, [double fallback = 0]) =>
      seasonStats[key] ?? fallback;

  Player copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? teamId,
    String? position,
    int? jerseyNumber,
    Sport? sport,
    Map<String, double>? seasonStats,
  }) {
    return Player(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      teamId: teamId ?? this.teamId,
      position: position ?? this.position,
      jerseyNumber: jerseyNumber ?? this.jerseyNumber,
      sport: sport ?? this.sport,
      seasonStats: seasonStats ?? this.seasonStats,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'teamId': teamId,
        'position': position,
        'jerseyNumber': jerseyNumber,
        'sport': sport.name,
        'seasonStats': seasonStats,
      };

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      teamId: json['teamId'] as String,
      position: json['position'] as String,
      jerseyNumber: asInt(json['jerseyNumber']),
      sport: Sport.values.byName(json['sport'] as String),
      seasonStats: asDoubleMap(json['seasonStats']),
    );
  }

  @override
  bool operator ==(Object other) => other is Player && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Player($fullName)';
}
