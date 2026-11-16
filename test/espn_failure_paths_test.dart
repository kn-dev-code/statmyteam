import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:statmyteam/data/espn/espn_http.dart';
import 'package:statmyteam/data/espn/espn_league_api.dart';
import 'package:statmyteam/data/espn/espn_leagues.dart';
import 'package:statmyteam/data/espn/espn_player_stats.dart';
import 'package:statmyteam/data/stats_repository.dart';
import 'package:statmyteam/models/models.dart';

/// Offline tests for how the ESPN pipeline fails: retries, hard failures
/// that drop a league to sample data, partial failures that are surfaced as
/// warnings, and bugs that must not be masked.
void main() {
  const site = '/apis/site/v2/sports/basketball/nba';
  const core = '/v2/sports/basketball/leagues/nba';
  const standingsPath = '/apis/v2/sports/basketball/nba/standings';

  /// A tiny NBA feed with [teamCount] teams, each with a one-player roster.
  Map<String, Object> nbaFeed({
    int teamCount = 4,
    bool scoreboardSeason = true,
    bool standingsSeason = false,
  }) {
    final ids = [for (var i = 1; i <= teamCount; i++) '$i'];
    return {
      '$site/scoreboard': {
        if (scoreboardSeason) 'season': {'year': 2027},
        'events': <Object>[],
      },
      standingsPath: {
        'children': [
          {
            'name': 'Eastern Conference',
            'abbreviation': 'East',
            'standings': {
              if (standingsSeason) 'season': 2027,
              'entries': [
                for (final id in ids)
                  {
                    'team': {
                      'id': id,
                      'location': 'City $id',
                      'name': 'Team $id',
                      'abbreviation': 'T$id',
                    },
                    'stats': [
                      {'name': 'wins', 'type': 'wins', 'value': 1},
                      {'name': 'losses', 'type': 'losses', 'value': 1},
                    ],
                  },
              ],
            },
          },
        ],
      },
      for (final id in ids)
        '$site/teams/$id/roster': {
          'athletes': [
            {
              'id': '${id}00',
              'firstName': 'Player',
              'lastName': id,
              'position': {'abbreviation': 'G'},
            },
          ],
        },
    };
  }

  http.Client serve(
    Map<String, Object> routes, {
    Set<String> failing = const {},
    List<String>? log,
  }) =>
      MockClient((request) async {
        final path = request.url.path;
        log?.add(path);
        if (failing.contains(path)) return http.Response('boom', 500);
        final body = routes[path];
        return body == null
            ? http.Response('not found', 404)
            : http.Response(jsonEncode(body), 200);
      });

  EspnLeagueApi api(http.Client client) => EspnLeagueApi(
        EspnLeague.nba,
        client: client,
        retryDelay: Duration.zero,
      );

  group('EspnHttp', () {
    test('a non-2xx status throws with the status code', () async {
      final http_ = EspnHttp(
        MockClient((_) async => http.Response('gone', 404)),
        retryDelay: Duration.zero,
      );
      await expectLater(
        http_.getJson('https://example.test/x'),
        throwsA(isA<EspnRequestException>()
            .having((e) => e.statusCode, 'statusCode', 404)),
      );
    });

    test('a JSON body that is not an object throws', () async {
      final http_ = EspnHttp(
        MockClient((_) async => http.Response('[1, 2]', 200)),
        retryDelay: Duration.zero,
      );
      await expectLater(
        http_.getJson('https://example.test/x'),
        throwsA(isA<EspnRequestException>()),
      );
    });

    test('a transient 503 is retried once', () async {
      var calls = 0;
      final http_ = EspnHttp(
        MockClient((_) async => ++calls == 1
            ? http.Response('busy', 503)
            : http.Response('{"ok": true}', 200)),
        retryDelay: Duration.zero,
      );
      expect(await http_.getJson('https://example.test/x'), {'ok': true});
      expect(calls, 2);
    });

    test('a 404 is not retried', () async {
      var calls = 0;
      final http_ = EspnHttp(
        MockClient((_) async {
          calls++;
          return http.Response('gone', 404);
        }),
        retryDelay: Duration.zero,
      );
      await expectLater(
        http_.getJson('https://example.test/x'),
        throwsA(isA<EspnRequestException>()),
      );
      expect(calls, 1);
    });
  });

  group('fetchLeague', () {
    test('empty standings throw instead of returning an empty league',
        () async {
      final routes = nbaFeed()..[standingsPath] = {'children': <Object>[]};
      await expectLater(
        api(serve(routes)).fetchLeague(),
        throwsA(isA<EspnDataException>()),
      );
    });

    test('the season comes from standings when the scoreboard fails',
        () async {
      final data = await api(serve(
        nbaFeed(standingsSeason: true),
        failing: {'$site/scoreboard'},
      )).fetchLeague();
      expect(data.seasonYear, 2027);
    });

    test('an unknown season throws rather than guessing from the calendar',
        () async {
      await expectLater(
        api(serve(nbaFeed(scoreboardSeason: false))).fetchLeague(),
        throwsA(isA<EspnDataException>()),
      );
    });

    test('a few failed rosters load the league with warnings', () async {
      final data = await api(serve(
        nbaFeed(),
        failing: {'$site/teams/2/roster'},
      )).fetchLeague();
      expect(data.teams, hasLength(4));
      expect(data.players, hasLength(3));
      expect(data.warnings, contains('1 of 4 rosters'));
    });

    test('most rosters failing throws', () async {
      await expectLater(
        api(serve(nbaFeed(), failing: {
          for (final id in ['1', '2', '3']) '$site/teams/$id/roster',
        })).fetchLeague(),
        throwsA(isA<EspnDataException>()),
      );
    });

    test('a malformed optional team list does not fail the league', () async {
      final routes = nbaFeed()
        ..['$site/teams'] = {
          'sports': [
            {'leagues': 'not a list'},
          ],
        };
      final data = await api(serve(routes)).fetchLeague();
      expect(data.teams, hasLength(4));
    });
  });

  group('StatsRepository.live', () {
    test('partial failures are surfaced as load warnings', () async {
      final repo = await StatsRepository.live(
        client: serve(nbaFeed(), failing: {'$site/teams/2/roster'}),
        leagues: const [EspnLeague.nba],
        retryDelay: Duration.zero,
      );
      expect(repo.liveLeagues, {League.nba});
      expect(repo.loadErrors, isEmpty);
      expect(repo.loadWarnings[League.nba], contains('1 of 4 rosters'));
    });

    test('a league slower than the deadline falls back with an error',
        () async {
      final never = Completer<http.Response>();
      final repo = await StatsRepository.live(
        client: MockClient((_) => never.future),
        leagues: const [EspnLeague.nba],
        leagueTimeout: const Duration(milliseconds: 50),
        retryDelay: Duration.zero,
      );
      expect(repo.liveLeagues, isEmpty);
      expect(repo.loadErrors[League.nba], contains('longer than'));
    });

    test('a parser bug is rethrown, not masked as sample data', () async {
      final routes = nbaFeed()
        ..[standingsPath] = {
          'children': [
            {
              'name': 'East',
              'standings': {'entries': 'not a list'},
            },
          ],
        };
      await expectLater(
        StatsRepository.live(
          client: serve(routes),
          leagues: const [EspnLeague.nba],
          retryDelay: Duration.zero,
        ),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('withSeasonStats', () {
    const athletePath = '$core/seasons/2027/types/2/athletes/100/statistics';

    Future<(StatsRepository, Player)> repoWith(
      Future<http.Response> Function(int call) onAthlete, {
      DateTime Function()? clock,
    }) async {
      var calls = 0;
      final routes = nbaFeed(teamCount: 1);
      final client = MockClient((request) async {
        if (request.url.path == athletePath) return onAthlete(++calls);
        final body = routes[request.url.path];
        return body == null
            ? http.Response('not found', 404)
            : http.Response(jsonEncode(body), 200);
      });
      final live = await StatsRepository.live(
        client: client,
        leagues: const [EspnLeague.nba],
        retryDelay: Duration.zero,
      );
      // Rebuild with an injectable clock, keeping the live stats source.
      final repo = clock == null
          ? live
          : StatsRepository(
              teams: live.teams,
              players: live.players,
              games: live.games,
              liveLeagues: live.liveLeagues,
              playerStats: EspnPlayerStatsSource(
                client: client,
                seasonYears: const {League.nba: 2027},
                retryDelay: Duration.zero,
              ),
              clock: clock,
            );
      return (repo, repo.players.single);
    }

    test('a server error is thrown and not cached, so a retry refetches',
        () async {
      final (repo, player) = await repoWith((call) async => call <= 2
          // First attempt and its automatic retry both fail.
          ? http.Response('boom', 500)
          : http.Response(
              jsonEncode({
                'splits': {
                  'categories': [
                    {
                      'name': 'general',
                      'stats': [
                        {'name': 'gamesPlayed', 'value': 9},
                      ],
                    },
                  ],
                },
              }),
              200,
            ));
      await expectLater(
        repo.withSeasonStats(player),
        throwsA(isA<EspnRequestException>()),
      );
      expect(repo.loadedSeasonStats(player), isNull);
      expect((await repo.withSeasonStats(player)).stat('gp'), 9);
    });

    test('concurrent requests for one player share a single fetch', () async {
      var athleteCalls = 0;
      final (repo, player) = await repoWith((call) async {
        athleteCalls = call;
        return http.Response('not found', 404);
      });
      await Future.wait([
        repo.withSeasonStats(player),
        repo.withSeasonStats(player),
      ]);
      expect(athleteCalls, 1);
    });

    test('an empty result is refetched once it is stale', () async {
      var now = DateTime(2026, 11, 16, 12);
      var athleteCalls = 0;
      final (repo, player) = await repoWith(
        (call) async {
          athleteCalls = call;
          return http.Response('not found', 404);
        },
        clock: () => now,
      );
      await repo.withSeasonStats(player);
      expect(repo.loadedSeasonStats(player)?.seasonStats, isEmpty);

      now = now.add(StatsRepository.emptyStatsTtl);
      expect(repo.loadedSeasonStats(player), isNull);
      await repo.withSeasonStats(player);
      expect(athleteCalls, 2);
    });
  });
}
