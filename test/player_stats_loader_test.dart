import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:statmyteam/data/football_data.dart';
import 'package:statmyteam/data/stats_repository.dart';
import 'package:statmyteam/models/models.dart';
import 'package:statmyteam/state/stats_scope.dart';
import 'package:statmyteam/widgets/player_stats_loader.dart';

/// Stats source whose responses the test completes by hand.
class _ManualStatsSource implements PlayerStatsSource {
  final requests = <Player, Completer<Map<String, double>>>{};

  @override
  bool supports(Player player) => true;

  @override
  Future<Map<String, double>> seasonStats(Player player) =>
      (requests[player] = Completer()).future;
}

void main() {
  final player = footballPlayers.first.copyWith(seasonStats: const {});
  final other = footballPlayers[1].copyWith(seasonStats: const {});

  late _ManualStatsSource source;
  late StatsRepository repo;

  setUp(() {
    source = _ManualStatsSource();
    repo = StatsRepository(
      teams: footballTeams,
      players: [player, other],
      games: const [],
      playerStats: source,
    );
  });

  Widget host(List<Player> players) => MaterialApp(
        home: Scaffold(
          body: StatsScope(
            repository: repo,
            child: PlayerStatsLoader(
              players: players,
              builder: (context, loaded) => Text(
                [for (final p in loaded) '${p.id}:${p.stat('gp')}'].join(','),
              ),
            ),
          ),
        ),
      );

  testWidgets('shows loading, then the builder with fetched stats',
      (tester) async {
    await tester.pumpWidget(host([player]));
    expect(find.text('Loading season stats…'), findsOneWidget);

    source.requests[player]!.complete({'gp': 7});
    await tester.pump();
    expect(find.text('${player.id}:7.0'), findsOneWidget);
  });

  testWidgets('a failed fetch shows Retry, and Retry loads the stats',
      (tester) async {
    await tester.pumpWidget(host([player]));
    source.requests[player]!.completeError(StateError('offline'));
    await tester.pump();
    expect(find.text('Could not load season stats.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(find.text('Loading season stats…'), findsOneWidget);

    source.requests[player]!.complete({'gp': 3});
    await tester.pump();
    expect(find.text('${player.id}:3.0'), findsOneWidget);
  });

  testWidgets('cached stats build immediately with no loading row',
      (tester) async {
    final fetch = repo.withSeasonStats(player);
    source.requests[player]!.complete({'gp': 5});
    await fetch;

    await tester.pumpWidget(host([player]));
    expect(find.text('Loading season stats…'), findsNothing);
    expect(find.text('${player.id}:5.0'), findsOneWidget);
  });

  testWidgets('switching players mid-load shows the new player, not the old',
      (tester) async {
    await tester.pumpWidget(host([player]));
    await tester.pumpWidget(host([other]));

    // The stale request finishing must not replace the new player's view.
    source.requests[player]!.complete({'gp': 1});
    await tester.pump();
    expect(find.text('${player.id}:1.0'), findsNothing);
    expect(find.text('Loading season stats…'), findsOneWidget);

    source.requests[other]!.complete({'gp': 2});
    await tester.pump();
    expect(find.text('${other.id}:2.0'), findsOneWidget);
  });
}
