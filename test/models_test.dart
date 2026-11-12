import 'package:flutter_test/flutter_test.dart';
import 'package:statmyteam/data/stats_repository.dart';
import 'package:statmyteam/models/models.dart';

void main() {
  group('Team', () {
    const lakers = Team(
      id: 'lakers',
      name: 'Lakers',
      abbreviation: 'LAL',
      city: 'Los Angeles',
      sport: Sport.basketball,
      season: '2026-27',
      wins: 12,
      losses: 4,
    );

    test('computes season record and win percentage', () {
      expect(lakers.record, '12-4');
      expect(lakers.gamesPlayed, 16);
      expect(lakers.winPercentage, 0.75);
      expect(lakers.displayName, 'Los Angeles Lakers');
    });

    test('round-trips through JSON', () {
      expect(Team.fromJson(lakers.toJson()), lakers);
    });
  });

  group('Player', () {
    const player = Player(
      id: 'lebron',
      firstName: 'LeBron',
      lastName: 'James',
      teamId: 'lakers',
      position: 'SF',
      jerseyNumber: 23,
      sport: Sport.basketball,
      seasonStats: {'ppg': 24.1, 'rpg': 7.4},
    );

    test('exposes identity and stats', () {
      expect(player.fullName, 'LeBron James');
      expect(player.stat('ppg'), 24.1);
      expect(player.stat('apg'), 0);
    });

    test('round-trips through JSON', () {
      final decoded = Player.fromJson(player.toJson());
      expect(decoded, player);
      expect(decoded.seasonStats['ppg'], 24.1);
    });
  });

  group('GameStats', () {
    final game = GameStats(
      id: 'g1',
      sport: Sport.basketball,
      season: '2026-27',
      startTime: DateTime.utc(2026, 11, 1, 2),
      homeTeamId: 'lakers',
      awayTeamId: 'bucks',
      status: GameStatus.completed,
      home: const TeamBoxScore(teamId: 'lakers', score: 118),
      away: const TeamBoxScore(teamId: 'bucks', score: 111),
      playerBoxScores: const [
        PlayerBoxScore(playerId: 'lebron', minutes: 36, stats: {'pts': 28}),
      ],
    );

    test('names a winner only when the game is final', () {
      expect(game.winnerTeamId, 'lakers');
      expect(game.lineForPlayer('lebron')?.stats['pts'], 28);
      expect(
        game.copyWith(status: GameStatus.scheduled).winnerTeamId,
        isNull,
      );
    });

    test('round-trips through JSON', () {
      final decoded = GameStats.fromJson(game.toJson());
      expect(decoded.id, game.id);
      expect(decoded.home.score, 118);
      expect(decoded.playerBoxScores.single.playerId, 'lebron');
    });
  });

  test('findTeamById returns null for unknown ids', () {
    final repo = StatsRepository.sampleFootball();
    expect(repo.findTeamById('por'), isNotNull);
    expect(repo.findTeamById('missing-team'), isNull);
    expect(() => repo.teamById('missing-team'), throwsStateError);
  });

}
