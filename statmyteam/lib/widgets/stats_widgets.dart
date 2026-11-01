import 'package:flutter/material.dart';

import '../logic/football_stats.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

/// A team color that stays readable on the dark surfaces.
Color teamColor(Team team) {
  final primary = Color(team.primaryColor);
  if (primary.computeLuminance() > 0.08) return primary;
  return Color(team.secondaryColor);
}

/// Circular abbreviation badge in the team's colors.
class TeamBadge extends StatelessWidget {
  const TeamBadge({super.key, required this.team, this.size = 44});

  final Team team;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = teamColor(team);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        team.abbreviation,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.28,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Rounded card used across the stats screens.
class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    // Material (not a decorated Container) so ListTile ink and selection
    // colors inside the card stay visible.
    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 13),
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

/// Small pill showing whether a player will play.
class PlayerStatusChip extends StatelessWidget {
  const PlayerStatusChip({super.key, required this.status, this.compact = false});

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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        compact ? status.shortLabel : status.label,
        style: TextStyle(
          color: color,
          fontSize: 11,
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
    final colorA = teamColor(teamA);
    final colorB = teamColor(teamB);
    final pctA = (teamAChance * 100).round();
    final pctB = 100 - pctA;

    Widget label(Team team, int pct, Color color, CrossAxisAlignment align) {
      return Column(
        crossAxisAlignment: align,
        children: [
          Text(
            '$pct%',
            style: TextStyle(
              color: color,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            team.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
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
                child: label(teamA, pctA, colorA, CrossAxisAlignment.start),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: label(teamB, pctB, colorB, CrossAxisAlignment.end),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Expanded(
                    flex: pctA.clamp(1, 99),
                    child: ColoredBox(color: colorA),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: pctB.clamp(1, 99),
                    child: ColoredBox(color: colorB),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
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
    final bothPresent = a != null && b != null;
    final aBetter = bothPresent && a != b && ((a > b) == def.higherIsBetter);
    final bBetter = bothPresent && a != b && !aBetter;

    // Bar share: for "lower is better" stats invert so the better side wins
    // more of the bar.
    double shareA = 0.5;
    if (bothPresent) {
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

    TextStyle valueStyle(bool better, Color color) => TextStyle(
          fontSize: 15,
          fontWeight: better ? FontWeight.w900 : FontWeight.w500,
          color: better ? color : AppColors.text.withValues(alpha: 0.7),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 72,
                child: Text(
                  a == null ? '—' : def.format(a),
                  style: valueStyle(aBetter, colorA),
                ),
              ),
              Expanded(
                child: Text(
                  def.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ),
              SizedBox(
                width: 72,
                child: Text(
                  b == null ? '—' : def.format(b),
                  textAlign: TextAlign.right,
                  style: valueStyle(bBetter, colorB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 6,
              child: bothPresent
                  ? Row(
                      children: [
                        Expanded(
                          flex: flexA,
                          child: ColoredBox(
                            color: aBetter
                                ? colorA
                                : colorA.withValues(alpha: 0.35),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          flex: 1000 - flexA,
                          child: ColoredBox(
                            color: bBetter
                                ? colorB
                                : colorB.withValues(alpha: 0.35),
                          ),
                        ),
                      ],
                    )
                  : const ColoredBox(color: AppColors.surfaceHigh),
            ),
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
      return const Text('No games yet',
          style: TextStyle(color: AppColors.muted));
    }
    return Wrap(
      spacing: 6,
      children: [
        for (final game in games)
          _chip(game.winnerTeamId == teamId
              ? 'W'
              : (game.winnerTeamId == null ? 'T' : 'L')),
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
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        result,
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
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
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug',
      'Sep', 'Oct', 'Nov', 'Dec'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              '${months[d.month - 1]} ${d.day}\n${d.year}',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
          Text(isHome ? 'vs ' : '@ ',
              style: const TextStyle(color: AppColors.muted)),
          TeamBadge(team: opponent, size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              opponent.displayName,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${won ? 'W' : 'L'} $mine–$theirs',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: won ? AppColors.accent : AppColors.danger,
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
