import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:statmyteam/data/espn/espn_player_stats.dart';
import 'package:statmyteam/data/favorites_store.dart';
import 'package:statmyteam/data/stats_repository.dart';
import 'package:statmyteam/l10n/l10n.dart';
import 'package:statmyteam/logic/football_stats.dart';
import 'package:statmyteam/logic/matchup_projector.dart';
import 'package:statmyteam/main.dart';
import 'package:statmyteam/models/models.dart';
import 'package:statmyteam/screens/team_select_screen.dart';
import 'package:statmyteam/state/favorites_scope.dart';
import 'package:statmyteam/state/stats_scope.dart';
import 'package:statmyteam/widgets/stats_widgets.dart';

/// HTTP client that counts how often it is closed.
class CountingClient extends http.BaseClient {
  int closes = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      throw UnimplementedError();

  @override
  void close() => closes++;
}

final _sample = StatsRepository.sampleFootball();
final _en = lookupAppLocalizations(const Locale('en'));

/// Sample data whose repository owns [client], so close() is observable.
StatsRepository _repoOwning(CountingClient client) => StatsRepository(
  teams: _sample.teams,
  players: _sample.players,
  games: _sample.games,
  playerStats: EspnPlayerStatsSource(
    client: client,
    ownsClient: true,
    seasonYears: const {},
  ),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('sport-aware matchup factors', () {
    MatchupProjection project(String a, String b) => MatchupProjector.project(
      teamA: _sample.teamById(a),
      teamB: _sample.teamById(b),
    );

    Set<FactorKind> kinds(MatchupProjection p) => {
      for (final f in p.factors) f.kind,
    };

    String allText(MatchupProjection p) => [
      for (final f in p.factors) _en.factorDetail(f, p.teamA, p.teamB),
    ].join('\n');

    final nba = _sample.teams
        .where((t) => t.league == League.nba)
        .take(2)
        .toList();
    final mls = _sample.teams
        .where((t) => t.league == League.mls)
        .take(2)
        .toList();

    test('NBA matchups never show football yards', () {
      final p = project(nba[0].id, nba[1].id);
      expect(kinds(p), isNot(contains(FactorKind.offense)));
      expect(kinds(p), isNot(contains(FactorKind.defense)));
      expect(
        kinds(p),
        containsAll([FactorKind.shooting, FactorKind.rebounding]),
      );
      expect(allText(p), isNot(contains('yards')));
      expect(allText(p), contains('points per game'));
    });

    test('MLS matchups talk about goals and expected goals', () {
      final p = project(mls[0].id, mls[1].id);
      expect(kinds(p), isNot(contains(FactorKind.offense)));
      expect(kinds(p), isNot(contains(FactorKind.turnovers)));
      expect(kinds(p), contains(FactorKind.chanceCreation));
      final text = allText(p);
      expect(text, isNot(contains('yards')));
      expect(text, contains('goals per game'));
      expect(text, isNot(contains('points per game')));
    });

    test('football keeps its yards and turnover factors', () {
      final p = project('por', 'aus');
      expect(
        kinds(p),
        containsAll([
          FactorKind.offense,
          FactorKind.defense,
          FactorKind.turnovers,
        ]),
      );
    });

    test('each sport uses its own home edge and margin scale', () {
      double homeEdge(String a, String b) {
        double chance(MatchupVenue v) => MatchupProjector.project(
          teamA: _sample.teamById(a),
          teamB: _sample.teamById(b),
          venue: v,
        ).teamAWinChance;
        return chance(MatchupVenue.teamAHome) - chance(MatchupVenue.neutral);
      }

      expect(
        homeEdge(nba[0].id, nba[1].id),
        closeTo(SportModel.basketball.homeFieldEdge, 1e-9),
      );
      expect(
        homeEdge(mls[0].id, mls[1].id),
        closeTo(SportModel.soccer.homeFieldEdge, 1e-9),
      );
      final soccer = project(mls[0].id, mls[1].id);
      expect(
        (soccer.teamAScore - soccer.teamBScore).abs(),
        lessThanOrEqualTo(SportModel.soccer.maxMargin),
      );
      final venue = soccer.factors.firstWhere(
        (f) => f.kind == FactorKind.venue,
      );
      expect(
        _en.factorDetail(venue, soccer.teamA, soccer.teamB),
        contains('worth about 5%'),
      );
    });
  });

  test('a final with a missing score is unknown, not a tie', () {
    final game = GameStats(
      id: 'g',
      sport: Sport.football,
      season: '2026',
      startTime: DateTime.utc(2026, 9, 1),
      homeTeamId: 'por',
      awayTeamId: 'aus',
      home: const TeamBoxScore(teamId: 'por', score: 20),
      away: const TeamBoxScore(teamId: 'aus', score: null),
      status: GameStatus.completed,
    );
    expect(GameResult.of(game, 'por'), GameResult.unknown);
    expect(_en.formResult(GameResult.unknown.name), '–');
    expect(_en.formResultSemantics(GameResult.unknown.name), 'No result');
  });

  test('unlisted football positions land in special teams everywhere', () {
    final por = _sample.teamById('por');
    const athlete = Player(
      id: 'por-ath',
      firstName: 'Ari',
      lastName: 'Utility',
      teamId: 'por',
      position: 'ATH',
      jerseyNumber: 1,
      sport: Sport.football,
    );
    final repo = StatsRepository(
      teams: _sample.teams,
      players: [..._sample.players, athlete],
      games: const [],
    );

    final sections = repo.rosterSections(por);
    final special = sections.singleWhere(
      (s) => s.group == PositionGroup.specialTeams,
    );
    expect(special.players, contains(athlete));
    expect(
      repo.rosterInGroup('por', PositionGroup.specialTeams),
      contains(athlete),
    );
    final listed = [for (final s in sections) ...s.players];
    expect(listed, hasLength(repo.rosterFor('por').length));
  });

  test('signed numbers take their sign from the rounded value', () {
    expect(_en.decimal(0.04, 1, signed: true), '0.0');
    expect(_en.decimal(-0.04, 1), '0.0');
    expect(_en.decimal(0.06, 1, signed: true), '+0.1');
    expect(_en.decimal(-2.5, 1, signed: true), '-2.5');
  });

  testWidgets('the slot remove button responds at its corner', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: FavoritesScope(
          store: await FavoritesStore.open(),
          child: StatsScope(
            repository: _sample,
            child: TeamSelectScreen(
              mode: TeamSelectMode.matchup,
              preselected: _sample.teamById('por'),
              sport: Sport.football,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final remove = find.byTooltip('Remove Lumberjacks');
    expect(remove, findsOneWidget);
    // Tap near the outer corner, the part that used to hang outside the
    // slot and ignore taps.
    final rect = tester.getRect(remove);
    await tester.tapAt(rect.topRight + const Offset(-6, 6));
    await tester.pumpAndSettle();

    expect(remove, findsNothing);
    expect(
      find.text('0 of 2 teams selected — choose Team A.'),
      findsOneWidget,
    );
  });

  testWidgets('the main menu fits a narrow phone at large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      StatMyTeamApp(
        repository: _sample,
        favorites: await FavoritesStore.open(),
        showLogin: false,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.bySemanticsLabel('Settings'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  group('bootstrap resources', () {
    // The loading screen spins forever, so pump frames instead of settling.
    Future<void> pumpFrames(WidgetTester tester) async {
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    testWidgets('dispose closes the repository exactly once', (tester) async {
      final client = CountingClient();
      await tester.pumpWidget(
        BootstrapApp(loadRepository: () async => _repoOwning(client)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sign in (demo)'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      expect(client.closes, 1);
    });

    testWidgets(
      'a store failure shows at once, and a stale slow repo is closed',
      (tester) async {
        final slow = Completer<StatsRepository>();
        final first = CountingClient();
        final second = CountingClient();
        var favoritesCalls = 0;
        var repoCalls = 0;

        await tester.pumpWidget(
          BootstrapApp(
            openFavorites: () async {
              if (++favoritesCalls == 1) throw Exception('storage offline');
              return FavoritesStore.open();
            },
            loadRepository: () {
              repoCalls++;
              return repoCalls == 1
                  ? slow.future
                  : Future.value(_repoOwning(second));
            },
          ),
        );
        await pumpFrames(tester);

        // eagerError: no waiting for the slow league load.
        expect(find.text('Could not start StatMyTeam'), findsOneWidget);
        expect(slow.isCompleted, isFalse);

        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();
        expect(find.text('Sign in (demo)'), findsOneWidget);

        // The abandoned attempt's repository arrives late: close it, and
        // leave the one the app is using alone.
        slow.complete(_repoOwning(first));
        await tester.pump();
        expect(first.closes, 1);
        expect(second.closes, 0);

        await tester.pumpWidget(const SizedBox());
        expect(second.closes, 1);
        expect(first.closes, 1, reason: 'no double close');
      },
    );

    testWidgets('a loader that throws synchronously shows the error', (
      tester,
    ) async {
      await tester.pumpWidget(
        BootstrapApp(loadRepository: () => throw StateError('sync boom')),
      );
      await pumpFrames(tester);
      expect(find.text('Could not start StatMyTeam'), findsOneWidget);
    });
  });
}
