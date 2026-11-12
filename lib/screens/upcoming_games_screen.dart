import 'package:flutter/material.dart';

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
    final repo = StatsScope.of(context);
    final sports = Sport.values
        .where((sport) => repo.teams.any((team) => team.sport == sport))
        .toList();
    final sport = sports.contains(_sport)
        ? _sport!
        : (sports.isEmpty ? null : sports.first);
    final leagues = sport == null
        ? <League>[]
        : League.values
              .where((league) => repo.teams.any(
                    (team) => team.sport == sport && team.league == league,
                  ))
              .toList();
    final league = leagues.contains(_league) ? _league : null;
    final games = sport == null
        ? <GameStats>[]
        : repo.upcomingGames(sport: sport, league: league);
    final teamsById = {for (final team in repo.teams) team.id: team};

    return Scaffold(
      appBar: const PillAppBar(title: 'Upcoming games'),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Text(
              'Choose a scheduled game to compare both teams.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            if (sports.length > 1) ...[
              const SectionTitle('Sport'),
              Wrap(
                spacing: 8,
                children: [
                  for (final option in sports)
                    ChoiceChip(
                      label: Text(option.label),
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
              const SectionTitle('League'),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: league == null,
                    onSelected: (_) => setState(() => _league = null),
                  ),
                  for (final option in leagues)
                    ChoiceChip(
                      label: Text(option.label),
                      selected: option == league,
                      onSelected: (_) => setState(() => _league = option),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            if (games.isEmpty)
              StatCard(
                child: Row(
                  children: [
                    const Icon(Icons.event_busy_rounded),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No upcoming ${sport?.label.toLowerCase() ?? 'sport'} '
                        'games are available right now.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                  ],
                ),
              )
            else
              for (final game in games)
                if (teamsById[game.homeTeamId] case final home?)
                  if (teamsById[game.awayTeamId] case final away?) ...[
                    _UpcomingGameTile(
                      game: game,
                      home: home,
                      away: away,
                      league: home.league,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => MatchupScreen(
                            teamA: home,
                            teamB: away,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
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
    required this.league,
    required this.onTap,
  });

  final GameStats game;
  final Team home;
  final Team away;
  final League? league;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final localStart = game.startTime.toLocal();
    final date = MaterialLocalizations.of(context).formatMediumDate(localStart);
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(localStart),
    );

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
              Positioned(left: 0, top: 0, child: TeamBadge(team: away, size: 34)),
              Positioned(right: 0, bottom: 0, child: TeamBadge(team: home, size: 34)),
            ],
          ),
        ),
        title: Text(
          '${away.abbreviation} @ ${home.abbreviation}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${away.name} at ${home.name}\n'
          '$date · $time${game.venue == null ? '' : ' · ${game.venue}'}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (league != null)
              Text(
                league!.label,
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
