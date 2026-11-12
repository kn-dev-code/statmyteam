
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:statmyteam/data/favorites_store.dart';
import 'package:statmyteam/data/settings_store.dart';
import 'package:statmyteam/data/stats_repository.dart';
import 'package:statmyteam/main.dart';
import 'package:statmyteam/theme/app_theme.dart';
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

Future<void> _tapText(
  WidgetTester tester,
  String text,
) async {
  final finder = find.text(text);

  expect(
    finder,
    findsWidgets,
    reason: 'Expected to find "$text" on the current screen.',
  );

  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();

  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

// Select a sport before opening the team selection screen.
Future<void> _selectFootball(WidgetTester tester) async {
  await _tapText(tester, 'American Football');
}

Future<void> _selectBasketball(WidgetTester tester) async {
  await _tapText(tester, 'Basketball');
}

Future<void> _selectSoccer(WidgetTester tester) async {
  await _tapText(tester, 'Soccer');
}

void main() {
  testWidgets(
    'main menu offers head-to-head and team stats',
    (tester) async {
      await tester.pumpWidget(await _app());

      expect(find.text('StatMyTeam'), findsWidgets);
      expect(find.text('Head-to-Head'), findsOneWidget);
      expect(find.text('Team Stats'), findsOneWidget);
      expect(find.textContaining('Bet'), findsNothing);
    },
  );

  testWidgets(
    'login shows email/password and SSO buttons',
    (tester) async {
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

      await _tapText(tester, 'Continue as guest');

      expect(find.text('Head-to-Head'), findsOneWidget);
    },
  );

  testWidgets(
    'pick two teams, see the projection, then compare players',
    (tester) async {
      _tallView(tester);

      await tester.pumpWidget(await _app());

      await _tapText(tester, 'Head-to-Head');
      await _selectFootball(tester);

      final compare = find.widgetWithText(
        FilledButton,
        'Compare teams',
      );

      expect(compare, findsOneWidget);

      expect(
        tester.widget<FilledButton>(compare).onPressed,
        isNull,
      );

      await _tapText(tester, 'Portland Lumberjacks');
      await _tapText(tester, 'Austin Stampede');

      expect(
        tester.widget<FilledButton>(compare).onPressed,
        isNotNull,
      );

      await tester.tap(compare);
      await tester.pumpAndSettle();

      expect(find.text('POR vs AUS'), findsOneWidget);
      expect(find.text('WIN PROBABILITY'), findsOneWidget);

      expect(
        find.text('What drives the projection'),
        findsOneWidget,
      );

      expect(find.text('Points / game'), findsOneWidget);

      double chance() {
        return tester
            .widget<WinProbabilityBar>(
              find.byType(WinProbabilityBar),
            )
            .teamAChance;
      }

      final portlandHome = chance();

      await _tapText(tester, '@ AUS');

      expect(chance(), lessThan(portlandHome));

      await _tapText(tester, 'Compare players');

      expect(find.text('Caleb Vance'), findsOneWidget);
      expect(find.text('Jace Whitaker'), findsOneWidget);
      expect(find.text('Passer rating'), findsOneWidget);

      await tester.tap(
        find.widgetWithText(ChoiceChip, 'K'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Henrik Solberg'), findsOneWidget);
      expect(find.text('Paulo Santos'), findsOneWidget);
      expect(find.text('Field goal %'), findsOneWidget);
    },
  );

  testWidgets(
    'team stats shows roster with role and availability',
    (tester) async {
      _tallView(tester);

      await tester.pumpWidget(await _app());

      await _tapText(tester, 'Team Stats');
      await _selectFootball(tester);

      await _tapText(tester, 'Sacramento Prospectors');

      expect(find.text('Season stats'), findsOneWidget);
      expect(find.text('Injury report'), findsOneWidget);
      expect(find.text('Strengths & weaknesses'), findsOneWidget);
      expect(find.text('IR'), findsWidgets);

      await tester.tap(
        find.text('Ryan Castellano').first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Injured reserve'), findsOneWidget);
      expect(find.text('Starter'), findsOneWidget);
      expect(find.text('Quarterback'), findsOneWidget);
    },
  );

  testWidgets(
    'teams are sorted into NFL and NCAA tabs',
    (tester) async {
      _tallView(tester);

      await tester.pumpWidget(await _app());

      await _tapText(tester, 'Team Stats');
      await _selectFootball(tester);

      expect(
        find.text('Portland Lumberjacks'),
        findsOneWidget,
      );

      expect(
        find.text('Prairie Tech Bison'),
        findsNothing,
      );

      await _tapText(tester, 'NCAA');

      expect(
        find.text('Prairie Tech Bison'),
        findsOneWidget,
      );

      expect(
        find.text('Great Plains Conference'),
        findsOneWidget,
      );

      expect(
        find.text('Portland Lumberjacks'),
        findsNothing,
      );

      await _tapText(tester, 'Prairie Tech Bison');

      expect(
        find.textContaining(
          'NCAA · Great Plains Conference',
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.text('Bo Calder').first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Class'), findsOneWidget);
      expect(find.text('RS Junior'), findsOneWidget);
    },
  );

  testWidgets(
    'head-to-head selection status updates for both teams',
    (tester) async {
      _tallView(tester);
      await tester.pumpWidget(await _app());
      await _tapText(tester, 'Head-to-Head');
      await _selectFootball(tester);

      final compare = find.widgetWithText(FilledButton, 'Compare teams');
      final status = find.byKey(const ValueKey('matchup_selection_status'));

      expect(status, findsOneWidget);
      expect(find.text('0 of 2 teams selected — choose Team A.'), findsOneWidget);
      expect(tester.widget<FilledButton>(compare).onPressed, isNull);
      expect(find.byKey(const ValueKey('clear_matchup_selection')), findsNothing);

      await _tapText(tester, 'Portland Lumberjacks');
      expect(find.text('1 of 2 teams selected — choose Team B.'), findsOneWidget);
      expect(tester.widget<FilledButton>(compare).onPressed, isNull);

      await _tapText(tester, 'Austin Stampede');
      expect(find.text('2 of 2 teams selected — ready to compare.'), findsOneWidget);
      expect(tester.widget<FilledButton>(compare).onPressed, isNotNull);
      expect(find.byKey(const ValueKey('clear_matchup_selection')), findsOneWidget);
    },
  );

  testWidgets(
    'clear selection resets both matchup picks and disables comparison',
    (tester) async {
      _tallView(tester);
      await tester.pumpWidget(await _app());
      await _tapText(tester, 'Head-to-Head');
      await _selectFootball(tester);

      await _tapText(tester, 'Portland Lumberjacks');
      await _tapText(tester, 'Austin Stampede');

      final compare = find.widgetWithText(FilledButton, 'Compare teams');
      expect(tester.widget<FilledButton>(compare).onPressed, isNotNull);

      await tester.tap(find.byKey(const ValueKey('clear_matchup_selection')));
      await tester.pumpAndSettle();

      expect(find.text('0 of 2 teams selected — choose Team A.'), findsOneWidget);
      expect(find.text('Team A'), findsOneWidget);
      expect(find.text('Team B'), findsOneWidget);
      expect(tester.widget<FilledButton>(compare).onPressed, isNull);
      expect(find.byKey(const ValueKey('clear_matchup_selection')), findsNothing);

      // Selection can start again after resetting both teams.
      await _tapText(tester, 'Portland Lumberjacks');
      expect(find.text('1 of 2 teams selected — choose Team B.'), findsOneWidget);
    },
  );

  testWidgets(
    'switching league clears head-to-head picks',
    (tester) async {
      _tallView(tester);

      await tester.pumpWidget(await _app());

      await _tapText(tester, 'Head-to-Head');
      await _selectFootball(tester);

      final portland = find.text('Portland Lumberjacks');

      expect(
        portland,
        findsOneWidget,
        reason:
            'Portland Lumberjacks should be visible '
            'in the NFL Head-to-Head team list.',
      );

      await tester.ensureVisible(portland);
      await tester.pumpAndSettle();

      await tester.tap(portland);
      await tester.pumpAndSettle();

      expect(find.text('Lumberjacks'), findsOneWidget);

      await _tapText(tester, 'NCAA');

      expect(find.text('Team A'), findsOneWidget);

      await _tapText(
        tester,
        'Cascade State Timberwolves',
      );

      await _tapText(
        tester,
        'Prairie Tech Bison',
      );

      final compare = find.widgetWithText(
        FilledButton,
        'Compare teams',
      );

      expect(compare, findsOneWidget);

      expect(
        tester.widget<FilledButton>(compare).onPressed,
        isNotNull,
      );

      await tester.tap(compare);
      await tester.pumpAndSettle();

      expect(find.text('CSU vs PTU'), findsOneWidget);
    },
  );

  testWidgets(
    'favorites grid shows season records',
    (tester) async {
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
    },
  );

  testWidgets(
    'settings switches to dark mode and remembers it',
    (tester) async {
      _tallView(tester);

      SharedPreferences.setMockInitialValues({});

      final prefs = await SharedPreferences.getInstance();
      final favorites = await FavoritesStore.open();

      await tester.pumpWidget(
        StatMyTeamApp(
          repository: StatsRepository.sampleFootball(),
          favorites: favorites,
          settings: SettingsStore(prefs),
          showLogin: false,
        ),
      );

      Brightness themeBrightness() {
        return Theme.of(
          tester.element(find.byType(Scaffold).last),
        ).brightness;
      }

      expect(
        themeBrightness(),
        Brightness.light,
      );

      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Appearance'), findsOneWidget);

      await _tapText(tester, 'Dark');

      expect(
        themeBrightness(),
        Brightness.dark,
      );

      expect(AppColors.isDark, isTrue);

      expect(
        prefs.getString('theme_mode'),
        'dark',
      );

      expect(find.text('Appearance'), findsOneWidget);

      await _tapText(tester, 'Light');

      expect(
        themeBrightness(),
        Brightness.light,
      );

      expect(AppColors.isDark, isFalse);
    },
  );

  testWidgets(
    'basketball team select hides football clubs',
    (tester) async {
      _tallView(tester);
      await tester.pumpWidget(await _app());

      await _tapText(tester, 'Team Stats');
      expect(find.text('American Football'), findsOneWidget);
      expect(find.text('Basketball'), findsOneWidget);
      expect(find.text('Soccer'), findsOneWidget);

      await _selectBasketball(tester);

      expect(find.text('Seattle Rainiers'), findsOneWidget);
      expect(find.text('Portland Lumberjacks'), findsNothing);
      expect(find.text('Prairie Tech Bison'), findsNothing);
    },
  );

  testWidgets(
    'soccer head-to-head stays in MLS and opens a matchup',
    (tester) async {
      _tallView(tester);
      await tester.pumpWidget(await _app());

      await _tapText(tester, 'Head-to-Head');
      await _selectSoccer(tester);

      expect(find.text('Portland Cascades'), findsOneWidget);
      expect(find.text('Portland Lumberjacks'), findsNothing);

      await _tapText(tester, 'Portland Cascades');
      await _tapText(tester, 'New York Harbor');

      final compare = find.widgetWithText(FilledButton, 'Compare teams');
      expect(tester.widget<FilledButton>(compare).onPressed, isNotNull);

      await tester.tap(compare);
      await tester.pumpAndSettle();

      expect(find.text('PDX vs NYC'), findsOneWidget);
      expect(find.text('Goals / game'), findsOneWidget);
      expect(find.textContaining('outlook'), findsWidgets);
    },
  );
}
