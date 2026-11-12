import 'package:flutter/material.dart';

import '../models/team.dart';
import '../search/stats_search_delegate.dart';
import '../state/favorites_scope.dart';
import '../state/stats_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/matchup_card.dart';
import '../widgets/stats_widgets.dart';
import 'settings_tab.dart';
import 'team_detail_screen.dart';
import 'team_select_screen.dart';
import 'upcoming_games_screen.dart';

/// App home: a floating pill nav over three tabs (Home, Teams, Saved).
class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int _tab = 0;

  static const _items = [
    FloatingNavItem(icon: Icons.home_outlined, label: 'Home'),
    FloatingNavItem(icon: Icons.shield_outlined, label: 'Teams'),
    FloatingNavItem(icon: Icons.bookmark_border_rounded, label: 'Saved'),
    FloatingNavItem(icon: Icons.tune_rounded, label: 'Settings'),
  ];

  void _select(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    // Only the visible tab is built so text finders and semantics see one
    // copy of shared sections like "Favorite teams".
    final body = switch (_tab) {
      0 => _HomeTab(onViewSaved: () => _select(2)),
      1 => const TeamSelectScreen(
        mode: TeamSelectMode.single,
        bottomInset: FloatingNavBar.clearance,
      ),
      2 => const _SavedTab(),
      _ => const SettingsTab(),
    };

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: body),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Center(
                  child: FloatingNavBar(
                    items: _items,
                    index: _tab,
                    onSelect: _select,
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

void _open(BuildContext context, Widget screen) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

void _search(BuildContext context) =>
    showSearch(context: context, delegate: StatsSearchDelegate());

/// Saved matchups as team pairs, skipping ids no longer in the data set.
List<(Team, Team)> _savedMatchups(BuildContext context) {
  final repo = StatsScope.of(context);
  final favorites = FavoritesScope.of(context);
  final byId = {for (final t in repo.teams) t.id: t};
  return [
    for (final key in favorites.matchupIds)
      if (key.split('|') case [final a, final b]
          when byId.containsKey(a) && byId.containsKey(b))
        (byId[a]!, byId[b]!),
  ];
}

List<Team> _favoriteTeams(BuildContext context) {
  final repo = StatsScope.of(context);
  final favorites = FavoritesScope.of(context);
  final byId = {for (final t in repo.teams) t.id: t};
  return [for (final id in favorites.ids) ?byId[id]]
    ..sort((a, b) => b.winPercentage.compareTo(a.winPercentage));
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: Text(
            'StatMyTeam',
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: -0.6,
            ),
          ),
        ),
        Text(
          '.',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.orange,
          ),
        ),
      ],
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.onViewSaved});

  final VoidCallback onViewSaved;

  @override
  Widget build(BuildContext context) {
    final repo = StatsScope.of(context);
    final favoriteTeams = _favoriteTeams(context);
    final savedMatchups = _savedMatchups(context);

    // Feature a saved matchup if there is one, otherwise the two best
    // records in the first league.
    (Team, Team)? featured;
    var featuredEyebrow = 'Your saved matchup';
    if (savedMatchups.isNotEmpty) {
      featured = savedMatchups.first;
    } else if (repo.leagues.isNotEmpty) {
      final top =
          repo.teams.where((t) => t.league == repo.leagues.first).toList()
            ..sort((a, b) => b.winPercentage.compareTo(a.winPercentage));
      if (top.length >= 2) featured = (top[0], top[1]);
      featuredEyebrow = 'Top of the ${repo.leagues.first.label}';
    }

    final season = repo.teams.isEmpty ? null : repo.teams.first.season;

    return Scaffold(
      appBar: PillAppBar(
        titleWidget: const _Wordmark(),
        info: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (season != null) ...[
              Text(
                season,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
            ],
            RoundIconButton.accent(
              icon: Icons.add_rounded,
              tooltip: 'New head-to-head',
              onPressed: () => _open(
                context,
                const TeamSelectScreen(mode: TeamSelectMode.matchup),
              ),
            ),
          ],
        ),
        actions: [
          RoundIconButton(
            icon: Icons.search_rounded,
            tooltip: 'Search teams and players',
            onPressed: () => _search(context),
          ),
        ],
      ),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            FloatingNavBar.clearance,
          ),
          children: [
            if (repo.loadError != null) ...[
              StatCard(
                color: AppColors.orange.withValues(alpha: 0.16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      size: 18,
                      color: AppColors.gold,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Live NFL feed unavailable — showing sample data.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (featured != null)
              FeaturedMatchupBanner(
                teamA: featured.$1,
                teamB: featured.$2,
                eyebrow: featuredEyebrow,
              ),
            const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.compare_arrows_rounded,
                      title: 'Head-to-Head',
                      subtitle:
                          'Compare two teams and see who is projected '
                          'to win',
                      dark: true,
                      onTap: () => _open(
                        context,
                        const TeamSelectScreen(mode: TeamSelectMode.matchup),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.shield_outlined,
                      title: 'Team Stats',
                      subtitle: 'Season numbers, form, roster, and injuries',
                      onTap: () => _open(
                        context,
                        const TeamSelectScreen(mode: TeamSelectMode.single),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            StatCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                onTap: () => _open(context, const UpcomingGamesScreen()),
                leading: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceHigh,
                  ),
                  child: Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.ink,
                  ),
                ),
                title: const Text(
                  'Upcoming games',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  'Choose a scheduled game to compare both teams instantly',
                  style: TextStyle(color: AppColors.muted, fontSize: 12.5),
                ),
                trailing: Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.muted,
                ),
              ),
            ),
            SectionTitle(
              'Favorite teams',
              subtitle: favoriteTeams.isEmpty
                  ? 'Star a team on its profile to pin it here'
                  : null,
              trailing: favoriteTeams.isEmpty
                  ? null
                  : SectionLink('View all', onTap: onViewSaved),
            ),
            if (favoriteTeams.isEmpty)
              const _EmptyCard(
                icon: Icons.star_border_rounded,
                text: 'No favorites yet. Open any team and tap the star.',
              )
            else
              _FavoritesGrid(teams: favoriteTeams),
            SectionTitle(
              'Saved matchups',
              subtitle: savedMatchups.isEmpty
                  ? 'Bookmark a head-to-head to see it here'
                  : null,
            ),
            if (savedMatchups.isEmpty)
              const _EmptyCard(
                icon: Icons.bookmark_border_rounded,
                text:
                    'No saved matchups yet. Open a matchup and tap the '
                    'bookmark.',
              )
            else
              for (final (a, b) in savedMatchups) ...[
                MatchupCard(teamA: a, teamB: b),
                const SizedBox(height: 12),
              ],
            const SizedBox(height: 20),
            Text(
              repo.isLive
                  ? 'NFL teams and rosters load from ESPN. NCAA sample data '
                        'remains available for college browsing.'
                  : 'Sample league data: teams and players are fictional '
                        'while testing.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoritesGrid extends StatelessWidget {
  const _FavoritesGrid({required this.teams});

  final List<Team> teams;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: teams.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) {
        final team = teams[index];
        return FavoriteTeamTile(
          team: team,
          onTap: () => _open(context, TeamDetailScreen(team: team)),
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.dark = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? AppColors.onInk : AppColors.text;
    return Material(
      color: dark ? AppColors.ink : AppColors.surface,
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
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dark ? AppColors.orange : AppColors.surfaceHigh,
                    ),
                    child: Icon(
                      icon,
                      color: dark ? Colors.white : AppColors.ink,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 20,
                    color: fg.withValues(alpha: 0.5),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: TextStyle(
                  color: fg,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: dark
                      ? AppColors.onInk.withValues(alpha: 0.6)
                      : AppColors.muted,
                  fontSize: 12.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return StatCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.muted),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(text, style: TextStyle(color: AppColors.muted)),
          ),
        ],
      ),
    );
  }
}

