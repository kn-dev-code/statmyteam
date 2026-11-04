String formatMoney(double value, {bool showSign = false}) {
  final negative = value < 0;
  final abs = value.abs();
  final raw = abs.toStringAsFixed(2);
  final parts = raw.split('.');
  final grouped = _groupThousands(parts[0]);
  final sign = negative
      ? '-'
      : (showSign && value > 0 ? '+' : '');
  return '$sign\$$grouped.${parts[1]}';
}

String formatPercent(double value, {int decimals = 1}) {
  return '${(value * 100).toStringAsFixed(decimals)}%';
}

String formatAmericanOdds(int odds) {
  if (odds > 0) return '+$odds';
  return '$odds';
}

String _groupThousands(String digits) {
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
