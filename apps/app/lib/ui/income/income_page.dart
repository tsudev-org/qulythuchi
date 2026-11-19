import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../../state/providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';

enum IncomeGroupBy { payer, category, plan }

/// "Khoản thu": cộng thu theo tháng/năm (gộp theo người trả, danh mục, khoản thu) và các khoản thu nhận nhiều đợt
/// (job freelance, hợp đồng) với tiến độ, đợt kế tiếp, phần quá hạn.
class IncomePage extends ConsumerStatefulWidget {
  const IncomePage({super.key});

  @override
  ConsumerState<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends ConsumerState<IncomePage> {
  late CivilDate _month = () {
    final t = todayCivil();
    return CivilDate(t.year, t.month, 1);
  }();
  bool _wholeYear = false;
  IncomeGroupBy _by = IncomeGroupBy.payer;
  bool _showClosed = false;

  DateRange get _range => _wholeYear
      ? DateRange(CivilDate(_month.year, 1, 1), CivilDate(_month.year, 12, 31))
      : DateRange(_month, CivilDate(_month.year, _month.month, CivilDate.daysInMonth(_month.year, _month.month)));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    final data = ref.watch(ledgerProvider);
    final today = todayCivil();
    final text = Theme.of(context).textTheme;
    final wallets = data.wallets.where((w) => !w.excludeFromTotal).toList();
    final groups = Ledger.incomeBy(wallets, data.txns, _range, switch (_by) {
      IncomeGroupBy.payer => (t) => t.payee?.trim().isEmpty ?? true ? null : t.payee!.trim(),
      IncomeGroupBy.category => (t) => t.categoryId,
      IncomeGroupBy.plan => (t) => t.incomePlanId,
    });
    final totals = <Currency, (int, int, int)>{};
    for (final g in groups) {
      final c = g.received.currency;
      final (n, w, k) = totals[c] ?? (0, 0, 0);
      totals[c] = (n + g.received.minor, w + g.withheld.minor, k + g.count);
    }
    String groupLabel(String? key) => switch (_by) {
      IncomeGroupBy.payer => key ?? l.incomeNoPayer,
      IncomeGroupBy.category => data.category(key)?.name ?? l.txnNoCategory,
      IncomeGroupBy.plan => data.incomePlan(key)?.name ?? l.incomeNoPlan,
    };
    final plans = data.incomePlans.where((x) => _showClosed || x.status == IncomePlanStatus.active).toList();
    final closedCount = data.incomePlans.where((x) => x.status != IncomePlanStatus.active).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.incomeTitle),
        actions: [
          IconButton(
            tooltip: l.incomeRecord,
            icon: const Icon(Icons.add_card),
            onPressed: data.wallets.isEmpty ? null : () => context.go('/transactions/new?kind=income'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('income.newPlan'),
        onPressed: () => context.go('/more/income/new'),
        icon: const Icon(Icons.add),
        label: Text(l.incomePlanNew),
      ),
      body: PageBody(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(QtSpace.s4, 0, QtSpace.s4, 96),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(QtSpace.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: l.periodPrev,
                          onPressed: () => setState(() => _month = _month.addMonths(_wholeYear ? -12 : -1)),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Expanded(
                          child: Text(
                            _wholeYear ? l.incomeYear(_month.year) : l.periodTitle(_month.month, _month.year),
                            textAlign: TextAlign.center,
                            style: text.titleMedium,
                          ),
                        ),
                        IconButton(
                          tooltip: l.periodNext,
                          onPressed: () => setState(() => _month = _month.addMonths(_wholeYear ? 12 : 1)),
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                    SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(value: false, label: Text(l.incomeByMonth)),
                        ButtonSegment(value: true, label: Text(l.incomeByYear)),
                      ],
                      selected: {_wholeYear},
                      showSelectedIcon: false,
                      onSelectionChanged: (s) => setState(() => _wholeYear = s.first),
                    ),
                    const SizedBox(height: QtSpace.s3),
                    Text(l.incomeTotalReceived, style: TextStyle(color: p.textSecondary)),
                    if (totals.isEmpty) MoneyText(Money.zero(Currency.vnd), style: text.headlineSmall),
                    for (final MapEntry(key: c, value: (n, w, k)) in totals.entries) ...[
                      MoneyText(Money(n, c), key: Key('income.total.${c.code}'), style: text.headlineSmall),
                      Text(
                        [
                          l.incomeReceipts(k),
                          if (w > 0) l.incomeWithheldTotal(formatMoney(Money(w, c), locale: context.appLocale)),
                          if (w > 0) l.incomeGrossTotal(formatMoney(Money(n + w, c), locale: context.appLocale)),
                        ].join(' · '),
                        style: TextStyle(color: p.textMuted, fontSize: QtFontSize.sm),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: QtSpace.s4),
            Row(
              children: [
                Expanded(
                  child: Semantics(header: true, child: Text(l.incomeSumBy, style: text.titleMedium)),
                ),
                DropdownButton<IncomeGroupBy>(
                  value: _by,
                  underline: const SizedBox.shrink(),
                  items: [
                    DropdownMenuItem(value: IncomeGroupBy.payer, child: Text(l.incomeByPayer)),
                    DropdownMenuItem(value: IncomeGroupBy.category, child: Text(l.incomeByCategory)),
                    DropdownMenuItem(value: IncomeGroupBy.plan, child: Text(l.incomeByPlan)),
                  ],
                  onChanged: (v) => setState(() => _by = v ?? _by),
                ),
              ],
            ),
            Card(
              child: groups.isEmpty
                  ? Padding(padding: const EdgeInsets.all(QtSpace.s4), child: Text(l.incomeNone))
                  : Column(
                      children: [
                        for (final g in groups)
                          ListTile(
                            title: Text(groupLabel(g.key), maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                              [
                                l.incomeReceipts(g.count),
                                l.incomeLast(formatDate(g.lastDate)),
                                if (!g.withheld.isZero)
                                  l.incomeWithheldTotal(formatMoney(g.withheld, locale: context.appLocale)),
                              ].join(' · '),
                            ),
                            trailing: MoneyText(g.received),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: QtSpace.s6),
            Row(
              children: [
                Expanded(
                  child: Semantics(header: true, child: Text(l.incomePlansTitle, style: text.titleMedium)),
                ),
                if (closedCount > 0)
                  TextButton(
                    onPressed: () => setState(() => _showClosed = !_showClosed),
                    child: Text(_showClosed ? l.incomeHideClosed : l.incomeShowClosed(closedCount)),
                  ),
              ],
            ),
            Text(l.incomePlansHelp, style: TextStyle(color: p.textSecondary)),
            const SizedBox(height: QtSpace.s2),
            if (plans.isEmpty)
              Card(child: Padding(padding: const EdgeInsets.all(QtSpace.s4), child: Text(l.incomePlansEmpty)))
            else
              for (final plan in plans)
                Padding(
                  padding: const EdgeInsets.only(bottom: QtSpace.s3),
                  child: IncomePlanCard(plan: plan, progress: Ledger.incomePlanProgress(plan, data.txns, today)),
                ),
          ],
        ),
      ),
    );
  }
}

class IncomePlanCard extends StatelessWidget {
  const IncomePlanCard({super.key, required this.plan, required this.progress});
  final IncomePlan plan;
  final IncomePlanProgress progress;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    final locale = context.appLocale;
    final next = progress.nextInstallment;
    final overdue = !progress.overdue.isZero && plan.status == IncomePlanStatus.active;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(QtRadius.lg),
        onTap: () => context.go('/more/income/${plan.id}'),
        child: Padding(
          padding: const EdgeInsets.all(QtSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      plan.name,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (plan.status != IncomePlanStatus.active)
                    Text(
                      plan.status == IncomePlanStatus.completed ? l.incomeStatusDone : l.incomeStatusCancelled,
                      style: TextStyle(color: p.textMuted),
                    ),
                ],
              ),
              if (plan.payer != null) Text(plan.payer!, style: TextStyle(color: p.textSecondary)),
              const SizedBox(height: QtSpace.s2),
              Text(
                plan.total > 0
                    ? l.incomeProgress(
                        formatMoney(progress.gross, locale: locale),
                        formatMoney(Money(plan.total, plan.currency), locale: locale),
                      )
                    : l.incomeReceivedSoFar(formatMoney(progress.received, locale: locale)),
              ),
              if (progress.progressBp != null) ...[
                const SizedBox(height: QtSpace.s1),
                ProgressBar(
                  basisPoints: progress.progressBp!,
                  color: progress.progressBp! >= 10000 ? p.success : p.primary,
                  semanticLabel: plan.name,
                ),
              ],
              if (next != null && plan.status == IncomePlanStatus.active) ...[
                const SizedBox(height: QtSpace.s2),
                Text(
                  l.incomeNext(
                    next.label ?? l.incomeInstallment,
                    formatMoney(Money(next.amount, plan.currency), locale: locale),
                    formatDate(next.date),
                  ),
                  style: TextStyle(color: overdue ? p.danger : p.textSecondary),
                ),
              ],
              if (overdue)
                Text(
                  l.incomeOverdue(formatMoney(progress.overdue, locale: locale)),
                  style: TextStyle(color: p.danger, fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
