import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:statmyteam/data/espn/espn_player_stats.dart';
import 'package:statmyteam/data/favorites_store.dart';
import 'package:statmyteam/data/settings_store.dart';
import 'package:statmyteam/data/stats_repository.dart';
import 'package:statmyteam/l10n/l10n.dart';
import 'package:statmyteam/logic/matchup_projector.dart';
import 'package:statmyteam/main.dart';
import 'package:statmyteam/models/models.dart';
import 'package:statmyteam/screens/upcoming_games_screen.dart';
import 'package:statmyteam/state/stats_scope.dart';
import 'package:statmyteam/theme/app_theme.dart';
import 'package:statmyteam/widgets/matchup_card.dart';
import 'package:statmyteam/widgets/stats_widgets.dart';

/// Preferences whose writes stay pending until the test finishes them.
class ManualPrefs implements SharedPreferences {
  final writes = <Completer<bool>>[];

  @override
  String? getString(String key) => null;

  @override
  Future<bool> setString(String key, String value) {
    final write = Completer<bool>();
    writes.add(write);
    return write.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// HTTP client that records whether it was closed.
class TrackingClient extends http.BaseClient {
  bool closed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      throw UnimplementedError();

  @override
  void close() => closed = true;
}

final _sample = StatsRepository.sampleFootball();

Widget _localized(Widget child, {StatsRepository? repo}) => MaterialApp(
  theme: AppTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: StatsScope(
    repository: repo ?? _sample,
    child: Scaffold(body: child),
  ),
);

GameStats _game({
  required String home,
  required String away,
  required int? homeScore,
  required int? awayScore,
  GameStatus status = GameStatus.completed,
  DateTime? start,
}) => GameStats(
  id: '$home-$away-${start ?? 0}',
  sport: Sport.football,
  season: '2026',
  startTime: start ?? DateTime.utc(2026, 10, 4),
  homeTeamId: home,
  awayTeamId: away,
  home: TeamBoxScore(teamId: home, score: homeScore),
  away: TeamBoxScore(teamId: away, score: awayScore),
  status: status,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('game results', () {
    final tie = _game(home: 'por', away: 'aus', homeScore: 17, awayScore: 17);

    test('a final with no winner is a tie for both sides', () {
      expect(GameResult.of(tie, 'por'), GameResult.tie);
      expect(GameResult.of(tie, 'aus'), GameResult.tie);
    });

    testWidgets('the result tile shows a tie as T, not as a loss', (
      tester,
    ) async {
      await tester.pumpWidget(
        _localized(
          GameResultTile(
            game: tie,
            teamId: 'por',
            opponent: _sample.teamById('aus'),
          ),
        ),
      );
      expect(find.text('T 17–17'), findsOneWidget);
      expect(find.textContaining('L '), findsNothing);
    });
  });

  group('SettingsStore', () {
    test('overlapping failed saves roll back to what is on disk', () async {
      final prefs = ManualPrefs();
      final settings = SettingsStore(prefs);

      final toDark = settings.setThemeMode(ThemeMode.dark);
      final toLight = settings.setThemeMode(ThemeMode.light);
      expect(settings.themeMode, ThemeMode.light);

      // The second save fails first, then the first one.
      prefs.writes[1].complete(false);
      await expectLater(toLight, throwsA(isA<PreferenceSaveException>()));
      prefs.writes[0].complete(false);
      await expectLater(toDark, throwsA(isA<PreferenceSaveException>()));

      // Nothing was saved, so the screen must match disk again.
      expect(settings.themeMode, ThemeMode.system);
    });
  });

  test('saved favorites keep the order the user added them', () async {
    final store = await FavoritesStore.open();
    await store.toggle('por');
    await store.toggle('aus');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('favorite_team_ids'), ['por', 'aus']);
  });

  test('AppPalette lerps colors and switches brightness halfway', () {
    const light = AppPalette.light;
    const dark = AppPalette.dark;
    expect(light.lerp(dark, 0).surface, light.surface);
    expect(light.lerp(dark, 1).surface, dark.surface);
    expect(light.lerp(dark, 0.4).brightness, Brightness.light);
    expect(light.lerp(dark, 0.6).brightness, Brightness.dark);
    expect(
      light.lerp(dark, 0.5).surface,
      Color.lerp(light.surface, dark.surface, 0.5),
    );
    expect(light.lerp(null, 0.5), same(light));
    expect(light.copyWith(accent: dark.accent).accent, dark.accent);
  });

  group('StatsRepository.close', () {
    StatsRepository repoWith(TrackingClient client, {required bool owns}) =>
        StatsRepository(
          teams: const [],
          players: const [],
          games: const [],
          playerStats: EspnPlayerStatsSource(
            client: client,
            ownsClient: owns,
            seasonYears: const {},
          ),
        );

    test('closes a client it created', () {
      final client = TrackingClient();
      repoWith(client, owns: true).close();
      expect(client.closed, isTrue);
    });

    test('leaves an injected client open', () {
      final client = TrackingClient();
      repoWith(client, owns: false).close();
      expect(client.closed, isFalse);
    });
  });

  testWidgets('projections are cached per repository', (tester) async {
    final other = StatsRepository.sampleFootball();
    final results = <MatchupProjection>[];
    Widget probe(StatsRepository repo) => _localized(
      Builder(
        builder: (context) {
          results.add(
            projectMatchup(context, repo.teamById('por'), repo.teamById('aus')),
          );
          return const SizedBox();
        },
      ),
      repo: repo,
    );

    await tester.pumpWidget(probe(_sample));
    await tester.pumpWidget(probe(_sample));
    await tester.pumpWidget(probe(other));

    expect(results[1], same(results[0]), reason: 'same repo, same result');
    expect(results[2], isNot(same(results[0])), reason: 'new repo, new cache');
  });

  testWidgets('upcoming games lists a scheduled game and opens it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = StatsRepository(
      teams: _sample.teams,
      players: _sample.players,
      games: [
        ..._sample.games,
        _game(
          home: 'por',
          away: 'aus',
          homeScore: null,
          awayScore: null,
          status: GameStatus.scheduled,
          start: DateTime.now().toUtc().add(const Duration(days: 3)),
        ),
      ],
    );
    await tester.pumpWidget(
      StatMyTeamApp(
        repository: repo,
        favorites: await FavoritesStore.open(),
        showLogin: false,
      ),
    );
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(
          MaterialPageRoute<void>(builder: (_) => const UpcomingGamesScreen()),
        );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Football'));
    await tester.pumpAndSettle();
    expect(find.text('AUS @ POR'), findsOneWidget);
    expect(find.textContaining('Stampede at Lumberjacks'), findsOneWidget);

    await tester.tap(find.text('AUS @ POR'));
    await tester.pumpAndSettle();
    expect(find.text('POR vs AUS'), findsOneWidget);
  });

  testWidgets('the Teams tab keeps its state when you come back', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      StatMyTeamApp(
        repository: _sample,
        favorites: await FavoritesStore.open(),
        showLogin: false,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Teams'));
    await tester.pumpAndSettle();
    final showHidden = find.byKey(const ValueKey('show_hidden_teams'));
    await tester.tap(showHidden);
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Home'));
    await tester.pumpAndSettle();
    expect(showHidden, findsNothing, reason: 'hidden tab is offstage');

    await tester.tap(find.bySemanticsLabel('Teams'));
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(showHidden).value, isTrue);
  });

  testWidgets('favorite tiles do not overflow at large text sizes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final favorites = await FavoritesStore.open();
    await favorites.toggle('por');
    await favorites.toggle('aus');
    await tester.pumpWidget(
      StatMyTeamApp(
        repository: _sample,
        favorites: favorites,
        showLogin: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FavoriteTeamTile), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  group('error handlers', () {
    late FlutterExceptionHandler? savedFlutterHandler;
    late ErrorCallback? savedPlatformHandler;
    late ErrorWidgetBuilder savedErrorWidget;

    setUp(() {
      savedFlutterHandler = FlutterError.onError;
      savedPlatformHandler = PlatformDispatcher.instance.onError;
      savedErrorWidget = ErrorWidget.builder;
    });

    tearDown(() {
      FlutterError.onError = savedFlutterHandler;
      PlatformDispatcher.instance.onError = savedPlatformHandler;
      ErrorWidget.builder = savedErrorWidget;
    });

    test('framework and async errors reach the reporter', () {
      final reported = <String>[];
      // Swallow the test framework's own handling for this synthetic error.
      FlutterError.onError = (_) {};
      installErrorHandlers(
        reporter: (error, stack, source) => reported.add('$source: $error'),
        releaseMode: true,
      );

      FlutterError.onError!(
        FlutterErrorDetails(exception: StateError('build broke')),
      );
      final handled = PlatformDispatcher.instance.onError!(
        StateError('async broke'),
        StackTrace.empty,
      );

      expect(reported, [
        'FlutterError: Bad state: build broke',
        'PlatformDispatcher: Bad state: async broke',
      ]);
      expect(handled, isTrue, reason: 'release builds mark errors handled');
      expect(
        ErrorWidget.builder(const FlutterErrorDetails(exception: 1)),
        isA<ErrorPlaceholder>(),
      );
    });

    test('debug builds let async errors surface', () {
      installErrorHandlers(reporter: (_, _, _) {}, releaseMode: false);
      expect(
        PlatformDispatcher.instance.onError!(StateError('x'), StackTrace.empty),
        isFalse,
      );
    });

    testWidgets('the placeholder falls back to English without l10n', (
      tester,
    ) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: ErrorPlaceholder(),
        ),
      );
      expect(find.text('Something went wrong'), findsOneWidget);
    });
  });
}
