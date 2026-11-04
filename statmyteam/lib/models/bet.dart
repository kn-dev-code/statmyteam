import 'json_codec.dart';

enum BetMarket { moneyline, spread, total, playerProp }

enum BetStatus { pending, won, lost, push }

/// A lined selection sitting on the slip, before it is placed.
class BetPick {
  const BetPick({
    required this.gameId,
    required this.market,
    required this.selectionLabel,
    required this.stake,
    required this.decimalOdds,
    required this.modelWinChance,
    this.teamId,
    this.playerId,
    this.spread,
    this.totalLine,
  });

  final String gameId;
  final BetMarket market;
  final String selectionLabel;
  final double stake;
  final double decimalOdds;
  final double modelWinChance;
  final String? teamId;
  final String? playerId;
  final double? spread;
  final double? totalLine;

  double get potentialPayout => stake * decimalOdds;

  double get potentialProfit => potentialPayout - stake;

  BetPick copyWith({double? stake}) {
    return BetPick(
      gameId: gameId,
      market: market,
      selectionLabel: selectionLabel,
      stake: stake ?? this.stake,
      decimalOdds: decimalOdds,
      modelWinChance: modelWinChance,
      teamId: teamId,
      playerId: playerId,
      spread: spread,
      totalLine: totalLine,
    );
  }

  Bet toBet({required String id, required DateTime placedAt}) {
    return Bet(
      id: id,
      gameId: gameId,
      market: market,
      selectionLabel: selectionLabel,
      stake: stake,
      decimalOdds: decimalOdds,
      modelWinChance: modelWinChance,
      placedAt: placedAt,
      teamId: teamId,
      playerId: playerId,
      spread: spread,
      totalLine: totalLine,
    );
  }
}

/// A virtual wager placed against a game, team, or player.
class Bet {
  const Bet({
    required this.id,
    required this.gameId,
    required this.market,
    required this.selectionLabel,
    required this.stake,
    required this.decimalOdds,
    required this.modelWinChance,
    required this.placedAt,
    this.teamId,
    this.playerId,
    this.spread,
    this.totalLine,
    this.status = BetStatus.pending,
    this.settledAt,
  });

  final String id;
  final String gameId;
  final BetMarket market;
  final String selectionLabel;
  final double stake;
  final double decimalOdds;

  /// Model-estimated probability that this selection wins, 0–1.
  final double modelWinChance;
  final DateTime placedAt;
  final String? teamId;
  final String? playerId;
  final double? spread;
  final double? totalLine;
  final BetStatus status;
  final DateTime? settledAt;

  bool get isSettled => status != BetStatus.pending;

  double get potentialPayout => stake * decimalOdds;

  double get potentialProfit => potentialPayout - stake;

  /// Profit credited to the virtual bankroll. Pending bets realize 0.
  double get realizedProfit => switch (status) {
        BetStatus.won => potentialProfit,
        BetStatus.lost => -stake,
        BetStatus.push || BetStatus.pending => 0,
      };

  /// American odds implied by [decimalOdds].
  int get americanOdds {
    if (decimalOdds >= 2) {
      return ((decimalOdds - 1) * 100).round();
    }
    return (-100 / (decimalOdds - 1)).round();
  }

  Bet copyWith({
    String? id,
    BetStatus? status,
    DateTime? settledAt,
    double? stake,
  }) {
    return Bet(
      id: id ?? this.id,
      gameId: gameId,
      market: market,
      selectionLabel: selectionLabel,
      stake: stake ?? this.stake,
      decimalOdds: decimalOdds,
      modelWinChance: modelWinChance,
      placedAt: placedAt,
      teamId: teamId,
      playerId: playerId,
      spread: spread,
      totalLine: totalLine,
      status: status ?? this.status,
      settledAt: settledAt ?? this.settledAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'gameId': gameId,
        'market': market.name,
        'selectionLabel': selectionLabel,
        'stake': stake,
        'decimalOdds': decimalOdds,
        'modelWinChance': modelWinChance,
        'placedAt': placedAt.toIso8601String(),
        'teamId': teamId,
        'playerId': playerId,
        'spread': spread,
        'totalLine': totalLine,
        'status': status.name,
        'settledAt': settledAt?.toIso8601String(),
      };

  factory Bet.fromJson(Map<String, dynamic> json) {
    return Bet(
      id: json['id'] as String,
      gameId: json['gameId'] as String,
      market: BetMarket.values.byName(json['market'] as String),
      selectionLabel: json['selectionLabel'] as String,
      stake: asDouble(json['stake']),
      decimalOdds: asDouble(json['decimalOdds']),
      modelWinChance: asDouble(json['modelWinChance']),
      placedAt: asDateTime(json['placedAt']),
      teamId: json['teamId'] as String?,
      playerId: json['playerId'] as String?,
      spread: json['spread'] == null ? null : asDouble(json['spread']),
      totalLine: json['totalLine'] == null ? null : asDouble(json['totalLine']),
      status: BetStatus.values.byName(json['status'] as String),
      settledAt:
          json['settledAt'] == null ? null : asDateTime(json['settledAt']),
    );
  }

  @override
  bool operator ==(Object other) => other is Bet && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Bet($selectionLabel ${status.name})';
}
