import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n.dart';
import '../logic/football_stats.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

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
        context.l10n.noRecentScores,
        style: TextStyle(color: context.colors.muted),
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
    final dayFormat = DateFormat.Md(
      Localizations.localeOf(context).toLanguageTag(),
    );

    final l10n = context.l10n;
    final summary = l10n.chartRecentScores(
      spots.length,
      spots.map((s) => l10n.decimal(s.y, 0)).join(l10n.listSeparator),
    );

    // fl_chart draws to a canvas; give screen readers the numbers instead.
    return Semantics(
      label: summary,
      excludeSemantics: true,
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            minY: (minY - 4).clamp(0, 100),
            maxY: maxY + 6,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: context.colors.border,
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
                    context.l10n.decimal(value, 0),
                    style: TextStyle(color: context.colors.muted, fontSize: 10),
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
                        dayFormat.format(d),
                        style: TextStyle(
                          color: context.colors.muted,
                          fontSize: 10,
                        ),
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
                    color: context.colors.surface,
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
        context.l10n.noChartableStats,
        style: TextStyle(color: context.colors.muted),
      );
    }

    final maxValue = rows
        .map((r) => r.value.abs())
        .fold<double>(1, (a, b) => a > b ? a : b);

    final l10n = context.l10n;
    final summary = l10n.chartPlayerStats(
      rows
          .map(
            (r) => l10n.chartStatValue(
              l10n.stat(r.def),
              l10n.statValue(r.def, r.value),
            ),
          )
          .join(l10n.listSeparator),
    );

    return Semantics(
      label: summary,
      excludeSemantics: true,
      child: SizedBox(
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
                  reservedSize: 34,
                  getTitlesWidget: (value, _) {
                    final i = value.toInt();
                    if (i < 0 || i >= rows.length) {
                      return const SizedBox.shrink();
                    }
                    // Full label, wrapped to two lines; cutting at the first
                    // space breaks languages that do not use spaces.
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: SizedBox(
                        width: 60,
                        child: Text(
                          l10n.stat(rows[i].def),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.colors.muted,
                            fontSize: 9,
                            height: 1.1,
                          ),
                        ),
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
                        color: context.colors.surfaceHigh,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
