import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../../domain/reports.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../../state/settings.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';
import 'charts.dart';

String presetLabel(AppLocalizations l, ReportPreset p) => switch (p) {
  ReportPreset.thisMonth => l.reportThisMonth,
  ReportPreset.lastMonth => l.reportLastMonth,
  ReportPreset.last3Months => l.reportLast3Months,
  ReportPreset.thisYear => l.reportThisYear,
  ReportPreset.custom => l.periodCustom,
};

String monthLabel(CivilDate m) => '${m.month}/${(m.year % 100).toString().padLeft(2, '0')}';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  ReportPreset _preset = ReportPreset.thisMonth;
  CivilDate? _from;
  CivilDate? _to;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    final c = context.chartPalette;
    final loc = context.appLocale;
    final hide = ref.watch(settingsProvider.select((s) => s.hideBalances));
    final base = Currency.of(ref.watch(settingsProvider.select((s) => s.baseCurrency)));
    final data = ref.watch(ledgerProvider);
    final today = todayCivil();
    final custom = (_from != null && _to != null && !(_to! < _from!)) ? DateRange(_from!, _to!) : null;
    final range = presetRange(_preset, today, custom: custom);
    final rep = Reports(data, base);
    final sum = rep.summary(range);
    final prev = rep.summary(previousRange(range));
    String? delta(Money cur, Money before) {
      final bp = changeBp(cur, before);
      if (bp == null || hide) return null;
      return l.reportVsPrevious(
        '${bp > 0
            ? '+'
            : bp < 0
            ? '−'
            : ''}${percentText(bp.abs())}%',
      );
    }

    String fmt(Money m, {bool sign = false}) => hide ? '••••••' : formatMoney(m, locale: loc, plusSign: sign);

    final months = rep.monthly(today, 6);
    final shares = rep.categoryShares(range);
    final maxShare = shares.isEmpty ? Money.zero(base) : shares.map((s) => s.amount).reduce((a, b) => a > b ? a : b);
    final netWorth = rep.netWorth(today, 6);
    final calMonth = range.end > today ? today : range.end;
    final daily = rep.dailyExpense(calMonth);

    String catName(String? id) {
      if (id == CategoryShare.otherId) return l.reportOther;
      return data.category(id)?.name ?? l.uncategorized;
    }

    void openCategory(String? id) {
      if (id == CategoryShare.otherId) return;
      context.go(
        Uri(
          path: '/transactions',
          queryParameters: {'cat': id ?? 'none', 'from': range.start.toString(), 'to': range.end.toString()},
        ).toString(),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.navReports)),
      body: PageBody(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(QtSpace.s4, QtSpace.s2, QtSpace.s4, QtSpace.s12),
          children: [
            // Bộ lọc kỳ: một hàng phía trên mọi biểu đồ.
            Wrap(
              spacing: QtSpace.s2,
              runSpacing: QtSpace.s2,
              children: [
                for (final pr in ReportPreset.values)
                  ChoiceChip(
                    label: Text(presetLabel(l, pr)),
                    selected: _preset == pr,
                    onSelected: (_) => setState(() => _preset = pr),
                  ),
              ],
            ),
            if (_preset == ReportPreset.custom) ...[
              const SizedBox(height: QtSpace.s3),
              Row(
                children: [
                  Expanded(
                    child: DateField(label: l.budgetFrom, value: _from, onChanged: (d) => setState(() => _from = d)),
                  ),
                  const SizedBox(width: QtSpace.s3),
                  Expanded(
                    child: DateField(label: l.budgetTo, value: _to, onChanged: (d) => setState(() => _to = d)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: QtSpace.s2),
            Text(
              '${formatDate(range.start)} - ${formatDate(range.end)} · ${base.code}',
              style: TextStyle(color: p.textSecondary, fontSize: QtFontSize.sm),
            ),
            if (sum.missing.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: QtSpace.s1),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_outlined, size: 18, color: p.warning),
                    const SizedBox(width: QtSpace.s1),
                    Expanded(
                      child: Text(
                        l.ratesMissing(sum.missing.map((c) => c.code).join(', ')),
                        style: TextStyle(fontSize: QtFontSize.sm),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: QtSpace.s3),
            // Ô số liệu chính.
            LayoutBuilder(
              builder: (context, cons) {
                final tiles = [
                  _StatTile(label: l.reportIncome, value: fmt(sum.income), delta: delta(sum.income, prev.income)),
                  _StatTile(label: l.reportExpense, value: fmt(sum.expense), delta: delta(sum.expense, prev.expense)),
                  _StatTile(label: l.reportNet, value: fmt(sum.net, sign: true)),
                  _StatTile(
                    label: l.reportSavingsRate,
                    value: sum.savingsRateBp == null ? '-' : '${percentText(sum.savingsRateBp!)}%',
                  ),
                ];
                final perRow = cons.maxWidth >= 640 ? 4 : 2;
                final w = (cons.maxWidth - QtSpace.s3 * (perRow - 1)) / perRow;
                return Wrap(
                  spacing: QtSpace.s3,
                  runSpacing: QtSpace.s3,
                  children: [for (final t in tiles) SizedBox(width: w, child: t)],
                );
              },
            ),
            const SizedBox(height: QtSpace.s4),
            ChartCard(
              title: l.reportMonthly,
              legend: ChartLegend(items: [(c.series1, l.reportIncome), (c.series2, l.reportExpense)]),
              chart: PairedBarChart(
                labels: [for (final m in months) monthLabel(m.month)],
                a: [for (final m in months) m.income],
                b: [for (final m in months) m.expense],
                readout: (i) =>
                    l.reportMonthReadout(monthLabel(months[i].month), fmt(months[i].income), fmt(months[i].expense)),
              ),
              table: DataTableView(
                headers: [l.reportColMonth, l.reportIncome, l.reportExpense, l.reportNet],
                rows: [
                  for (final m in months)
                    [monthLabel(m.month), fmt(m.income), fmt(m.expense), fmt(m.income - m.expense, sign: true)],
                ],
              ),
            ),
            const SizedBox(height: QtSpace.s4),
            ChartCard(
              title: l.reportByCategory,
              chart: shares.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: QtSpace.s4),
                      child: Text(l.reportEmpty, style: TextStyle(color: p.textSecondary)),
                    )
                  : HorizontalBars(
                      rows: [
                        for (final s in shares)
                          (
                            catName(s.categoryId),
                            fmt(s.amount),
                            maxShare.isZero ? 0 : s.amount.basisPointsOf(maxShare),
                            '${percentText(s.shareBp)}%',
                            s.categoryId == CategoryShare.otherId ? null : () => openCategory(s.categoryId),
                          ),
                      ],
                    ),
              table: DataTableView(
                headers: [l.reportColCategory, l.reportColAmount, l.reportColShare],
                rows: [
                  for (final s in shares) [catName(s.categoryId), fmt(s.amount), '${percentText(s.shareBp)}%'],
                ],
              ),
            ),
            const SizedBox(height: QtSpace.s4),
            ChartCard(
              title: l.reportNetWorth,
              chart: LineChart(
                labels: [for (final (m, _) in netWorth) monthLabel(m)],
                values: [for (final (_, v) in netWorth) v],
                readout: (i) => l.reportPointReadout(monthLabel(netWorth[i].$1), fmt(netWorth[i].$2)),
              ),
              table: DataTableView(
                headers: [l.reportColMonth, l.reportNetWorth],
                rows: [
                  for (final (m, v) in netWorth) [monthLabel(m), fmt(v)],
                ],
              ),
            ),
            const SizedBox(height: QtSpace.s4),
            ChartCard(
              title: l.reportCalendar(monthLabel(CivilDate(calMonth.year, calMonth.month, 1))),
              chart: SpendingCalendar(
                month: calMonth,
                daily: daily,
                readout: (d) => l.reportDayReadout(
                  formatDate(CivilDate(calMonth.year, calMonth.month, d)),
                  fmt(daily[d] ?? Money.zero(base)),
                ),
              ),
              table: DataTableView(
                headers: [l.reportColDay, l.reportExpense],
                rows: [
                  for (final e in (daily.entries.toList()..sort((a, b) => a.key.compareTo(b.key))))
                    [formatDate(CivilDate(calMonth.year, calMonth.month, e.key)), fmt(e.value)],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, this.delta});
  final String label;
  final String value;

  /// "+12% so với kỳ trước" - chữ, không chỉ dựa vào màu.
  final String? delta;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(QtSpace.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: context.palette.textSecondary, fontSize: QtFontSize.sm),
          ),
          const SizedBox(height: QtSpace.s1),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
          if (delta != null)
            Text(
              delta!,
              style: TextStyle(color: context.palette.textSecondary, fontSize: QtFontSize.sm),
            ),
        ],
      ),
    ),
  );
}
