import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
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
        MaterialPageRoute<void>(builder: (_) => TeamDetailScreen(team: team)),
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
    final saved = await saveWithFeedback(
      context,
      () => store.setHidden(team.id, hidden),
      failureMessage: context.l10n.hiddenSaveFailed,
    );
    if (!mounted) return;
    setState(() {
      _savingHidden = false;
      if (saved && hidden && _a?.id == team.id) _a = null;
      if (saved && hidden && _b?.id == team.id) _b = null;
    });
  }

  void _clearSelection() => setState(() {
    _a = null;
    _b = null;
  });

  void _openMatchup() {
    final a = _a;
    final b = _b;
    if (a == null || b == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MatchupScreen(teamA: a, teamB: b),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final repo = StatsScope.of(context);
    final sports = repo.sports;
    final sport = _sport != null && sports.contains(_sport)
        ? _sport!
        : (sports.isEmpty ? null : sports.first);
    final leagues = repo.leaguesFor(sport);
    final defaultTitle = _isMatchup
        ? l10n.headToHeadTitle
        : l10n.teamStatsTitle;

    if (leagues.isEmpty) {
      return Scaffold(
        appBar: PillAppBar(title: defaultTitle),
        body: const _NoTeams(),
      );
    }

    final league = _league != null && leagues.contains(_league)
        ? _league!
        : leagues.first;

    final favorites = FavoritesScope.of(context);
    // Conferences are cached by the repository; only the hidden filter runs
    // per build.
    final conferences = <(String?, List<Team>)>[
      for (final MapEntry(:key, :value)
          in repo.teamsByConference(league, sport: sport).entries)
        if ([
              for (final team in value)
                if (_showHidden || !favorites.isHidden(team.id)) team,
            ]
            case final visible when visible.isNotEmpty)
          (key, visible),
    ];

    final title = sport == null
        ? defaultTitle
        : (_isMatchup
              ? l10n.sportMatchupTitle(l10n.sport(sport))
              : l10n.sportTeamsTitle(l10n.sport(sport)));

    return Scaffold(
      appBar: PillAppBar(
        title: title,
        actions: [
          RoundIconButton(
            tooltip: l10n.searchTeamsPlayers,
            icon: Icons.search_rounded,
            onPressed: () => StatsSearchDelegate.open(context),
          ),
        ],
      ),
      bottomNavigationBar: _isMatchup
          ? _MatchupActions(
              hasSelection: _a != null || _b != null,
              canCompare: _a != null && _b != null,
              onClear: _clearSelection,
              onCompare: _openMatchup,
            )
          : null,
      body: ContentWidth(
        // Slivers so long leagues (130+ college teams) build one conference
        // at a time as they scroll into view.
        child: CustomScrollView(
          key: const ValueKey('team_selection_scroll'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverList.list(
                children: [
                  SwitchListTile.adaptive(
                    key: const ValueKey('show_hidden_teams'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.showHiddenTeams),
                    subtitle: Text(l10n.showHiddenTeamsHint),
                    value: _showHidden,
                    onChanged: (value) => setState(() => _showHidden = value),
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
                    _SelectionPanel(
                      a: _a,
                      b: _b,
                      onClearA: () => setState(() => _a = null),
                      onClearB: () => setState(() => _b = null),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      _isMatchup
                          ? l10n.matchupInstructions(league.label)
                          : l10n.singleInstructions(league.label),
                      style: TextStyle(
                        color: context.colors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (conferences.isEmpty) const _NoVisibleTeams(),
                ],
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, widget.bottomInset),
              sliver: SliverList.builder(
                itemCount: conferences.length,
                itemBuilder: (context, index) {
                  final (conference, teams) = conferences[index];
                  return _ConferenceSection(
                    title: conference == null
                        ? l10n.independentTeams
                        : l10n.conferenceTitle(conference),
                    children: [
                      for (final team in teams)
                        _TeamRow(
                          key: ValueKey('team_row_${team.id}'),
                          team: team,
                          selectedAs: team == _a
                              ? l10n.slotA
                              : team == _b
                              ? l10n.slotB
                              : null,
                          showChevron: !_isMatchup,
                          hidden: favorites.isHidden(team.id),
                          onToggleHidden: _savingHidden
                              ? null
                              : () => _setTeamHidden(
                                  team,
                                  !favorites.isHidden(team.id),
                                ),
                          onTap: favorites.isHidden(team.id)
                              ? null
                              : () => _onTeamTap(team),
                        ),
                    ],
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

class _NoTeams extends StatelessWidget {
  const _NoTeams();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.groups_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              l10n.noTeamsTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(l10n.noTeamsBody, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _NoVisibleTeams extends StatelessWidget {
  const _NoVisibleTeams();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return StatCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            const Icon(Icons.info_outline_rounded, size: 32),
            const SizedBox(height: 12),
            Text(
              l10n.noVisibleTeams,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(l10n.noVisibleTeamsHint, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// "Clear selection" and "Compare teams" pinned under the matchup picker.
class _MatchupActions extends StatelessWidget {
  const _MatchupActions({
    required this.hasSelection,
    required this.canCompare,
    required this.onClear,
    required this.onCompare,
  });

  final bool hasSelection;
  final bool canCompare;
  final VoidCallback onClear;
  final VoidCallback onCompare;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
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
                if (hasSelection) ...[
                  TextButton.icon(
                    key: const ValueKey('clear_matchup_selection'),
                    onPressed: onClear,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: Text(l10n.clearSelection),
                  ),
                  const SizedBox(height: 4),
                ],
                FilledButton.icon(
                  onPressed: canCompare ? onCompare : null,
                  icon: const Icon(Icons.compare_arrows_rounded),
                  label: Text(l10n.compareTeams),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Team A / VS / Team B slots plus a live status line.
class _SelectionPanel extends StatelessWidget {
  const _SelectionPanel({
    required this.a,
    required this.b,
    required this.onClearA,
    required this.onClearB,
  });

  final Team? a;
  final Team? b;
  final VoidCallback onClearA;
  final VoidCallback onClearB;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = switch ((a, b)) {
      (null, null) => l10n.selectionNone,
      (_?, _?) => l10n.selectionReady,
      (null, _) => l10n.selectionNeedA,
      (_, null) => l10n.selectionNeedB,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatCard(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
          child: Row(
            children: [
              Expanded(
                child: _Slot(label: l10n.teamASlot, team: a, onClear: onClearA),
              ),
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.colors.ink,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  l10n.versusShort,
                  style: TextStyle(
                    color: context.colors.onInk,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                child: _Slot(label: l10n.teamBSlot, team: b, onClear: onClearB),
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
                a != null && b != null
                    ? Icons.check_circle_outline_rounded
                    : Icons.info_outline_rounded,
                size: 18,
                color: context.colors.muted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status,
                  key: const ValueKey('matchup_selection_status'),
                  style: TextStyle(
                    color: context.colors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One conference: a heading and a card of team rows.
class _ConferenceSection extends StatelessWidget {
  const _ConferenceSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(title),
        StatCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(children: children),
        ),
      ],
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
            if (sport != sports.first) const SizedBox(width: 8),
            ChoiceChip(
              key: ValueKey('sport_${sport.name}'),
              label: Text(context.l10n.sport(sport)),
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
            if (league != leagues.first) const SizedBox(width: 8),
            _LeaguePill(
              league: league,
              selected: league == selected,
              sport: sport,
              onTap: () => onSelect(league),
            ),
          ],
        ],
      ),
    );
  }
}

class _LeaguePill extends StatelessWidget {
  const _LeaguePill({
    required this.league,
    required this.selected,
    required this.onTap,
    this.sport,
  });

  final League league;
  final bool selected;
  final VoidCallback onTap;
  final Sport? sport;

  @override
  Widget build(BuildContext context) {
    final icon = league.isAmateur
        ? Icons.school_outlined
        : switch (sport ?? Sport.football) {
            Sport.basketball => Icons.sports_basketball,
            Sport.soccer => Icons.sports_soccer,
            Sport.baseball => Icons.sports_baseball,
            Sport.hockey => Icons.sports_hockey,
            Sport.football => Icons.sports_football,
          };

    return Tooltip(
      message: context.l10n.level(league),
      child: Semantics(
        selected: selected,
        child: Material(
          color: selected ? context.colors.ink : context.colors.surface,
          shape: StadiumBorder(side: BorderSide(color: context.colors.border)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('league_${league.name}'),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.fromLTRB(selected ? 5 : 20, 5, 20, 5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected) ...[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.colors.onInk,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 20, color: context.colors.ink),
                    ),
                    const SizedBox(width: 10),
                  ],
                  SizedBox(
                    height: 40,
                    child: Center(
                      child: Text(
                        league.label,
                        style: TextStyle(
                          color: selected
                              ? context.colors.onInk
                              : context.colors.text,
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
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({required this.label, required this.team, required this.onClear});

  final String label;
  final Team? team;
  final VoidCallback onClear;

  /// Room around the badge for the remove button's 48px touch target.
  static const double _overhang = 12;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selectedTeam = team;

    return Column(
      children: [
        // The box is larger than the 72px badge so the remove button, which
        // overhangs the badge corner, stays inside the hit-testable area
        // (a child outside its parent's bounds cannot be tapped).
        SizedBox(
          width: 72 + _overhang * 2,
          height: 72 + _overhang,
          child: Stack(
            children: [
              Positioned(
                left: _overhang,
                top: _overhang,
                child: selectedTeam == null
                    ? Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.colors.surfaceHigh,
                          border: Border.all(
                            color: context.colors.border,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          color: context.colors.muted,
                        ),
                      )
                    : TeamBadge(team: selectedTeam, size: 72),
              ),
              if (selectedTeam != null)
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    tooltip: l10n.removeTeam(selectedTeam.name),
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded, size: 14),
                    style: IconButton.styleFrom(
                      backgroundColor: context.colors.ink,
                      foregroundColor: context.colors.onInk,
                      minimumSize: const Size.square(26),
                      fixedSize: const Size.square(26),
                      padding: EdgeInsets.zero,
                      // 48px touch target around the 26px visual.
                      tapTargetSize: MaterialTapTargetSize.padded,
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
                ? context.colors.muted
                : context.colors.text,
          ),
        ),
        Text(
          selectedTeam?.record ?? l10n.pickATeam,
          style: TextStyle(color: context.colors.muted, fontSize: 12),
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
    this.hidden = false,
    this.onToggleHidden,
  });

  final Team team;
  final VoidCallback? onTap;
  final String? selectedAs;
  final bool showChevron;
  final bool hidden;
  final VoidCallback? onToggleHidden;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selected = selectedAs != null;
    final decimals = team.sport.scoresGoals ? 2 : 1;

    return ListTile(
      onTap: onTap,
      selected: selected,
      selectedTileColor: context.colors.surfaceHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: TeamBadge(team: team, size: 46),
      title: Text(
        team.displayName,
        key: ValueKey('team_name_${team.id}'),
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: context.colors.text,
        ),
      ),
      subtitle: Text(
        l10n.teamRowSubtitle(
          team.record,
          l10n.decimal(team.stat('ppg'), decimals),
          l10n.scoringRate(team.sport),
          l10n.decimal(team.stat('papg'), decimals),
        ),
        style: TextStyle(color: context.colors.muted, fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: ValueKey('hide_team_${team.id}'),
            tooltip: hidden
                ? l10n.restoreTeam(team.displayName)
                : l10n.hideTeam(team.displayName),
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
              backgroundColor: context.colors.ink,
              child: Text(
                selectedAs!,
                style: TextStyle(
                  color: context.colors.onInk,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          else if (showChevron)
            Icon(Icons.chevron_right_rounded, color: context.colors.muted),
        ],
      ),
    );
  }
}
