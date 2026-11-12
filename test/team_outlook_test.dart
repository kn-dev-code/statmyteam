import 'package:flutter_test/flutter_test.dart';
import 'package:statmyteam/data/stats_repository.dart';
import 'package:statmyteam/logic/sport_stats.dart';
import 'package:statmyteam/models/models.dart';

void main() {
  final repo = StatsRepository.sampleFootball();

  test('Austin grades as an offensive strength vs the NFL', () {
    final aus = repo.teamById('aus');
    final outlook = TeamOutlook.analyze(aus, repo.peersOf(aus));
    expect(outlook.strengths, isNotEmpty);
    expect(
      outlook.strengths.any((t) => t.def.key == 'ppg' || t.def.key == 'papg'),
      isTrue,
    );
    expect(outlook.summary.toLowerCase(), contains('austin'));
  });

  test('Orlando grades as a scoring weakness vs the NFL', () {
    final orl = repo.teamById('orl');
    final outlook = TeamOutlook.analyze(orl, repo.peersOf(orl));
    expect(outlook.weaknesses, isNotEmpty);
    expect(
      outlook.weaknesses.any((t) => t.def.key == 'ppg' || t.def.key == 'papg'),
      isTrue,
    );
  });

  test('Seattle Rainiers are an NBA scoring strength', () {
    final sea = repo.teamById('nba-sea');
    expect(sea.sport, Sport.basketball);
    final outlook = TeamOutlook.analyze(sea, repo.peersOf(sea));
    expect(outlook.strengths, isNotEmpty);
    expect(outlook.strengths.first.def.key, 'ppg');
    expect(outlook.strengths.first.rank, 1);
  });

  test('Portland Cascades are an MLS attacking strength', () {
    final pdx = repo.teamById('mls-pdx');
    expect(pdx.sport, Sport.soccer);
    final outlook = TeamOutlook.analyze(pdx, repo.peersOf(pdx));
    expect(outlook.strengths, isNotEmpty);
    expect(
      outlook.strengths.any((t) => t.def.key == 'ppg' || t.def.key == 'xg'),
      isTrue,
    );
  });

  test('peers stay inside the same sport and league', () {
    final sea = repo.teamById('nba-sea');
    final peers = repo.peersOf(sea);
    expect(peers, hasLength(6));
    expect(peers.every((t) => t.sport == Sport.basketball), isTrue);
    expect(peers.every((t) => t.league == League.nba), isTrue);
    expect(peers.map((t) => t.id), isNot(contains('por')));
  });
}
