/// Hits the real ESPN APIs. Slow and network-dependent by design: it is the
/// check that the live feeds still have the shape the parsers expect.
///
/// Tagged `live`, which dart_test.yaml skips by default so CI and everyday
/// runs stay offline. Run it with:
///   flutter test --run-skipped --tags live
@Tags(['live'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:statmyteam/data/stats_repository.dart';
import 'package:statmyteam/models/models.dart';

void main() {
  late StatsRepository repo;

  setUpAll(() async {
    repo = await StatsRepository.live();
  });

  test('every league loads live from ESPN', () {
    expect(repo.loadErrors, isEmpty, reason: '${repo.loadErrors}');
    expect(
      repo.liveLeagues,
      containsAll([League.nfl, League.ncaa, League.nba, League.mls]),
    );
  });

  for (final (league, minTeams, minPlayers) in [
    (League.nfl, 32, 1000),
    (League.ncaa, 120, 5000),
    (League.nba, 30, 300),
    (League.mls, 28, 500),
  ]) {
    test('${league.label} has teams, rosters, games, and team stats', () {
      final teams = repo.teams.where((t) => t.league == league).toList();
      expect(teams.length, greaterThanOrEqualTo(minTeams));
      final ids = {for (final t in teams) t.id};
      expect(
        repo.players.where((p) => ids.contains(p.teamId)).length,
        greaterThan(minPlayers),
      );
      expect(
        repo.games.where((g) => ids.contains(g.homeTeamId)).isNotEmpty,
        isTrue,
      );
      final withStats = teams.where((t) => t.seasonStats.containsKey('ppg'));
      expect(withStats.length, greaterThan(teams.length ~/ 2));
      // Every listed result can be labelled, including non-league opponents.
      for (final team in teams.take(5)) {
        for (final game in repo.recentGames(team.id)) {
          expect(repo.findTeamById(game.homeTeamId), isNotNull);
          expect(repo.findTeamById(game.awayTeamId), isNotNull);
        }
      }
    });

    test('${league.label} player stats load on demand', () async {
      final team = repo.teams.firstWhere((t) => t.league == league);
      // Starters are the most likely to have played this season.
      final starters = repo
          .rosterFor(team.id)
          .where((p) => p.isStarter)
          .take(6)
          .toList();
      final loaded = await Future.wait(starters.map(repo.withSeasonStats));
      expect(
        loaded.any((p) => p.seasonStats.containsKey('gp')),
        isTrue,
        reason: 'no ${league.label} starter on ${team.displayName} had stats',
      );
    });
  }
}
