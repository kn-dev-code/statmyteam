import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:statmyteam/main.dart';
import 'package:statmyteam/state/betting_controller.dart';

void main() {
  testWidgets('shows bankroll, bet board, and prediction history', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      StatMyTeamApp(controller: BettingController.demo()),
    );

    expect(find.text('StatMyTeam'), findsOneWidget);
    expect(find.text('VIRTUAL BANKROLL'), findsOneWidget);
    expect(find.text('Bet board'), findsOneWidget);
    expect(find.text('Prediction log'), findsOneWidget);
    expect(find.text('LAL ML'), findsWidgets);
    expect(find.text('WON'), findsWidgets);
    expect(find.text('LOST'), findsWidgets);
    expect(find.text('OPEN'), findsWidgets);
  });

  testWidgets('adding a moneyline updates the bet slip', (tester) async {
    await tester.pumpWidget(
      StatMyTeamApp(controller: BettingController.demo()),
    );

    await tester.tap(find.text('Add moneyline').first);
    await tester.pumpAndSettle();
    expect(find.text('On slip'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Bet slip'), findsWidgets);
    expect(find.text('Place virtual bets'), findsOneWidget);
  });
}
