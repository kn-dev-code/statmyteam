int asInt(Object? value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

double asDouble(Object? value, [double fallback = 0]) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

DateTime asDateTime(Object? value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  throw FormatException('Expected ISO-8601 date, got $value');
}

Map<String, double> asDoubleMap(Object? value) {
  if (value is! Map) return const {};
  return value.map(
    (key, dynamic v) => MapEntry(key.toString(), asDouble(v)),
  );
}
