import '../models/models.dart';

/// Turns season W/L into a matchup win chance and fair odds.
class Predictor {
  static const homeAdvantage = 0.03;

  /// Bill James log5 using each team's season win percentage, then a small
  /// home-court nudge. Result is clamped so long-shot games still price.
  static double moneylineWinChance({
    required Team team,
    required Team opponent,
    bool isHome = false,
  }) {
    final p = team.winPercentage.clamp(0.05, 0.95);
    final q = opponent.winPercentage.clamp(0.05, 0.95);
    final denominator = p + q - 2 * p * q;
    final log5 = denominator == 0 ? 0.5 : (p - p * q) / denominator;
    return (log5 + (isHome ? homeAdvantage : -homeAdvantage)).clamp(0.05, 0.95);
  }

  static double decimalOdds(double winChance) {
    final p = winChance.clamp(0.05, 0.95);
    return 1 / p;
  }

  static int americanOdds(double decimal) {
    if (decimal >= 2) {
      return ((decimal - 1) * 100).round();
    }
    return (-100 / (decimal - 1)).round();
  }
}
