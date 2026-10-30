import 'json_codec.dart';
import 'sport.dart';

/// Availability for the next game.
enum PlayerStatus {
  active,
  questionable,
  out,
  injuredReserve;

  String get label => switch (this) {
        PlayerStatus.active => 'Active',
        PlayerStatus.questionable => 'Questionable',
        PlayerStatus.out => 'Out',
        PlayerStatus.injuredReserve => 'Injured reserve',
      };

  String get shortLabel => switch (this) {
        PlayerStatus.active => 'ACT',
        PlayerStatus.questionable => 'Q',
        PlayerStatus.out => 'OUT',
        PlayerStatus.injuredReserve => 'IR',
      };

  /// True when the player will not suit up.
  bool get isUnavailable =>
      this == PlayerStatus.out || this == PlayerStatus.injuredReserve;
}

/// Where a player sits on the depth chart.
enum DepthRole {
  starter,
  rotation,
  backup;

  String get label => switch (this) {
        DepthRole.starter => 'Starter',
        DepthRole.rotation => 'Rotation',
        DepthRole.backup => 'Backup',
      };
}

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
    this.role,
    this.status = PlayerStatus.active,
    this.injuryNote,
    this.age,
    this.heightInches,
    this.weightLbs,
    this.yearsPro,
    this.college,
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

  final DepthRole? role;
  final PlayerStatus status;

  /// Short injury description, e.g. `Hamstring`. Null when healthy.
  final String? injuryNote;
  final int? age;
  final int? heightInches;
  final int? weightLbs;
  final int? yearsPro;
  final String? college;

  bool get isStarter => role == DepthRole.starter;

  bool get isAvailable => !status.isUnavailable;

  /// Height as feet-inches, e.g. `6'2"`.
  String? get heightLabel => heightInches == null
      ? null
      : "${heightInches! ~/ 12}'${heightInches! % 12}\"";

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
    DepthRole? role,
    PlayerStatus? status,
    String? injuryNote,
    int? age,
    int? heightInches,
    int? weightLbs,
    int? yearsPro,
    String? college,
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
      role: role ?? this.role,
      status: status ?? this.status,
      injuryNote: injuryNote ?? this.injuryNote,
      age: age ?? this.age,
      heightInches: heightInches ?? this.heightInches,
      weightLbs: weightLbs ?? this.weightLbs,
      yearsPro: yearsPro ?? this.yearsPro,
      college: college ?? this.college,
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
        'role': role?.name,
        'status': status.name,
        'injuryNote': injuryNote,
        'age': age,
        'heightInches': heightInches,
        'weightLbs': weightLbs,
        'yearsPro': yearsPro,
        'college': college,
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
      role: json['role'] == null
          ? null
          : DepthRole.values.byName(json['role'] as String),
      status: json['status'] == null
          ? PlayerStatus.active
          : PlayerStatus.values.byName(json['status'] as String),
      injuryNote: json['injuryNote'] as String?,
      age: json['age'] == null ? null : asInt(json['age']),
      heightInches:
          json['heightInches'] == null ? null : asInt(json['heightInches']),
      weightLbs: json['weightLbs'] == null ? null : asInt(json['weightLbs']),
      yearsPro: json['yearsPro'] == null ? null : asInt(json['yearsPro']),
      college: json['college'] as String?,
    );
  }

  @override
  bool operator ==(Object other) => other is Player && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Player($fullName)';
}
