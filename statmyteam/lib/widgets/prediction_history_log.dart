import 'package:flutter/material.dart';

import '../logic/money.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class PredictionHistoryLog extends StatefulWidget {
  const PredictionHistoryLog({
    super.key,
    required this.bets,
    required this.resolveGame,
    required this.resolveTeam,
  });

  final List<Bet> bets;
  final GameStats Function(String id) resolveGame;
  final Team Function(String id) resolveTeam;

  @override
  State<PredictionHistoryLog> createState() => _PredictionHistoryLogState();
}

class _PredictionHistoryLogState extends State<PredictionHistoryLog> {
  BetStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final visible = [
      for (final bet in widget.bets)
        if (_filter == null || bet.status == _filter) bet,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _FilterChip(
              label: 'All',
              selected: _filter == null,
              onTap: () => setState(() => _filter = null),
            ),
            for (final status in BetStatus.values)
              _FilterChip(
                label: _statusLabel(status),
                selected: _filter == status,
                color: _statusColor(status),
                onTap: () => setState(() => _filter = status),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (visible.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No predictions in this filter yet.',
              style: TextStyle(color: AppColors.muted),
            ),
          )
        else
          for (var i = 0; i < visible.length; i++)
            _HistoryTile(
              bet: visible[i],
              home: widget.resolveTeam(
                widget.resolveGame(visible[i].gameId).homeTeamId,
              ),
              away: widget.resolveTeam(
                widget.resolveGame(visible[i].gameId).awayTeamId,
              ),
              isLast: i == visible.length - 1,
            ),
      ],
    );
  }

  static String _statusLabel(BetStatus status) => switch (status) {
        BetStatus.pending => 'Open',
        BetStatus.won => 'Won',
        BetStatus.lost => 'Lost',
        BetStatus.push => 'Push',
      };

  static Color _statusColor(BetStatus status) => switch (status) {
        BetStatus.pending => AppColors.pending,
        BetStatus.won => AppColors.accent,
        BetStatus.lost => AppColors.danger,
        BetStatus.push => AppColors.muted,
      };
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.accent;
    return Material(
      color: selected ? accent.withValues(alpha: 0.16) : AppColors.surfaceHigh,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? accent : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? accent : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.bet,
    required this.home,
    required this.away,
    required this.isLast,
  });

  final Bet bet;
  final Team home;
  final Team away;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = _PredictionHistoryLogState._statusColor(bet.status);
    final label = _PredictionHistoryLogState._statusLabel(bet.status);
    final matchup = '${away.abbreviation} @ ${home.abbreviation}';
    final profit = bet.isSettled ? bet.realizedProfit : bet.potentialProfit;
    final date = bet.placedAt.toLocal();
    final dateLabel =
        '${date.month}/${date.day}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: AppColors.border),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            label.toUpperCase(),
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          bet.isSettled
                              ? formatMoney(profit, showSign: true)
                              : 'To win ${formatMoney(profit)}',
                          style: TextStyle(
                            color: bet.status == BetStatus.lost
                                ? AppColors.danger
                                : bet.status == BetStatus.won
                                    ? AppColors.accent
                                    : AppColors.gold,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      bet.selectionLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$matchup  ·  ${formatMoney(bet.stake)} at ${formatAmericanOdds(bet.americanOdds)}  ·  ${formatPercent(bet.modelWinChance)} model',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
