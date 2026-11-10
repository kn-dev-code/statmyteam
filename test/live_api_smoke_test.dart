import 'package:flutter_test/flutter_test.dart';
import 'package:statmyteam/data/stats_repository.dart';

void main() {
  test('liveFootball loads NFL teams and players from ESPN', () async {
    final repo = await StatsRepository.liveFootball();
    expect(repo.isLive, isTrue, reason: repo.loadError);
    final nfl = repo.teams.where((t) => t.league?.name == 'nfl').toList();
    expect(nfl.length, greaterThanOrEqualTo(30));
    expect(repo.players.where((p) => p.teamId.startsWith('nfl-')).length,
        greaterThan(500));
    expect(repo.games.where((g) => g.id.startsWith('nfl-')).isNotEmpty, isTrue);
    final team = nfl.first;
    expect(team.record.contains('-'), isTrue);
    expect(repo.rosterFor(team.id), isNotEmpty);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
