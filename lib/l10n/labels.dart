import 'dart:math' as math;

import 'package:intl/intl.dart';

import '../data/load_status.dart';
import '../logic/football_stats.dart';
import '../logic/matchup_projector.dart';
import '../logic/sport_stats.dart';
import '../models/models.dart';
import 'app_localizations.dart';

/// Localized display text for domain values (sports, positions, stats,
/// outlooks, projection factors) and locale-aware number formatting. Logic
/// classes carry data; this turns it into words and digits for the current
/// locale.
extension DomainLabels on AppLocalizations {
  String sport(Sport sport) => sportName(sport.name);

  String sportMenu(Sport sport) => sportMenuName(sport.name);

  String level(League league) => leagueLevel(league.name);

  String status(PlayerStatus status) => playerStatus(status.name);

  String statusShort(PlayerStatus status) => playerStatusShort(status.name);

  String role(DepthRole role) => depthRole(role.name);

  String group(PositionGroup group) => positionGroupName(group.name);

  String groupShort(PositionGroup group) => positionGroupShort(group.name);

  String stat(StatDef def) => statLabel(def.labelKey);

  /// "PPG" or "GPG" for team rows.
  String scoringRate(Sport sport) =>
      scoringRateAbbrev(sport.scoresGoals ? 'goals' : 'points');

  String failure(LoadFailure failure) => loadFailure(failure.kind.name);

  String gap(FeedGap gap) => feedGap(gap.part.name, gap.failed, gap.total);

  // ── Numbers ──────────────────────────────────────────────────────────────

  /// [value] with exactly [digits] decimals in the locale's format; a
  /// leading `+` on positive values when [signed]. The sign follows the
  /// rounded value, so 0.04 is "0.0", never "+0.0" or "-0.0".
  String decimal(double value, int digits, {bool signed = false}) {
    final factor = math.pow(10, digits);
    var rounded = (value * factor).round() / factor;
    if (rounded == 0) rounded = 0; // Drop the sign of negative zero.
    final text = _NumberFormats.decimal(localeName, digits).format(rounded);
    return signed && rounded > 0 ? '+$text' : text;
  }

  /// A 0–1 [fraction] as a locale-formatted percentage, e.g. `64%`.
  String percent(double fraction, {int digits = 0}) =>
      _NumberFormats.percent(localeName, digits).format(fraction);

  /// `3` for whole numbers, `3.5` otherwise.
  String trimmed(double value) =>
      decimal(value, value == value.roundToDouble() ? 0 : 1);

  /// A stat value formatted per its [StatDef] (decimals, percent, sign).
  String statValue(StatDef def, double value) => def.isPercent
      ? percent(value, digits: def.decimals)
      : decimal(value, def.decimals, signed: def.signed);

  /// Parts joined with the locale's " · " separator.
  String dotted(Iterable<String> parts) => parts.join(dotSeparator);

  // ── Lists and ordinals ───────────────────────────────────────────────────

  /// Items joined as prose: `A`, `A and B`, `A, B, and C`.
  String list(List<String> items) => switch (items.length) {
    0 => '',
    1 => items.single,
    2 => listTwo(items[0], items[1]),
    _ => listMany(
      items.sublist(0, items.length - 1).join(listSeparator),
      items.last,
    ),
  };

  /// League labels in [League] order as prose, e.g. `NFL and NBA`.
  String leagues(Iterable<League> leagues) => list([
    for (final league in League.values)
      if (leagues.contains(league)) league.label,
  ]);

  /// `1st`, `2nd`, `11th` in English. Other locales use the `1.` style
  /// common in European languages until they add their own rules here.
  String ordinal(int n) {
    if (!localeName.startsWith('en')) return '$n.';
    if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
    return switch (n % 10) {
      1 => '${n}st',
      2 => '${n}nd',
      3 => '${n}rd',
      _ => '${n}th',
    };
  }

  // ── Team outlook ─────────────────────────────────────────────────────────

  String traitHeadline(TeamTrait trait) {
    final key = trait.def.key;
    if (SportStats.traitCopyKeys.contains(key)) {
      return trait.isStrength ? traitStrength(key) : traitWeakness(key);
    }
    final label = stat(trait.def).toLowerCase();
    return trait.isStrength
        ? traitAboveAverage(label)
        : traitBelowAverage(label);
  }

  String traitDetailFor(TeamTrait trait, Team team) {
    final value = statValue(trait.def, trait.value);
    final rank = ordinal(trait.rank);
    final league = team.league;
    return league == null
        ? traitDetailNoLeague(value, rank, trait.of)
        : traitDetail(value, rank, trait.of, league.label);
  }

