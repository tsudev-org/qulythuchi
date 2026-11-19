import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../../state/providers.dart';
import '../../state/settings.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../transactions/txn_tile.dart';
import '../widgets/amount_field.dart';
import '../widgets/common.dart';
import '../widgets/currency_field.dart';
import '../widgets/edit_page.dart';
import '../widgets/form_fields.dart';
import 'income_page.dart';

/// Thêm/sửa khoản thu nhiều đợt (job freelance, hợp đồng) + ghi từng lần nhận tiền.
class IncomePlanFormPage extends ConsumerStatefulWidget {
  const IncomePlanFormPage({super.key, this.planId});
  final String? planId;

  @override
  ConsumerState<IncomePlanFormPage> createState() => _IncomePlanFormPageState();
}

class _Installment {
  _Installment(this.date, this.amount, this.label);
  CivilDate date;
  final TextEditingController amount;
  final TextEditingController label;
}

class _IncomePlanFormPageState extends ConsumerState<IncomePlanFormPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _payer = TextEditingController();
  final _total = TextEditingController();
  final _note = TextEditingController();
  final _inst = <_Installment>[];
  IncomePlan? _editing;
  Currency _currency = Currency.vnd;
  String? _walletId;
  String? _categoryId;
  CivilDate? _start = todayCivil();
  CivilDate? _due;
  IncomePlanStatus _status = IncomePlanStatus.active;
  bool _withholding = false;

  @override
  void initState() {
    super.initState();
    hideToastSoon(context);
    final data = ref.read(ledgerProvider);
    _currency = Currency.of(ref.read(settingsProvider).baseCurrency);
    final w = data.wallets.where((w) => !w.archived && w.currency == _currency).firstOrNull;
    _walletId = w?.id;
    final plan = data.incomePlan(widget.planId);
    if (plan != null) {
      _editing = plan;
      _name.text = plan.name;
      _payer.text = plan.payer ?? '';
      _note.text = plan.note ?? '';
      _currency = plan.currency;
      _walletId = data.wallet(plan.defaultWalletId) == null ? null : plan.defaultWalletId;
      _categoryId = plan.categoryId;
      _start = plan.startDate;
      _due = plan.dueDate;
      _status = plan.status;
      _withholding = plan.withholdingBp > 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final loc = context.appLocale;
        String fmt(int v) => formatMoney(Money(v, plan.currency), locale: loc, withSymbol: false);
        setState(() {
          if (plan.total > 0) _total.text = fmt(plan.total);
          for (final i in plan.installments) {
            _inst.add(
              _Installment(i.date, TextEditingController(text: fmt(i.amount)), TextEditingController(text: i.label)),
            );
          }
        });
      });
    } else {
      // Gợi ý danh mục "Freelance" nếu có.
      _categoryId = data.categories
          .where((c) => c.kind == CategoryKind.income && c.taxType == IncomeTaxType.casual)
          .firstOrNull
          ?.id;
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _payer, _total, _note]) {
      c.dispose();
    }
    for (final i in _inst) {
      i.amount.dispose();
      i.label.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final n = ref.read(ledgerProvider.notifier);
    final loc = context.appLocale;
    try {
      final installments = [
        for (final i in _inst)
          PlannedInstallment(
            date: i.date,
            amount: AmountField.tryValue(i.amount.text, _currency, loc)!.minor,
            label: i.label.text.trim().isEmpty ? null : i.label.text.trim(),
          ),
      ];
      var total = AmountField.tryValue(_total.text, _currency, loc)?.minor ?? 0;
      if (total == 0 && installments.isNotEmpty) total = installments.fold(0, (a, b) => a + b.amount);
      final saved = n.saveIncomePlan(
        IncomePlan(
          id: _editing?.id ?? n.newId(),
          name: _name.text.trim(),
          payer: _payer.text.trim().isEmpty ? null : _payer.text.trim(),
          currency: _currency,
          total: total,
          defaultWalletId: _walletId,
          categoryId: _categoryId,
          startDate: _start,
          dueDate: _due,
          installments: installments,
          status: _status,
          withholdingBp: _withholding ? VnPitRules.forYear(todayCivil().year).casualWithholdingBp : 0,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        ),
      );
      context.toast(context.l10n.saved);
      if (_editing == null) {
        setState(() => _editing = saved);
      } else {
        closePage(context, '/more/income');
      }
    } on Object catch (e) {
      context.toast(errorMessage(context, e));
    }
  }

  Future<void> _delete() async {
    final plan = _editing!;
    final l = context.l10n;
    if (!await confirmDialog(context, message: l.incomePlanDeleteConfirm(plan.name)) || !mounted) return;
    ref.read(ledgerProvider.notifier).deleteIncomePlan(plan.id);
    context.toast(l.deleted);
    closePage(context, '/more/income');
  }

  /// Ghi một lần nhận tiền: nhập số TRƯỚC thuế (theo hợp đồng) ⇒ tự tính thuế khấu trừ và thực nhận.
  Future<void> _receive(IncomePlan plan, IncomePlanProgress progress) async {
    final l = context.l10n;
    final loc = context.appLocale;
    final data = ref.read(ledgerProvider);
    final wallets = data.wallets.where((w) => !w.archived && w.currency == plan.currency).toList();
    if (wallets.isEmpty) {
      context.toast(l.incomeNoWalletForCurrency(plan.currency.code));
      return;
    }
    final rules = VnPitRules.forYear(todayCivil().year);
    final key = GlobalKey<FormState>();
    var date = todayCivil();
    var walletId = wallets.any((w) => w.id == plan.defaultWalletId) ? plan.defaultWalletId! : wallets.first.id;
    final suggested = progress.nextInstallment?.amount ?? (plan.total > 0 ? progress.remaining.minor : null);
    final result = await showDialog<(String, int, int, CivilDate)>(
      context: context,
      builder: (ctx) => ControllerScope(
        count: 2,
        builder: (ctx, c) {
          if (c[0].text.isEmpty && suggested != null && suggested > 0) {
            c[0].text = formatMoney(Money(suggested, plan.currency), locale: loc, withSymbol: false);
          }
          int gross() => AmountField.tryValue(c[0].text, plan.currency, loc)?.minor ?? 0;
          int autoWithheld() {
            final g = gross();
            if (plan.withholdingBp <= 0 || plan.currency.code != 'VND') return 0;
            if (g < rules.casualWithholdingThreshold) return 0;
            return (g * plan.withholdingBp + 5000) ~/ 10000;
          }

          return StatefulBuilder(
            builder: (ctx, setLocal) {
              final withheld = c[1].text.trim().isEmpty
                  ? autoWithheld()
                  : (AmountField.tryValue(c[1].text, plan.currency, loc)?.minor ?? 0);
              final net = gross() - withheld;
              return AlertDialog(
                title: Text(l.incomeReceive),
                content: SizedBox(
                  width: 440,
                  child: Form(
                    key: key,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: c[0],
                            autofocus: true,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: l.incomeGrossAmount,
                              suffixText: plan.currency.symbol,
                            ),
                            onChanged: (_) => setLocal(() {}),
                          ),
                          const SizedBox(height: QtSpace.s3),
                          TextField(
                            controller: c[1],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: l.txnTaxWithheld,
                              hintText: formatMoney(Money(autoWithheld(), plan.currency), locale: loc),
                              helperText: plan.withholdingBp > 0
                                  ? l.incomeWithholdHint(
                                      formatMoney(Money(rules.casualWithholdingThreshold, Currency.vnd), locale: loc),
                                    )
                                  : null,
                              helperMaxLines: 3,
                            ),
                            onChanged: (_) => setLocal(() {}),
                          ),
                          const SizedBox(height: QtSpace.s3),
                          DropdownButtonFormField<String>(
                            initialValue: walletId,
                            isExpanded: true,
                            decoration: InputDecoration(labelText: l.txnWallet),
                            items: [for (final w in wallets) DropdownMenuItem(value: w.id, child: Text(w.name))],
                            onChanged: (v) => walletId = v ?? walletId,
                          ),
                          const SizedBox(height: QtSpace.s3),
                          DateField(label: l.txnDate, value: date, onChanged: (v) => setLocal(() => date = v)),
                          const SizedBox(height: QtSpace.s3),
                          Text(
                            l.incomeNetPreview(formatMoney(Money(net, plan.currency), locale: loc)),
                            style: Theme.of(ctx).textTheme.titleSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.actionCancel)),
                  FilledButton(
                    key: const Key('income.receive.save'),
                    onPressed: net <= 0 || withheld < 0
                        ? null
                        : () => Navigator.pop(ctx, (walletId, net, withheld, date)),
                    child: Text(l.actionSave),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
    if (result == null || !mounted) return;
    try {
      ref
          .read(ledgerProvider.notifier)
          .recordIncomeReceipt(plan.id, walletId: result.$1, net: result.$2, withheld: result.$3, date: result.$4);
      context.toast(l.saved);
    } on Object catch (e) {
      context.toast(errorMessage(context, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    final data = ref.watch(ledgerProvider);
    final editing = _editing == null ? null : data.incomePlan(_editing!.id) ?? _editing;
    final progress = editing == null ? null : Ledger.incomePlanProgress(editing, data.txns, todayCivil());
    final wallets = data.wallets.where((w) => !w.archived && w.currency == _currency).toList();
    return EditPage(
      title: _editing == null ? l.incomePlanNew : l.incomePlanEdit,
      formKey: _form,
      onSave: _save,
      onDelete: _editing == null ? null : _delete,
      children: [
        if (editing != null && progress != null) ...[
          IncomePlanCard(plan: editing, progress: progress),
          if (editing.status == IncomePlanStatus.active)
            FilledButton.icon(
              key: const Key('income.receive'),
              onPressed: () => _receive(editing, progress),
              icon: const Icon(Icons.add),
              label: Text(l.incomeReceive),
            ),
        ],
        TextFormField(
          key: const Key('income.name'),
          controller: _name,
          autofocus: _editing == null,
          maxLength: 100,
          decoration: InputDecoration(labelText: l.incomePlanName, hintText: l.incomePlanNameHint, counterText: ''),
          validator: (v) => (v == null || v.trim().isEmpty) ? l.errNameRequired : null,
        ),
        TextFormField(
          controller: _payer,
          maxLength: 100,
          decoration: InputDecoration(labelText: l.incomePayer, counterText: ''),
        ),
        CurrencyField(
          value: _currency,
          onChanged: (editing != null && (progress?.receipts.isNotEmpty ?? false))
              ? null
              : (c) => setState(() {
                  _currency = c;
                  _walletId = data.wallets.where((w) => !w.archived && w.currency == c).firstOrNull?.id;
                }),
        ),
        AmountField(
          key: const Key('income.total'),
          controller: _total,
          currency: _currency,
          label: l.incomePlanTotal,
          allowZero: true,
        ),
        DropdownButtonFormField<String?>(
          initialValue: wallets.any((w) => w.id == _walletId) ? _walletId : null,
          isExpanded: true,
          decoration: InputDecoration(labelText: l.incomeDefaultWallet),
          items: [
            DropdownMenuItem(value: null, child: Text(l.none)),
            for (final w in wallets) DropdownMenuItem(value: w.id, child: Text(w.name)),
          ],
          onChanged: (v) => setState(() => _walletId = v),
        ),
        DropdownButtonFormField<String?>(
          initialValue: data.category(_categoryId) == null ? null : _categoryId,
          isExpanded: true,
          decoration: InputDecoration(labelText: l.txnCategory),
          items: [
            DropdownMenuItem(value: null, child: Text(l.none)),
            for (final (id, name, child) in categoryOptions(data.categories, CategoryKind.income))
              DropdownMenuItem(value: id, child: Text(child ? '   $name' : name)),
          ],
          onChanged: (v) => setState(() => _categoryId = v),
        ),
        DateField(
          label: l.incomeStart,
          value: _start,
          onChanged: (d) => setState(() => _start = d),
          onCleared: () => setState(() => _start = null),
        ),
        DateField(
          label: l.incomeDue,
          value: _due,
          onChanged: (d) => setState(() => _due = d),
          onCleared: () => setState(() => _due = null),
        ),
        SwitchListTile(
          value: _withholding,
          onChanged: _currency.code == 'VND' ? (v) => setState(() => _withholding = v) : null,
          title: Text(l.incomeWithholding),
          subtitle: Text(l.incomeWithholdingSub),
          contentPadding: EdgeInsets.zero,
        ),
        Semantics(header: true, child: Text(l.incomeInstallments, style: Theme.of(context).textTheme.titleMedium)),
        Text(l.incomeInstallmentsHelp, style: TextStyle(color: p.textSecondary)),
        for (final (idx, i) in _inst.indexed)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(QtSpace.s3),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: i.label,
                          maxLength: 60,
                          decoration: InputDecoration(
                            labelText: l.incomeInstallmentLabel(idx + 1),
                            hintText: l.incomeInstallmentHint,
                            counterText: '',
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: l.actionDelete,
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _inst.removeAt(idx)),
                      ),
                    ],
                  ),
                  const SizedBox(height: QtSpace.s2),
                  AmountField(controller: i.amount, currency: _currency, label: l.txnAmount),
                  const SizedBox(height: QtSpace.s2),
                  DateField(label: l.txnDate, value: i.date, onChanged: (d) => setState(() => i.date = d)),
                ],
              ),
            ),
          ),
        OutlinedButton.icon(
          key: const Key('income.addInstallment'),
          onPressed: _inst.length >= 24
              ? null
              : () => setState(
                  () => _inst.add(
                    _Installment(
                      _inst.isEmpty ? (_start ?? todayCivil()) : _inst.last.date.addMonths(1),
                      TextEditingController(),
                      TextEditingController(),
                    ),
                  ),
                ),
          icon: const Icon(Icons.add),
          label: Text(l.incomeAddInstallment),
        ),
        if (_editing != null)
          DropdownButtonFormField<IncomePlanStatus>(
            initialValue: _status,
            decoration: InputDecoration(labelText: l.incomeStatus),
            items: [
              DropdownMenuItem(value: IncomePlanStatus.active, child: Text(l.incomeStatusActive)),
              DropdownMenuItem(value: IncomePlanStatus.completed, child: Text(l.incomeStatusDone)),
              DropdownMenuItem(value: IncomePlanStatus.cancelled, child: Text(l.incomeStatusCancelled)),
            ],
            onChanged: (v) => setState(() => _status = v ?? _status),
          ),
        TextFormField(
          controller: _note,
          maxLength: 500,
          maxLines: 3,
          minLines: 1,
          decoration: InputDecoration(labelText: l.txnNote),
        ),
        if (progress != null && progress.receipts.isNotEmpty) ...[
          Semantics(header: true, child: Text(l.incomeReceiptsTitle, style: Theme.of(context).textTheme.titleMedium)),
          Card(
            child: Column(
              children: [for (final t in progress.receipts.reversed) TxnTile(txn: t, data: data, showDate: true)],
            ),
          ),
        ],
      ],
    );
  }
}
