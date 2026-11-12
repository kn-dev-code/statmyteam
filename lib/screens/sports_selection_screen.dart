import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/stats_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/stats_widgets.dart';
import 'team_select_screen.dart';

class SportsSelectionScreen extends StatelessWidget {
  const SportsSelectionScreen({super.key, required this.mode});

  final TeamSelectMode mode;

  static const _comingSoon = {Sport.baseball, Sport.hockey};

  @override
  Widget build(BuildContext context) {
    final repo = StatsScope.of(context);
    final available = {
      for (final sport in repo.sports) sport,
    };

    return Scaffold(
      appBar: const PillAppBar(title: 'Select a sport'),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Text(
              mode == TeamSelectMode.matchup
                  ? 'Choose a sport to compare two teams.'
                  : 'Choose a sport to browse team stats.',
              style: TextStyle(color: AppColors.muted, fontSize: 15),
            ),
            const SizedBox(height: 16),
            for (final sport in Sport.values) ...[
              _SportCard(
                sport: sport,
                enabled: available.contains(sport),
                comingSoon: _comingSoon.contains(sport),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TeamSelectScreen(
                      mode: mode,
                      sport: sport,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _SportCard extends StatelessWidget {
  const _SportCard({
    required this.sport,
    required this.enabled,
    required this.comingSoon,
    required this.onTap,
  });

  final Sport sport;
  final bool enabled;
  final bool comingSoon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (sport) {
      Sport.football => Icons.sports_football,
      Sport.basketball => Icons.sports_basketball,
      Sport.soccer => Icons.sports_soccer,
      Sport.baseball => Icons.sports_baseball,
      Sport.hockey => Icons.sports_hockey,
    };
    final subtitle = comingSoon
        ? 'Coming soon'
        : switch (sport) {
            Sport.football => 'NFL and college teams',
            Sport.basketball => 'NBA clubs',
            Sport.soccer => 'MLS clubs',
            _ => sport.label,
          };

    return StatCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        enabled: enabled && !comingSoon,
        onTap: enabled && !comingSoon ? onTap : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.ink),
        ),
        title: Text(
          sport.menuLabel,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        trailing: Icon(
          enabled && !comingSoon
              ? Icons.arrow_forward_rounded
              : Icons.lock_outline_rounded,
          color: AppColors.muted,
        ),
      ),
    );
  }
}
