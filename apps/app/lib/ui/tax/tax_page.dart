import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../../domain/default_categories.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../widgets/amount_field.dart';
import '../widgets/common.dart';

/// Thuế thu nhập cá nhân (Việt Nam): ước tính quyết toán năm từ sổ, máy tính lương gross/net, hạn nộp, phân loại
/// danh mục thu. CHỈ ĐỂ THAM KHẢO.
class TaxPage extends ConsumerStatefulWidget {
  const TaxPage({super.key});

  @override
  ConsumerState<TaxPage> createState() => _TaxPageState();
}

class _TaxPageState extends ConsumerState<TaxPage> {
  int _year = todayCivil().year;
  final _salary = TextEditingController();
  bool _netMode = false;

  @override
  void dispose() {
    _salary.dispose();
    super.dispose();
  }

  String _m(int v) => formatMoney(Money(v, Currency.vnd), locale: context.appLocale);

  Future<void> _editProfile(TaxProfile p) async {
    final l = context.l10n;
    final loc = context.appLocale;
    final ins = TextEditingController(
      text: p.monthlyInsurance == null
          ? ''
          : formatMoney(Money(p.monthlyInsurance!, Currency.vnd), locale: loc, withSymbol: false),
    );
    var dep = p.dependents;
    var resident = p.residency == TaxResidency.resident;
    var business = p.businessHousehold;
    final saved = await showDialog<TaxProfile>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(l.taxProfile),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(l.taxDependents)),
                      IconButton(
                        tooltip: l.taxLess,
                        onPressed: dep > 0 ? () => setLocal(() => dep--) : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Text('$dep', key: const Key('tax.dependents')),
                      IconButton(
                        tooltip: l.taxMore,
                        onPressed: dep < 20 ? () => setLocal(() => dep++) : null,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  TextField(
                    controller: ins,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l.taxInsurance,
                      helperText: l.taxInsuranceHelp,
                      helperMaxLines: 3,
                      suffixText: '₫',
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: resident,
                    onChanged: (v) => setLocal(() => resident = v),
                    title: Text(l.taxResident),
                    subtitle: Text(l.taxResidentSub),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: business,
                    onChanged: (v) => setLocal(() => business = v),
                    title: Text(l.taxBusiness),
                    subtitle: Text(l.taxBusinessSub),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.actionCancel)),
            FilledButton(
              onPressed: () => Navigator.pop(
                ctx,
                TaxProfile(
                  dependents: dep,
                  residency: resident ? TaxResidency.resident : TaxResidency.nonResident,
                  monthlyInsurance: AmountField.tryValue(ins.text, Currency.vnd, loc)?.minor,
                  monthlyCharity: p.monthlyCharity,
                  remindersEnabled: p.remindersEnabled,
                  businessHousehold: business,
                ),
              ),
              child: Text(l.actionSave),
            ),
          ],
        ),
      ),
    );
    ins.dispose();
    if (saved == null || !mounted) return;
    try {
      ref.read(ledgerProvider.notifier).saveTaxProfile(saved);
      context.toast(l.saved);
    } on Object catch (e) {
      context.toast(errorMessage(context, e));
    }
  }

  Future<void> _classify(Category c) async {
    final l = context.l10n;
    final v = await showDialog<IncomeTaxType>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(c.name),
        children: [
          for (final t in IncomeTaxType.values)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, t),
              child: ListTile(
                selected: t == c.taxType,
                title: Text(taxTypeLabel(l, t)),
                subtitle: Text(taxTypeHelp(l, t)),
              ),
            ),
        ],
      ),
    );
    if (v == null || !mounted) return;
    ref
        .read(ledgerProvider.notifier)
        .saveCategory(
          Category(
            id: c.id,
            name: c.name,
            kind: c.kind,
            parentId: c.parentId,
            icon: c.icon,
            color: c.color,
            archived: c.archived,
            taxType: v,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final data = ref.watch(ledgerProvider);
    final profile = data.taxProfile;
    final today = todayCivil();
    final e = AnnualPitEstimate.fromLedger(
      year: _year,
      txns: data.txns,
      categories: data.categories,
      wallets: data.wallets,
      profile: profile,
    );
    final rules = e.rules;
    final deadlines = VnTaxCalendar.upcoming(today, days: 400, business: profile.businessHousehold);
    final incomeCats = data.categories.where((c) => c.kind == CategoryKind.income && !c.archived).toList();
    final unclassified = incomeCats.where((c) => c.taxType == IncomeTaxType.unknown && c.parentId == null).length;

    final input = AmountField.tryValue(_salary.text, Currency.vnd, context.appLocale)?.minor;
    MonthlyPit? calc;
    if (input != null && input > 0) {
      final gross = _netMode
          ? rules.grossForNet(input, dependents: profile.dependents, insurance: profile.monthlyInsurance)
          : input;
      calc = rules.monthly(
        gross: gross,
        dependents: profile.dependents,
        insurance: profile.monthlyInsurance,
        resident: profile.residency == TaxResidency.resident,
      );
    }

    Widget line(String label, String value, {bool strong = false, Color? color, Key? key}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: strong ? null : p.textSecondary)),
          ),
          Text(
            value,
            key: key,
            style: (strong ? text.titleSmall : text.bodyMedium)?.copyWith(color: color),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l.taxTitle),
        actions: [
          IconButton(
            tooltip: l.taxProfile,
            icon: const Icon(Icons.badge_outlined),
            onPressed: () => _editProfile(profile),
          ),
        ],
      ),
      body: PageBody(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(QtSpace.s4, 0, QtSpace.s4, QtSpace.s12),
          children: [
            Card(
              color: p.bgSubtle,
              child: Padding(
                padding: const EdgeInsets.all(QtSpace.s3),
                child: Text(
                  l.taxDisclaimer,
                  style: TextStyle(color: p.textSecondary, fontSize: QtFontSize.sm),
                ),
              ),
            ),
            const SizedBox(height: QtSpace.s3),
            Card(
              child: ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: Text(l.taxProfile),
                subtitle: Text(
                  [
                    l.taxDependentsN(profile.dependents),
                    profile.residency == TaxResidency.resident ? l.taxResident : l.taxNonResident,
                    if (profile.monthlyInsurance != null) l.taxInsuranceN(_m(profile.monthlyInsurance!)),
                  ].join(' · '),
                ),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => _editProfile(profile),
              ),
            ),
            if (unclassified > 0 || incomeCats.isEmpty) ...[
              const SizedBox(height: QtSpace.s3),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(QtSpace.s4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l.taxUnclassified(unclassified), style: TextStyle(color: p.warning)),
                      const SizedBox(height: QtSpace.s2),
                      FilledButton.tonal(
                        key: const Key('tax.standardCategories'),
                        onPressed: () {
                          final n = ref
                              .read(ledgerProvider.notifier)
                              .ensureStandardIncomeCategories(
                                context.appLocale == AppLocale.vi ? DefaultCategoryLocale.vi : DefaultCategoryLocale.en,
                              );
                          context.toast(l.taxStandardDone(n));
                        },
                        child: Text(l.taxStandardCategories),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: QtSpace.s4),
            Row(
              children: [
                Expanded(
                  child: Semantics(header: true, child: Text(l.taxEstimateTitle(_year), style: text.titleMedium)),
                ),
                IconButton(
                  tooltip: l.periodPrev,
                  onPressed: () => setState(() => _year--),
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  tooltip: l.periodNext,
                  onPressed: _year >= today.year ? null : () => setState(() => _year++),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(QtSpace.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    line(l.taxSalaryIncome, _m(e.salaryIncome)),
                    line(l.taxCasualIncome, _m(e.casualIncome)),
                    if (e.businessRevenue > 0) line(l.taxBusinessRevenue, _m(e.businessRevenue)),
                    if (e.investmentIncome > 0) line(l.taxInvestmentIncome, _m(e.investmentIncome)),
                    if (e.exemptIncome > 0) line(l.taxExemptIncome, _m(e.exemptIncome)),
                    if (e.unclassifiedIncome > 0)
                      line(l.taxUnclassifiedIncome, _m(e.unclassifiedIncome), color: p.warning),
                    const Divider(),
                    line(l.taxInsuranceYear, '-${_m(e.insurance)}'),
                    line(l.taxDeductionYear, '-${_m(e.deduction)}'),
                    line(l.taxTaxable, _m(e.taxable)),
                    line(l.taxDue, _m(e.tax), strong: true, key: const Key('tax.due')),
                    line(l.taxWithheld, _m(e.withheld)),
                    const Divider(),
                    line(
                      e.balance > 0 ? l.taxPayMore : l.taxRefund,
                      _m(e.balance.abs()),
                      strong: true,
                      color: e.balance > 0 ? p.danger : p.success,
                      key: const Key('tax.balance'),
                    ),
                    const SizedBox(height: QtSpace.s2),
                    Text(
                      l.taxSettlementNote(formatDate(VnTaxCalendar.selfSettlementDeadline(_year))),
                      style: TextStyle(color: p.textMuted, fontSize: QtFontSize.sm),
                    ),
                    if (e.businessOverThreshold)
                      Padding(
                        padding: const EdgeInsets.only(top: QtSpace.s2),
                        child: Text(
                          l.taxBusinessOver(_m(rules.businessExemptRevenue)),
                          style: TextStyle(color: p.warning),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: QtSpace.s6),
            Semantics(header: true, child: Text(l.taxCalcTitle, style: text.titleMedium)),
            const SizedBox(height: QtSpace.s2),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(QtSpace.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(value: false, label: Text(l.taxFromGross)),
                        ButtonSegment(value: true, label: Text(l.taxFromNet)),
                      ],
                      selected: {_netMode},
                      showSelectedIcon: false,
                      onSelectionChanged: (s) => setState(() => _netMode = s.first),
                    ),
                    const SizedBox(height: QtSpace.s3),
                    TextField(
                      key: const Key('tax.salary'),
                      controller: _salary,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: _netMode ? l.taxNetSalary : l.taxGrossSalary,
                        suffixText: '₫',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    if (calc != null) ...[
                      const SizedBox(height: QtSpace.s3),
                      line(l.taxGrossSalary, _m(calc.gross), key: const Key('tax.calc.gross')),
                      line(l.taxInsuranceMonth, '-${_m(calc.insurance)}'),
                      line(l.taxDeductionMonth, '-${_m(calc.deduction)}'),
                      line(l.taxTaxable, _m(calc.taxable)),
                      line(l.taxMonthTax, '-${_m(calc.tax)}', key: const Key('tax.calc.tax')),
                      const Divider(),
                      line(l.taxNetSalary, _m(calc.net), strong: true, key: const Key('tax.calc.net')),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: QtSpace.s6),
            Semantics(header: true, child: Text(l.taxDeadlines, style: text.titleMedium)),
            const SizedBox(height: QtSpace.s2),
            Card(
              child: Column(
                children: [
                  for (final d in deadlines.take(6))
                    ListTile(
                      leading: const Icon(Icons.event_outlined),
                      title: Text(switch (d.kind) {
                        TaxDeadlineKind.selfSettlement => l.taxDeadlineSelf(d.forYear),
                        TaxDeadlineKind.authorizeEmployer => l.taxDeadlineAuthorize(d.forYear),
                        TaxDeadlineKind.businessQuarterly => l.taxDeadlineBusiness,
                      }),
                      subtitle: Text(l.taxDeadlineIn(formatDate(d.date), today.daysUntil(d.date))),
                    ),
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: Text(l.settingsTaxReminders),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/more/settings'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: QtSpace.s6),
            Semantics(header: true, child: Text(l.taxRulesTitle(rules.fromYear), style: text.titleMedium)),
            const SizedBox(height: QtSpace.s2),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(QtSpace.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    line(l.taxPersonalDeduction, _m(rules.personalDeduction)),
                    line(l.taxDependentDeduction, _m(rules.dependentDeduction)),
                    for (final (i, b) in rules.brackets.indexed)
                      line(
                        b.upTo == null
                            ? l.taxBracketOver(i + 1, _m(rules.brackets[i - 1].upTo!))
                            : l.taxBracketUpTo(i + 1, _m(b.upTo!)),
                        context.percent(b.rateBp),
                      ),
                    line(
                      l.taxCasualRule(_m(rules.casualWithholdingThreshold)),
                      context.percent(rules.casualWithholdingBp),
                    ),
                    line(l.taxBusinessThreshold, _m(rules.businessExemptRevenue)),
                    const SizedBox(height: QtSpace.s2),
                    Text(
                      l.taxSource(rules.source, rules.verifiedOn),
                      style: TextStyle(color: p.textMuted, fontSize: QtFontSize.sm),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: QtSpace.s6),
            Semantics(header: true, child: Text(l.taxCategoriesTitle, style: text.titleMedium)),
            const SizedBox(height: QtSpace.s2),
            Card(
              child: Column(
                children: [
                  for (final c in incomeCats)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.only(
                        left: c.parentId == null ? QtSpace.s4 : QtSpace.s8,
                        right: QtSpace.s4,
                      ),
                      title: Text(c.name),
                      trailing: Text(
                        c.taxType == IncomeTaxType.unknown && c.parentId != null
                            ? l.taxInherit
                            : taxTypeLabel(l, c.taxType),
                        style: TextStyle(color: c.taxType == IncomeTaxType.unknown ? p.textMuted : null),
                      ),
                      onTap: () => _classify(c),
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

String taxTypeLabel(AppLocalizations l, IncomeTaxType t) => switch (t) {
  IncomeTaxType.unknown => l.taxTypeUnknown,
  IncomeTaxType.salary => l.taxTypeSalary,
  IncomeTaxType.casual => l.taxTypeCasual,
  IncomeTaxType.business => l.taxTypeBusiness,
  IncomeTaxType.investment => l.taxTypeInvestment,
  IncomeTaxType.exempt => l.taxTypeExempt,
};

String taxTypeHelp(AppLocalizations l, IncomeTaxType t) => switch (t) {
  IncomeTaxType.unknown => l.taxTypeUnknownHelp,
  IncomeTaxType.salary => l.taxTypeSalaryHelp,
  IncomeTaxType.casual => l.taxTypeCasualHelp,
  IncomeTaxType.business => l.taxTypeBusinessHelp,
  IncomeTaxType.investment => l.taxTypeInvestmentHelp,
  IncomeTaxType.exempt => l.taxTypeExemptHelp,
};
