import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../../state/providers.dart';
import '../../state/settings.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../widgets/common.dart';

/// Tháng đang xem trên thẻ số dư theo tháng (mặc định tháng hiện tại).
final periodMonthProvider = NotifierProvider<PeriodMonthNotifier, CivilDate>(PeriodMonthNotifier.new);

final class PeriodMonthNotifier extends Notifier<CivilDate> {
  @override
  CivilDate build() {
    final t = todayCivil();
    return CivilDate(t.year, t.month, 1);
  }

  void shift(int months) => state = state.addMonths(months);
  void reset() => state = build();
}

/// Thẻ "Số dư theo tháng": số dư đầu tháng (chuyển từ tháng trước) + thu - chi ± chuyển/điều chỉnh = cuối tháng
/// (chuyển sang tháng sau). Tắt "mang số dư sang" trong Cài đặt thì chỉ hiện thu, chi, chênh lệch của tháng.
class PeriodBalanceCard extends ConsumerWidget {
  const PeriodBalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final p = context.palette;
    final data = ref.watch(ledgerProvider);
    final carry = ref.watch(settingsProvider.select((s) => s.carryOverBalance));
    final month = ref.watch(periodMonthProvider);
    final end = CivilDate(month.year, month.month, CivilDate.daysInMonth(month.year, month.month));
    final wallets = data.wallets.where((w) => !w.excludeFromTotal).toList();
    final sums = Ledger.periodSummary(wallets, data.txns, DateRange(month, end));
    final now = todayCivil();
    final isCurrent = month.year == now.year && month.month == now.month;
    final prev = month.addMonths(-1);
    final next = month.addMonths(1);
    final text = Theme.of(context).textTheme;

    Widget row(String label, Money m, {bool strong = false, Color? color, Key? key}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: QtSpace.s1),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: strong ? text.titleSmall : TextStyle(color: p.textSecondary)),
          ),
          MoneyText(
            m,
            key: key,
            style: (strong ? text.titleMedium : text.bodyMedium)?.copyWith(color: color),
          ),
        ],
      ),
    );

    return Card(
      key: const Key('overview.period'),
      child: Padding(
        padding: const EdgeInsets.all(QtSpace.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(l.periodTitle(month.month, month.year), style: text.titleMedium),
                  ),
                ),
                IconButton(
                  tooltip: l.periodPrev,
                  onPressed: () => ref.read(periodMonthProvider.notifier).shift(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                if (!isCurrent)
                  TextButton(
                    onPressed: () => ref.read(periodMonthProvider.notifier).reset(),
                    child: Text(l.periodThisMonth),
                  ),
                IconButton(
                  tooltip: l.periodNext,
                  onPressed: () => ref.read(periodMonthProvider.notifier).shift(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            for (final s in sums) ...[
              if (sums.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: QtSpace.s2),
                  child: Text(s.currency.code, style: text.labelLarge?.copyWith(color: p.textMuted)),
                ),
              if (carry) row(l.periodOpening(prev.month), s.opening, key: Key('period.opening.${s.currency.code}')),
              row(l.periodIncome, s.income, color: p.success),
              row(l.periodExpense, Money(-s.expense.minor, s.currency), color: p.danger),
              if (carry && !(s.transferNet - s.fees + s.adjustment).isZero)
                row(l.periodOther, s.transferNet - s.fees + s.adjustment),
              if (!s.taxWithheld.isZero) row(l.periodWithheld, s.taxWithheld),
              const Divider(),
              if (carry)
                row(l.periodClosing(next.month), s.closing, strong: true, key: Key('period.closing.${s.currency.code}'))
              else
                row(l.periodNet, s.net, strong: true, color: s.net.isNegative ? p.danger : p.success),
              if (s.savingRateBp != null)
                Text(
                  l.periodSavingRate(context.percent(s.savingRateBp!)),
                  style: TextStyle(color: p.textMuted, fontSize: QtFontSize.sm),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
