
import 'package:flutter/material.dart';

import '../models/models.dart';
import '../search/stats_search_delegate.dart';
import '../state/stats_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/stats_widgets.dart';
import 'matchup_screen.dart';
import 'team_detail_screen.dart';

enum TeamSelectMode { single, matchup }

/// Select one team for statistics or two teams for comparison.
class TeamSelectScreen extends StatefulWidget {
  const TeamSelectScreen({
    super.key,
    required this.mode,
    this.preselected,
    this.bottomInset = 24,
  });

  final TeamSelectMode mode;
  final Team? preselected;
  final double bottomInset;

  @override
  State<TeamSelectScreen> createState() => _TeamSelectScreenState();
}

class _TeamSelectScreenState extends State<TeamSelectScreen> {
  Team? _a;
  Team? _b;
  League? _league;

  bool get _isMatchup => widget.mode == TeamSelectMode.matchup;

  @override
  void initState() {
    super.initState();

    _a = widget.preselected;
    _league = widget.preselected?.league;
  }

  void _selectLeague(League league) {
    if (_league == league) return;

    setState(() {
      _league = league;
      _a = null;
      _b = null;
    });
  }

  void _onTeamTap(Team team) {
    if (!_isMatchup) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TeamDetailScreen(team: team),
        ),
      );
      return;
    }

    setState(() {
      if (_a == team) {
        _a = null;
      } else if (_b == team) {
        _b = null;
      } else if (_a == null) {
        _a = team;
      } else {
        _b = team;
      }
    });
  }

  void _openMatchup() {
    if (_a == null || _b == null) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MatchupScreen(
          teamA: _a!,
          teamB: _b!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = StatsScope.of(context);
    final leagues = repo.leagues;

    if (leagues.isEmpty) {
      return Scaffold(
        appBar: PillAppBar(
          title: _isMatchup ? 'Head-to-Head' : 'Team Stats',
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.groups_outlined, size: 48),
                SizedBox(height: 12),
                Text(
                  'No teams available',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Team data could not be loaded. Please try again later.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final league = _league != null && leagues.contains(_league)
        ? _league!
        : leagues.first;

    final conferences = repo.teamsByConference(league);

    return Scaffold(
      appBar: PillAppBar(
        title: _isMatchup ? 'Head-to-Head' : 'Team Stats',
        actions: [
          RoundIconButton(
            tooltip: 'Search teams and players',
            icon: Icons.search_rounded,
            onPressed: () {
              showSearch(
                context: context,
                delegate: StatsSearchDelegate(),
              );
            },
          ),
        ],
      ),

      bottomNavigationBar: _isMatchup
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 688),
                    child: FilledButton.icon(
                      onPressed: _a != null && _b != null
                          ? _openMatchup
                          : null,
                      icon: const Icon(
                        Icons.compare_arrows_rounded,
                      ),
                      label: const Text('Compare teams'),
                    ),
                  ),
                ),
              ),
            )
          : null,

      body: ContentWidth(
        child: SingleChildScrollView(
          key: const ValueKey('team_selection_scroll'),
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            widget.bottomInset,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (leagues.length > 1) ...[
                _LeaguePills(
                  leagues: leagues,
                  selected: league,
                  onSelect: _selectLeague,
                ),
                const SizedBox(height: 14),
              ],

              if (_isMatchup) ...[
                StatCard(
                  padding: const EdgeInsets.fromLTRB(
                    12,
                    16,
                    12,
                    16,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _Slot(
                          label: 'Team A',
                          team: _a,
                          onClear: () {
                            setState(() {
                              _a = null;
                            });
                          },
                        ),
                      ),

                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          'VS',
                          style: TextStyle(
                            color: AppColors.onInk,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      Expanded(
                        child: _Slot(
                          label: 'Team B',
                          team: _b,
                          onClear: () {
                            setState(() {
                              _b = null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  _isMatchup
                      ? 'Tap two ${league.label} teams. '
                          'Tap a selected team again to remove it.'
                      : 'Choose a ${league.label} team to see its season.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              if (conferences.isEmpty)
                const StatCard(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 32),
                        SizedBox(height: 12),
                        Text(
                          'No teams in this league',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Try selecting another league.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

              for (final entry in conferences.entries) ...[
                SectionTitle('${entry.key} Conference'),

                StatCard(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: [
                      for (final team in entry.value)
                        _TeamRow(
                          key: ValueKey('team_row_${team.id}'),
                          team: team,
                          selectedAs: team == _a
                              ? 'A'
                              : team == _b
                                  ? 'B'
                                  : null,
                          showChevron: !_isMatchup,
                          onTap: () => _onTeamTap(team),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// NFL and NCAA league selection.
class _LeaguePills extends StatelessWidget {
  const _LeaguePills({
    required this.leagues,
    required this.selected,
    required this.onSelect,
  });

  final List<League> leagues;
  final League selected;
  final ValueChanged<League> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final league in leagues) ...[
            if (league != leagues.first)
              const SizedBox(width: 8),

            Tooltip(
              message: league.level,
              child: Material(
                color: league == selected
                    ? AppColors.ink
                    : AppColors.surface,
                shape: StadiumBorder(
                  side: BorderSide(
                    color: AppColors.border,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: ValueKey('league_${league.name}'),
                  onTap: () => onSelect(league),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      league == selected ? 5 : 20,
                      5,
                      20,
                      5,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (league == selected) ...[
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.onInk,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              league.isAmateur
                                  ? Icons.school_outlined
                                  : Icons.sports_football,
                              size: 20,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],

                        SizedBox(
                          height: 40,
                          child: Center(
                            child: Text(
                              league.label,
                              style: TextStyle(
                                color: league == selected
                                    ? AppColors.onInk
                                    : AppColors.text,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Displays a selected team or an empty selection slot.
class _Slot extends StatelessWidget {
  const _Slot({
    required this.label,
    required this.team,
    required this.onClear,
  });

  final String label;
  final Team? team;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final selectedTeam = team;

    return Column(
      children: [
        SizedBox(
          width: 72,
          height: 72,
          child: selectedTeam == null
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceHigh,
                    border: Border.all(
                      color: AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: AppColors.muted,
                  ),
                )
              : Stack(
                  clipBehavior: Clip.none,
                  children: [
                    TeamBadge(
                      team: selectedTeam,
                      size: 72,
                    ),

                    Positioned(
                      right: -10,
                      top: -10,
                      child: IconButton(
                        tooltip:
                            'Remove ${selectedTeam.name}',
                        onPressed: onClear,
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 14,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.ink,
                          foregroundColor: AppColors.onInk,
                          minimumSize: const Size.square(26),
                          fixedSize: const Size.square(26),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
        ),

        const SizedBox(height: 8),

        Text(
          selectedTeam?.name ?? label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selectedTeam == null
                ? AppColors.muted
                : AppColors.text,
          ),
        ),

        Text(
          selectedTeam?.record ?? 'Pick a team',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Individual selectable team row.
class _TeamRow extends StatelessWidget {
  const _TeamRow({
    super.key,
    required this.team,
    required this.onTap,
    this.selectedAs,
    this.showChevron = false,
  });

  final Team team;
  final VoidCallback onTap;
  final String? selectedAs;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final selected = selectedAs != null;

    return ListTile(
      onTap: onTap,
      selected: selected,
      selectedTileColor: AppColors.surfaceHigh,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 2,
      ),

      leading: TeamBadge(
        team: team,
        size: 46,
      ),

      title: Text(
        team.displayName,
        key: ValueKey('team_name_${team.id}'),
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
      ),

      subtitle: Text(
        '${team.record} · '
        '${team.stat('ppg').toStringAsFixed(1)} PPG · '
        '${team.stat('papg').toStringAsFixed(1)} allowed',
        style: TextStyle(
          color: AppColors.muted,
          fontSize: 12,
        ),
      ),

      trailing: selected
          ? CircleAvatar(
              radius: 15,
              backgroundColor: AppColors.ink,
              child: Text(
                selectedAs!,
                style: TextStyle(
                  color: AppColors.onInk,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          : showChevron
              ? Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.muted,
                )
              : null,
    );
  }
}
