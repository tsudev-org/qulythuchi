import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../../state/providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../widgets/common.dart';

class DebtsPage extends ConsumerWidget {
  const DebtsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final p = context.palette;
    final data = ref.watch(ledgerProvider);
    final today = todayCivil();
    final lend = <Currency, Money>{};
    final borrow = <Currency, Money>{};
    for (final d in data.debts.where((d) => !d.closed)) {
      final w = data.wallet(d.walletId);
      if (w == null) continue;
      final rem = Ledger.debtStatus(d, w, data.txns).remaining;
      final target = d.kind == DebtKind.lend ? lend : borrow;
      target[w.currency] = (target[w.currency] ?? Money.zero(w.currency)) + rem;
    }
    return Scaffold(
      appBar: AppBar(title: Text(l.moreDebts)),
      floatingActionButton: data.wallets.isEmpty
          ? null
          : FloatingActionButton(
              tooltip: l.debtNew,
              onPressed: () => context.go('/more/debts/new'),
              child: const Icon(Icons.add),
            ),
      body: PageBody(
        child: data.debts.isEmpty
            ? EmptyState(icon: Icons.handshake_outlined, title: l.emptyDebtsTitle, body: l.emptyDebtsBody)
            : ListView(
                padding: const EdgeInsets.fromLTRB(QtSpace.s4, 0, QtSpace.s4, 96),
                children: [
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.call_received, color: p.success),
                          title: Text(l.debtsLendTotal),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [if (lend.isEmpty) const Text('0'), for (final m in lend.values) MoneyText(m)],
                          ),
                        ),
                        ListTile(
                          leading: Icon(Icons.call_made, color: p.danger),
                          title: Text(l.debtsBorrowTotal),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (borrow.isEmpty) const Text('0'),
                              for (final m in borrow.values) MoneyText(m),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: QtSpace.s4),
                  Card(
                    child: Column(
                      children: [
                        for (final d in data.debts)
                          Builder(
                            builder: (context) {
                              final w = data.wallet(d.walletId);
                              final st = w == null ? null : Ledger.debtStatus(d, w, data.txns);
                              final overdue =
                                  !d.closed && st != null && !st.settled && d.dueDate != null && d.dueDate! < today;
                              final status = d.closed
                                  ? l.debtClosed
                                  : (st?.settled ?? false)
                                  ? l.debtSettled
                                  : overdue
                                  ? l.debtOverdue
                                  : (d.dueDate == null ? '' : '${l.debtDue}: ${formatDate(d.dueDate!)}');
                              return ListTile(
                                leading: Icon(
                                  d.kind == DebtKind.lend ? Icons.call_received : Icons.call_made,
                                  color: d.closed ? p.textMuted : (d.kind == DebtKind.lend ? p.success : p.danger),
                                ),
                                title: Text(d.counterparty, maxLines: 1, overflow: TextOverflow.ellipsis),
                                subtitle: Text(
                                  [
                                    d.kind == DebtKind.lend ? l.debtLend : l.debtBorrow,
                                    if (status.isNotEmpty) status,
                                  ].join(' · '),
                                  style: TextStyle(color: overdue ? p.danger : null),
                                ),
                                trailing: st == null ? null : MoneyText(st.remaining),
                                onTap: () => context.go('/more/debts/${d.id}'),
                              );
                            },
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
