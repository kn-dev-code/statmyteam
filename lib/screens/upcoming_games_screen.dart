import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/models.dart';
import '../state/stats_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/stats_widgets.dart';
import 'matchup_screen.dart';

/// Lists scheduled games for a sport and opens a matchup with one tap.
class UpcomingGamesScreen extends StatefulWidget {
  const UpcomingGamesScreen({super.key});

  @override
  State<UpcomingGamesScreen> createState() => _UpcomingGamesScreenState();
}

class _UpcomingGamesScreenState extends State<UpcomingGamesScreen> {
  Sport? _sport;
  League? _league;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final repo = StatsScope.of(context);
    final sports = repo.sports;
    final sport = sports.contains(_sport)
        ? _sport!
        : (sports.isEmpty ? null : sports.first);
    final leagues = sport == null ? const <League>[] : repo.leaguesFor(sport);
    final league = leagues.contains(_league) ? _league : null;
    final games = [
      if (sport != null)
        for (final game in repo.upcomingGames(sport: sport, league: league))
          if ((
                repo.findTeamById(game.homeTeamId),
                repo.findTeamById(game.awayTeamId),
              )
              case (final home?, final away?))
            (game: game, home: home, away: away),
    ];

    return Scaffold(
      appBar: PillAppBar(title: l10n.upcomingGamesTitle),
      body: ContentWidth(
        // Lazy list: a full slate can be dozens of games.
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              sliver: SliverList.list(
                children: [
                  Text(
                    l10n.upcomingIntro,
                    style: TextStyle(color: context.colors.muted, fontSize: 13),
                  ),
                  if (sports.length > 1) ...[
                    SectionTitle(l10n.sportSection),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final option in sports)
                          ChoiceChip(
                            label: Text(l10n.sport(option)),
                            selected: option == sport,
                            onSelected: (_) => setState(() {
                              _sport = option;
                              _league = null;
                            }),
                          ),
                      ],
                    ),
                  ],
                  if (leagues.length > 1) ...[
                    SectionTitle(l10n.leagueSection),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text(l10n.allLeagues),
                          selected: league == null,
                          onSelected: (_) => setState(() => _league = null),
                        ),
                        for (final option in leagues)
                          ChoiceChip(
                            label: Text(option.label),
                            tooltip: l10n.level(option),
                            selected: option == league,
                            onSelected: (_) => setState(() => _league = option),
                          ),
                      ],
                    ),
                  ],
                  if (games.isEmpty) ...[
                    const SizedBox(height: 14),
                    StatCard(
                      child: Row(
                        children: [
                          const Icon(Icons.event_busy_rounded),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.noUpcomingGames(
                                sport == null ? '' : l10n.sport(sport),
                              ),
                              style: TextStyle(color: context.colors.muted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList.separated(
                itemCount: games.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final (:game, :home, :away) = games[index];
                  return _UpcomingGameTile(
                    game: game,
                    home: home,
                    away: away,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => MatchupScreen(teamA: home, teamB: away),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingGameTile extends StatelessWidget {
  const _UpcomingGameTile({
    required this.game,
    required this.home,
    required this.away,
    required this.onTap,
  });

  final GameStats game;
  final Team home;
  final Team away;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localizations = MaterialLocalizations.of(context);
    final localStart = game.startTime.toLocal();
    final date = localizations.formatMediumDate(localStart);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(localStart),
    );
    final when = game.venue == null
        ? l10n.gameWhen(date, time)
        : l10n.gameWhenVenue(date, time, game.venue!);
    final league = home.league;

    return StatCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: SizedBox(
          width: 44,
          height: 56,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                child: TeamBadge(team: away, size: 34),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: TeamBadge(team: home, size: 34),
              ),
            ],
          ),
        ),
        title: Text(
          l10n.gameAtShort(away.abbreviation, home.abbreviation),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${l10n.gameAtLong(away.name, home.name)}\n$when',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: context.colors.muted, fontSize: 12),
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (league != null)
              Text(
                league.label,
                style: TextStyle(
                  color: context.colors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            Icon(Icons.chevron_right_rounded, color: context.colors.muted),
          ],
        ),
      ),
    );
  }
}
