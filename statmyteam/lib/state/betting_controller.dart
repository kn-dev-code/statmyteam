import 'package:flutter/foundation.dart';

import '../data/sample_data.dart';
import '../logic/predictor.dart';
import '../models/models.dart';

class BettingController extends ChangeNotifier {
  BettingController({
    required this.startingBankroll,
    required this.teams,
    required this.players,
    required this.games,
    required List<Bet> bets,
  }) : _bets = List<Bet>.of(bets);

  factory BettingController.demo() {
    return BettingController(
      startingBankroll: 1000,
      teams: sampleTeams,
      players: samplePlayers,
      games: sampleGames,
      bets: sampleBets,
    );
  }

  final double startingBankroll;
  final List<Team> teams;
  final List<Player> players;
  final List<GameStats> games;

  final List<Bet> _bets;
  final List<BetPick> _slip = [];
  int _idSeed = 100;

  List<Bet> get bets => List.unmodifiable(_bets);
  List<BetPick> get slip => List.unmodifiable(_slip);

  List<GameStats> get board => games
      .where((game) => game.status != GameStatus.completed)
      .toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));

  List<Bet> get history {
    final copy = List<Bet>.of(_bets);
    copy.sort((a, b) => b.placedAt.compareTo(a.placedAt));
    return copy;
  }

  double get pendingStakes => _bets
      .where((bet) => bet.status == BetStatus.pending)
      .fold(0, (sum, bet) => sum + bet.stake);

  double get settledProfit => _bets
      .where((bet) => bet.isSettled)
      .fold(0, (sum, bet) => sum + bet.realizedProfit);

  double get availableBalance =>
      startingBankroll + settledProfit - pendingStakes;

  double get equity => startingBankroll + settledProfit;

  int get settledWins =>
      _bets.where((bet) => bet.status == BetStatus.won).length;

  int get settledLosses =>
      _bets.where((bet) => bet.status == BetStatus.lost).length;

  int get pendingCount =>
      _bets.where((bet) => bet.status == BetStatus.pending).length;

  double get winRate {
    final decided = settledWins + settledLosses;
    if (decided == 0) return 0;
    return settledWins / decided;
  }

  List<double> get bankrollCurve {
    final settled = _bets.where((bet) => bet.isSettled).toList()
      ..sort((a, b) => (a.settledAt ?? a.placedAt)
          .compareTo(b.settledAt ?? b.placedAt));
    final points = <double>[startingBankroll];
    var running = startingBankroll;
    for (final bet in settled) {
      running += bet.realizedProfit;
      points.add(running);
    }
    return points;
  }

  Team teamById(String id) => teams.firstWhere((team) => team.id == id);

  Player playerById(String id) =>
      players.firstWhere((player) => player.id == id);

  GameStats gameById(String id) =>
      games.firstWhere((game) => game.id == id);

  double homeWinChance(GameStats game) {
    return Predictor.moneylineWinChance(
      team: teamById(game.homeTeamId),
      opponent: teamById(game.awayTeamId),
      isHome: true,
    );
  }

  BetPick? selectedPickFor(String gameId) {
    for (final pick in _slip) {
      if (pick.gameId == gameId) return pick;
    }
    return null;
  }

  void toggleMoneyline(GameStats game, Team team, double winChance) {
    final existing = selectedPickFor(game.id);
    if (existing != null && existing.teamId == team.id) {
      _slip.remove(existing);
      notifyListeners();
      return;
    }
    _slip.removeWhere((pick) => pick.gameId == game.id);
    _slip.add(
      BetPick(
        gameId: game.id,
        market: BetMarket.moneyline,
        selectionLabel: '${team.abbreviation} ML',
        stake: 25,
        decimalOdds: Predictor.decimalOdds(winChance),
        modelWinChance: winChance,
        teamId: team.id,
      ),
    );
    notifyListeners();
  }

  void removePick(BetPick pick) {
    _slip.remove(pick);
    notifyListeners();
  }

  void updateStake(BetPick pick, double stake) {
    final index = _slip.indexOf(pick);
    if (index < 0) return;
    _slip[index] = pick.copyWith(stake: stake.clamp(1, 10000));
    notifyListeners();
  }

  double get slipTotal =>
      _slip.fold(0, (sum, pick) => sum + pick.stake);

  /// Places every pick on the slip. Returns an error message, or null on success.
  String? placeSlip() {
    if (_slip.isEmpty) return 'Add a pick to the slip first.';
    if (slipTotal > availableBalance) {
      return 'Not enough virtual bankroll for this slip.';
    }
    final now = DateTime.now().toUtc();
    for (final pick in _slip) {
      _idSeed += 1;
      _bets.insert(0, pick.toBet(id: 'b$_idSeed', placedAt: now));
    }
    _slip.clear();
    notifyListeners();
    return null;
  }
}
