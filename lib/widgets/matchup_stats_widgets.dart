import 'package:flutter/material.dart';

import '../logic/football_stats.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'team_badge.dart';

class WinProbabilityBar extends StatelessWidget {
  const WinProbabilityBar({
    super.key,
    required this.teamA,
    required this.teamB,
    required this.teamAChance,
  });

  final Team teamA;
  final Team teamB;
  final double teamAChance;

  @override
  Widget build(BuildContext context) {
    final pctA = (teamAChance * 100).round();
    final pctB = 100 - pctA;
    final aLeads = pctA >= pctB;

    Widget label(Team team, int pct, bool leads, CrossAxisAlignment align) {
      return Column(
        crossAxisAlignment: align,
        children: [
          Text(
            '$pct%',
            style: TextStyle(
              color: leads ? AppColors.accent : AppColors.muted,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            team.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Semantics(
      label: '${teamA.name} $pctA percent, ${teamB.name} $pctB percent',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: label(teamA, pctA, aLeads, CrossAxisAlignment.start),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: label(teamB, pctB, !aLeads, CrossAxisAlignment.end),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 12,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: pctA.clamp(1, 99),
                  child: _barSegment(
                    aLeads ? AppColors.accent : AppColors.border,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: pctB.clamp(1, 99),
                  child: _barSegment(
                    aLeads ? AppColors.border : AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _barSegment(Color color) => DecoratedBox(
    decoration: ShapeDecoration(color: color, shape: const StadiumBorder()),
  );
}

/// One stat, both sides: values at the edges, label in the middle, and a
/// split bar underneath. The better side is bold and full color.
class StatCompareRow extends StatelessWidget {
  const StatCompareRow({
    super.key,
    required this.def,
    required this.valueA,
    required this.valueB,
    required this.colorA,
    required this.colorB,
  });

  final StatDef def;
  final double? valueA;
  final double? valueB;
  final Color colorA;
  final Color colorB;

  @override
  Widget build(BuildContext context) {
    final a = valueA;
    final b = valueB;
    final edge = StatEdge.of(def, a, b);

    // Bar share: for "lower is better" stats invert so the better side wins
    // more of the bar.
    double shareA = 0.5;
    if (a != null && b != null) {
      final sa = a.abs();
      final sb = b.abs();
      if (sa + sb > 0) {
        shareA = def.higherIsBetter ? sa / (sa + sb) : sb / (sa + sb);
      }
      if (def.signed) {
        // Differentials can be negative; compare on a shifted scale.
        final low = (a < b ? a : b);
        final shift = low < 0 ? -low + 1 : 1;
        shareA = (a + shift) / (a + shift + b + shift);
      }
    }
    final flexA = (shareA * 1000).round().clamp(20, 980);

    TextStyle valueStyle(bool better) => TextStyle(
      fontSize: 16,
      fontWeight: better ? FontWeight.w800 : FontWeight.w500,
      color: better ? AppColors.accent : AppColors.muted,
    );

    Widget segment(Color color, bool better) => DecoratedBox(
      decoration: ShapeDecoration(
        color: better ? color : color.withValues(alpha: 0.22),
        shape: const StadiumBorder(),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 72,
                child: Text(
                  a == null ? '—' : def.format(a),
                  style: valueStyle(edge.aBetter),
                ),
              ),
              Expanded(
                child: Text(
                  def.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(
                width: 72,
                child: Text(
                  b == null ? '—' : def.format(b),
                  textAlign: TextAlign.right,
                  style: valueStyle(edge.bBetter),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 6,
            child: edge.bothPresent
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: flexA,
                        child: segment(colorA, edge.aBetter),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        flex: 1000 - flexA,
                        child: segment(colorB, edge.bBetter),
                      ),
                    ],
                  )
                : DecoratedBox(
                    decoration: ShapeDecoration(
                      color: AppColors.surfaceHigh,
                      shape: StadiumBorder(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Which side of a two-value stat comparison is better.
class StatEdge {
  const StatEdge._(this.bothPresent, this.aBetter, this.bBetter);

  factory StatEdge.of(StatDef def, double? a, double? b) {
    final both = a != null && b != null;
    final aBetter = both && a != b && ((a > b) == def.higherIsBetter);
    final bBetter = both && a != b && !aBetter;
    return StatEdge._(both, aBetter, bBetter);
  }

  final bool bothPresent;
  final bool aBetter;
  final bool bBetter;
}

/// Three-column grid of stat duels: each tile shows the label and both
/// teams' values, with the better value in bold green and a caret under it.
class StatDuelGrid extends StatelessWidget {
  const StatDuelGrid({
    super.key,
    required this.defs,
    required this.valuesA,
    required this.valuesB,
    this.columns = 3,
  });

  final List<StatDef> defs;
  final Map<String, double> valuesA;
  final Map<String, double> valuesB;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final rows = <List<StatDef>>[
      for (var i = 0; i < defs.length; i += columns)
        defs.sublist(i, (i + columns).clamp(0, defs.length)),
    ];

    return Column(
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) const SizedBox(height: 6),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var c = 0; c < columns; c++) ...[
                  if (c > 0)
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: AppColors.border,
                    ),
                  Expanded(
                    child: c < rows[r].length
                        ? _DuelTile(
                            def: rows[r][c],
                            a: valuesA[rows[r][c].key],
                            b: valuesB[rows[r][c].key],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _DuelTile extends StatelessWidget {
  const _DuelTile({required this.def, required this.a, required this.b});

  final StatDef def;
  final double? a;
  final double? b;

  @override
  Widget build(BuildContext context) {
    final edge = StatEdge.of(def, a, b);

    Widget value(double? v, bool better) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            v == null ? '—' : def.format(v),
            style: TextStyle(
              fontSize: better ? 17 : 15,
              fontWeight: better ? FontWeight.w800 : FontWeight.w400,
              color: better ? AppColors.accent : AppColors.muted,
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(
            height: 12,
            child: better
                ? Icon(
                    Icons.keyboard_arrow_up_rounded,
                    size: 18,
                    color: AppColors.accent,
                  )
                : null,
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 6),
      child: Column(
        children: [
          Text(
            def.label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Flexible(child: value(a, edge.aBetter)),
              Flexible(child: value(b, edge.bBetter)),
            ],
          ),
        ],
      ),
    );
  }
}

/// W/L chips for a team's recent results, newest on the left.
class FormStrip extends StatelessWidget {
  const FormStrip({super.key, required this.teamId, required this.games});

  final String teamId;
  final List<GameStats> games;

  @override
  Widget build(BuildContext context) {
    if (games.isEmpty) {
      return Text('No games yet', style: TextStyle(color: AppColors.muted));
    }
    return Wrap(
      spacing: 6,
      children: [
        for (final game in games)
          _chip(
            game.winnerTeamId == teamId
                ? 'W'
                : (game.winnerTeamId == null ? 'T' : 'L'),
          ),
      ],
    );
  }

  Widget _chip(String result) {
    final color = switch (result) {
      'W' => AppColors.accent,
      'L' => AppColors.danger,
      _ => AppColors.muted,
    };
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        result,
        style: TextStyle(
          color: result == 'W' ? AppColors.onAccent : Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12.5,
        ),
      ),
    );
  }
}

/// One completed game, read from [teamId]'s perspective.
class GameResultTile extends StatelessWidget {
  const GameResultTile({
    super.key,
    required this.game,
    required this.teamId,
    required this.opponent,
  });

  final GameStats game;
  final String teamId;
  final Team opponent;

  @override
  Widget build(BuildContext context) {
    final isHome = game.homeTeamId == teamId;
    final mine = isHome ? game.home.score : game.away.score;
    final theirs = isHome ? game.away.score : game.home.score;
    final won = game.winnerTeamId == teamId;
    final d = game.startTime.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          TeamBadge(team: opponent, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${isHome ? 'vs' : '@'} ${opponent.displayName}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${months[d.month - 1]} ${d.day}, ${d.year}',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: ShapeDecoration(
              color: (won ? AppColors.accent : AppColors.danger).withValues(
                alpha: 0.1,
              ),
              shape: const StadiumBorder(),
            ),
            child: Text(
              '${won ? 'W' : 'L'} $mine–$theirs',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: won ? AppColors.accent : AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Centers content and caps width on tablets / desktop.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: child,
      ),
    );
  }
}

/// Compact multi-column grid of labeled stat values.
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.items, this.crossAxisCount = 2});

  final List<({String label, String value})> items;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final tileWidth = (width - (crossAxisCount - 1) * 10) / crossAxisCount;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final item in items)
              SizedBox(
                width: tileWidth,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.value,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Points scored in recent completed games, newest last on the chart.
