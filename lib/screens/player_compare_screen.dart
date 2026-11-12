import 'package:flutter/material.dart';

import '../data/stats_repository.dart';
import '../logic/football_stats.dart';
import '../logic/sport_stats.dart';
import '../models/models.dart';
import '../state/stats_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/stats_widgets.dart';
import 'player_detail_screen.dart';

/// Pick one player from each team and compare them stat by stat.
class PlayerCompareScreen extends StatefulWidget {
  const PlayerCompareScreen({
    super.key,
    required this.teamA,
    required this.teamB,
  });

  final Team teamA;
  final Team teamB;

  @override
  State<PlayerCompareScreen> createState() => _PlayerCompareScreenState();
}

class _PlayerCompareScreenState extends State<PlayerCompareScreen> {
  PositionGroup _group = PositionGroup.quarterback;
  String? _position;
  Player? _a;
  Player? _b;

  bool get _isFootball => widget.teamA.sport == Sport.football;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repo = StatsScope.of(context);
    _position ??= _positions(repo).firstOrNull;
    if (_a == null && _b == null) _selectDefaults(repo);
  }

  List<String> _positions(StatsRepository repo) {
    final seen = <String>{};
    return [
      for (final team in [widget.teamA, widget.teamB])
        for (final player in repo.rosterFor(team.id))
          if (seen.add(player.position)) player.position,
    ];
  }

  List<Player> _options(StatsRepository repo, Team team) {
    if (_isFootball) return repo.rosterInGroup(team.id, _group);
    final position = _position;
    if (position == null) return const [];
    return [
      for (final player in repo.rosterFor(team.id))
        if (player.position == position) player,
    ];
  }

  /// Starters first, so switching groups lines up the likely matchup.
  Player? _defaultFor(StatsRepository repo, Team team) {
    final group = _options(repo, team);
    if (group.isEmpty) return null;
    return group.firstWhere((p) => p.isStarter, orElse: () => group.first);
  }

  void _selectDefaults(StatsRepository repo) {
    _a = _defaultFor(repo, widget.teamA);
    _b = _defaultFor(repo, widget.teamB);
  }

  @override
  Widget build(BuildContext context) {
    final repo = StatsScope.of(context);
    final a = _a;
    final b = _b;
    final colorA = teamColor(widget.teamA);
    final colorB = teamColor(widget.teamB);

    return Scaffold(
      appBar: const PillAppBar(title: 'Compare players'),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                'POSITION',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_isFootball)
                  for (final group in PositionGroup.values)
                    ChoiceChip(
                      label: Text(group.shortLabel),
                      selected: _group == group,
                      onSelected: (_) => setState(() {
                        _group = group;
                        _selectDefaults(repo);
                      }),
                    )
                else
                  for (final position in _positions(repo))
                    ChoiceChip(
                      label: Text(position),
                      selected: _position == position,
                      onSelected: (_) => setState(() {
                        _position = position;
                        _selectDefaults(repo);
                      }),
                    ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _PlayerPicker(
                    team: widget.teamA,
                    options: _options(repo, widget.teamA),
                    value: a,
                    onChanged: (p) => setState(() => _a = p),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PlayerPicker(
                    team: widget.teamB,
                    options: _options(repo, widget.teamB),
                    value: b,
                    onChanged: (p) => setState(() => _b = p),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (a != null && b != null) ...[
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _tappableCard(a, widget.teamA)),
                    const SizedBox(width: 12),
                    Expanded(child: _tappableCard(b, widget.teamB)),
                  ],
                ),
              ),
              if (a.position != b.position)
                Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'Different positions: stats that only apply to one '
                    'player show a dash for the other.',
                    style: TextStyle(color: AppColors.gold, fontSize: 13),
                  ),
                ),
              _EdgeSummary(a: a, b: b, colorA: colorA, colorB: colorB),
              StatCard(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Text(
                            a.lastName,
                            style: TextStyle(
                              color: colorA,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            b.lastName,
                            style: TextStyle(
                              color: colorB,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (final def in SportStats.forComparison(a, b))
                      StatCompareRow(
                        def: def,
                        valueA: a.seasonStats[def.key],
                        valueB: b.seasonStats[def.key],
                        colorA: colorA,
                        colorB: colorB,
                      ),
                  ],
                ),
              ),
            ] else
              StatCard(
                child: Text(
                  'One of these teams has no player listed at this position.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tappableCard(Player player, Team team) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PlayerDetailScreen(player: player),
        ),
      ),
      child: PlayerSummaryCard(player: player, team: team, compact: true),
    );
  }
}

class _PlayerPicker extends StatelessWidget {
  const _PlayerPicker({
    required this.team,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final Team team;
  final List<Player> options;
  final Player? value;
  final ValueChanged<Player> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Player>(
      key: ValueKey('${team.id}-${value?.id}-${options.length}'),
      initialValue: options.contains(value) ? value : null,
      isExpanded: true,
      borderRadius: BorderRadius.circular(20),
      dropdownColor: AppColors.surface,
      decoration: InputDecoration(
        labelText: team.name,
        labelStyle: TextStyle(
          color: AppColors.muted,
          fontWeight: FontWeight.w600,
        ),
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
      ),
      items: [
        for (final p in options)
          DropdownMenuItem(
            value: p,
            child: Text(
              '${p.position} ${p.firstName[0]}. ${p.lastName}'
              '${p.isAvailable ? '' : ' (${p.status.shortLabel})'}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (p) {
        if (p != null) onChanged(p);
      },
    );
  }
}

/// "Vance leads 5 of 8 categories" style summary.
class _EdgeSummary extends StatelessWidget {
  const _EdgeSummary({
    required this.a,
    required this.b,
    required this.colorA,
    required this.colorB,
  });

  final Player a;
  final Player b;
  final Color colorA;
  final Color colorB;

  @override
  Widget build(BuildContext context) {
    var winsA = 0;
    var winsB = 0;
    for (final def in SportStats.forComparison(a, b)) {
      if (def.key == 'gp') continue;
      final va = a.seasonStats[def.key];
      final vb = b.seasonStats[def.key];
      if (va == null || vb == null || va == vb) continue;
      if ((va > vb) == def.higherIsBetter) {
        winsA++;
      } else {
        winsB++;
      }
    }
    final total = winsA + winsB;

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 24, 6, 12),
      child: Text.rich(
        TextSpan(
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          children: total == 0
              ? [const TextSpan(text: 'No shared stats to compare')]
              : winsA == winsB
              ? [TextSpan(text: 'Dead even: $winsA–$winsB in shared stats')]
              : [
                  TextSpan(
                    text: winsA > winsB ? a.lastName : b.lastName,
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextSpan(
                    text:
                        ' leads ${winsA > winsB ? winsA : winsB} of '
                        '$total categories',
                  ),
                ],
        ),
      ),
    );
  }
}
