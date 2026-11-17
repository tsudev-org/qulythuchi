import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../../state/providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../transactions/txn_tile.dart';
import '../widgets/amount_field.dart';
import '../widgets/common.dart';
import '../widgets/edit_page.dart';
import '../widgets/form_fields.dart';

class DebtFormPage extends ConsumerStatefulWidget {
  const DebtFormPage({super.key, this.debtId});
  final String? debtId;

  @override
  ConsumerState<DebtFormPage> createState() => _DebtFormPageState();
}

class _DebtFormPageState extends ConsumerState<DebtFormPage> {
  final _form = GlobalKey<FormState>();
  final _who = TextEditingController();
  final _principal = TextEditingController();
  final _interest = TextEditingController();
  final _note = TextEditingController();
  Debt? _editing;
  DebtKind _kind = DebtKind.lend;
  String? _walletId;
  CivilDate _start = todayCivil();
  CivilDate? _due;
  bool _disburse = true;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    hideToastSoon(context);
    final data = ref.read(ledgerProvider);
    _walletId = data.wallets.where((w) => !w.archived).firstOrNull?.id;
    final d = data.debt(widget.debtId);
    if (d != null) {
      _editing = d;
      _kind = d.kind;
      _walletId = d.walletId;
      _who.text = d.counterparty;
      _start = d.startDate;
      _due = d.dueDate;
      _closed = d.closed;
      _note.text = d.note ?? '';
      if (d.annualInterestBp > 0) _interest.text = percentText(d.annualInterestBp);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final cur = ref.read(ledgerProvider).wallet(d.walletId)?.currency ?? Currency.vnd;
        _principal.text = formatMoney(Money(d.principal, cur), locale: context.appLocale, withSymbol: false);
      });
    }
  }

  @override
  void dispose() {
    for (final c in [_who, _principal, _interest, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  int? _interestBp() {
    final t = _interest.text.trim();
    if (t.isEmpty) return 0;
    final m = RegExp(r'^(\d{1,3})(?:[.,](\d{1,2}))?$').firstMatch(t);
    if (m == null) return null;
    return int.parse(m.group(1)!) * 100 + int.parse((m.group(2) ?? '').padRight(2, '0'));
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final data = ref.read(ledgerProvider);
    final n = ref.read(ledgerProvider.notifier);
    final w = data.wallet(_walletId);
    try {
      if (w == null) throw const FormatException();
      n.saveDebt(
        Debt(
          id: _editing?.id ?? n.newId(),
          walletId: w.id,
          kind: _kind,
          counterparty: _who.text.trim(),
          principal: AmountField.tryValue(_principal.text, w.currency, context.appLocale)!.minor,
          startDate: _start,
          dueDate: _due,
          annualInterestBp: _interestBp() ?? 0,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          closed: _closed,
        ),
        recordDisbursement: _editing == null && _disburse,
      );
      context.toast(context.l10n.saved);
      closePage(context, '/more/debts');
    } on Object catch (e) {
      context.toast(errorMessage(context, e));
    }
  }

  Future<void> _delete() async {
    final d = _editing!;
    final l = context.l10n;
    if (!await confirmDialog(context, message: l.debtDeleteConfirm(d.counterparty)) || !mounted) return;
    ref.read(ledgerProvider.notifier).deleteDebt(d.id);
    context.toast(l.deleted);
    closePage(context, '/more/debts');
  }

  Future<void> _payment(Currency cur) async {
    final d = _editing!;
    final l = context.l10n;
    final locale = context.appLocale;
    final key = GlobalKey<FormState>();
    var date = todayCivil();
    final result = await showDialog<(int, CivilDate)>(
      context: context,
      builder: (ctx) => ControllerScope(
        count: 1,
        builder: (ctx, c) => StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: Text(d.kind == DebtKind.lend ? l.debtCollect : l.debtRecordPayment),
            content: SizedBox(
              width: 420,
              child: Form(
                key: key,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AmountField(controller: c[0], currency: cur, label: l.txnAmount, autofocus: true),
                    const SizedBox(height: QtSpace.s4),
                    DateField(label: l.txnDate, value: date, onChanged: (v) => setLocal(() => date = v)),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.actionCancel)),
              FilledButton(
                onPressed: () {
                  if (!key.currentState!.validate()) return;
                  Navigator.pop(ctx, (AmountField.tryValue(c[0].text, cur, locale)!.minor, date));
                },
                child: Text(l.actionSave),
              ),
            ],
          ),
        ),
      ),
    );
    if (result == null || !mounted) return;
    try {
      ref.read(ledgerProvider.notifier).recordDebtPayment(d.id, result.$1, result.$2);
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
    final w = data.wallet(_walletId);
    final cur = w?.currency ?? Currency.vnd;
    final editing = _editing == null ? null : data.debt(_editing!.id) ?? _editing;
    final st = (editing != null && w != null) ? Ledger.debtStatus(editing, w, data.txns) : null;
    final payments = editing == null ? const <Txn>[] : data.txns.where((t) => t.debtId == editing.id).toList();
    return EditPage(
      title: _editing == null ? l.debtNew : l.debtEdit,
      formKey: _form,
      onSave: _save,
      onDelete: _editing == null ? null : _delete,
      children: [
        if (st != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(QtSpace.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    st.settled ? l.debtSettled : l.debtRemaining(formatMoney(st.remaining, locale: context.appLocale)),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: st.settled ? p.success : null),
                  ),
                  Text(l.debtPaid(formatMoney(st.paid, locale: context.appLocale))),
                  if (!st.settled) ...[
                    const SizedBox(height: QtSpace.s3),
                    FilledButton.icon(
                      onPressed: () => _payment(cur),
                      icon: const Icon(Icons.add),
                      label: Text(_kind == DebtKind.lend ? l.debtCollect : l.debtRecordPayment),
                    ),
                  ],
                ],
              ),
            ),
          ),
        SegmentedButton<DebtKind>(
          segments: [
            ButtonSegment(value: DebtKind.lend, label: Text(l.debtLend), icon: const Icon(Icons.call_received)),
            ButtonSegment(value: DebtKind.borrow, label: Text(l.debtBorrow), icon: const Icon(Icons.call_made)),
          ],
          selected: {_kind},
          showSelectedIcon: false,
          onSelectionChanged: _editing == null ? (s) => setState(() => _kind = s.first) : null,
        ),
        TextFormField(
          controller: _who,
          autofocus: _editing == null,
          maxLength: 80,
          decoration: InputDecoration(labelText: l.debtCounterparty, counterText: ''),
          validator: (v) => (v == null || v.trim().isEmpty) ? l.errNameRequired : null,
        ),
        DropdownButtonFormField<String>(
          initialValue: _walletId,
          isExpanded: true,
          decoration: InputDecoration(labelText: l.txnWallet),
          items: [
            for (final w in data.wallets.where((w) => !w.archived || w.id == _walletId))
              DropdownMenuItem(value: w.id, child: Text('${w.name} (${w.currency.code})')),
          ],
          validator: (v) => v == null ? l.errWalletMissing : null,
          onChanged: _editing == null ? (v) => setState(() => _walletId = v) : null,
        ),
        AmountField(controller: _principal, currency: cur, label: l.debtPrincipal),
        DateField(label: l.debtStart, value: _start, onChanged: (d) => setState(() => _start = d)),
        DateField(
          label: l.debtDue,
          value: _due,
          onChanged: (d) => setState(() => _due = d),
          onCleared: () => setState(() => _due = null),
        ),
        TextFormField(
          controller: _interest,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: l.debtInterest, suffixText: '%'),
          validator: (_) => _interestBp() == null ? l.errRateInvalid : null,
        ),
        TextFormField(
          controller: _note,
          maxLength: 500,
          decoration: InputDecoration(labelText: l.txnNote),
        ),
        if (_editing == null)
          SwitchListTile(
            value: _disburse,
            onChanged: (v) => setState(() => _disburse = v),
            title: Text(l.debtRecordDisbursement),
            contentPadding: EdgeInsets.zero,
          )
        else
          SwitchListTile(
            value: _closed,
            onChanged: (v) => setState(() => _closed = v),
            title: Text(l.debtClose),
            contentPadding: EdgeInsets.zero,
          ),
        if (payments.isNotEmpty) ...[
          Semantics(header: true, child: Text(l.debtPayments, style: Theme.of(context).textTheme.titleMedium)),
          Card(
            child: Column(
              children: [for (final t in payments) TxnTile(txn: t, data: data, showDate: true)],
            ),
          ),
        ],
      ],
    );
  }
}
