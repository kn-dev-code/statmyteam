import 'package:flutter/material.dart';

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
