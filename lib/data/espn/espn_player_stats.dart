import 'package:http/http.dart' as http;

import '../../models/models.dart';
import 'espn_http.dart';
import 'espn_leagues.dart';

/// Loads a player's season stats on demand.
///
/// Rosters are loaded up front, but per-player stats would be thousands of
/// requests, so screens ask for them only when a player is shown.
abstract interface class PlayerStatsSource {
  /// Whether this source knows how to load stats for [player].
  bool supports(Player player);

  /// Season stats keyed by app stat code. Empty when the player has not
  /// recorded any stats this season.
  Future<Map<String, double>> seasonStats(Player player);
}

/// [PlayerStatsSource] backed by ESPN's core athlete statistics endpoint.
class EspnPlayerStatsSource implements PlayerStatsSource {
  EspnPlayerStatsSource({
    required http.Client client,
    required Map<League, int> seasonYears,
    Duration timeout = const Duration(seconds: 20),
    Duration retryDelay = const Duration(milliseconds: 400),
  })  : _http = EspnHttp(client, timeout: timeout, retryDelay: retryDelay),
        _seasonYears = Map.unmodifiable(seasonYears);

  final EspnHttp _http;
  final Map<League, int> _seasonYears;

  @override
  bool supports(Player player) {
    final league = EspnLeague.forPlayerId(player.id);
    return league != null && _seasonYears.containsKey(league.league);
  }

  @override
  Future<Map<String, double>> seasonStats(Player player) async {
    final league = EspnLeague.forPlayerId(player.id);
    final year = league == null ? null : _seasonYears[league.league];
    final athleteId = league?.espnAthleteId(player.id);
    if (league == null || year == null || athleteId == null) {
      throw ArgumentError.value(player.id, 'player', 'not a live ESPN player');
    }
    final url = '${league.coreBase}/seasons/$year/types/'
        '${league.regularSeasonType}/athletes/$athleteId/statistics';
    try {
      return league.playerStats(parseEspnStats(await _http.getJson(url)));
    } on EspnRequestException catch (e) {
      // ESPN 404s athletes who have not appeared this season.
      if (e.isNotFound) return const {};
      rethrow;
    }
  }
}
