import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../../state/providers.dart';
import '../../state/settings.dart';
import '../widgets/amount_field.dart';
import '../widgets/common.dart';
import '../widgets/edit_page.dart';
import '../widgets/form_fields.dart';
import 'plan_page.dart';

class BudgetFormPage extends ConsumerStatefulWidget {
  const BudgetFormPage({super.key, this.budgetId});
  final String? budgetId;

  @override
  ConsumerState<BudgetFormPage> createState() => _BudgetFormPageState();
}

class _BudgetFormPageState extends ConsumerState<BudgetFormPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _startDay = TextEditingController(text: '1');
  final _alert = TextEditingController(text: '80');
  Budget? _editing;
  late Currency _currency;
  BudgetPeriod _period = BudgetPeriod.monthly;
  int _weekday = 1;
  CivilDate? _from;
  CivilDate? _to;
  List<String> _categories = [];
  List<String> _wallets = [];
  bool _rollover = false;

  @override
  void initState() {
    super.initState();
    hideToastSoon(context);
    _currency = Currency.of(ref.read(settingsProvider).baseCurrency);
    final b = ref.read(ledgerProvider).budget(widget.budgetId);
    if (b != null) {
      _editing = b;
      _name.text = b.name;
      _currency = b.currency;
      _period = b.period;
      _from = b.customStart;
      _to = b.customEnd;
      _categories = [...b.categoryIds];
      _wallets = [...b.walletIds];
      _rollover = b.rollover;
      _alert.text = percentText(b.alertAtBp);
      if (b.period == BudgetPeriod.weekly) {
        _weekday = b.startDay.clamp(1, 7);
      } else {
        _startDay.text = '${b.startDay}';
      }
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _amount.text = formatMoney(b.limit, locale: context.appLocale, withSymbol: false),
      );
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _amount, _startDay, _alert]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final n = ref.read(ledgerProvider.notifier);
    try {
      n.saveBudget(
        Budget(
          id: _editing?.id ?? n.newId(),
          name: _name.text.trim(),
          amount: AmountField.tryValue(_amount.text, _currency, context.appLocale)!.minor,
          currency: _currency,
          period: _period,
          categoryIds: _categories,
          walletIds: _wallets,
          startDay: _period == BudgetPeriod.weekly ? _weekday : (int.tryParse(_startDay.text) ?? 1).clamp(1, 31),
          customStart: _period == BudgetPeriod.custom ? _from : null,
          customEnd: _period == BudgetPeriod.custom ? _to : null,
          rollover: _rollover && _period != BudgetPeriod.custom,
          alertAtBp: (int.tryParse(_alert.text) ?? 80) * 100,
        ),
      );
      context.toast(context.l10n.saved);
      closePage(context, '/plan');
    } on Object catch (e) {
      context.toast(errorMessage(context, e));
    }
  }

  Future<void> _delete() async {
    final b = _editing!;
    final l = context.l10n;
    if (!await confirmDialog(context, message: l.budgetDeleteConfirm(b.name)) || !mounted) return;
    ref.read(ledgerProvider.notifier).deleteBudget(b.id);
    context.toast(l.deleted);
    closePage(context, '/plan');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final data = ref.watch(ledgerProvider);
    final walletOptions = [
      for (final w in data.wallets)
        if (w.currency == _currency && !w.archived) (w.id, w.name, false),
    ];
    return EditPage(
      title: _editing == null ? l.budgetNew : l.budgetEdit,
      formKey: _form,
      onSave: _save,
      onDelete: _editing == null ? null : _delete,
      children: [
        TextFormField(
          controller: _name,
          autofocus: _editing == null,
          maxLength: 60,
          decoration: InputDecoration(labelText: l.budgetName, counterText: ''),
          validator: (v) => (v == null || v.trim().isEmpty) ? l.errNameRequired : null,
        ),
        DropdownButtonFormField<Currency>(
          initialValue: _currency,
          isExpanded: true,
          decoration: InputDecoration(labelText: l.walletCurrency),
          items: [for (final c in Currency.all) DropdownMenuItem(value: c, child: Text('${c.code} (${c.symbol})'))],
          onChanged: (v) => setState(() {
            _currency = v ?? _currency;
            _wallets = [];
          }),
        ),
        AmountField(controller: _amount, currency: _currency, label: l.budgetAmount),
        DropdownButtonFormField<BudgetPeriod>(
          initialValue: _period,
          isExpanded: true,
          decoration: InputDecoration(labelText: l.budgetPeriod),
          items: [for (final p in BudgetPeriod.values) DropdownMenuItem(value: p, child: Text(periodLabel(l, p)))],
          onChanged: (v) => setState(() => _period = v ?? _period),
        ),
        if (_period == BudgetPeriod.monthly)
          TextFormField(
            controller: _startDay,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l.budgetStartDay),
            validator: (v) {
              final d = int.tryParse(v ?? '');
              return (d == null || d < 1 || d > 31) ? l.budgetStartDay : null;
            },
          ),
        if (_period == BudgetPeriod.weekly)
          DropdownButtonFormField<int>(
            initialValue: _weekday,
            decoration: InputDecoration(labelText: l.budgetStartWeekday),
            items: [for (var d = 1; d <= 7; d++) DropdownMenuItem(value: d, child: Text(weekdayName(l, d)))],
            onChanged: (v) => setState(() => _weekday = v ?? 1),
          ),
        if (_period == BudgetPeriod.custom) ...[
          DateField(label: l.budgetFrom, value: _from, onChanged: (d) => setState(() => _from = d)),
          DateField(label: l.budgetTo, value: _to, onChanged: (d) => setState(() => _to = d)),
        ],
        MultiSelectField(
          label: l.budgetCategories,
          allLabel: l.budgetAllCategories,
          options: categoryOptions(data.categories, CategoryKind.expense),
          selected: _categories,
          onChanged: (v) => setState(() => _categories = v),
        ),
        MultiSelectField(
          label: l.budgetWallets,
          allLabel: l.budgetAllWallets,
          options: walletOptions,
          selected: _wallets,
          onChanged: (v) => setState(() => _wallets = v),
        ),
        TextFormField(
          controller: _alert,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l.budgetAlertAt, suffixText: '%'),
          validator: (v) {
            final d = int.tryParse(v ?? '');
            return (d == null || d < 10 || d > 100) ? l.errAlertRange : null;
          },
        ),
        if (_period != BudgetPeriod.custom)
          SwitchListTile(
            value: _rollover,
            onChanged: (v) => setState(() => _rollover = v),
            title: Text(l.budgetRollover),
            contentPadding: EdgeInsets.zero,
          ),
      ],
    );
  }
}