/// Every pinned team and bookmarked matchup in one place.
class _SavedTab extends StatelessWidget {
  const _SavedTab();

  @override
  Widget build(BuildContext context) {
    final favorites = FavoritesScope.of(context);
    final teams = _favoriteTeams(context);
    final matchups = _savedMatchups(context);

    return Scaffold(
      appBar: PillAppBar(
        title: 'Saved',
        actions: [
          RoundIconButton(
            icon: Icons.search_rounded,
            tooltip: 'Search teams and players',
            onPressed: () => _search(context),
          ),
        ],
      ),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            FloatingNavBar.clearance,
          ),
          children: [
            SectionTitle('Favorite teams', subtitle: '${teams.length} pinned'),
            if (teams.isEmpty)
              const _EmptyCard(
                icon: Icons.star_border_rounded,
                text: 'No favorites yet. Open any team and tap the star.',
              )
            else
              StatCard(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    for (final team in teams)
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        onTap: () =>
                            _open(context, TeamDetailScreen(team: team)),
                        leading: TeamBadge(team: team, size: 44),
                        title: Text(
                          team.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${team.record} · '
                          '${(team.winPercentage * 100).round()}% win rate',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12.5,
                          ),
                        ),
                        trailing: IconButton(
                          tooltip: 'Remove favorite',
                          icon: const Icon(
                            Icons.star_rounded,
                            color: AppColors.orange,
                          ),
                          onPressed: () => favorites.toggle(team.id),
                        ),
                      ),
                  ],
                ),
              ),
            SectionTitle(
              'Saved matchups',
              subtitle: '${matchups.length} bookmarked',
            ),
            if (matchups.isEmpty)
              const _EmptyCard(
                icon: Icons.bookmark_border_rounded,
                text:
                    'No saved matchups yet. Open a matchup and tap the '
                    'bookmark.',
              )
            else
              for (final (a, b) in matchups) ...[
                MatchupCard(teamA: a, teamB: b),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }
}
