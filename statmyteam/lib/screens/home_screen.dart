import 'package:flutter/material.dart';

import '../state/betting_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/bankroll_display.dart';
import '../widgets/bet_slip_selection_card.dart';
import '../widgets/bet_slip_sheet.dart';
import '../widgets/prediction_history_log.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = BettingScope.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'StatMyTeam',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
            Text(
              'Stats, matchups, educated bets',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final count = controller.slip.length;
          return FloatingActionButton.extended(
            onPressed: () => showBetSlipSheet(context),
            backgroundColor: AppColors.accent,
            foregroundColor: const Color(0xFF042016),
            icon: Badge(
              isLabelVisible: count > 0,
              label: Text('$count'),
              child: const Icon(Icons.receipt_long),
            ),
            label: const Text(
              'Bet slip',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          );
        },
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: BankrollDisplay(
                        balance: controller.availableBalance,
                        startingBankroll: controller.startingBankroll,
                        equity: controller.equity,
                        wins: controller.settledWins,
                        losses: controller.settledLosses,
                        pendingCount: controller.pendingCount,
                        winRate: controller.winRate,
                        curve: controller.bankrollCurve,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: _SectionHeader(
                      title: 'Bet board',
                      subtitle: 'Tap a moneyline to drop it on the slip',
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList.separated(
                      itemCount: controller.board.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final game = controller.board[index];
                        final home = controller.teamById(game.homeTeamId);
                        final away = controller.teamById(game.awayTeamId);
                        final chance = controller.homeWinChance(game);
                        return BetSlipSelectionCard(
                          game: game,
                          home: home,
                          away: away,
                          homeWinChance: chance,
                          selectedTeamId:
                              controller.selectedPickFor(game.id)?.teamId,
                          onSelect: (team, winChance) {
                            controller.toggleMoneyline(game, team, winChance);
                          },
                        );
                      },
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: _SectionHeader(
                      title: 'Prediction log',
                      subtitle: 'Every virtual bet, settled or still open',
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    sliver: SliverToBoxAdapter(
                      child: PredictionHistoryLog(
                        bets: controller.history,
                        resolveGame: controller.gameById,
                        resolveTeam: controller.teamById,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
