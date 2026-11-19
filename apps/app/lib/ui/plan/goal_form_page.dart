import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../../state/providers.dart';
import '../../state/settings.dart';
import '../widgets/amount_field.dart';
import '../widgets/common.dart';
import '../widgets/edit_page.dart';
import '../widgets/form_fields.dart';

class GoalFormPage extends ConsumerStatefulWidget {
  const GoalFormPage({super.key, this.goalId});
  final String? goalId;

  @override
  ConsumerState<GoalFormPage> createState() => _GoalFormPageState();
}

class _GoalFormPageState extends ConsumerState<GoalFormPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _target = TextEditingController();
  final _starting = TextEditingController();
  Goal? _editing;
  late Currency _currency;
  CivilDate? _deadline;
  bool _achieved = false;

  @override
  void initState() {
    super.initState();
    hideToastSoon(context);
    _currency = Currency.of(ref.read(settingsProvider).baseCurrency);
    final g = ref.read(ledgerProvider).goal(widget.goalId);
    if (g != null) {
      _editing = g;
      _name.text = g.name;
      _currency = g.currency;
      _deadline = g.deadline;
      _achieved = g.achieved;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final loc = context.appLocale;
        _target.text = formatMoney(Money(g.target, g.currency), locale: loc, withSymbol: false);
        if (g.startingAmount > 0) {
          _starting.text = formatMoney(Money(g.startingAmount, g.currency), locale: loc, withSymbol: false);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _target, _starting]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final n = ref.read(ledgerProvider.notifier);
    final loc = context.appLocale;
    try {
      n.saveGoal(
        Goal(
          id: _editing?.id ?? n.newId(),
          name: _name.text.trim(),
          target: AmountField.tryValue(_target.text, _currency, loc)!.minor,
          currency: _currency,
          deadline: _deadline,
          startingAmount: AmountField.tryValue(_starting.text, _currency, loc)?.minor ?? 0,
          icon: _editing?.icon,
          achieved: _achieved,
        ),
      );
      context.toast(context.l10n.saved);
      closePage(context, '/plan');
    } on Object catch (e) {
      context.toast(errorMessage(context, e));
    }
  }

  Future<void> _delete() async {
    final g = _editing!;
    final l = context.l10n;
    if (!await confirmDialog(context, message: l.goalDeleteConfirm(g.name)) || !mounted) return;
    ref.read(ledgerProvider.notifier).deleteGoal(g.id);
    context.toast(l.deleted);
    closePage(context, '/plan');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return EditPage(
      title: _editing == null ? l.goalNew : l.goalEdit,
      formKey: _form,
      onSave: _save,
      onDelete: _editing == null ? null : _delete,
      children: [
        TextFormField(
          controller: _name,
          autofocus: _editing == null,
          maxLength: 60,
          decoration: InputDecoration(labelText: l.goalName, counterText: ''),
          validator: (v) => (v == null || v.trim().isEmpty) ? l.errNameRequired : null,
        ),
        DropdownButtonFormField<Currency>(
          initialValue: _currency,
          isExpanded: true,
          decoration: InputDecoration(labelText: l.walletCurrency),
          items: [for (final c in Currency.all) DropdownMenuItem(value: c, child: Text('${c.code} (${c.symbol})'))],
          onChanged: _editing == null ? (v) => setState(() => _currency = v ?? _currency) : null,
        ),
        AmountField(controller: _target, currency: _currency, label: l.goalTarget),
        AmountField(controller: _starting, currency: _currency, label: l.goalStarting, allowZero: true),
        DateField(
          label: l.goalDeadline,
          value: _deadline,
          onChanged: (d) => setState(() => _deadline = d),
          onCleared: () => setState(() => _deadline = null),
        ),
        if (_editing != null)
          SwitchListTile(
            value: _achieved,
            onChanged: (v) => setState(() => _achieved = v),
            title: Text(l.goalAchieved),
            contentPadding: EdgeInsets.zero,
          ),
      ],
    );
  }
}
