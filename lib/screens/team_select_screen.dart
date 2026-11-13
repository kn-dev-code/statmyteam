import 'package:flutter/material.dart';

import '../models/models.dart';
import '../search/stats_search_delegate.dart';
import '../state/favorites_scope.dart';
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
    this.sport,
    this.bottomInset = 24,
  });

  final TeamSelectMode mode;
  final Team? preselected;

  /// When set, only that sport's teams are listed.
  final Sport? sport;
  final double bottomInset;

  @override
  State<TeamSelectScreen> createState() => _TeamSelectScreenState();
}

class _TeamSelectScreenState extends State<TeamSelectScreen> {
  Team? _a;
  Team? _b;
  League? _league;
  Sport? _sport;

  bool _showHidden = false;
  bool _savingHidden = false;

  bool get _isMatchup => widget.mode == TeamSelectMode.matchup;

  @override
  void initState() {
    super.initState();
    _a = widget.preselected;
    _league = widget.preselected?.league;
    _sport = widget.sport ?? widget.preselected?.sport;
  }

  void _selectSport(Sport sport) {
    if (_sport == sport) return;

    setState(() {
      _sport = sport;
      _league = null;
      _a = null;
      _b = null;
    });
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

  Future<void> _setTeamHidden(Team team, bool hidden) async {
    if (_savingHidden) return;

    final store = FavoritesScope.of(context);
    setState(() => _savingHidden = true);

    try {
      await store.setHidden(team.id, hidden);

      if (!mounted) return;

      setState(() {
        if (hidden && _a?.id == team.id) _a = null;
        if (hidden && _b?.id == team.id) _b = null;
      });
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save hidden teams. Try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _savingHidden = false);
      }
    }
  }

  void _clearSelection() {
    setState(() {
      _a = null;
      _b = null;
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
    final sports = repo.sports;

    final sport = _sport != null && sports.contains(_sport)
        ? _sport!
        : (sports.isEmpty ? null : sports.first);

    final leagues = repo.leaguesFor(sport);

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

    final hiddenTeams = FavoritesScope.of(context);
    final allConferences = repo.teamsByConference(
      league,
      sport: sport,
    );

    final conferences = <String, List<Team>>{};

    for (final entry in allConferences.entries) {
      final visible = entry.value.where(
        (team) => _showHidden || !hiddenTeams.isHidden(team.id),
      ).toList();

      if (visible.isNotEmpty) {
        conferences[entry.key] = visible;
      }
    }

    return Scaffold(
      appBar: PillAppBar(
        title: sport == null
            ? (_isMatchup ? 'Head-to-Head' : 'Team Stats')
            : (_isMatchup
                ? '${sport.label} matchup'
                : '${sport.label} teams'),
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_a != null || _b != null) ...[
                          TextButton.icon(
                            key: const ValueKey(
                              'clear_matchup_selection',
                            ),
                            onPressed: _clearSelection,
                            icon: const Icon(
                              Icons.restart_alt_rounded,
                            ),
                            label: const Text('Clear selection'),
                          ),
                          const SizedBox(height: 4),
                        ],
                        FilledButton.icon(
                          onPressed: _a != null && _b != null
                              ? _openMatchup
                              : null,
                          icon: const Icon(
                            Icons.compare_arrows_rounded,
                          ),
                          label: const Text('Compare teams'),
                        ),
                      ],
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
              SwitchListTile.adaptive(
                key: const ValueKey('show_hidden_teams'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Show hidden teams'),
                subtitle: const Text(
                  'Use the eye button beside a team to hide or restore it.',
                ),
                value: _showHidden,
                onChanged: (value) {
                  setState(() => _showHidden = value);
                },
              ),
              const SizedBox(height: 8),
              if (widget.sport == null && sports.length > 1) ...[
                _SportPills(
                  sports: sports,
                  selected: sport!,
                  onSelect: _selectSport,
                ),
                const SizedBox(height: 14),
              ],
              if (leagues.length > 1) ...[
                _LeaguePills(
                  leagues: leagues,
                  selected: league,
                  sport: sport,
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
                            setState(() => _a = null);
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
                            setState(() => _b = null);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Row(
                    children: [
                      Icon(
                        _a != null && _b != null
                            ? Icons.check_circle_outline_rounded
                            : Icons.info_outline_rounded,
                        size: 18,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _a == null && _b == null
                              ? '0 of 2 teams selected — choose Team A.'
                              : _a != null && _b != null
                                  ? '2 of 2 teams selected — ready to compare.'
                                  : _a == null
                                      ? '1 of 2 teams selected — choose Team A.'
                                      : '1 of 2 teams selected — choose Team B.',
                          key: const ValueKey(
                            'matchup_selection_status',
                          ),
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
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
                          'No visible teams',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Turn on Show hidden teams or select another league.',
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
                          scoringLabel: team.sport.scoringLabel,
                          hidden: hiddenTeams.isHidden(team.id),
                          onToggleHidden: _savingHidden
                              ? null
                              : () => _setTeamHidden(
                                    team,
                                    !hiddenTeams.isHidden(team.id),
                                  ),
                          onTap: hiddenTeams.isHidden(team.id)
                              ? null
                              : () => _onTeamTap(team),
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

class _SportPills extends StatelessWidget {
  const _SportPills({
    required this.sports,
    required this.selected,
    required this.onSelect,
  });

  final List<Sport> sports;
  final Sport selected;
  final ValueChanged<Sport> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final sport in sports) ...[
            if (sport != sports.first)
              const SizedBox(width: 8),
            ChoiceChip(
              key: ValueKey('sport_${sport.name}'),
              label: Text(sport.label),
              selected: sport == selected,
              onSelected: (_) => onSelect(sport),
            ),
          ],
        ],
      ),
    );
  }
}

class _LeaguePills extends StatelessWidget {
  const _LeaguePills({
    required this.leagues,
    required this.selected,
    required this.onSelect,
    this.sport,
  });

  final List<League> leagues;
  final League selected;
  final ValueChanged<League> onSelect;
  final Sport? sport;

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
                                  : switch (sport ?? Sport.football) {
                                      Sport.basketball =>
                                        Icons.sports_basketball,
                                      Sport.soccer =>
                                        Icons.sports_soccer,
                                      Sport.baseball =>
                                        Icons.sports_baseball,
                                      Sport.hockey =>
                                        Icons.sports_hockey,
                                      Sport.football =>
                                        Icons.sports_football,
                                    },
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
                        tooltip: 'Remove ${selectedTeam.name}',
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

class _TeamRow extends StatelessWidget {
  const _TeamRow({
    super.key,
    required this.team,
    required this.onTap,
    this.selectedAs,
    this.showChevron = false,
    this.scoringLabel = 'PPG',
    this.hidden = false,
    this.onToggleHidden,
  });

  final Team team;
  final VoidCallback? onTap;
  final String? selectedAs;
  final bool showChevron;
  final String scoringLabel;
  final bool hidden;
  final VoidCallback? onToggleHidden;

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
        '${team.stat('ppg').toStringAsFixed(team.sport == Sport.soccer ? 2 : 1)} '
        '$scoringLabel · '
        '${team.stat('papg').toStringAsFixed(team.sport == Sport.soccer ? 2 : 1)} allowed',
        style: TextStyle(
          color: AppColors.muted,
          fontSize: 12,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: ValueKey('hide_team_${team.id}'),
            tooltip: hidden
                ? 'Restore ${team.displayName}'
                : 'Hide ${team.displayName}',
            icon: Icon(
              hidden
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
            onPressed: onToggleHidden,
          ),
          if (selected)
            CircleAvatar(
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
          else if (showChevron)
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.muted,
            ),
        ],
      ),
    );
  }
}
