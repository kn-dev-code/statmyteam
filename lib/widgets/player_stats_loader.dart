import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../data/stats_repository.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import '../state/stats_scope.dart';
import '../theme/app_theme.dart';
import 'stats_widgets.dart';

/// Builds [builder] with [players] once their season stats are available.
///
/// Live rosters load without per-player stats; this fetches them on demand
/// (cached in the repository), showing a loading row meanwhile and a retry
/// action if the request fails. Players that already have stats, such as
/// sample data, build immediately.
class PlayerStatsLoader extends StatefulWidget {
  const PlayerStatsLoader({
    super.key,
    required this.players,
    required this.builder,
  });

  final List<Player> players;
  final Widget Function(BuildContext context, List<Player> players) builder;

  @override
  State<PlayerStatsLoader> createState() => _PlayerStatsLoaderState();
}

class _PlayerStatsLoaderState extends State<PlayerStatsLoader> {
  List<Player>? _ready;
  Future<List<Player>>? _pending;
  StatsRepository? _repo;
  List<Player> _players = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only a different repository needs a reload; other inherited changes
    // (theme, media query) must not restart an in-flight fetch.
    if (!identical(StatsScope.of(context), _repo)) _load();
  }

  @override
  void didUpdateWidget(covariant PlayerStatsLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_samePlayers(widget.players, _players)) _load();
  }

  void _load() {
    final repo = _repo = StatsScope.of(context);
    _players = List.of(widget.players);
    final loaded = [for (final p in widget.players) repo.loadedSeasonStats(p)];
    if (loaded.every((p) => p != null)) {
      _ready = loaded.cast<Player>();
      _pending = null;
      return;
    }
    _ready = null;
    final ids = [for (final p in widget.players) p.id];
    _pending =
        Future.wait([for (final p in widget.players) repo.withSeasonStats(p)])
            .catchError((Object error, StackTrace stack) {
              developer.log(
                'Season stats failed for $ids',
                name: 'PlayerStatsLoader',
                error: error,
                stackTrace: stack,
              );
              // Rethrow so the FutureBuilder shows the error state with Retry.
              Error.throwWithStackTrace(error, stack);
            });
  }

  /// Same player objects in the same order (an updated [Player] with the
  /// same id counts as a change).
  static bool _samePlayers(List<Player> a, List<Player> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!identical(a[i], b[i])) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final ready = _ready;
    if (ready != null) return widget.builder(context, ready);

    return FutureBuilder<List<Player>>(
      future: _pending,
      builder: (context, snapshot) {
        // A new future (Retry) keeps the previous snapshot's error until it
        // settles, so check the state before reading data / error.
        final done = snapshot.connectionState == ConnectionState.done;
        if (done && snapshot.hasData) {
          return widget.builder(context, snapshot.data!);
        }
        if (done && snapshot.hasError) {
          return StatCard(
            child: Row(
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  color: context.colors.gold,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(context.l10n.couldNotLoadSeasonStats)),
                TextButton(
                  onPressed: () => setState(_load),
                  child: Text(context.l10n.retry),
                ),
              ],
            ),
          );
        }
        return StatCard(
          child: Row(
            children: [
              const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(
                context.l10n.loadingSeasonStats,
                style: TextStyle(color: context.colors.muted),
              ),
            ],
          ),
        );
      },
    );
  }
}