  String outlookSummary(TeamOutlook outlook) {
    final team = outlook.team;
    final name = team.displayName;
    if (!outlook.graded) return outlookNotGraded(name);
    final strengths = outlook.strengths;
    final weaknesses = outlook.weaknesses;
    if (strengths.isEmpty && weaknesses.isEmpty) {
      final league = team.league;
      return league == null
          ? outlookMiddleNoLeague(name)
          : outlookMiddle(name, league.label);
    }
    String lower(TeamTrait t) => traitHeadline(t).toLowerCase();
    final opening = switch (strengths.length) {
      0 => outlookNoEdge(name),
      1 => outlookStrongestOne(name, lower(strengths[0])),
      _ => outlookStrongestTwo(name, lower(strengths[0]), lower(strengths[1])),
    };
    if (weaknesses.isEmpty) return opening;
    final worst = weaknesses.first;
    return sentenceJoin(
      opening,
      outlookConcern(lower(worst), statValue(worst.def, worst.value)),
    );
  }

  // ── Matchup projection ───────────────────────────────────────────────────

  String factorName(MatchupFactor factor) => factorTitle(factor.kind.name);

  String factorDetail(MatchupFactor factor, Team a, Team b) {
    String signed(double? v, [int digits = 1]) =>
        decimal(v ?? 0, digits, signed: true);

    String fixed(double? v) => decimal(v ?? 0, 1);

    String missing(Team team, List<Player> players) => players.isEmpty
        ? factorTeamHealthy(team.abbreviation)
        : factorTeamMissing(
            team.abbreviation,
            [
              for (final p in players)
                missingPlayer(p.position, p.lastName, statusShort(p.status)),
            ].join(listSeparator),
          );

    return switch (factor.kind) {
      FactorKind.record => factorRecord(
        a.abbreviation,
        a.record,
        b.abbreviation,
        b.record,
      ),
      FactorKind.scoringMargin => factorScoringMargin(
        signed(factor.valueA),
        signed(factor.valueB),
        a.sport.scoresGoals ? 'goals' : 'points',
      ),
      FactorKind.shooting => factorShooting(
        percent(factor.valueA ?? 0, digits: 1),
        percent(factor.valueB ?? 0, digits: 1),
      ),
      FactorKind.rebounding => factorRebounding(
        fixed(factor.valueA),
        fixed(factor.valueB),
      ),
      FactorKind.chanceCreation => factorChanceCreation(
        decimal(factor.valueA ?? 0, 2),
        decimal(factor.valueB ?? 0, 2),
      ),
      FactorKind.chancePrevention => factorChancePrevention(
        decimal(factor.valueA ?? 0, 2),
        decimal(factor.valueB ?? 0, 2),
      ),
      FactorKind.offense => factorOffense(
        fixed(factor.valueA),
        fixed(factor.valueB),
      ),
      FactorKind.defense => factorDefense(
        fixed(factor.valueA),
        fixed(factor.valueB),
      ),
      FactorKind.turnovers => factorTurnovers(
        signed(factor.valueA, 0),
        signed(factor.valueB, 0),
      ),
      FactorKind.venue => switch (factor.favors) {
        null => factorVenueNeutral,
        final home => factorVenueHome(
          home.city,
          ((factor.valueA ?? 0) * 100).round(),
        ),
      },
      FactorKind.availability => dotted([
        missing(a, factor.missingA),
        missing(b, factor.missingB),
      ]),
      FactorKind.headToHead =>
        factor.meetings == 0
            ? factorNoMeetings
            : factorHeadToHead(
                a.abbreviation,
                factor.winsA,
                factor.winsB,
                b.abbreviation,
                factor.meetings,
              ),
    };
  }

  /// Point spread for the favorite, e.g. `AUS -3.5`, or "Pick'em".
  String spread(MatchupProjection p) {
    if (p.isPickEm) return spreadPickEm;
    return spreadLine(p.favorite.abbreviation, trimmed(p.spread));
  }
}

/// NumberFormat instances are costly to build and these helpers run per row
/// in build methods, so keep one per locale and digit count.
abstract final class _NumberFormats {
  static final Map<(String, int), NumberFormat> _decimal = {};
  static final Map<(String, int), NumberFormat> _percent = {};

  static NumberFormat decimal(String locale, int digits) =>
      _decimal.putIfAbsent(
        (locale, digits),
        () => NumberFormat.decimalPatternDigits(
          locale: locale,
          decimalDigits: digits,
        ),
      );

  static NumberFormat percent(String locale, int digits) =>
      _percent.putIfAbsent(
        (locale, digits),
        () => NumberFormat.decimalPercentPattern(
          locale: locale,
          decimalDigits: digits,
        ),
      );
}
