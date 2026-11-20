import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:statmyteam/data/load_status.dart';
import 'package:statmyteam/l10n/l10n.dart';
import 'package:statmyteam/logic/football_stats.dart';
import 'package:statmyteam/logic/matchup_projector.dart';
import 'package:statmyteam/logic/sport_stats.dart';
import 'package:statmyteam/models/models.dart';

/// Every ICU select in app_en.arb ends in `other{{key}}`, so a new enum
/// value or stat key would silently show its raw key on screen. These
/// tests fail instead.
void main() {
  final en = lookupAppLocalizations(const Locale('en'));

  void expectTranslated(
    String Function(String) message,
    Iterable<String> keys,
  ) {
    for (final key in keys) {
      expect(message(key), isNot(key), reason: 'no English text for "$key"');
      expect(message(key), isNotEmpty, reason: 'empty text for "$key"');
    }
  }

  test('every enum shown to users has text', () {
    expectTranslated(en.sportName, Sport.values.map((e) => e.name));
    expectTranslated(en.sportMenuName, Sport.values.map((e) => e.name));
    expectTranslated(en.leagueLevel, League.values.map((e) => e.name));
    expectTranslated(en.playerStatus, PlayerStatus.values.map((e) => e.name));
    expectTranslated(
      en.playerStatusShort,
      PlayerStatus.values.map((e) => e.name),
    );
    expectTranslated(en.depthRole, DepthRole.values.map((e) => e.name));
    expectTranslated(
      en.positionGroupName,
      PositionGroup.values.map((e) => e.name),
    );
    expectTranslated(
      en.positionGroupShort,
      PositionGroup.values.map((e) => e.name),
    );
    expectTranslated(en.factorTitle, FactorKind.values.map((e) => e.name));
    expectTranslated(en.loadFailure, LoadFailureKind.values.map((e) => e.name));
    expectTranslated(en.themeMode, ['system', 'light', 'dark']);
  });

  test('every feed part has text', () {
    for (final part in FeedPart.values) {
      final text = en.gap(FeedGap(part, 1, 2));
      // Not the generic fallback branch.
      expect(text, isNot(en.feedGap('unknown', 1, 2)), reason: part.name);
    }
  });

  test('every position code on a roster has a name', () {
    const codes = [
      // Football
      'QB', 'RB', 'FB', 'WR', 'TE', 'OL', 'DE', 'DT', 'DL', 'LB', 'CB', 'S',
      'DB', 'K', 'P', 'LS',
      // Basketball
      'PG', 'SG', 'SF', 'PF', 'C', 'G', 'F',
      // Soccer
      'GK', 'DEF', 'MID', 'FWD',
    ];
    expectTranslated(en.positionName, codes);
  });

  test('every stat definition has a label', () {
    const positions = {
      Sport.football: [
        'QB', 'RB', 'FB', 'WR', 'TE', 'DE', 'DT', 'DL', 'LB', 'CB', 'S', //
        'DB', 'K',
      ],
      Sport.basketball: ['PG', 'SG', 'SF', 'PF', 'C', 'G', 'F'],
      Sport.soccer: ['GK', 'DEF', 'MID', 'FWD'],
    };
    final defs = <StatDef>[
      for (final sport in Sport.values) ...SportStats.teamStats(sport),
      for (final MapEntry(key: sport, value: codes) in positions.entries)
        for (final code in codes) ...SportStats.forPosition(sport, code),
    ];
    // Recent-game metrics on the matchup screen.
    final keys = {
      for (final def in defs) def.labelKey,
      'recentScored',
      'recentAllowed',
      'recentMargin',
    };
    expectTranslated(en.statLabel, keys);
  });

  test('every hand-written trait has strength and weakness copy', () {
    expectTranslated(en.traitStrength, SportStats.traitCopyKeys);
    expectTranslated(en.traitWeakness, SportStats.traitCopyKeys);
  });
}
