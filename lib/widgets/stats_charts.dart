import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

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
