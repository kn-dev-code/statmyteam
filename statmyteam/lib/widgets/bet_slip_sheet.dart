import 'package:flutter/material.dart';

import '../logic/money.dart';
import '../logic/predictor.dart';
import '../models/models.dart';
import '../state/betting_controller.dart';
import '../state/betting_scope.dart';
import '../theme/app_theme.dart';

Future<void> showBetSlipSheet(BuildContext context) async {
  final result = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      final controller = BettingScope.of(context);
      return AnimatedBuilder(
        animation: controller,
        builder: (context, _) => BetSlipSheet(controller: controller),
      );
    },
  );
  if (!context.mounted || result == null) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        result == 'placed'
            ? 'Predictions locked in. Bankroll updated.'
            : result,
      ),
    ),
  );
}

class BetSlipSheet extends StatelessWidget {
  const BetSlipSheet({super.key, required this.controller});

  final BettingController controller;

  @override
  Widget build(BuildContext context) {
    final picks = controller.slip;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bet slip',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          Text(
            '${picks.length} pick${picks.length == 1 ? '' : 's'}  ·  ${formatMoney(controller.availableBalance)} available',
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          if (picks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Text(
                'Tap a moneyline on the board to add a pick.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: picks.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final pick = picks[index];
                  return _SlipRow(
                    pick: pick,
                    onRemove: () => controller.removePick(pick),
                    onStake: (stake) => controller.updateStake(pick, stake),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Slip total', style: TextStyle(color: AppColors.muted)),
              const Spacer(),
              Text(
                formatMoney(controller.slipTotal),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: picks.isEmpty
                ? null
                : () {
                    final error = controller.placeSlip();
                    Navigator.of(context).pop(error ?? 'placed');
                  },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: const Color(0xFF042016),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Place virtual bets',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlipRow extends StatelessWidget {
  const _SlipRow({
    required this.pick,
    required this.onRemove,
    required this.onStake,
  });

  final BetPick pick;
  final VoidCallback onRemove;
  final ValueChanged<double> onStake;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  pick.selectionLabel,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                formatAmericanOdds(Predictor.americanOdds(pick.decimalOdds)),
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w800,
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 18),
                color: AppColors.muted,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          Text(
            '${formatPercent(pick.modelWinChance)} model win chance  ·  to win ${formatMoney(pick.potentialProfit)}',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Stake', style: TextStyle(color: AppColors.muted)),
              Expanded(
                child: Slider(
                  value: pick.stake.clamp(5, 200),
                  min: 5,
                  max: 200,
                  divisions: 39,
                  label: formatMoney(pick.stake),
                  onChanged: onStake,
                ),
              ),
              SizedBox(
                width: 72,
                child: Text(
                  formatMoney(pick.stake),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
