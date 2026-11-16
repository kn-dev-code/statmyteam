import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'espn_leagues.dart';

/// Thrown when ESPN answers with a non-2xx status or an unexpected payload.
class EspnRequestException implements Exception {
  const EspnRequestException(this.url, {this.statusCode, this.reason});

  final String url;
  final int? statusCode;
  final String? reason;

  bool get isNotFound => statusCode == 404;

  /// Rate limiting and server errors are worth one more try.
  bool get isTransient =>
      statusCode != null && (statusCode == 429 || statusCode! >= 500);

  @override
  String toString() => statusCode != null
      ? 'ESPN request failed ($statusCode): $url'
      : 'ESPN request failed (${reason ?? 'bad payload'}): $url';
}

/// Thrown when ESPN answers, but the feed is missing data a league needs
/// (no standings, no season, most rosters failing).
class EspnDataException implements Exception {
  const EspnDataException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Thin JSON GET wrapper shared by the league loader and player stats.
///
/// Transient failures (timeouts, connection errors, 429 / 5xx) are retried
/// once after [retryDelay]; anything else is thrown immediately.
class EspnHttp {
  EspnHttp(
    this.client, {
    this.timeout = const Duration(seconds: 20),
    this.retryDelay = const Duration(milliseconds: 400),
  });

  final http.Client client;
  final Duration timeout;
  final Duration retryDelay;

  Future<Map<String, dynamic>> getJson(String url) async {
    try {
      return await _getJsonOnce(url);
    } on EspnRequestException catch (e) {
      if (!e.isTransient) rethrow;
    } on TimeoutException {
      // Retry below.
    } on http.ClientException {
      // Retry below.
    }
    await Future<void>.delayed(retryDelay);
    return _getJsonOnce(url);
  }

  Future<Map<String, dynamic>> _getJsonOnce(String url) async {
    final response = await client.get(Uri.parse(url)).timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw EspnRequestException(url, statusCode: response.statusCode);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw EspnRequestException(url, reason: 'expected a JSON object');
    }
    return decoded;
  }
}

/// Flattens a core-API `statistics` payload into `category.name` → value.
EspnStats parseEspnStats(Map<String, dynamic>? json) {
  final out = <String, double>{};
  final splits = json?['splits'];
  if (splits is! Map) return out;
  final categories = splits['categories'];
  if (categories is! List) return out;
  for (final category in categories) {
    if (category is! Map) continue;
    final categoryName = category['name'];
    final stats = category['stats'];
    if (categoryName is! String || stats is! List) continue;
    for (final stat in stats) {
      if (stat is! Map) continue;
      final name = stat['name'];
      final value = stat['value'];
      if (name is String && value is num) {
        out['$categoryName.$name'] = value.toDouble();
      }
    }
  }
  return out;
}

/// Runs [task] over [items] with at most [concurrency] tasks running at
/// once, preserving input order. [task] should not throw.
Future<List<R>> mapWithConcurrency<T, R>(
  List<T> items,
  int concurrency,
  Future<R> Function(T item) task,
) async {
  final results = List<R?>.filled(items.length, null);
  var next = 0;
  Future<void> worker() async {
    while (next < items.length) {
      final index = next++;
      results[index] = await task(items[index]);
    }
  }

  final workers = concurrency < items.length ? concurrency : items.length;
  await Future.wait([for (var i = 0; i < workers; i++) worker()]);
  return results.cast<R>();
}
