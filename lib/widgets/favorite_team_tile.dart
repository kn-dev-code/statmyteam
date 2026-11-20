import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'team_badge.dart';

class FavoriteTeamTile extends StatelessWidget {
  const FavoriteTeamTile({super.key, required this.team, required this.onTap});

  final Team team;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pct = (team.winPercentage * 100).round();
    return Material(
      color: context.colors.surface,
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
                  // Shrinks instead of overflowing at large text sizes.
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        team.record,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          letterSpacing: -0.5,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.l10n.percent(team.winPercentage),
                    style: TextStyle(
                      color: pct >= 50
                          ? context.colors.accent
                          : context.colors.danger,
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
                  color: pct >= 50
                      ? context.colors.accent
                      : context.colors.danger,
                  backgroundColor: context.colors.surfaceHigh,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
