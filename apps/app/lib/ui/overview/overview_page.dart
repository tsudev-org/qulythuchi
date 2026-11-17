import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../../state/providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../transactions/txn_tile.dart';
import '../widgets/common.dart';

class OverviewPage extends ConsumerWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final p = context.palette;
    final data = ref.watch(ledgerProvider);
    final totals = data.totals();
    final today = todayCivil();
    final monthStart = CivilDate(today.year, today.month, 1);
    final income = <Currency, int>{};
    final expense = <Currency, int>{};
    for (final t in data.txns) {
      if (t.pending || t.excludeFromReports || t.date < monthStart || t.date > today) continue;
      final cur = data.wallet(t.walletId)?.currency;
      if (cur == null) continue;
      if (t.kind == TxnKind.income) income[cur] = (income[cur] ?? 0) + t.amount;
      if (t.kind == TxnKind.expense) expense[cur] = (expense[cur] ?? 0) + t.amount;
    }
    final wallets = data.wallets.where((w) => !w.archived).toList();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l.navOverview)),
      floatingActionButton: wallets.isEmpty
          ? null
          : FloatingActionButton(
              tooltip: l.txnNew,
              onPressed: () => context.go('/transactions/new'),
              child: const Icon(Icons.add),
            ),
      body: PageBody(
        child: wallets.isEmpty
            ? EmptyState(
                icon: Icons.account_balance_wallet_outlined,
                title: l.emptyWalletsTitle,
                body: l.emptyWalletsBody,
                action: FilledButton.icon(
                  onPressed: () => context.go('/wallets/new'),
                  icon: const Icon(Icons.add),
                  label: Text(l.walletNew),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(QtSpace.s4, 0, QtSpace.s4, 96),
                children: [
                  if (data.skipped > 0) ...[
                    _Banner(text: l.skippedRecords(data.skipped)),
                    const SizedBox(height: QtSpace.s3),
                  ],
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(QtSpace.s4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.overviewTotal, style: TextStyle(color: p.textSecondary)),
                          const SizedBox(height: QtSpace.s1),
                          if (totals.isEmpty) MoneyText(Money.zero(Currency.vnd), style: textTheme.headlineMedium),
                          for (final m in totals.values) MoneyText(m, style: textTheme.headlineMedium),
                          const SizedBox(height: QtSpace.s4),
                          Wrap(
                            spacing: QtSpace.s6,
                            runSpacing: QtSpace.s2,
                            children: [
                              _Stat(
                                label: l.overviewMonthIncome,
                                icon: Icons.south_west,
                                values: [for (final e in income.entries) Money(e.value, e.key)],
                              ),
                              _Stat(
                                label: l.overviewMonthExpense,
                                icon: Icons.north_east,
                                values: [for (final e in expense.entries) Money(-e.value, e.key)],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: QtSpace.s6),
                  _SectionHeader(title: l.overviewWallets, onMore: () => context.go('/wallets'), more: l.seeAll),
                  Card(
                    child: Column(
                      children: [
                        for (final w in wallets)
                          ListTile(
                            leading: Icon(walletTypeIcon(w.type)),
                            title: Text(w.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(walletTypeLabel(l, w.type)),
                            trailing: MoneyText(data.balance(w), style: const TextStyle(fontWeight: FontWeight.w600)),
                            onTap: () => context.go('/wallets/${w.id}'),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: QtSpace.s6),
                  _SectionHeader(title: l.overviewRecent, onMore: () => context.go('/transactions'), more: l.seeAll),
                  if (data.txns.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: QtSpace.s6),
                      child: Text(l.emptyTxnsBody, style: TextStyle(color: p.textSecondary)),
                    )
                  else
                    Card(
                      child: Column(
                        children: [for (final t in data.txns.take(8)) TxnTile(txn: t, data: data, showDate: true)],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.icon, required this.values});
  final String label;
  final IconData icon;
  final List<Money> values;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(child: Icon(icon, size: 18, color: p.textSecondary)),
        const SizedBox(width: QtSpace.s2),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: p.textSecondary, fontSize: QtFontSize.sm),
            ),
            if (values.isEmpty) MoneyText(Money.zero(Currency.vnd)),
            for (final v in values) MoneyText(v, colored: true, signed: true),
          ],
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onMore, required this.more});
  final String title;
  final VoidCallback onMore;
  final String more;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: QtSpace.s2),
    child: Row(
      children: [
        Expanded(
          child: Semantics(header: true, child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
        ),
        TextButton(onPressed: onMore, child: Text(more)),
      ],
    ),
  );
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(QtSpace.s3),
      decoration: BoxDecoration(
        border: Border.all(color: p.warning),
        borderRadius: BorderRadius.circular(QtRadius.lg),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_outlined, color: p.warning),
          const SizedBox(width: QtSpace.s2),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
