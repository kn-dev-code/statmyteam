import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:statmyteam/data/stats_repository.dart';
import 'package:statmyteam/main.dart';
import 'package:statmyteam/state/betting_controller.dart';
import 'package:statmyteam/widgets/stats_widgets.dart';

Widget _app() => StatMyTeamApp(
      controller: BettingController.demo(),
      repository: StatsRepository.sampleFootball(),
    );

void _tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _openBetBoard(WidgetTester tester) async {
  await tester.tap(find.text('Bet Board'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('main menu offers head-to-head, team stats, and bet board', (
    tester,
  ) async {
    await tester.pumpWidget(_app());

    expect(find.text('StatMyTeam'), findsOneWidget);
    expect(find.text('Head-to-Head'), findsOneWidget);
    expect(find.text('Team Stats'), findsOneWidget);
    expect(find.text('Bet Board'), findsOneWidget);
  });

  testWidgets('shows bankroll, bet board, and prediction history', (
    tester,
  ) async {
    _tallView(tester);
    await tester.pumpWidget(_app());
    await _openBetBoard(tester);

    expect(find.text('VIRTUAL BANKROLL'), findsOneWidget);
    expect(find.text('Bet board'), findsOneWidget);
    expect(find.text('Prediction log'), findsOneWidget);
    expect(find.text('LAL ML'), findsWidgets);
    expect(find.text('WON'), findsWidgets);
    expect(find.text('LOST'), findsWidgets);
    expect(find.text('OPEN'), findsWidgets);
  });

  testWidgets('adding a moneyline updates the bet slip', (tester) async {
    await tester.pumpWidget(_app());
    await _openBetBoard(tester);

    await tester.tap(find.text('Add moneyline').first);
    await tester.pumpAndSettle();
    expect(find.text('On slip'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Bet slip'), findsWidgets);
    expect(find.text('Place virtual bets'), findsOneWidget);
  });

  testWidgets('pick two teams, see the projection, then compare players', (
    tester,
  ) async {
    _tallView(tester);
    await tester.pumpWidget(_app());

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
    await tester.pumpWidget(_app());

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
}
