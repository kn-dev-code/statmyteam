import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:statmyteam/data/favorites_store.dart';
import 'package:statmyteam/data/stats_repository.dart';
import 'package:statmyteam/models/models.dart';
import 'package:statmyteam/screens/team_select_screen.dart';
import 'package:statmyteam/state/favorites_scope.dart';
import 'package:statmyteam/state/stats_scope.dart';

const team = Team(
  id: 'hidden-test',
  name: 'Tigers',
  abbreviation: 'TIG',
  city: 'Test',
  sport: Sport.football,
  season: '2026',
  league: League.nfl,
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'hidden teams persist across store instances and can be restored',
    () async {
      final store = await FavoritesStore.open();

      await store.setHidden(team.id, true);

      expect(
        (await FavoritesStore.open()).isHidden(team.id),
        isTrue,
      );

      await store.setHidden(team.id, false);

      expect(
        (await FavoritesStore.open()).hiddenIds,
        isEmpty,
      );
    },
  );

  test(
    'hiding preserves favorite teams and favorite matchups',
    () async {
      final store = await FavoritesStore.open();

      await store.toggle(team.id);
      await store.toggleMatchup(team.id, 'other');
      await store.setHidden(team.id, true);

      expect(store.isFavorite(team.id), isTrue);
      expect(
        store.isFavoriteMatchup(team.id, 'other'),
        isTrue,
      );
    },
  );

  testWidgets(
    'hide removes row, show hidden allows restore, and clears pick',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1;

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final store = await FavoritesStore.open();
      final repo = StatsRepository(
        teams: [team],
        players: [],
        games: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FavoritesScope(
            store: store,
            child: StatsScope(
              repository: repo,
              child: const TeamSelectScreen(
                mode: TeamSelectMode.matchup,
              ),
            ),
          ),
        ),
      );

      final row = find.byKey(
        const ValueKey('team_row_hidden-test'),
      );

      final eye = find.byKey(
        const ValueKey('hide_team_hidden-test'),
      );

      final showHidden = find.byKey(
        const ValueKey('show_hidden_teams'),
      );

      await tester.tap(row);
      await tester.pumpAndSettle();

      expect(
        find.text('1 of 2 teams selected — choose Team B.'),
        findsOneWidget,
      );

      await tester.tap(eye);
      await tester.pumpAndSettle();

      expect(row, findsNothing);
      expect(
        find.text('0 of 2 teams selected — choose Team A.'),
        findsOneWidget,
      );
      expect(
        find.text('No visible teams'),
        findsOneWidget,
      );

      await tester.tap(showHidden);
      await tester.pumpAndSettle();

      expect(row, findsOneWidget);

      ListTile teamTile() => tester.widget<ListTile>(
            find.descendant(
              of: row,
              matching: find.byType(ListTile),
            ),
          );

      expect(teamTile().onTap, isNull);

      await tester.tap(eye);
      await tester.pumpAndSettle();

      expect(store.isHidden(team.id), isFalse);

      await tester.tap(showHidden);
      await tester.pumpAndSettle();

      expect(row, findsOneWidget);
      expect(teamTile().onTap, isNotNull);
    },
  );
}
