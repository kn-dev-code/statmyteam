import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:statmyteam/data/favorites_store.dart';
import 'package:statmyteam/data/stats_repository.dart';
import 'package:statmyteam/main.dart';
import 'package:statmyteam/widgets/stats_widgets.dart';

Future<Widget> _app() async {
  SharedPreferences.setMockInitialValues({});
  final favorites = await FavoritesStore.open();
  return StatMyTeamApp(
    repository: StatsRepository.sampleFootball(),
    favorites: favorites,
    showLogin: false,
  );
}

void _tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('main menu offers head-to-head and team stats', (
    tester,
  ) async {
    await tester.pumpWidget(await _app());

    expect(find.text('StatMyTeam'), findsWidgets);
    expect(find.text('Head-to-Head'), findsOneWidget);
    expect(find.text('Team Stats'), findsOneWidget);
    expect(find.textContaining('Bet'), findsNothing);
  });

  testWidgets('login shows email/password and SSO buttons', (tester) async {
    _tallView(tester);
    SharedPreferences.setMockInitialValues({});
    final favorites = await FavoritesStore.open();
    await tester.pumpWidget(
      StatMyTeamApp(
        repository: StatsRepository.sampleFootball(),
        favorites: favorites,
      ),
    );

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.text('Continue as guest'), findsOneWidget);

    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();
    expect(find.text('Head-to-Head'), findsOneWidget);
  });

  testWidgets('pick two teams, see the projection, then compare players', (
    tester,
  ) async {
    _tallView(tester);
    await tester.pumpWidget(await _app());

    await tester.tap(find.text('Head-to-Head'));
    await tester.pumpAndSettle();

    final compare = find.widgetWithText(FilledButton, 'Compare teams');
    expect(tester.widget<FilledButton>(compare).onPressed, isNull);

    await tester.tap(find.text('Portland Lumberjacks'));
    await tester.tap(find.text('Austin Stampede'));
    await tester.pump();
    expect(tester.widget<FilledButton>(compare).onPressed, isNotNull);

    await tester.tap(compare);
    await tester.pumpAndSettle();
    expect(find.text('POR vs AUS'), findsOneWidget);
    expect(find.text('WIN PROBABILITY'), findsOneWidget);
    expect(find.text('What drives the projection'), findsOneWidget);
    expect(find.text('Points / game'), findsOneWidget);

    double chance() =>
        tester.widget<WinProbabilityBar>(find.byType(WinProbabilityBar))
            .teamAChance;
    final portlandHome = chance();
    await tester.tap(find.text('@ AUS'));
    await tester.pumpAndSettle();
    expect(chance(), lessThan(portlandHome));

    await tester.tap(find.text('Compare players'));
    await tester.pumpAndSettle();
    // Starting QBs are lined up by default.
    expect(find.text('Caleb Vance'), findsOneWidget);
    expect(find.text('Jace Whitaker'), findsOneWidget);
    expect(find.text('Passer rating'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'K'));
    await tester.pumpAndSettle();
    expect(find.text('Henrik Solberg'), findsOneWidget);
    expect(find.text('Paulo Santos'), findsOneWidget);
    expect(find.text('Field goal %'), findsOneWidget);
  });

  testWidgets('team stats shows roster with role and availability', (
    tester,
  ) async {
    _tallView(tester);
    await tester.pumpWidget(await _app());

    await tester.tap(find.text('Team Stats'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sacramento Prospectors'));
    await tester.pumpAndSettle();

    expect(find.text('Season stats'), findsOneWidget);
    expect(find.text('Injury report'), findsOneWidget);
    expect(find.text('IR'), findsWidgets);

    await tester.tap(find.text('Ryan Castellano').first);
    await tester.pumpAndSettle();
    expect(find.text('Injured reserve'), findsOneWidget);
    expect(find.text('Starter'), findsOneWidget);
    expect(find.text('Quarterback'), findsOneWidget);
  });

  testWidgets('teams are sorted into NFL and NCAA tabs', (tester) async {
    _tallView(tester);
    await tester.pumpWidget(await _app());

    await tester.tap(find.text('Team Stats'));
    await tester.pumpAndSettle();
    expect(find.text('Portland Lumberjacks'), findsOneWidget);
    expect(find.text('Prairie Tech Bison'), findsNothing);

    await tester.tap(find.text('NCAA'));
    await tester.pumpAndSettle();
    expect(find.text('Prairie Tech Bison'), findsOneWidget);
    expect(find.text('Great Plains Conference'), findsOneWidget);
    expect(find.text('Portland Lumberjacks'), findsNothing);

    await tester.tap(find.text('Prairie Tech Bison'));
    await tester.pumpAndSettle();
    expect(find.textContaining('NCAA · Great Plains Conference'), findsOneWidget);

    await tester.tap(find.text('Bo Calder').first);
    await tester.pumpAndSettle();
    expect(find.text('Class'), findsOneWidget);
    expect(find.text('RS Junior'), findsOneWidget);
  });

  testWidgets('switching league clears head-to-head picks', (tester) async {
    _tallView(tester);
    await tester.pumpWidget(await _app());

    await tester.tap(find.text('Head-to-Head'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Portland Lumberjacks'));
    await tester.pump();
    expect(find.text('Lumberjacks'), findsOneWidget); // slot A filled

    await tester.tap(find.text('NCAA'));
    await tester.pumpAndSettle();
    expect(find.text('Team A'), findsOneWidget); // slot A empty again

    await tester.tap(find.text('Cascade State Timberwolves'));
    await tester.tap(find.text('Prairie Tech Bison'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Compare teams'));
    await tester.pumpAndSettle();
    expect(find.text('CSU vs PTU'), findsOneWidget);
  });

  testWidgets('favorites grid shows season records', (tester) async {
    SharedPreferences.setMockInitialValues({
      'favorite_team_ids': ['por'],
    });
    final favorites = await FavoritesStore.open();
    _tallView(tester);
    await tester.pumpWidget(
      StatMyTeamApp(
        repository: StatsRepository.sampleFootball(),
        favorites: favorites,
        showLogin: false,
      ),
    );

    expect(find.text('Favorite teams'), findsOneWidget);
    expect(find.text('Lumberjacks'), findsOneWidget);
    expect(find.textContaining('-'), findsWidgets);
  });
}
