import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../../domain/reports.dart';
import '../../state/capture_providers.dart';
import '../../state/providers.dart';
import '../../state/settings.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../plan/plan_page.dart';
import '../quick_entry/quick_entry_sheet.dart';
import '../recurring/recurring_page.dart';
import '../transactions/txn_tile.dart';
import '../widgets/common.dart';
import '../widgets/cot_tang_truong.dart';
import 'period_card.dart';

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
    final base = Currency.of(ref.watch(settingsProvider.select((s) => s.baseCurrency)));
    final converted = data.totalIn(base);
    final pending = data.pendingTxns;
    final safe = Reports(data, base).safeToSpend(today);
    final bills = upcomingBills(data, today);
    final watchBudgets = [
      for (final b in data.budgets)
        if (Ledger.budgetStatus(
              b,
              txns: data.txns,
              categories: data.categories,
              wallets: data.wallets,
              today: today,
            ).state !=
            BudgetState.ok)
          b,
    ];
    final textTheme = Theme.of(context).textTheme;

    // Ghi nhanh yêu cầu từ widget màn hình chính.
    if (ref.watch(pendingQuickEntryProvider) != null && wallets.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final m = ref.read(pendingQuickEntryProvider.notifier).take();
        if (m == null || !context.mounted) return;
        showQuickEntry(context, mode: QuickEntryMode.values.firstWhere((x) => x.name == m));
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.navOverview),
        actions: [
          if (wallets.isNotEmpty)
            IconButton(
              key: const Key('overview.quick'),
              tooltip: l.quickTitle,
              onPressed: () => showQuickEntry(context),
              icon: const Icon(Icons.bolt_outlined),
            ),
        ],
      ),
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
                  // Thẻ số liệu trên cùng của bố cục bang-dieu-khien, nền hoạ tiết cot-tang-truong (bản sắc v5.0.0).
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        const Positioned(right: QtSpace.s4, bottom: 0, width: 220, height: 96, child: CotTangTruong()),
                        Padding(
                          padding: const EdgeInsets.all(QtSpace.s4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.overviewTotal, style: TextStyle(color: p.textSecondary)),
                              const SizedBox(height: QtSpace.s1),
                              if (totals.isEmpty) MoneyText(Money.zero(Currency.vnd), style: textTheme.headlineMedium),
                              for (final m in totals.values) MoneyText(m, style: textTheme.headlineMedium),
                              if (totals.length > 1 || (totals.length == 1 && totals.keys.first != base)) ...[
                                const SizedBox(height: QtSpace.s2),
                                Text(l.overviewTotalIn(base.code), style: TextStyle(color: p.textSecondary)),
                                MoneyText(converted.total, style: textTheme.titleLarge),
                                if (converted.missing.isNotEmpty)
                                  Text(
                                    l.ratesMissing(converted.missing.map((c) => c.code).join(', ')),
                                    style: TextStyle(color: p.warning, fontSize: QtFontSize.sm),
                                  ),
                              ],
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
                      ],
                    ),
                  ),
                  const SizedBox(height: QtSpace.s4),
                  _SafeToSpendCard(safe: safe),
                  if (pending.isNotEmpty) ...[
                    const SizedBox(height: QtSpace.s6),
                    _SectionHeader(
                      title: l.pendingTitle(pending.length),
                      onMore: () => context.go('/transactions'),
                      more: l.seeAll,
                    ),
                    Card(
                      child: Column(
                        children: [
                          for (final t in pending.take(5))
                            Column(
                              children: [
                                TxnTile(txn: t, data: data, showDate: true),
                                Padding(
                                  padding: const EdgeInsets.only(right: QtSpace.s2, bottom: QtSpace.s1),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () => ref.read(ledgerProvider.notifier).deleteTxn(t.id),
                                        child: Text(l.pendingSkip),
                                      ),
                                      const SizedBox(width: QtSpace.s2),
                                      FilledButton(
                                        onPressed: () => ref.read(ledgerProvider.notifier).confirmPending(t.id),
                                        child: Text(l.pendingConfirm),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: QtSpace.s6),
                  const PeriodBalanceCard(),
                  if (bills.isNotEmpty) ...[
                    const SizedBox(height: QtSpace.s6),
                    _SectionHeader(title: l.billsUpcoming, onMore: () => context.go('/more/recurring'), more: l.seeAll),
                    Card(
                      child: Column(
                        children: [for (final (r, due) in bills) BillTile(recurring: r, due: due, data: data)],
                      ),
                    ),
                  ],
                  if (watchBudgets.isNotEmpty) ...[
                    const SizedBox(height: QtSpace.s6),
                    _SectionHeader(title: l.budgetAlertsTitle, onMore: () => context.go('/plan'), more: l.seeAll),
                    for (final b in watchBudgets)
                      Padding(
                        padding: const EdgeInsets.only(bottom: QtSpace.s3),
                        child: BudgetCard(budget: b, data: data),
                      ),
                  ],
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

class _SafeToSpendCard extends ConsumerWidget {
  const _SafeToSpendCard({required this.safe});
  final SafeToSpend safe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final p = context.palette;
    final hide = ref.watch(settingsProvider.select((s) => s.hideBalances));
    String fmt(Money m) => hide ? '••••••' : formatMoney(m, locale: context.appLocale);
    final over = safe.amount.isNegative;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(QtRadius.lg),
        onTap: () => context.go('/more/reports'),
        child: Padding(
          padding: const EdgeInsets.all(QtSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(over ? Icons.error_outline : Icons.shield_outlined, color: over ? p.danger : p.primary),
                  const SizedBox(width: QtSpace.s2),
                  Expanded(
                    child: Text(l.safeTitle, style: TextStyle(color: p.textSecondary)),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: QtSpace.s1),
              MoneyText(safe.amount, style: Theme.of(context).textTheme.titleLarge),
              Text(
                over ? l.safeOver(fmt(-safe.amount)) : l.safePerDay(fmt(safe.perDay)),
                style: TextStyle(color: over ? p.danger : p.textPrimary),
              ),
              const SizedBox(height: QtSpace.s1),
              Text(
                l.safeExplain(fmt(safe.income), fmt(safe.spent), fmt(safe.upcomingBills), fmt(safe.goals)),
                style: TextStyle(color: p.textSecondary, fontSize: QtFontSize.sm),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
