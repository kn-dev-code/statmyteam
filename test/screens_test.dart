import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:statmyteam/data/favorites_store.dart';
import 'package:statmyteam/data/stats_repository.dart';
import 'package:statmyteam/main.dart';
import 'package:statmyteam/models/models.dart';
import 'package:statmyteam/screens/player_compare_screen.dart';
import 'package:statmyteam/screens/player_detail_screen.dart';
import 'package:statmyteam/screens/team_detail_screen.dart';

import 'stores_test.dart' show FlakyPrefs;

final _sample = StatsRepository.sampleFootball();

/// Sample data with some leagues marked as failed or incomplete.
StatsRepository _repoWith({
  Map<League, LoadFailure> errors = const {},
  Map<League, List<FeedGap>> warnings = const {},
  List<GameStats> extraGames = const [],
}) => StatsRepository(
  teams: _sample.teams,
  players: _sample.players,
  games: [..._sample.games, ...extraGames],
  liveLeagues: {League.ncaa, League.nba, League.mls},
  loadErrors: errors,
  loadWarnings: warnings,
);

Future<void> _pumpApp(
  WidgetTester tester, {
  StatsRepository? repo,
  FavoritesStore? favorites,
  bool showLogin = false,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    StatMyTeamApp(
      repository: repo ?? _sample,
      favorites: favorites ?? await FavoritesStore.open(),
      showLogin: showLogin,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _push(WidgetTester tester, Widget screen) async {
  tester
      .state<NavigatorState>(find.byType(Navigator).first)
      .push(MaterialPageRoute<void>(builder: (_) => screen));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('startup failure shows a short error and Retry recovers', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      BootstrapApp(
        loadRepository: () async {
          attempts++;
          if (attempts == 1) {
            throw StateError('secret detail https://example.invalid/boom');
          }
          return _sample;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not start StatMyTeam'), findsOneWidget);
    expect(find.textContaining('https://'), findsNothing);
    expect(find.textContaining('secret detail'), findsNothing);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Could not start StatMyTeam'), findsNothing);
    expect(find.text('Sign in (demo)'), findsOneWidget);
  });

  testWidgets('feed banner explains failures without technical detail', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      repo: _repoWith(
        errors: {
          League.nfl: const LoadFailure(
            LoadFailureKind.server,
            'ESPN request failed (500): https://site.api.espn.com/x',
          ),
        },
        warnings: {
          League.nba: const [FeedGap(FeedPart.rosters, 1, 30)],
        },
      ),
    );

    expect(
      find.text(
        'Live NFL feed unavailable — showing sample data. '
        'Some NBA data is missing.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.textContaining('Live NFL feed unavailable'));
    await tester.pumpAndSettle();

    expect(find.text('Live data problems'), findsOneWidget);
    expect(find.text('NFL: showing sample data'), findsOneWidget);
    expect(
      find.text('The live feed is having problems right now.'),
      findsOneWidget,
    );
    expect(find.text('NBA: live, incomplete'), findsOneWidget);
    expect(find.text('1 of 30 rosters did not load.'), findsOneWidget);
    expect(find.textContaining('https://'), findsNothing);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Live data problems'), findsNothing);
  });

  group('search', () {
    Future<void> openSearch(WidgetTester tester) async {
      await _pumpApp(tester);
      await tester.tap(find.byTooltip('Search teams and players'));
      await tester.pumpAndSettle();
    }

    testWidgets('prompts, finds players by name, and reports no matches', (
      tester,
    ) async {
      await openSearch(tester);
      expect(find.text('Type a team or player name'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'caleb   vance');
      await tester.pumpAndSettle();
      expect(find.text('Caleb Vance'), findsOneWidget);
      expect(find.text('Players'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.pumpAndSettle();
      expect(find.text('No matches for "zzzz"'), findsOneWidget);
    });

    testWidgets('finds teams and exact jersey numbers', (tester) async {
      await openSearch(tester);

      await tester.enterText(find.byType(TextField), 'lumberjacks');
      await tester.pumpAndSettle();
      expect(find.text('Teams'), findsOneWidget);
      expect(find.text('Portland Lumberjacks'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '#9');
      await tester.pumpAndSettle();
      expect(find.text('Caleb Vance'), findsOneWidget);
      expect(find.text('Theo Marsh'), findsNothing);
    });
  });

  testWidgets('upcoming games shows an empty state for the sample slate', (
    tester,
  ) async {
    await _pumpApp(tester);
    await tester.tap(find.text('Upcoming games'));
    await tester.pumpAndSettle();

    expect(
      find.text('Choose a scheduled game to compare both teams.'),
      findsOneWidget,
    );
    expect(find.textContaining('No upcoming'), findsOneWidget);
  });

  testWidgets('player detail shows position, bio, and season stats', (
    tester,
  ) async {
    await _pumpApp(tester);
    final vance = _sample.players.firstWhere((p) => p.lastName == 'Vance');
    await _push(tester, PlayerDetailScreen(player: vance));

    expect(find.text('Quarterback'), findsOneWidget);
    expect(find.text('Oregon State'), findsOneWidget);
    expect(find.text('5 yrs'), findsOneWidget);
    expect(find.text('Starter'), findsOneWidget);
    expect(find.text('Pass yards'), findsWidgets);
  });

  testWidgets('player compare cards are buttons that open the player', (
    tester,
  ) async {
    await _pumpApp(tester);
    await _push(
      tester,
      PlayerCompareScreen(
        teamA: _sample.teamById('por'),
        teamB: _sample.teamById('aus'),
      ),
    );

    expect(find.text('POSITION'), findsOneWidget);
    final card = find.bySemanticsLabel(RegExp(r'^Open '));
    expect(card, findsNWidgets(2));

    await tester.tap(card.first);
    await tester.pumpAndSettle();
    expect(find.byType(PlayerDetailScreen), findsOneWidget);
  });

  testWidgets('login validates email and password', (tester) async {
    await _pumpApp(tester, showLogin: true);

    await tester.tap(find.text('Sign in (demo)'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Password must be at least 6 characters'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'not-an-email');
    await tester.tap(find.text('Sign in (demo)'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email'), findsOneWidget);
  });

  testWidgets('a failed favorite save shows a message and keeps state', (
    tester,
  ) async {
    final favorites = FavoritesStore(FlakyPrefs());
    await _pumpApp(tester, favorites: favorites);
    await _push(tester, TeamDetailScreen(team: _sample.teamById('por')));

    await tester.tap(find.byTooltip('Add favorite'));
    await tester.pumpAndSettle();

    expect(find.text('Could not save your change. Try again.'), findsOneWidget);
    expect(favorites.isFavorite('por'), isFalse);
    expect(find.byTooltip('Add favorite'), findsOneWidget);
  });

  testWidgets('a result against an unknown team does not break the screen', (
    tester,
  ) async {
    final ghostGame = GameStats(
      id: 'ghost-game',
      sport: Sport.football,
      season: '2026',
      startTime: DateTime.utc(2030, 1, 1),
      homeTeamId: 'por',
      awayTeamId: 'not-a-team',
      home: const TeamBoxScore(teamId: 'por', score: 21),
      away: const TeamBoxScore(teamId: 'not-a-team', score: 14),
      status: GameStatus.completed,
    );
    await _pumpApp(tester, repo: _repoWith(extraGames: [ghostGame]));
    await _push(tester, TeamDetailScreen(team: _sample.teamById('por')));

    expect(tester.takeException(), isNull);
    expect(find.text('Recent results'), findsOneWidget);
  });
}
