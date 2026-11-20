import 'package:flutter/material.dart';

import '../data/stats_repository.dart';
import '../l10n/l10n.dart';
import '../logic/football_stats.dart';
import '../logic/sport_stats.dart';
import '../models/models.dart';
import '../state/stats_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/player_stats_loader.dart';
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
    final colorA = teamColor(context, widget.teamA);
    final colorB = teamColor(context, widget.teamB);
    final l10n = context.l10n;

    return Scaffold(
      appBar: PillAppBar(title: l10n.comparePlayers),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                l10n.position.toUpperCase(),
                style: TextStyle(
                  color: context.colors.muted,
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
                  for (final group in PositionGroup.comparable)
                    ChoiceChip(
                      label: Text(l10n.groupShort(group)),
                      tooltip: l10n.group(group),
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
                      tooltip: l10n.positionName(position),
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
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    l10n.differentPositions,
                    style: TextStyle(color: context.colors.gold, fontSize: 13),
                  ),
                ),
              PlayerStatsLoader(
                players: [a, b],
                builder: (context, loaded) =>
                    _comparison(loaded[0], loaded[1], colorA, colorB),
              ),
            ] else
              StatCard(
                child: Text(
                  l10n.noPlayerAtPosition,
                  style: TextStyle(color: context.colors.muted),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Edge summary + stat-by-stat table, built once both players' season
  /// stats have loaded.
  Widget _comparison(Player a, Player b, Color colorA, Color colorB) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
      ],
    );
  }

  /// Summary card that opens the player's page. InkWell over a transparent
  /// Material gives focus, keyboard activation, a ripple, and button
  /// semantics, which a bare GestureDetector does not.
  Widget _tappableCard(Player player, Team team) {
    return Semantics(
      button: true,
      label: context.l10n.openPlayer(player.fullName),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PlayerDetailScreen(player: player),
            ),
          ),
          child: PlayerSummaryCard(player: player, team: team, compact: true),
        ),
      ),
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
      dropdownColor: context.colors.surface,
      decoration: InputDecoration(
        labelText: team.name,
        labelStyle: TextStyle(
          color: context.colors.muted,
          fontWeight: FontWeight.w600,
        ),
        fillColor: context.colors.surface,
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
              p.isAvailable
                  ? context.l10n.pickerItem(
                      p.position,
                      p.firstName.isEmpty ? '' : p.firstName[0],
                      p.lastName,
                    )
                  : context.l10n.pickerItemUnavailable(
                      p.position,
                      p.firstName.isEmpty ? '' : p.firstName[0],
                      p.lastName,
                      context.l10n.statusShort(p.status),
                    ),
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
    final l10n = context.l10n;

    List<TextSpan> leads() {
      final name = winsA > winsB ? a.lastName : b.lastName;
      final text = l10n.leadsCategories(
        name,
        winsA > winsB ? winsA : winsB,
        total,
      );
      // Highlight the leader's name wherever the locale places it.
      final at = text.indexOf(name);
      if (at < 0) return [TextSpan(text: text)];
      return [
        TextSpan(text: text.substring(0, at)),
        TextSpan(
          text: name,
          style: TextStyle(
            color: context.colors.accent,
            fontWeight: FontWeight.w900,
          ),
        ),
        TextSpan(text: text.substring(at + name.length)),
      ];
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 24, 6, 12),
      child: Text.rich(
        TextSpan(
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          children: total == 0
              ? [TextSpan(text: l10n.noSharedStats)]
              : winsA == winsB
              ? [TextSpan(text: l10n.deadEven(winsA, winsB))]
              : leads(),
        ),
      ),
    );
  }
}
