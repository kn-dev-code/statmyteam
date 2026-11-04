import 'package:flutter_test/flutter_test.dart';
import 'package:statmyteam/logic/money.dart';
import 'package:statmyteam/logic/predictor.dart';
import 'package:statmyteam/models/models.dart';
import 'package:statmyteam/state/betting_controller.dart';

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

  group('Bet', () {
    final won = Bet(
      id: 'b1',
      gameId: 'g1',
      market: BetMarket.moneyline,
      selectionLabel: 'LAL ML',
      stake: 50,
      decimalOdds: 1.8,
      modelWinChance: 0.61,
      placedAt: DateTime.utc(2026, 11, 1),
      status: BetStatus.won,
    );

    test('computes payouts and realized profit', () {
      expect(won.potentialPayout, 90);
      expect(won.realizedProfit, 40);
      expect(won.copyWith(status: BetStatus.lost).realizedProfit, -50);
      expect(won.copyWith(status: BetStatus.pending).realizedProfit, 0);
      expect(won.americanOdds, -125);
    });

    test('round-trips through JSON', () {
      final decoded = Bet.fromJson(won.toJson());
      expect(decoded, won);
      expect(decoded.decimalOdds, 1.8);
    });
  });

  group('Predictor', () {
    const favorite = Team(
      id: 'a',
      name: 'A',
      abbreviation: 'A',
      city: 'A',
      sport: Sport.basketball,
      season: '2026-27',
      wins: 12,
      losses: 4,
    );
    const underdog = Team(
      id: 'b',
      name: 'B',
      abbreviation: 'B',
      city: 'B',
      sport: Sport.basketball,
      season: '2026-27',
      wins: 8,
      losses: 8,
    );

    test('gives the better record a higher win chance at home', () {
      final chance = Predictor.moneylineWinChance(
        team: favorite,
        opponent: underdog,
        isHome: true,
      );
      expect(chance, greaterThan(0.5));
      expect(chance, lessThan(1));
      expect(Predictor.decimalOdds(chance), closeTo(1 / chance, 0.0001));
    });
  });

  group('BettingController', () {
    test('tracks virtual bankroll as bets are placed', () {
      final controller = BettingController.demo();
      final opening = controller.availableBalance;
      expect(opening, lessThan(controller.startingBankroll));
      expect(controller.settledWins, 2);
      expect(controller.settledLosses, 3);

      final game = controller.board.first;
      final home = controller.teamById(game.homeTeamId);
      controller.toggleMoneyline(game, home, 0.6);
      expect(controller.slip, hasLength(1));

      final error = controller.placeSlip();
      expect(error, isNull);
      expect(controller.slip, isEmpty);
      expect(controller.availableBalance, opening - 25);
      expect(controller.pendingCount, 2);
    });
  });

  test('formats money and odds', () {
    expect(formatMoney(1240), '\$1,240.00');
    expect(formatMoney(-40, showSign: true), '-\$40.00');
    expect(formatAmericanOdds(125), '+125');
    expect(formatPercent(0.62), '62.0%');
  });
}
