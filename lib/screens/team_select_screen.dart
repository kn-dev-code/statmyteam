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

/// Pick one team (team stats) or two teams (head-to-head).
class TeamSelectScreen extends StatefulWidget {
  const TeamSelectScreen({
    super.key,
    required this.mode,
    this.preselected,
    this.bottomInset = 24,
  });

  final TeamSelectMode mode;

  /// Fills the first matchup slot, e.g. when coming from a team page.
  final Team? preselected;

  /// Extra space below the list, e.g. to clear a floating nav bar.
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

  /// Matchups stay within one league, so changing league clears picks.
  void _selectLeague(League league) {
    if (league == _league) return;
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

  void _openMatchup() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MatchupScreen(teamA: _a!, teamB: _b!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = StatsScope.of(context);
    final leagues = repo.leagues;
    final league = _league ?? leagues.first;
    final conferences = repo.teamsByConference(league);

    return Scaffold(
      appBar: PillAppBar(
        title: _isMatchup ? 'Head-to-Head' : 'Team Stats',
        actions: [
          RoundIconButton(
            tooltip: 'Search teams and players',
            icon: Icons.search_rounded,
            onPressed: () =>
                showSearch(context: context, delegate: StatsSearchDelegate()),
          ),
        ],
      ),
      bottomNavigationBar: _isMatchup
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                // Center with heightFactor 1 so the bar keeps its intrinsic
                // height instead of filling the screen.
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 688),
                    child: FilledButton.icon(
                      onPressed: _a != null && _b != null ? _openMatchup : null,
                      icon: const Icon(Icons.compare_arrows_rounded),
                      label: const Text('Compare teams'),
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: ContentWidth(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 8, 16, widget.bottomInset),
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
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _Slot(
                        label: 'Team A',
                        team: _a,
                        onClear: () => setState(() => _a = null),
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
                        onClear: () => setState(() => _b = null),
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
                    ? 'Tap two ${league.label} teams. Tap a selected team '
                          'again to remove it.'
                    : 'Choose a ${league.label} team to see its season.',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
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
                        team: team,
                        selectedAs: team == _a
                            ? 'A'
                            : (team == _b ? 'B' : null),
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
    );
  }
}

/// League filter: the selected league is a black pill with an icon disc,
/// the others are white outlined pills.
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
          for (final l in leagues) ...[
            if (l != leagues.first) const SizedBox(width: 8),
            Tooltip(
              message: l.level,
              child: Material(
                color: l == selected ? AppColors.ink : AppColors.surface,
                shape: StadiumBorder(side: BorderSide(color: AppColors.border)),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onSelect(l),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      l == selected ? 5 : 20,
                      5,
                      20,
                      5,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (l == selected) ...[
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.onInk,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              l.isAmateur
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
                              l.label,
                              style: TextStyle(
                                color: l == selected
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
  const _Slot({required this.label, required this.team, required this.onClear});

  final String label;
  final Team? team;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final t = team;
    return Column(
      children: [
        SizedBox(
          width: 72,
          height: 72,
          child: t == null
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceHigh,
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Icon(Icons.add_rounded, color: AppColors.muted),
                )
              : Stack(
                  clipBehavior: Clip.none,
                  children: [
                    TeamBadge(team: t, size: 72),
                    Positioned(
                      right: -10,
                      top: -10,
                      child: IconButton(
                        tooltip: 'Remove ${t.name}',
                        onPressed: onClear,
                        icon: const Icon(Icons.close_rounded, size: 14),
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
          t?.name ?? label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: t == null ? AppColors.muted : AppColors.text,
          ),
        ),
        Text(
          t?.record ?? 'Pick a team',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    );
  }
}

class _TeamRow extends StatelessWidget {
  const _TeamRow({
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: TeamBadge(team: team, size: 46),
      title: Text(
        team.displayName,
        style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text),
      ),
      subtitle: Text(
        '${team.record} · ${team.stat('ppg').toStringAsFixed(1)} PPG · '
        '${team.stat('papg').toStringAsFixed(1)} allowed',
        style: TextStyle(color: AppColors.muted, fontSize: 12),
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
          : (showChevron
                ? Icon(Icons.chevron_right_rounded, color: AppColors.muted)
                : null),
    );
  }
}
