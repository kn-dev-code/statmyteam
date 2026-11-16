import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:statmyteam/data/espn/espn_leagues.dart';
import 'package:statmyteam/data/stats_repository.dart';
import 'package:statmyteam/models/models.dart';

/// Offline tests for the ESPN live-data pipeline, against canned payloads
/// shaped like ESPN's site / core APIs.
void main() {
  const site = '/apis/site/v2/sports/basketball/nba';
  const core = '/v2/sports/basketball/leagues/nba';

  Map<String, dynamic> team(String id, String city, String name, String abbr) =>
      {'id': id, 'location': city, 'name': name, 'abbreviation': abbr};

  Map<String, dynamic> stat(String name, num value, [String? type]) =>
      {'name': name, 'type': type ?? name.toLowerCase(), 'value': value};

  Map<String, dynamic> stats(Map<String, Map<String, num>> categories) => {
        'splits': {
          'categories': [
            for (final MapEntry(key: category, value: values)
                in categories.entries)
              {
                'name': category,
                'stats': [
                  for (final MapEntry(:key, :value) in values.entries)
                    {'name': key, 'value': value},
                ],
              },
          ],
        },
      };

  final nbaRoutes = <String, Object>{
    '$site/scoreboard': {
      'season': {'year': 2027},
      'events': <Object>[],
    },
    '/apis/v2/sports/basketball/nba/standings': {
      'children': [
        {
          'name': 'Eastern Conference',
          'abbreviation': 'East',
          'standings': {
            'entries': [
              {
                'team': team('1', 'Atlanta', 'Hawks', 'ATL'),
                'stats': [
                  stat('wins', 8),
                  stat('losses', 4),
                  stat('avgPointsFor', 115.5),
                  stat('avgPointsAgainst', 110),
                  // Split records reuse stat names; must not override totals.
                  stat('wins', 5, 'homerecord_wins'),
                ],
              },
            ],
          },
        },
        {
          'name': 'Western Conference',
          'abbreviation': 'West',
          'standings': {
            'entries': [
              {
                'team': team('13', 'Los Angeles', 'Lakers', 'LAL'),
                'stats': [
                  stat('wins', 7),
                  stat('losses', 6),
                  stat('avgPointsFor', 118.25),
                  stat('avgPointsAgainst', 116),
                ],
              },
            ],
          },
        },
      ],
    },
    '$site/teams': {
      'sports': [
        {
          'leagues': [
            {
              'teams': [
                {
                  'team': {
                    'id': '1',
                    'color': 'c8102e',
                    'alternateColor': 'fdb927',
                  },
                },
              ],
            },
          ],
        },
      ],
    },
    '$core/seasons/2027/types/2/teams/1/statistics': stats({
      'offensive': {'avgPoints': 115.5, 'fieldGoalPct': 47.5},
      'general': {'avgRebounds': 44},
    }),
    '$site/teams/1/roster': {
      'athletes': [
        {
          'id': '100',
          'firstName': 'Avery',
          'lastName': 'Guard',
          'jersey': '11',
          'position': {'abbreviation': 'G'},
          'experience': {'years': 8},
          'injuries': <Object>[],
        },
        {
          'id': '101',
          'firstName': 'Blake',
          'lastName': 'Forward',
          'jersey': '5',
          'position': {'abbreviation': 'F-C'},
          'injuries': [
            {'status': 'Out', 'detail': 'Ankle'},
          ],
        },
      ],
    },
    '$site/teams/13/roster': {
      'athletes': [
        {
          'id': '200',
          'firstName': 'Casey',
          'lastName': 'Center',
          'jersey': '3',
          'position': {'abbreviation': 'C'},
        },
      ],
    },
    '$site/teams/1/schedule': {
      'events': [
        {
          'id': '900',
          'date': '2026-11-01T00:00Z',
          'competitions': [
            {
              'status': {
                'type': {
                  'name': 'STATUS_FINAL',
                  'state': 'post',
                  'completed': true,
                },
              },
              'competitors': [
                {
                  'homeAway': 'home',
                  'team': team('1', 'Atlanta', 'Hawks', 'ATL'),
                  'score': {'value': 120},
                },
                {
                  'homeAway': 'away',
                  'team': team('99', 'Exhibition', 'Select', 'EXH'),
                  'score': {'value': 100},
                },
              ],
            },
          ],
        },
      ],
    },
    '$core/seasons/2027/types/2/athletes/100/statistics': stats({
      'general': {'gamesPlayed': 10},
      'offensive': {'avgPoints': 25, 'fieldGoalPct': 44},
    }),
  };

  late List<String> requested;

  http.Client fakeEspn() => MockClient((request) async {
        final path = request.url.path;
        requested.add(path);
        // The NFL feed is "down" to exercise the per-league fallback.
        if (path.contains('/football/nfl/')) {
          return http.Response('upstream error', 500);
        }
        final body = nbaRoutes[path];
        return body == null
            ? http.Response('not found', 404)
            : http.Response(jsonEncode(body), 200);
      });

  late StatsRepository repo;

  setUp(() async {
    requested = [];
    repo = await StatsRepository.live(
      client: fakeEspn(),
      leagues: const [EspnLeague.nfl, EspnLeague.nba],
    );
  });

  test('a failed league falls back to sample data without hiding the error',
      () {
    expect(repo.liveLeagues, {League.nba});
    expect(repo.loadErrors.keys, [League.nfl]);
    expect(repo.loadErrors[League.nfl], contains('500'));
    expect(repo.sampleLeagues, [League.nfl]);
    expect(repo.teams.where((t) => t.league == League.nfl), isNotEmpty);
  });

  test('teams take records, conference, colors, and stats from ESPN', () {
    final hawks = repo.teamById('nba-1');
    expect(hawks.displayName, 'Atlanta Hawks');
    expect(hawks.conference, 'East');
    expect(hawks.record, '8-4');
    expect(hawks.primaryColor, 0xFFC8102E);
    expect(hawks.stat('ppg'), 115.5);
    expect(hawks.stat('papg'), 110);
    expect(hawks.stat('fgPct'), closeTo(0.475, 1e-9));
    expect(hawks.stat('rpg'), 44);
  });

  test('a team whose stats request fails still loads from standings', () {
    final lakers = repo.teamById('nba-13');
    expect(lakers.record, '7-6');
    expect(lakers.stat('ppg'), 118.25);
    expect(lakers.seasonStats.containsKey('fgPct'), isFalse);
    expect(repo.rosterFor('nba-13').single.position, 'C');
  });

  test('rosters normalize positions and carry injuries', () {
    final roster = {for (final p in repo.rosterFor('nba-1')) p.id: p};
    final guard = roster['nba-p-100']!;
    expect(guard.position, 'G');
    expect(guard.yearsPro, 8);
    expect(guard.isStarter, isTrue);
    expect(guard.seasonStats, isEmpty, reason: 'stats load on demand');

    final forward = roster['nba-p-101']!;
    expect(forward.position, 'F');
    expect(forward.status, PlayerStatus.out);
    expect(forward.injuryNote, 'Ankle');
  });

  test('results against non-league opponents stay labelled', () {
    final game = repo.recentGames('nba-1').single;
    expect(game.id, 'nba-g-900');
    expect(game.home.score, 120);
    expect(repo.findTeamById(game.awayTeamId)?.displayName, 'Exhibition Select');
    expect(repo.teams.any((t) => t.id == game.awayTeamId), isFalse);
  });

  test('player stats load on demand, map to app keys, and are cached',
      () async {
    final guard =
        repo.rosterFor('nba-1').firstWhere((p) => p.id == 'nba-p-100');
    expect(repo.loadedSeasonStats(guard), isNull);

    final loaded = await repo.withSeasonStats(guard);
    expect(loaded.stat('gp'), 10);
    expect(loaded.stat('pts'), 25);
    expect(loaded.stat('fgPct'), closeTo(0.44, 1e-9));

    final before = requested.length;
    expect((await repo.withSeasonStats(guard)).stat('pts'), 25);
    expect(repo.loadedSeasonStats(guard)?.stat('pts'), 25);
    expect(requested.length, before, reason: 'second lookup is cached');
  });

  test('a player with no stats this season gets an empty map, not an error',
      () async {
    final forward =
        repo.rosterFor('nba-1').firstWhere((p) => p.id == 'nba-p-101');
    final loaded = await repo.withSeasonStats(forward);
    expect(loaded.seasonStats, isEmpty);
  });

  test('sample players need no fetch', () {
    final sample = repo.players.firstWhere((p) => p.sport == Sport.football);
    expect(repo.loadedSeasonStats(sample), same(sample));
  });

  test('soccer club names are not doubled with their city', () {
    const club = Team(
      id: 'mls-1',
      name: 'Atlanta United FC',
      abbreviation: 'ATL',
      city: 'Atlanta',
      sport: Sport.soccer,
      season: '2026',
    );
    expect(club.displayName, 'Atlanta United FC');
  });

  test('League.describe reads as prose', () {
    expect(League.describe([League.nba]), 'NBA');
    expect(League.describe([League.mls, League.nfl]), 'NFL and MLS');
    expect(
      League.describe([League.nfl, League.ncaa, League.mls]),
      'NFL, NCAA, and MLS',
    );
  });
}
