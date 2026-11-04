import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/stats_widgets.dart';
import 'team_select_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void open(Widget screen) => Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));

    return Scaffold(
      body: SafeArea(
        child: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
            children: [
              const Icon(Icons.sports_football, color: AppColors.accent, size: 40),
              const SizedBox(height: 12),
              const Text(
                'StatMyTeam',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              const Text(
                'Football stats, matchups, and projections',
                style: TextStyle(color: AppColors.muted, fontSize: 15),
              ),
              const SizedBox(height: 32),
              _MenuCard(
                icon: Icons.compare_arrows,
                title: 'Head-to-Head',
                subtitle:
                    'Pick two teams to compare their stats and see who is '
                    'projected to win',
                highlight: true,
                onTap: () => open(
                  const TeamSelectScreen(mode: TeamSelectMode.matchup),
                ),
              ),
              const SizedBox(height: 12),
              _MenuCard(
                icon: Icons.shield_outlined,
                title: 'Team Stats',
                subtitle: 'Season numbers, recent form, roster, and injuries',
                onTap: () => open(
                  const TeamSelectScreen(mode: TeamSelectMode.single),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Sample league data: teams and players are fictional while '
                'testing.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlight ? AppColors.surfaceHigh : AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: highlight ? AppColors.accent : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.accent),
              ),
              const SizedBox(width: 16),
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
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
