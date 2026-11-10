import 'package:flutter/material.dart';

import '../models/models.dart';
import '../search/stats_search_delegate.dart';
import '../state/stats_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/stats_widgets.dart';
import 'matchup_screen.dart';
import 'team_detail_screen.dart';

enum TeamSelectMode { single, matchup }

/// Pick one team (team stats) or two teams (head-to-head).
class TeamSelectScreen extends StatefulWidget {
  const TeamSelectScreen({super.key, required this.mode, this.preselected});

  final TeamSelectMode mode;

  /// Fills the first matchup slot, e.g. when coming from a team page.
  final Team? preselected;

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
      appBar: AppBar(
        title: Text(_isMatchup ? 'Head-to-Head' : 'Team Stats'),
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
      bottomNavigationBar: _isMatchup
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: FilledButton.icon(
                  onPressed: _a != null && _b != null ? _openMatchup : null,
                  icon: const Icon(Icons.compare_arrows),
                  label: const Text('Compare teams'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            if (leagues.length > 1) ...[
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<League>(
                  showSelectedIcon: false,
                  segments: [
                    for (final l in leagues)
                      ButtonSegment(
                        value: l,
                        label: Text(l.label),
                        tooltip: l.level,
                      ),
                  ],
                  selected: {league},
                  onSelectionChanged: (s) => _selectLeague(s.first),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_isMatchup) ...[
              Row(
                children: [
                  Expanded(
                    child: _Slot(
                      label: 'Team A',
                      team: _a,
                      onClear: () => setState(() => _a = null),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'VS',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w900,
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
              const SizedBox(height: 4),
            ],
            Text(
              _isMatchup
                  ? 'Tap two ${league.label} teams. Tap a selected team again '
                      'to remove it.'
                  : 'Choose a ${league.label} team to see its season.',
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            for (final entry in conferences.entries) ...[
              SectionTitle('${entry.key} Conference'),
              StatCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
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

class _Slot extends StatelessWidget {
  const _Slot({required this.label, required this.team, required this.onClear});

  final String label;
  final Team? team;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final t = team;
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: t == null ? AppColors.border : teamColor(t),
          width: t == null ? 1 : 2,
        ),
      ),
      child: t == null
          ? Center(
              child: Text(
                label,
                style: const TextStyle(color: AppColors.muted),
              ),
            )
          : Row(
              children: [
                TeamBadge(team: t, size: 36),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        t.record,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Remove ${t.name}',
                  visualDensity: VisualDensity.compact,
                  onPressed: onClear,
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
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
      selectedTileColor: teamColor(team).withValues(alpha: 0.08),
      leading: TeamBadge(team: team),
      title: Text(
        team.displayName,
        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.text),
      ),
      subtitle: Text(
        '${team.record} · ${team.stat('ppg').toStringAsFixed(1)} PPG · '
        '${team.stat('papg').toStringAsFixed(1)} allowed',
        style: const TextStyle(color: AppColors.muted, fontSize: 12),
      ),
      trailing: selected
          ? CircleAvatar(
              radius: 14,
              backgroundColor: teamColor(team),
              child: Text(
                selectedAs!,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          : (showChevron
              ? const Icon(Icons.chevron_right, color: AppColors.muted)
              : null),
    );
  }
}
