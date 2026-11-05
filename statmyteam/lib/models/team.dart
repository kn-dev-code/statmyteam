import 'json_codec.dart';
import 'league.dart';
import 'sport.dart';

/// A franchise in a given sport and season, including its overall W/L.
class Team {
  const Team({
    required this.id,
    required this.name,
    required this.abbreviation,
    required this.city,
    required this.sport,
    required this.season,
    this.league,
    this.conference,
    this.division,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.primaryColor = 0xFF2EE59D,
    this.secondaryColor = 0xFFFFFFFF,
    this.seasonStats = const {},
  });

  final String id;
  final String name;
  final String abbreviation;
  final String city;
  final Sport sport;
  final String season;

  /// Competition level, e.g. NFL or NCAA. Null for sports without one yet.
  final League? league;
  final String? conference;
  final String? division;
  final int wins;
  final int losses;
  final int draws;

  /// ARGB color used on badges and comparison views.
  final int primaryColor;
  final int secondaryColor;

  /// Team season averages keyed by stat code, e.g. `ppg`, `papg`, `ypg`.
  final Map<String, double> seasonStats;

  double stat(String key, [double fallback = 0]) =>
      seasonStats[key] ?? fallback;

  int get gamesPlayed => wins + losses + draws;

  /// Season win rate in 0–1. Draws do not count as wins.
  double get winPercentage => gamesPlayed == 0 ? 0 : wins / gamesPlayed;

  String get record => draws > 0 ? '$wins-$losses-$draws' : '$wins-$losses';

  String get displayName => '$city $name';

  Team copyWith({
    String? id,
    String? name,
    String? abbreviation,
    String? city,
    Sport? sport,
    String? season,
    League? league,
    String? conference,
    String? division,
    int? wins,
    int? losses,
    int? draws,
    int? primaryColor,
    int? secondaryColor,
    Map<String, double>? seasonStats,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      abbreviation: abbreviation ?? this.abbreviation,
      city: city ?? this.city,
      sport: sport ?? this.sport,
      season: season ?? this.season,
      league: league ?? this.league,
      conference: conference ?? this.conference,
      division: division ?? this.division,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      seasonStats: seasonStats ?? this.seasonStats,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'abbreviation': abbreviation,
        'city': city,
        'sport': sport.name,
        'season': season,
        'league': league?.name,
        'conference': conference,
        'division': division,
        'wins': wins,
        'losses': losses,
        'draws': draws,
        'primaryColor': primaryColor,
        'secondaryColor': secondaryColor,
        'seasonStats': seasonStats,
      };

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as String,
      name: json['name'] as String,
      abbreviation: json['abbreviation'] as String,
      city: json['city'] as String,
      sport: Sport.values.byName(json['sport'] as String),
      season: json['season'] as String,
      league: json['league'] == null
          ? null
          : League.values.byName(json['league'] as String),
      conference: json['conference'] as String?,
      division: json['division'] as String?,
      wins: asInt(json['wins']),
      losses: asInt(json['losses']),
      draws: asInt(json['draws']),
      primaryColor: asInt(json['primaryColor'], 0xFF2EE59D),
      secondaryColor: asInt(json['secondaryColor'], 0xFFFFFFFF),
      seasonStats: asDoubleMap(json['seasonStats']),
    );
  }

  @override
  bool operator ==(Object other) => other is Team && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Team($abbreviation $record)';
}
