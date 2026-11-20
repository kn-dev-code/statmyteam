import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../logic/sport_stats.dart';
import '../models/models.dart';
import '../state/favorites_scope.dart';
import '../state/stats_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/stats_widgets.dart';
import '../widgets/team_outlook_card.dart';
import 'player_detail_screen.dart';
import 'team_select_screen.dart';

/// One team's season: headline numbers, stats, form, injuries, roster.
class TeamDetailScreen extends StatelessWidget {
  const TeamDetailScreen({super.key, required this.team});

  final Team team;

  static const _recentCount = 5;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final repo = StatsScope.of(context);
    final favorites = FavoritesScope.of(context);
    final injuries = repo.injuryReport(team.id);
    final recent = repo.recentGames(team.id, limit: _recentCount);
    final isFavorite = favorites.isFavorite(team.id);
    final teamStats = SportStats.teamStats(team.sport);

    // Feed ids can point at teams that are not in the data set; skip those
    // results rather than failing the whole screen.
    final results = [
      for (final game in recent)
        if (repo.findTeamById(
              game.homeTeamId == team.id ? game.awayTeamId : game.homeTeamId,
            )
            case final opponent?)
          (game: game, opponent: opponent),
    ];

    final rows = <_RosterEntry>[
      // Sections are cached by the repository; this is just a flat list of
      // references for the lazy sliver below.
      for (final section in repo.rosterSections(team)) ...[
        _RosterHeader(
          section.group != null
              ? l10n.group(section.group!)
              : l10n.positionName(section.position ?? ''),
        ),
        for (final (i, player) in section.players.indexed)
          _RosterPlayer(
            player,
            first: i == 0,
            last: i == section.players.length - 1,
          ),
      ],
    ];

    return Scaffold(
      appBar: PillAppBar(
        title: team.displayName,
        actions: [
          RoundIconButton(
            tooltip: isFavorite ? l10n.removeFavorite : l10n.addFavorite,
            icon: isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
            iconColor: isFavorite ? AppColors.orange : context.colors.ink,
            onPressed: () =>
                saveWithFeedback(context, () => favorites.toggle(team.id)),
          ),
        ],
      ),
      body: ContentWidth(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverList.list(
                children: [
                  _HeaderCard(team: team, recent: recent),
                  SectionTitle(
                    l10n.strengthsWeaknesses,
                    subtitle: l10n.rankedAgainstLeague,
                  ),
                  TeamOutlookCard(outlook: repo.outlookFor(team)),
                  SectionTitle(l10n.seasonStats),
                  StatCard(
                    child: StatGrid(
                      items: [
                        for (final def in teamStats)
                          (
                            label: l10n.stat(def),
                            value: l10n.statValue(def, team.stat(def.key)),
                          ),
                      ],
                    ),
                  ),
                  SectionTitle(
                    l10n.scoringTrend,
                    subtitle: l10n.scoringTrendSubtitle,
                  ),
                  StatCard(
                    child: RecentFormChart(
                      teamId: team.id,
                      games: recent,
                      color: teamColor(context, team),
                    ),
                  ),
                  SectionTitle(l10n.recentResults),
                  StatCard(
                    child: results.isEmpty
                        ? Text(
                            l10n.noRecentResults,
                            style: TextStyle(color: context.colors.muted),
                          )
                        : Column(
                            children: [
                              for (final (:game, :opponent) in results)
                                GameResultTile(
                                  game: game,
                                  teamId: team.id,
                                  opponent: opponent,
                                ),
                            ],
                          ),
                  ),
                  SectionTitle(
                    l10n.injuryReport,
                    subtitle: injuries.isEmpty
                        ? l10n.everyoneAvailable
                        : l10n.playersListed(injuries.length),
                  ),
                  if (injuries.isNotEmpty)
                    StatCard(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        children: [
                          for (final p in injuries) _PlayerTile(player: p),
                        ],
                      ),
                    ),
                  SectionTitle(l10n.roster, subtitle: l10n.rosterSubtitle),
                ],
              ),
            ),
            // Rows build lazily: a college roster can be 100+ players.
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList.builder(
                itemCount: rows.length,
                itemBuilder: (context, index) => switch (rows[index]) {
                  _RosterHeader(:final label) => Padding(
                    padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
                    child: Semantics(
                      header: true,
                      child: Text(
                        label.toUpperCase(),
                        style: TextStyle(
                          color: context.colors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  _RosterPlayer(:final player, :final first, :final last) =>
                    _RosterRow(first: first, last: last, player: player),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Crest, record, last results, and the compare action.
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.team, required this.recent});

  final Team team;
  final List<GameStats> recent;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return StatCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TeamBadge(team: team, size: 72),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.displayName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      [
                        if (team.league != null) team.league!.label,
                        if (team.conference != null)
                          l10n.conferenceTitle(team.conference!),
                        l10n.seasonLabel(team.season),
                      ].join(l10n.dotSeparator),
                      style: TextStyle(color: context.colors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          StatGrid(
            crossAxisCount: 3,
            items: [
              (label: l10n.statRecord, value: team.record),
              (label: l10n.statWinPct, value: l10n.percent(team.winPercentage)),
              (
                label: l10n.statPointDiff,
                value: l10n.decimal(
                  team.stat('ppg') - team.stat('papg'),
                  1,
                  signed: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.lastNGames(TeamDetailScreen._recentCount).toUpperCase(),
            style: TextStyle(
              color: context.colors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          FormStrip(teamId: team.id, games: recent),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TeamSelectScreen(
                  mode: TeamSelectMode.matchup,
                  preselected: team,
                  sport: team.sport,
                ),
              ),
            ),
            icon: const Icon(Icons.compare_arrows_rounded),
            label: Text(l10n.compareAgainstAnother),
          ),
        ],
      ),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListTile(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PlayerDetailScreen(player: player),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.colors.surfaceHigh,
          shape: BoxShape.circle,
        ),
        child: Text(
          '${player.jerseyNumber}',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
      title: Text(
        player.fullName,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        [
          player.position,
          if (player.role case final role?) l10n.role(role),
          ?player.injuryNote,
        ].join(l10n.dotSeparator),
        style: TextStyle(color: context.colors.muted, fontSize: 12),
      ),
      trailing: PlayerStatusChip(status: player.status, compact: true),
    );
  }
}

/// One item in the flattened, lazily built roster list.
sealed class _RosterEntry {
  const _RosterEntry();
}

class _RosterHeader extends _RosterEntry {
  const _RosterHeader(this.label);

  final String label;
}

class _RosterPlayer extends _RosterEntry {
  const _RosterPlayer(this.player, {required this.first, required this.last});

  final Player player;
  final bool first;
  final bool last;
}

/// A player row drawn as one slice of a card, so a section still reads as a
/// single rounded card while each row builds on demand.
class _RosterRow extends StatelessWidget {
  const _RosterRow({
    required this.player,
    required this.first,
    required this.last,
  });

  final Player player;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) {
    const radius = Radius.circular(AppTheme.radius);
    return Material(
      color: context.colors.surface,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.vertical(
        top: first ? radius : Radius.zero,
        bottom: last ? radius : Radius.zero,
      ),
      child: Padding(
        padding: EdgeInsets.only(top: first ? 6 : 0, bottom: last ? 6 : 0),
        child: _PlayerTile(player: player),
      ),
    );
  }
}
