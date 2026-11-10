
import 'package:flutter/material.dart';

import '../search/stats_search_delegate.dart';
import '../models/team.dart';
import '../state/favorites_scope.dart';
import '../state/stats_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/stats_widgets.dart';
import 'team_detail_screen.dart';
import 'matchup_screen.dart';
import 'team_select_screen.dart';
import 'sports_selection_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void open(Widget screen) => Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));

    final repo = StatsScope.of(context);
    final favorites = FavoritesScope.of(context);

    final favoriteTeams = [
      for (final id in favorites.ids)
        if (repo.teams.any((t) => t.id == id)) repo.teamById(id),
    ]..sort((a, b) => b.winPercentage.compareTo(a.winPercentage));

    // Load saved matchups.
    final savedMatchups = <(Team, Team)>[];

    for (final key in favorites.matchupIds) {
      final parts = key.split('|');
      if (parts.length != 2) continue;

      final matchingA =
          repo.teams.where((t) => t.id == parts[0]);
      final matchingB =
          repo.teams.where((t) => t.id == parts[1]);

      if (matchingA.isNotEmpty && matchingB.isNotEmpty) {
        savedMatchups.add(
          (matchingA.first, matchingB.first),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('StatMyTeam'),
        actions: [
          IconButton(
            tooltip: 'Search teams and players',
            icon: const Icon(Icons.search),
            onPressed: () => showSearch(
              context: context,
              delegate: StatsSearchDelegate(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              const Icon(
                Icons.sports_football,
                color: AppColors.accent,
                size: 40,
              ),
              const SizedBox(height: 12),
              const Text(
                'StatMyTeam',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                repo.isLive
                    ? 'Live NFL data · football stats, matchups, and projections'
                    : 'Football stats, matchups, and projections',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 15,
                ),
              ),
              if (repo.loadError != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Live NFL feed unavailable — showing sample data.',
                  style: TextStyle(
                    color: AppColors.gold.withValues(alpha: 0.95),
                    fontSize: 12,
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // FAVORITE TEAMS
              SectionTitle(
                'Favorite teams',
                subtitle: favoriteTeams.isEmpty
                    ? 'Star a team on its profile to pin it here'
                    : 'Season W/L for your pinned clubs',
              ),

              if (favoriteTeams.isEmpty)
                StatCard(
                  child: Text(
                    'No favorites yet. Open any team and tap the star.',
                    style: TextStyle(
                      color: AppColors.muted.withValues(alpha: 0.95),
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: favoriteTeams.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.05,
                  ),
                  itemBuilder: (context, index) {
                    final team = favoriteTeams[index];
                    return FavoriteTeamTile(
                      team: team,
                      onTap: () => open(
                        TeamDetailScreen(team: team),
                      ),
                    );
                  },
                ),

              // ORIGINAL HEAD-TO-HEAD BUTTON
              const SizedBox(height: 12),
              _MenuCard(
                icon: Icons.compare_arrows,
                title: 'Head-to-Head',
                subtitle:
                    'Pick two teams to compare their stats and see who is '
                    'projected to win',
                highlight: true,
                onTap: () => open(
                  const SportsSelectionScreen(
                    mode: TeamSelectMode.matchup,
                  ),
                ),
              ),

              // ORIGINAL TEAM STATS BUTTON
              const SizedBox(height: 12),
              _MenuCard(
                icon: Icons.shield_outlined,
                title: 'Team Stats',
                subtitle:
                    'Season numbers, recent form, roster, and injuries',
                onTap: () => open(
                  const SportsSelectionScreen(
                    mode: TeamSelectMode.single,
                  ),
                ),
              ),

              // NEW FEATURE: SAVED MATCHUPS
              // Placed below existing navigation to preserve widget tests.
              const SizedBox(height: 20),

              SectionTitle(
                'Saved matchups',
                subtitle: savedMatchups.isEmpty
                    ? 'Bookmark a head-to-head comparison to see it here'
                    : 'Tap to reopen a comparison',
              ),

              if (savedMatchups.isEmpty)
                const StatCard(
                  child: Text(
                    'No saved matchups yet. Open a matchup and tap the bookmark.',
                    style: TextStyle(
                      color: AppColors.muted,
                    ),
                  ),
                )
              else
                for (final pair in savedMatchups) ...[
                  _MenuCard(
                    icon: Icons.bookmark,
                    title:
                        '${pair.$1.abbreviation} vs ${pair.$2.abbreviation}',
                    subtitle:
                        '${pair.$1.displayName} vs ${pair.$2.displayName}',
                    onTap: () => open(
                      MatchupScreen(
                        teamA: pair.$1,
                        teamB: pair.$2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

              const SizedBox(height: 28),

              Text(
                repo.isLive
                    ? 'NFL teams and rosters load from ESPN. NCAA sample data '
                        'remains available for college browsing.'
                    : 'Sample league data: teams and players are fictional while '
                        'testing.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                ),
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
      color: highlight
          ? AppColors.surfaceHigh
          : AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: highlight
                  ? AppColors.accent
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: AppColors.accent,
                ),
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
              const Icon(
                Icons.chevron_right,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
