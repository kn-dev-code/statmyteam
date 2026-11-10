import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../logic/football_stats.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

/// A team color that stays readable on the current card surface: not too
/// light on white cards, not too dark on charcoal ones. White text on it
/// (badges, jersey discs) stays legible in both modes.
Color teamColor(Team team) {
  final primary = Color(team.primaryColor);
  final secondary = Color(team.secondaryColor);
  bool tooLight(Color c) => c.computeLuminance() >= 0.5;
  bool tooDark(Color c) => c.computeLuminance() < 0.035;

  final Color base;
  if (!tooLight(primary)) {
    base = primary;
  } else if (!tooLight(secondary)) {
    base = secondary;
  } else {
    base = Color.lerp(primary, Colors.black, 0.45)!;
  }
  if (AppColors.isDark && tooDark(base)) {
    if (!tooDark(secondary) && !tooLight(secondary)) return secondary;
    return Color.lerp(base, Colors.white, 0.3)!;
  }
  return base;
}

/// Crest-style badge: a white ring around a team-color disc with the
/// abbreviation, echoing a club logo in a frame.
class TeamBadge extends StatelessWidget {
  const TeamBadge({super.key, required this.team, this.size = 44});

  final Team team;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = teamColor(team);
    final ring = size >= 56 ? 6.0 : (size >= 36 ? 3.5 : 2.0);
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(ring),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: size >= 56
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(color, Colors.white, 0.18)!, color],
          ),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                team.abbreviation,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: size * 0.26,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded white card used across the stats screens.
class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.child, this.padding, this.color});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    // Material (not a decorated Container) so ListTile ink and selection
    // colors inside the card stay visible.
    return Material(
      color: color ?? AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(18),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}

/// Bold section heading with an optional muted subtitle and trailing link.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 28, 4, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    height: 1.1,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Muted text link for section headers, e.g. "View all".
class SectionLink extends StatelessWidget {
  const SectionLink(this.label, {super.key, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(foregroundColor: AppColors.muted),
      child: Text(label, style: const TextStyle(fontSize: 15)),
    );
  }
}

/// Grey label pill, e.g. "Saved matchup" in the corner of a card.
class LabelPill extends StatelessWidget {
  const LabelPill(this.text, {super.key, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: ShapeDecoration(
        color: AppColors.surfaceHigh,
        shape: StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.text),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Grey pill with a muted label on the left and a bold value on the right.
class MetricPill extends StatelessWidget {
  const MetricPill({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: ShapeDecoration(
        color: AppColors.surfaceHigh,
        shape: StadiumBorder(),
      ),
      child: Row(
        children: [
          Text(
            label,
            maxLines: 1,
            style: TextStyle(color: AppColors.muted, fontSize: 14),
          ),
          const SizedBox(width: 6),
          // The value takes the remaining width and scales down if a long
          // value (e.g. "POR by 3.5") would not fit a narrow pill.
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? AppColors.text,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small pill showing whether a player will play.
class PlayerStatusChip extends StatelessWidget {
  const PlayerStatusChip({
    super.key,
    required this.status,
    this.compact = false,
  });

  final PlayerStatus status;
  final bool compact;

  static Color colorFor(PlayerStatus status) => switch (status) {
    PlayerStatus.active => AppColors.accent,
    PlayerStatus.questionable => AppColors.gold,
    PlayerStatus.out || PlayerStatus.injuredReserve => AppColors.danger,
  };

  @override
  Widget build(BuildContext context) {
    final color = colorFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: ShapeDecoration(
        color: color.withValues(alpha: 0.1),
        shape: const StadiumBorder(),
      ),
      child: Text(
        compact ? status.shortLabel : status.label,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Split bar showing each side's share of a probability.
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
class RecentFormChart extends StatelessWidget {
  const RecentFormChart({
    super.key,
    required this.teamId,
    required this.games,
    required this.color,
  });

  final String teamId;
  final List<GameStats> games;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final chronological = games.reversed.toList();
    if (chronological.isEmpty) {
      return Text(
        'No recent scores to chart',
        style: TextStyle(color: AppColors.muted),
      );
    }

    final spots = <FlSpot>[
      for (var i = 0; i < chronological.length; i++)
        FlSpot(
          i.toDouble(),
          ((chronological[i].homeTeamId == teamId
                      ? chronological[i].home.score
                      : chronological[i].away.score) ??
                  0)
              .toDouble(),
        ),
    ];
    final maxY = spots.map((s) => s.y).fold<double>(0, (a, b) => a > b ? a : b);
    final minY = spots
        .map((s) => s.y)
        .fold<double>(maxY, (a, b) => a < b ? a : b);

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minY: (minY - 4).clamp(0, 100),
          maxY: maxY + 6,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.border,
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, _) => Text(
                  value.toInt().toString(),
                  style: TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i >= chronological.length) {
                    return const SizedBox.shrink();
                  }
                  final d = chronological[i].startTime.toLocal();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${d.month}/${d.day}',
                      style: TextStyle(color: AppColors.muted, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.surface,
                  strokeWidth: 2.5,
                  strokeColor: color,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bars for a handful of player season totals.
class PlayerStatBarsChart extends StatelessWidget {
  const PlayerStatBarsChart({
    super.key,
    required this.defs,
    required this.player,
    required this.color,
  });

  final List<StatDef> defs;
  final Player player;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final rows = [
      for (final def in defs)
        if (player.seasonStats.containsKey(def.key))
          (def: def, value: player.stat(def.key)),
    ].take(5).toList();

    if (rows.isEmpty) {
      return Text(
        'No chartable season stats yet',
        style: TextStyle(color: AppColors.muted),
      );
    }

    final maxValue = rows
        .map((r) => r.value.abs())
        .fold<double>(1, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          maxY: maxValue * 1.15,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i >= rows.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      rows[i].def.label.split(' ').first,
                      style: TextStyle(color: AppColors.muted, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < rows.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: rows[i].value.abs(),
                    width: 22,
                    borderRadius: BorderRadius.circular(11),
                    color: color,
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxValue * 1.15,
                      color: AppColors.surfaceHigh,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Favorite team tile used in the home favorites grid.
class FavoriteTeamTile extends StatelessWidget {
  const FavoriteTeamTile({super.key, required this.team, required this.onTap});

  final Team team;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pct = (team.winPercentage * 100).round();
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TeamBadge(team: team, size: 52),
                  const Spacer(),
                  const Icon(
                    Icons.star_rounded,
                    color: AppColors.orange,
                    size: 22,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                team.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    team.record,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      letterSpacing: -0.5,
                      height: 1,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$pct%',
                    style: TextStyle(
                      color: pct >= 50 ? AppColors.accent : AppColors.danger,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: team.winPercentage,
                  minHeight: 5,
                  color: pct >= 50 ? AppColors.accent : AppColors.danger,
                  backgroundColor: AppColors.surfaceHigh,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
