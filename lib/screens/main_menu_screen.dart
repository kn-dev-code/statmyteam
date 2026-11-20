import 'package:flutter/material.dart';

import '../data/stats_repository.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import '../search/stats_search_delegate.dart';
import '../state/favorites_scope.dart';
import '../state/stats_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/matchup_card.dart';
import '../widgets/stats_widgets.dart';
import 'settings_tab.dart';
import 'sports_selection_screen.dart';
import 'team_detail_screen.dart';
import 'team_select_screen.dart';
import 'upcoming_games_screen.dart';

/// App home: a floating pill nav over four tabs (Home, Teams, Saved,
/// Settings).
class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int _tab = 0;

  /// Tabs opened so far. A tab is built on first visit and then kept alive,
  /// so the Teams tab keeps its sport, league, scroll position, and "show
  /// hidden" switch when the user comes back to it.
  final Set<int> _visited = {0};

  void _select(int i) => setState(() {
    _tab = i;
    _visited.add(i);
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = [
      FloatingNavItem(icon: Icons.home_outlined, label: l10n.navHome),
      FloatingNavItem(icon: Icons.shield_outlined, label: l10n.navTeams),
      FloatingNavItem(
        icon: Icons.bookmark_border_rounded,
        label: l10n.navSaved,
      ),
      FloatingNavItem(icon: Icons.tune_rounded, label: l10n.navSettings),
    ];

    // IndexedStack keeps visited tabs alive; hidden tabs are offstage, so
    // finders and screen readers only see the visible one.
    final body = IndexedStack(
      index: _tab,
      children: [
        for (var i = 0; i < items.length; i++)
          if (!_visited.contains(i))
            const SizedBox.shrink()
          else
            // Offstage tabs keep their state but pause animations.
            TickerMode(
              enabled: i == _tab,
              child: switch (i) {
                0 => _HomeTab(
                  onViewSaved: () => _select(2),
                  onOpenSettings: () => _select(3),
                ),
                1 => const TeamSelectScreen(
                  mode: TeamSelectMode.single,
                  bottomInset: FloatingNavBar.clearance,
                ),
                2 => const _SavedTab(),
                _ => const SettingsTab(),
              },
            ),
      ],
    );

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
                    items: items,
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

void _search(BuildContext context) => StatsSearchDelegate.open(context);

/// Per-league detail behind the home "feed unavailable" banner. Shows a
/// plain-language reason; technical detail stays in the logs.
void _showFeedProblems(BuildContext context, StatsRepository repo) {
  showDialog<void>(
    context: context,
    builder: (context) {
      final l10n = context.l10n;
      return AlertDialog(
        title: Text(l10n.feedProblemsTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final MapEntry(key: league, value: failure)
                  in repo.loadErrors.entries) ...[
                Text(
                  l10n.feedShowingSample(league.label),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(l10n.failure(failure)),
                const SizedBox(height: 12),
              ],
              for (final MapEntry(key: league, value: gaps)
                  in repo.loadWarnings.entries) ...[
                Text(
                  l10n.feedLiveIncomplete(league.label),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                for (final gap in gaps) Text(l10n.gap(gap)),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
        ],
      );
    },
  );
}

/// Saved matchups as team pairs, skipping ids no longer in the data set.
List<(Team, Team)> _savedMatchups(BuildContext context) {
  final repo = StatsScope.of(context);
  final favorites = FavoritesScope.of(context);
  return [
    for (final key in favorites.matchupIds)
      if (key.split('|') case [final a, final b])
        if ((repo.findTeamById(a), repo.findTeamById(b)) case (
          final teamA?,
          final teamB?,
        ))
          (teamA, teamB),
  ];
}

List<Team> _favoriteTeams(BuildContext context) {
  final repo = StatsScope.of(context);
  final favorites = FavoritesScope.of(context);
  return [for (final id in favorites.ids) ?repo.findTeamById(id)]
    ..sort((a, b) => b.winPercentage.compareTo(a.winPercentage));
}

/// The two best records in [league], in one pass.
(Team, Team)? _topTwo(StatsRepository repo, League league) {
  Team? first;
  Team? second;
  for (final team in repo.teams) {
    if (team.league != league) continue;
    if (first == null || team.winPercentage > first.winPercentage) {
      second = first;
      first = team;
    } else if (second == null || team.winPercentage > second.winPercentage) {
      second = team;
    }
  }
  return first != null && second != null ? (first, second) : null;
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: Text(
            context.l10n.appTitle,
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: -0.6,
            ),
          ),
        ),
        const ExcludeSemantics(
          child: Text(
            '.',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.orange,
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.onViewSaved, required this.onOpenSettings});

  final VoidCallback onViewSaved;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final repo = StatsScope.of(context);
    final favoriteTeams = _favoriteTeams(context);
    final savedMatchups = _savedMatchups(context);

    // Feature a saved matchup if there is one, otherwise the two best
    // records in the first league.
    (Team, Team)? featured;
    var featuredEyebrow = l10n.featuredSaved;
    if (savedMatchups.isNotEmpty) {
      featured = savedMatchups.first;
    } else if (repo.leagues.isNotEmpty) {
      final league = repo.leagues.first;
      featured = _topTwo(repo, league);
      featuredEyebrow = l10n.featuredTop(league.label);
    }

    // The header has fixed-size buttons; on narrow screens or with large
    // text, drop the season label so the wordmark keeps some room.
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final roomy = MediaQuery.sizeOf(context).width / textScale >= 420;
    final season = repo.teams.isEmpty || !roomy
        ? null
        : repo.teams.first.season;

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
              tooltip: l10n.newHeadToHead,
              onPressed: () => _open(
                context,
                const SportsSelectionScreen(mode: TeamSelectMode.matchup),
              ),
            ),
          ],
        ),
        actions: [
          RoundIconButton(
            icon: Icons.brightness_6_outlined,
            tooltip: l10n.openThemeSettings,
            onPressed: onOpenSettings,
          ),
          RoundIconButton(
            icon: Icons.search_rounded,
            tooltip: l10n.searchTeamsPlayers,
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
            if (repo.loadErrors.isNotEmpty || repo.loadWarnings.isNotEmpty) ...[
              _FeedBanner(repo: repo),
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
                      title: l10n.headToHeadTitle,
                      subtitle: l10n.headToHeadSubtitle,
                      dark: true,
                      onTap: () => _open(
                        context,
                        const SportsSelectionScreen(
                          mode: TeamSelectMode.matchup,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.shield_outlined,
                      title: l10n.teamStatsTitle,
                      subtitle: l10n.teamStatsSubtitle,
                      onTap: () => _open(
                        context,
                        const SportsSelectionScreen(
                          mode: TeamSelectMode.single,
                        ),
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
                    color: context.colors.surfaceHigh,
                  ),
                  child: Icon(
                    Icons.calendar_month_rounded,
                    color: context.colors.ink,
                  ),
                ),
                title: Text(
                  l10n.upcomingGamesTitle,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  l10n.upcomingGamesSubtitle,
                  style: TextStyle(color: context.colors.muted, fontSize: 12.5),
                ),
                trailing: Icon(
                  Icons.arrow_forward_rounded,
                  color: context.colors.muted,
                ),
              ),
            ),
            SectionTitle(
              l10n.favoriteTeams,
              subtitle: favoriteTeams.isEmpty
                  ? l10n.favoriteTeamsEmptyHint
                  : null,
              trailing: favoriteTeams.isEmpty
                  ? null
                  : SectionLink(l10n.viewAll, onTap: onViewSaved),
            ),
            if (favoriteTeams.isEmpty)
              _EmptyCard(
                icon: Icons.star_border_rounded,
                text: l10n.noFavorites,
              )
            else
              _FavoritesGrid(teams: favoriteTeams),
            SectionTitle(
              l10n.savedMatchups,
              subtitle: savedMatchups.isEmpty
                  ? l10n.savedMatchupsEmptyHint
                  : null,
            ),
            if (savedMatchups.isEmpty)
              _EmptyCard(
                icon: Icons.bookmark_border_rounded,
                text: l10n.noSavedMatchups,
              )
            else
              for (final (a, b) in savedMatchups) ...[
                MatchupCard(teamA: a, teamB: b),
                const SizedBox(height: 12),
              ],
            const SizedBox(height: 20),
            Text(
              !repo.isLive
                  ? l10n.dataSourceSample
                  : repo.sampleLeagues.isEmpty
                  ? l10n.dataSourceAllLive
                  : l10n.dataSourceMixed(
                      l10n.leagues(repo.liveLeagues),
                      l10n.leagues(repo.sampleLeagues),
                      repo.sampleLeagues.length,
                    ),
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Orange banner shown when some live feeds failed; opens the details.
class _FeedBanner extends StatelessWidget {
  const _FeedBanner({required this.repo});

  final StatsRepository repo;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = [
      if (repo.loadErrors.isNotEmpty)
        l10n.feedBannerUnavailable(
          repo.loadErrors.length,
          l10n.leagues(repo.loadErrors.keys),
        ),
      if (repo.loadWarnings.isNotEmpty)
        l10n.feedBannerMissing(l10n.leagues(repo.loadWarnings.keys)),
    ].join(' ');

    return Semantics(
      hint: l10n.feedBannerHint,
      child: StatCard(
        color: AppColors.orange.withValues(alpha: 0.16),
        padding: EdgeInsets.zero,
        // InkWell (not GestureDetector) for focus, keyboard activation,
        // ripple, and button semantics.
        child: InkWell(
          onTap: () => _showFeedProblems(context, repo),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 18,
                  color: context.colors.gold,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(text, style: const TextStyle(fontSize: 13)),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: context.colors.muted,
                ),
              ],
            ),
          ),
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
    // Square tiles, but never shorter than the content needs at the user's
    // text size (a fixed aspect ratio overflows at large text scales).
    const spacing = 12.0;
    const baseContentHeight = 160.0;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - spacing) / 2;
        final extent = tileWidth > baseContentHeight * textScale
            ? tileWidth
            : baseContentHeight * textScale;
        return _grid(extent);
      },
    );
  }

  Widget _grid(double extent) {
    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: teams.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: extent,
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
    final fg = dark ? context.colors.onInk : context.colors.text;
    return Material(
      color: dark ? context.colors.ink : context.colors.surface,
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
                      color: dark
                          ? AppColors.orange
                          : context.colors.surfaceHigh,
                    ),
                    child: Icon(
                      icon,
                      color: dark ? Colors.white : context.colors.ink,
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
                      ? context.colors.onInk.withValues(alpha: 0.6)
                      : context.colors.muted,
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
              color: context.colors.surfaceHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: context.colors.muted),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(text, style: TextStyle(color: context.colors.muted)),
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
    final l10n = context.l10n;
    final favorites = FavoritesScope.of(context);
    final teams = _favoriteTeams(context);
    final matchups = _savedMatchups(context);

    return Scaffold(
      appBar: PillAppBar(
        title: l10n.savedTitle,
        actions: [
          RoundIconButton(
            icon: Icons.search_rounded,
            tooltip: l10n.searchTeamsPlayers,
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
            SectionTitle(
              l10n.favoriteTeams,
              subtitle: l10n.pinnedCount(teams.length),
            ),
            if (teams.isEmpty)
              _EmptyCard(
                icon: Icons.star_border_rounded,
                text: l10n.noFavorites,
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
                          l10n.recordWinRate(
                            team.record,
                            (team.winPercentage * 100).round(),
                          ),
                          style: TextStyle(
                            color: context.colors.muted,
                            fontSize: 12.5,
                          ),
                        ),
                        trailing: IconButton(
                          tooltip: l10n.removeFavorite,
                          icon: const Icon(
                            Icons.star_rounded,
                            color: AppColors.orange,
                          ),
                          onPressed: () => saveWithFeedback(
                            context,
                            () => favorites.toggle(team.id),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            SectionTitle(
              l10n.savedMatchups,
              subtitle: l10n.bookmarkedCount(matchups.length),
            ),
            if (matchups.isEmpty)
              _EmptyCard(
                icon: Icons.bookmark_border_rounded,
                text: l10n.noSavedMatchups,
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
