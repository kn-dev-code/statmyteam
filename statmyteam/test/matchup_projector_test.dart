import 'package:flutter_test/flutter_test.dart';
import 'package:statmyteam/data/stats_repository.dart';
import 'package:statmyteam/logic/football_stats.dart';
import 'package:statmyteam/logic/matchup_projector.dart';
import 'package:statmyteam/models/models.dart';

void main() {
  final repo = StatsRepository.sampleFootball();
  final aus = repo.teamById('aus');
  final orl = repo.teamById('orl');
  final por = repo.teamById('por');

  MatchupProjection project(
    Team a,
    Team b, {
    MatchupVenue venue = MatchupVenue.neutral,
  }) =>
      MatchupProjector.project(
        teamA: a,
        teamB: b,
        rosterA: repo.rosterFor(a.id),
        rosterB: repo.rosterFor(b.id),
        headToHead: repo.headToHead(a.id, b.id),
        venue: venue,
      );

  test('the stronger team is favored and chances sum to 1', () {
    final p = project(aus, orl);
    expect(p.teamAWinChance, greaterThan(0.75));
    expect(p.teamAWinChance + p.teamBWinChance, closeTo(1, 1e-9));
    expect(p.favorite, aus);
    expect(p.teamAScore, greaterThan(p.teamBScore));
    expect(p.spreadLabel, startsWith('AUS -'));
  });

  test('swapping sides mirrors the projection on a neutral field', () {
    final ab = project(aus, por);
    final ba = project(por, aus);
    expect(ab.teamAWinChance, closeTo(ba.teamBWinChance, 1e-9));
  });

  test('home field shifts the chance by the home edge each way', () {
    final neutral = project(por, aus).teamAWinChance;
    final home =
        project(por, aus, venue: MatchupVenue.teamAHome).teamAWinChance;
    final away =
        project(por, aus, venue: MatchupVenue.teamBHome).teamAWinChance;
    expect(home - neutral, closeTo(MatchupProjector.homeFieldEdge, 1e-9));
    expect(neutral - away, closeTo(MatchupProjector.homeFieldEdge, 1e-9));
  });

  test('a starting QB on IR is penalized; a healthy roster is not', () {
    final sacQbOut =
        MatchupProjector.availabilityPenalty(repo.rosterFor('sac'));
    final healthy = MatchupProjector.availabilityPenalty([
      for (final p in repo.rosterFor('sac'))
        p.copyWith(status: PlayerStatus.active),
    ]);
    expect(healthy, 0);
    expect(sacQbOut, greaterThanOrEqualTo(MatchupProjector.qbImpact));
  });

  test('head-to-head factor reports past meetings', () {
    final p = project(por, aus);
    final h2h = p.factors.firstWhere((f) => f.title == 'Head-to-head');
    expect(h2h.detail, contains('POR 0–2 AUS'));
    expect(h2h.favors, aus);
  });

  test('every team has a starter in every position group', () {
    for (final team in repo.teams) {
      for (final group in PositionGroup.values) {
        expect(
          repo.rosterInGroup(team.id, group).any((p) => p.isStarter),
          isTrue,
          reason: '${team.abbreviation} missing ${group.label}',
        );
      }
    }
  });

  test('every team belongs to a league, and both leagues have data', () {
    expect(repo.leagues, [League.nfl, League.ncaa]);
    for (final team in repo.teams) {
      expect(team.league, isNotNull, reason: team.abbreviation);
      expect(repo.rosterFor(team.id), hasLength(11),
          reason: '${team.abbreviation} roster');
    }
    expect(repo.teamsByConference(League.ncaa).keys,
        containsAll(['Pacific Ridge', 'Great Plains']));
    expect(Team.fromJson(repo.teamById('ptu').toJson()).league, League.ncaa);
  });

  test('player role and status survive JSON', () {
    final player = repo.rosterFor('sac').first;
    final decoded = Player.fromJson(player.toJson());
    expect(decoded.status, PlayerStatus.injuredReserve);
    expect(decoded.role, DepthRole.starter);
    expect(decoded.heightLabel, player.heightLabel);
  });
}
