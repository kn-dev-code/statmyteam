import 'package:flutter/material.dart';

import '../logic/money.dart';
import '../logic/predictor.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class BetSlipSelectionCard extends StatelessWidget {
  const BetSlipSelectionCard({
    super.key,
    required this.game,
    required this.home,
    required this.away,
    required this.homeWinChance,
    required this.onSelect,
    this.selectedTeamId,
  });

  final GameStats game;
  final Team home;
  final Team away;
  final double homeWinChance;
  final String? selectedTeamId;
  final void Function(Team team, double winChance) onSelect;

  @override
  Widget build(BuildContext context) {
    final awayWinChance = 1 - homeWinChance;
    final kickoff = game.startTime.toLocal();
    final when =
        '${_weekday(kickoff.weekday)}  ·  ${_two(kickoff.hour)}:${_two(kickoff.minute)}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            Color(home.primaryColor).withValues(alpha: 0.16),
            AppColors.surface,
            Color(away.primaryColor).withValues(alpha: 0.16),
          ],
        ),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${game.sport.shortLabel}  ·  ${game.venue ?? 'TBD'}',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              Text(
                when,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _TeamIdentity(team: away, alignEnd: false)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'VS',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Expanded(child: _TeamIdentity(team: home, alignEnd: true)),
            ],
          ),
          const SizedBox(height: 16),
          _ChanceBar(home: home, away: away, homeWinChance: homeWinChance),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _OddsButton(
                  team: away,
                  chance: awayWinChance,
                  selected: selectedTeamId == away.id,
                  onTap: () => onSelect(away, awayWinChance),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OddsButton(
                  team: home,
                  chance: homeWinChance,
                  selected: selectedTeamId == home.id,
                  homeTag: true,
                  onTap: () => onSelect(home, homeWinChance),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _weekday(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[weekday - 1];
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}

class _TeamIdentity extends StatelessWidget {
  const _TeamIdentity({required this.team, required this.alignEnd});

  final Team team;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          team.abbreviation,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        Text(
          team.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          team.record,
          style: const TextStyle(
            color: AppColors.gold,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ChanceBar extends StatelessWidget {
  const _ChanceBar({
    required this.home,
    required this.away,
    required this.homeWinChance,
  });

  final Team home;
  final Team away;
  final double homeWinChance;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                Expanded(
                  flex: ((1 - homeWinChance) * 1000).round().clamp(1, 999),
                  child: ColoredBox(color: Color(away.primaryColor)),
                ),
                Expanded(
                  flex: (homeWinChance * 1000).round().clamp(1, 999),
                  child: ColoredBox(color: Color(home.primaryColor)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              '${formatPercent(1 - homeWinChance, decimals: 0)} model',
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
            const Spacer(),
            Text(
              '${formatPercent(homeWinChance, decimals: 0)} model',
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}

class _OddsButton extends StatelessWidget {
  const _OddsButton({
    required this.team,
    required this.chance,
    required this.selected,
    required this.onTap,
    this.homeTag = false,
  });

  final Team team;
  final double chance;
  final bool selected;
  final bool homeTag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final odds = Predictor.americanOdds(Predictor.decimalOdds(chance));
    final border = selected ? AppColors.accent : AppColors.border;
    final fill = selected
        ? AppColors.accent.withValues(alpha: 0.12)
        : AppColors.surfaceHigh;

    return Semantics(
      button: true,
      selected: selected,
      label: '${team.abbreviation} moneyline ${formatAmericanOdds(odds)}',
      child: Material(
        color: fill,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border, width: selected ? 1.6 : 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      team.abbreviation,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: selected ? AppColors.accent : AppColors.text,
                      ),
                    ),
                    if (homeTag) ...[
                      const SizedBox(width: 6),
                      const Text(
                        'HOME',
                        style: TextStyle(
                          fontSize: 9,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      formatAmericanOdds(odds),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: selected ? AppColors.accent : AppColors.gold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  selected ? 'On slip' : 'Add moneyline',
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
