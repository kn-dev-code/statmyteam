import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

export 'team_badge.dart';
export 'matchup_stats_widgets.dart';
export 'stats_charts.dart';
export 'favorite_team_tile.dart';

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


