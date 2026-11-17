import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../../l10n/app_localizations.dart';
import '../../state/ledger_repository.dart';
import '../../state/providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../widgets/common.dart';

String frequencyLabel(AppLocalizations l, RecurrenceRule r) {
  final base = switch (r.frequency) {
    Frequency.daily => l.freqDaily,
    Frequency.weekly => l.freqWeekly,
    Frequency.monthly => l.freqMonthly,
    Frequency.yearly => l.freqYearly,
  };
  return r.interval > 1 ? '$base ×${r.interval}' : base;
}

/// Lần đến hạn kế tiếp chưa ghi (sau `generatedThrough`, tính từ hôm nay trở đi hoặc kỳ quá hạn chưa sinh).
CivilDate? nextDue(Recurring r, CivilDate today) {
  if (r.paused) return null;
  final from = r.generatedThrough?.addDays(1) ?? r.rule.start;
  return r.rule.nextOnOrAfter(from);
}

/// Hóa đơn đến hạn trong [days] ngày tới (kể cả quá hạn chưa ghi).
List<(Recurring, CivilDate)> upcomingBills(LedgerData data, CivilDate today, {int days = 7}) {
  final out = <(Recurring, CivilDate)>[];
  for (final r in data.recurrings) {
    if (!r.isBill) continue;
    final due = nextDue(r, today);
    if (due != null && today.daysUntil(due) <= days) out.add((r, due));
  }
  out.sort((a, b) => a.$2.compareTo(b.$2));
  return out;
}

/// Ghi nhận trả hóa đơn (dùng ở đây và ở Tổng quan).
void payBillAction(BuildContext context, WidgetRef ref, Recurring r, CivilDate due) {
  try {
    ref.read(ledgerProvider.notifier).payBill(r.id, due, paidOn: todayCivil());
    context.toast(context.l10n.billPaid);
  } on Object catch (e) {
    context.toast(errorMessage(context, e));
  }
}

/// Dòng một hóa đơn sắp đến hạn.
class BillTile extends ConsumerWidget {
  const BillTile({super.key, required this.recurring, required this.due, required this.data});
  final Recurring recurring;
  final CivilDate due;
  final LedgerData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final p = context.palette;
    final today = todayCivil();
    final days = today.daysUntil(due);
    final cur = data.wallet(recurring.walletId)?.currency ?? Currency.vnd;
    final overdue = days < 0;
    return ListTile(
      leading: Icon(overdue ? Icons.error_outline : Icons.receipt_outlined, color: overdue ? p.danger : p.warning),
      title: Text(recurring.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        days <= 0 ? '${l.billDueToday} · ${formatDate(due)}' : l.billDueIn(formatDate(due), days),
        style: TextStyle(color: overdue ? p.danger : null),
      ),
      trailing: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: QtSpace.s2,
        children: [
          MoneyText(Money(recurring.amount, cur)),
          TextButton(onPressed: () => payBillAction(context, ref, recurring, due), child: Text(l.billPay)),
        ],
      ),
    );
  }
}

class RecurringPage extends ConsumerWidget {
  const RecurringPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final p = context.palette;
    final data = ref.watch(ledgerProvider);
    final today = todayCivil();
    final bills = upcomingBills(data, today, days: 31);
    return Scaffold(
      appBar: AppBar(title: Text(l.moreRecurring)),
      floatingActionButton: data.wallets.isEmpty
          ? null
          : FloatingActionButton(
              tooltip: l.recurringNew,
              onPressed: () => context.go('/more/recurring/new'),
              child: const Icon(Icons.add),
            ),
      body: PageBody(
        child: data.recurrings.isEmpty
            ? EmptyState(icon: Icons.event_repeat_outlined, title: l.emptyRecurringTitle, body: l.emptyRecurringBody)
            : ListView(
                padding: const EdgeInsets.fromLTRB(QtSpace.s4, 0, QtSpace.s4, 96),
                children: [
                  if (bills.isNotEmpty) ...[
                    Semantics(
                      header: true,
                      child: Text(l.billsUpcoming, style: Theme.of(context).textTheme.titleMedium),
                    ),
                    const SizedBox(height: QtSpace.s2),
                    Card(
                      child: Column(
                        children: [for (final (r, due) in bills) BillTile(recurring: r, due: due, data: data)],
                      ),
                    ),
                    const SizedBox(height: QtSpace.s6),
                  ],
                  Card(
                    child: Column(
                      children: [
                        for (final r in data.recurrings)
                          ListTile(
                            leading: Icon(
                              r.isBill ? Icons.receipt_long_outlined : Icons.event_repeat_outlined,
                              color: r.paused ? p.textMuted : null,
                            ),
                            title: Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                              [
                                frequencyLabel(l, r.rule),
                                data.wallet(r.walletId)?.name ?? '?',
                                if (r.paused)
                                  l.recurringPaused
                                else if (nextDue(r, today) case final d?)
                                  l.recurringNext(formatDate(d))
                                else
                                  l.recurringEnded,
                              ].join(' · '),
                            ),
                            trailing: MoneyText(
                              Money(
                                r.kind == TxnKind.expense ? -r.amount : r.amount,
                                data.wallet(r.walletId)?.currency ?? Currency.vnd,
                              ),
                              signed: true,
                              colored: true,
                            ),
                            onTap: () => context.go('/more/recurring/${r.id}'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
