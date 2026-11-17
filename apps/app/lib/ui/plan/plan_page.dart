import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../../l10n/app_localizations.dart';
import '../../state/ledger_repository.dart';
import '../../state/providers.dart';
import '../../state/settings.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../widgets/amount_field.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';

/// Kế hoạch: ngân sách (danh mục/phong bì), 6 hũ, mục tiêu tiết kiệm.
class PlanPage extends ConsumerStatefulWidget {
  const PlanPage({super.key});

  @override
  ConsumerState<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends ConsumerState<PlanPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this)..addListener(() => setState(() {}));

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final data = ref.watch(ledgerProvider);
    final fab = switch (_tabs.index) {
      0 => FloatingActionButton(
        tooltip: l.budgetNew,
        onPressed: () => context.go('/plan/budgets/new'),
        child: const Icon(Icons.add),
      ),
      2 => FloatingActionButton(
        tooltip: l.goalNew,
        onPressed: () => context.go('/plan/goals/new'),
        child: const Icon(Icons.add),
      ),
      _ => null,
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(l.navPlan),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: l.planBudgets),
            Tab(text: l.planJars),
            Tab(text: l.planGoals),
          ],
        ),
      ),
      floatingActionButton: fab,
      body: PageBody(
        child: TabBarView(
          controller: _tabs,
          children: [
            _BudgetsTab(data: data),
            const _JarsTab(),
            _GoalsTab(data: data),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Ngân sách

(IconData, Color, String) budgetStateLook(BuildContext context, BudgetState s) {
  final p = context.palette;
  final l = context.l10n;
  return switch (s) {
    BudgetState.ok => (Icons.check_circle_outline, p.success, l.budgetStateOk),
    BudgetState.warning => (Icons.warning_amber_outlined, p.warning, l.budgetStateWarning),
    BudgetState.over => (Icons.error_outline, p.danger, l.budgetStateOver),
  };
}

String periodLabel(AppLocalizations l, BudgetPeriod p) => switch (p) {
  BudgetPeriod.weekly => l.periodWeekly,
  BudgetPeriod.monthly => l.periodMonthly,
  BudgetPeriod.yearly => l.periodYearly,
  BudgetPeriod.custom => l.periodCustom,
};

/// Thẻ một ngân sách (dùng cả ở Tổng quan).
class BudgetCard extends ConsumerWidget {
  const BudgetCard({super.key, required this.budget, required this.data});
  final Budget budget;
  final LedgerData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final p = context.palette;
    final hide = ref.watch(settingsProvider.select((s) => s.hideBalances));
    final st = Ledger.budgetStatus(
      budget,
      txns: data.txns,
      categories: data.categories,
      wallets: data.wallets,
      today: todayCivil(),
    );
    final (icon, color, stateText) = budgetStateLook(context, st.state);
    String fmt(Money m) => hide ? '••••••' : formatMoney(m, locale: context.appLocale);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(QtRadius.lg),
        onTap: () => context.go('/plan/budgets/${budget.id}'),
        child: Padding(
          padding: const EdgeInsets.all(QtSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(budget.name, style: Theme.of(context).textTheme.titleMedium)),
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: QtSpace.s1),
                  Text(
                    stateText,
                    style: TextStyle(color: color, fontSize: QtFontSize.sm),
                  ),
                ],
              ),
              const SizedBox(height: QtSpace.s1),
              Text(
                '${periodLabel(l, budget.period)} · ${formatDate(st.range.start)} - ${formatDate(st.range.end)}',
                style: TextStyle(color: p.textSecondary, fontSize: QtFontSize.sm),
              ),
              const SizedBox(height: QtSpace.s3),
              ProgressBar(basisPoints: st.usedBp, color: color, semanticLabel: budget.name),
              const SizedBox(height: QtSpace.s2),
              Wrap(
                spacing: QtSpace.s4,
                runSpacing: QtSpace.s1,
                children: [
                  Text(l.budgetSpentOf(fmt(st.spent), fmt(st.limit))),
                  Text(
                    st.remaining.isNegative ? l.budgetOver(fmt(-st.remaining)) : l.budgetRemaining(fmt(st.remaining)),
                    style: TextStyle(color: st.remaining.isNegative ? p.danger : p.textSecondary),
                  ),
                ],
              ),
              if (st.dailyAllowance.isPositive) ...[
                const SizedBox(height: QtSpace.s1),
                Text(
                  l.budgetDaily(fmt(st.dailyAllowance)),
                  style: TextStyle(color: p.textSecondary, fontSize: QtFontSize.sm),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetsTab extends StatelessWidget {
  const _BudgetsTab({required this.data});
  final LedgerData data;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (data.budgets.isEmpty) {
      return EmptyState(icon: Icons.savings_outlined, title: l.emptyBudgetsTitle, body: l.emptyBudgetsBody);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(QtSpace.s4, QtSpace.s4, QtSpace.s4, 96),
      children: [
        for (final b in data.budgets)
          Padding(
            padding: const EdgeInsets.only(bottom: QtSpace.s3),
            child: BudgetCard(budget: b, data: data),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------- 6 hũ

String jarName(AppLocalizations l, Jar j) => switch (j.key) {
  'nec' => l.jarNec,
  'lts' => l.jarLts,
  'edu' => l.jarEdu,
  'ply' => l.jarPly,
  'ffa' => l.jarFfa,
  'giv' => l.jarGiv,
  _ => j.name,
};

class _JarsTab extends ConsumerStatefulWidget {
  const _JarsTab();

  @override
  ConsumerState<_JarsTab> createState() => _JarsTabState();
}

class _JarsTabState extends ConsumerState<_JarsTab> {
  final _sim = TextEditingController();

  @override
  void initState() {
    super.initState();
    _sim.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _sim.dispose();
    super.dispose();
  }

  Future<void> _edit(JarPlan plan) async {
    final saved = await showDialog<JarPlan>(
      context: context,
      builder: (_) => _JarEditDialog(plan: plan),
    );
    if (saved == null || !mounted) return;
    ref.read(ledgerProvider.notifier).saveJarPlan(saved);
    context.toast(context.l10n.saved);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    final data = ref.watch(ledgerProvider);
    final plan = data.jarPlan ?? JarPlan.sixJars();
    final base = Currency.of(ref.watch(settingsProvider.select((s) => s.baseCurrency)));
    final today = todayCivil();
    final monthStart = CivilDate(today.year, today.month, 1);
    var income = 0;
    for (final t in data.txns) {
      if (t.kind != TxnKind.income || t.pending || t.excludeFromReports) continue;
      if (t.date < monthStart || t.date > today) continue;
      if (data.wallet(t.walletId)?.currency == base) income += t.amount;
    }
    final sim = AmountField.tryValue(_sim.text, base, context.appLocale);
    final amount = (sim != null && sim.isPositive) ? sim : Money(income, base);
    final parts = plan.allocate(amount);
    return ListView(
      padding: const EdgeInsets.fromLTRB(QtSpace.s4, QtSpace.s4, QtSpace.s4, 96),
      children: [
        Text(l.jarsNote, style: TextStyle(color: p.textSecondary)),
        const SizedBox(height: QtSpace.s4),
        Card(
          child: ListTile(
            title: Text(l.jarsIncomeThisMonth(base.code)),
            trailing: MoneyText(Money(income, base), style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
        // Luôn giữ phần tử này (chỉ đổi nội dung): thêm/bớt phần tử phía trên ô nhập sẽ dựng lại ô nhập và
        // làm mất focus khi đang gõ.
        Padding(
          padding: const EdgeInsets.only(top: QtSpace.s2),
          child: Text(
            income == 0 && sim == null ? l.jarsNoIncome(base.code) : '',
            style: TextStyle(color: p.textSecondary),
          ),
        ),
        const SizedBox(height: QtSpace.s4),
        AmountField(
          key: const ValueKey('jar-sim'),
          controller: _sim,
          currency: base,
          label: l.jarsSimulate,
          allowZero: true,
        ),
        const SizedBox(height: QtSpace.s4),
        Card(
          child: Column(
            children: [
              for (final j in plan.jars)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: p.bgSubtle,
                    foregroundColor: p.textPrimary,
                    child: Text('${percentText(j.basisPoints)}%', style: const TextStyle(fontSize: QtFontSize.xs)),
                  ),
                  title: Text(jarName(l, j)),
                  trailing: MoneyText(parts[j.key]!, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ),
        const SizedBox(height: QtSpace.s4),
        OutlinedButton.icon(onPressed: () => _edit(plan), icon: const Icon(Icons.tune), label: Text(l.jarsEdit)),
      ],
    );
  }
}

class _JarEditDialog extends StatefulWidget {
  const _JarEditDialog({required this.plan});
  final JarPlan plan;

  @override
  State<_JarEditDialog> createState() => _JarEditDialogState();
}

class _JarEditDialogState extends State<_JarEditDialog> {
  late List<Jar> _jars = [...widget.plan.jars];
  late final List<TextEditingController> _c = [
    for (final j in widget.plan.jars) TextEditingController(text: percentText(j.basisPoints)),
  ];

  @override
  void dispose() {
    for (final c in _c) {
      c.dispose();
    }
    super.dispose();
  }

  /// "55" hoặc "12,5"/"12.5" ⇒ phần vạn; sai ⇒ null.
  int? _bp(String s) {
    final m = RegExp(r'^(\d{1,3})(?:[.,](\d{1,2}))?$').firstMatch(s.trim());
    if (m == null) return null;
    return int.parse(m.group(1)!) * 100 + int.parse((m.group(2) ?? '').padRight(2, '0'));
  }

  int get _total => _c.fold(0, (a, c) => a + (_bp(c.text) ?? 0));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ok = _total == 10000 && _c.every((c) => _bp(c.text) != null);
    return AlertDialog(
      title: Text(l.jarsEdit),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < _jars.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: QtSpace.s3),
                  child: TextField(
                    controller: _c[i],
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: jarName(l, _jars[i]), suffixText: '%'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              Semantics(
                liveRegion: true,
                child: Text(
                  l.jarsTotalMustBe100(percentText(_total)),
                  style: TextStyle(color: ok ? context.palette.success : context.palette.danger),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(() {
            _jars = [...JarPlan.sixJars().jars];
            for (var i = 0; i < _c.length && i < _jars.length; i++) {
              _c[i].text = percentText(_jars[i].basisPoints);
            }
          }),
          child: Text(l.jarsReset),
        ),
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.actionCancel)),
        FilledButton(
          onPressed: ok
              ? () => Navigator.pop(
                  context,
                  JarPlan([for (var i = 0; i < _jars.length; i++) Jar(_jars[i].key, _jars[i].name, _bp(_c[i].text)!)]),
                )
              : null,
          child: Text(l.actionSave),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Mục tiêu

class _GoalsTab extends ConsumerWidget {
  const _GoalsTab({required this.data});
  final LedgerData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final p = context.palette;
    final hide = ref.watch(settingsProvider.select((s) => s.hideBalances));
    if (data.goals.isEmpty) {
      return EmptyState(icon: Icons.flag_outlined, title: l.emptyGoalsTitle, body: l.emptyGoalsBody);
    }
    String fmt(Money m) => hide ? '••••••' : formatMoney(m, locale: context.appLocale);
    final today = todayCivil();
    return ListView(
      padding: const EdgeInsets.fromLTRB(QtSpace.s4, QtSpace.s4, QtSpace.s4, 96),
      children: [
        for (final g in data.goals)
          Padding(
            padding: const EdgeInsets.only(bottom: QtSpace.s3),
            child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(QtRadius.lg),
                onTap: () => context.go('/plan/goals/${g.id}'),
                child: Padding(
                  padding: const EdgeInsets.all(QtSpace.s4),
                  child: Builder(
                    builder: (context) {
                      final st = Ledger.goalStatus(g, data.txns, today);
                      final done = g.achieved || st.progressBp >= 10000;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(done ? Icons.emoji_events_outlined : Icons.flag_outlined, color: p.primary),
                              const SizedBox(width: QtSpace.s2),
                              Expanded(child: Text(g.name, style: Theme.of(context).textTheme.titleMedium)),
                              if (done) Text(l.goalAchieved, style: TextStyle(color: p.success)),
                            ],
                          ),
                          const SizedBox(height: QtSpace.s3),
                          ProgressBar(
                            basisPoints: st.progressBp,
                            color: done ? p.success : p.primary,
                            semanticLabel: g.name,
                          ),
                          const SizedBox(height: QtSpace.s2),
                          Text(
                            l.goalProgress(fmt(st.saved), fmt(Money(g.target, g.currency)), percentText(st.progressBp)),
                          ),
                          if (g.deadline != null)
                            Text(
                              '${l.goalDeadline}: ${formatDate(g.deadline!)}',
                              style: TextStyle(color: p.textSecondary, fontSize: QtFontSize.sm),
                            ),
                          if (!done && st.monthlyNeeded != null)
                            Text(
                              l.goalMonthly(fmt(st.monthlyNeeded!)),
                              style: TextStyle(color: p.textSecondary, fontSize: QtFontSize.sm),
                            ),
                          if (!done) ...[
                            const SizedBox(height: QtSpace.s2),
                            Align(
                              alignment: Alignment.centerRight,
                              child: OutlinedButton.icon(
                                onPressed: () => context.go('/transactions/new?kind=transfer&goal=${g.id}'),
                                icon: const Icon(Icons.add),
                                label: Text(l.goalContribute),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
