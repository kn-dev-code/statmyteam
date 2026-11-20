import 'dart:async';

import 'package:http/http.dart' as http;

import 'espn/espn_http.dart';

/// A part of a league feed that is fetched per team.
enum FeedPart { teamStats, rosters, schedules }

/// Part of a live league that failed to load while the league itself loaded,
/// e.g. 3 of 30 rosters.
class FeedGap {
  const FeedGap(this.part, this.failed, this.total);

  final FeedPart part;
  final int failed;
  final int total;

  @override
  bool operator ==(Object other) =>
      other is FeedGap &&
      other.part == part &&
      other.failed == failed &&
      other.total == total;

  @override
  int get hashCode => Object.hash(part, failed, total);

  @override
  String toString() => '$failed of $total ${part.name}';
}

/// Why a live league could not load, coarse enough to explain to a user.
enum LoadFailureKind {
  /// The feed took too long.
  timeout,

  /// No connection, DNS failure, socket closed.
  network,

  /// ESPN answered with an error status.
  server,

  /// ESPN answered, but without the data the league needs.
  badData,
}

/// A failed league load: a user-facing [kind] plus the technical [detail],
/// which is for logs and tests only and must not be shown in the UI.
class LoadFailure {
  const LoadFailure(this.kind, this.detail);

  /// Classifies a feed failure (see `StatsRepository.live`).
  factory LoadFailure.from(Object error) {
    final kind = switch (error) {
      TimeoutException() => LoadFailureKind.timeout,
      http.ClientException() => LoadFailureKind.network,
      EspnRequestException(statusCode: _?) => LoadFailureKind.server,
      _ => LoadFailureKind.badData,
    };
    return LoadFailure(kind, '$error');
  }

  final LoadFailureKind kind;
  final String detail;

  @override
  String toString() => '${kind.name}: $detail';
}
