import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../../state/providers.dart';
import '../../theme/tokens.g.dart';
import '../widgets/amount_field.dart';
import '../widgets/common.dart';
import '../widgets/edit_page.dart';
import '../widgets/form_fields.dart';

class RecurringFormPage extends ConsumerStatefulWidget {
  const RecurringFormPage({super.key, this.recurringId});
  final String? recurringId;

  @override
  ConsumerState<RecurringFormPage> createState() => _RecurringFormPageState();
}

class _RecurringFormPageState extends ConsumerState<RecurringFormPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _interval = TextEditingController(text: '1');
  final _remind = TextEditingController(text: '1');
  final _note = TextEditingController();
  Recurring? _editing;
  TxnKind _kind = TxnKind.expense;
  String? _walletId;
  String? _categoryId;
  Frequency _freq = Frequency.monthly;
  CivilDate _start = todayCivil();
  CivilDate? _until;
  bool _isBill = true;
  bool _auto = false;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    hideToastSoon(context);
    final data = ref.read(ledgerProvider);
    _walletId = data.wallets.where((w) => !w.archived).firstOrNull?.id;
    final r = data.recurring(widget.recurringId);
    if (r != null) {
      _editing = r;
      _name.text = r.name;
      _kind = r.kind;
      _walletId = r.walletId;
      _categoryId = r.categoryId;
      _freq = r.rule.frequency;
      _interval.text = '${r.rule.interval}';
      _start = r.rule.start;
      _until = r.rule.until;
      _isBill = r.isBill;
      _auto = r.autoCreate;
      _paused = r.paused;
      _remind.text = '${r.remindDaysBefore}';
      _note.text = r.note ?? '';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final cur = ref.read(ledgerProvider).wallet(r.walletId)?.currency ?? Currency.vnd;
        _amount.text = formatMoney(Money(r.amount, cur), locale: context.appLocale, withSymbol: false);
      });
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _amount, _interval, _remind, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final data = ref.read(ledgerProvider);
    final n = ref.read(ledgerProvider.notifier);
    final w = data.wallet(_walletId);
    try {
      if (w == null) throw const FormatException();
      final old = _editing;
      final rule = RecurrenceRule(
        frequency: _freq,
        start: _start,
        interval: (int.tryParse(_interval.text) ?? 1).clamp(1, 366),
        // Ngày trong tháng / thứ trong tuần lấy theo ngày bắt đầu (lõi tự kẹp cuối tháng); giữ tùy chọn cũ khi
        // không đổi tần suất (có thể đến từ đồng bộ/nhập khẩu).
        weekdays: old != null && old.rule.frequency == _freq ? old.rule.weekdays : const [],
        monthDay: old != null && old.rule.frequency == _freq ? old.rule.monthDay : null,
        count: old != null && old.rule.frequency == _freq ? old.rule.count : null,
        until: _until,
      );
      final ruleChanged = old == null || old.rule.start != _start || old.rule.frequency != _freq;
      n.saveRecurring(
        Recurring(
          id: old?.id ?? n.newId(),
          walletId: w.id,
          name: _name.text.trim(),
          kind: _kind,
          amount: AmountField.tryValue(_amount.text, w.currency, context.appLocale)!.minor,
          rule: rule,
          categoryId: _categoryId,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          isBill: _isBill,
          autoCreate: _auto,
          remindDaysBefore: int.tryParse(_remind.text) ?? 1,
          // Đổi lịch: chỉ sinh từ hôm nay trở đi, không sinh bù quá khứ của lịch mới.
          generatedThrough: ruleChanged && old != null ? todayCivil().addDays(-1) : old?.generatedThrough,
          paused: _paused,
        ),
      );
      context.toast(context.l10n.saved);
      closePage(context, '/more/recurring');
    } on Object catch (e) {
      context.toast(errorMessage(context, e));
    }
  }

  Future<void> _delete() async {
    final r = _editing!;
    final l = context.l10n;
    if (!await confirmDialog(context, message: l.recurringDeleteConfirm(r.name)) || !mounted) return;
    ref.read(ledgerProvider.notifier).deleteRecurring(r.id);
    context.toast(l.deleted);
    closePage(context, '/more/recurring');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final data = ref.watch(ledgerProvider);
    final w = data.wallet(_walletId);
    final catKind = _kind == TxnKind.income ? CategoryKind.income : CategoryKind.expense;
    final cats = categoryOptions(data.categories, catKind);
    return EditPage(
      title: _editing == null ? l.recurringNew : l.recurringEdit,
      formKey: _form,
      onSave: _save,
      onDelete: _editing == null ? null : _delete,
      children: [
        SegmentedButton<TxnKind>(
          segments: [
            ButtonSegment(value: TxnKind.expense, label: Text(l.txnExpense)),
            ButtonSegment(value: TxnKind.income, label: Text(l.txnIncome)),
          ],
          selected: {_kind},
          showSelectedIcon: false,
          onSelectionChanged: (s) => setState(() {
            _kind = s.first;
            _categoryId = null;
            if (_kind == TxnKind.income) _isBill = false;
          }),
        ),
        TextFormField(
          controller: _name,
          autofocus: _editing == null,
          maxLength: 60,
          decoration: InputDecoration(labelText: l.recurringName, counterText: ''),
          validator: (v) => (v == null || v.trim().isEmpty) ? l.errNameRequired : null,
        ),
        AmountField(controller: _amount, currency: w?.currency ?? Currency.vnd, label: l.txnAmount),
        DropdownButtonFormField<String>(
          initialValue: _walletId,
          isExpanded: true,
          decoration: InputDecoration(labelText: l.txnWallet),
          items: [
            for (final w in data.wallets.where((w) => !w.archived || w.id == _walletId))
              DropdownMenuItem(value: w.id, child: Text('${w.name} (${w.currency.code})')),
          ],
          validator: (v) => v == null ? l.errWalletMissing : null,
          onChanged: (v) => setState(() => _walletId = v),
        ),
        DropdownButtonFormField<String?>(
          key: ValueKey('cat-$_kind'),
          initialValue: cats.any((c) => c.$1 == _categoryId) ? _categoryId : null,
          isExpanded: true,
          decoration: InputDecoration(labelText: l.txnCategory),
          items: [
            DropdownMenuItem(value: null, child: Text(l.uncategorized)),
            for (final (id, name, child) in cats)
              DropdownMenuItem(
                value: id,
                child: Padding(
                  padding: EdgeInsets.only(left: child ? QtSpace.s6 : 0),
                  child: Text(name, overflow: TextOverflow.ellipsis),
                ),
              ),
          ],
          onChanged: (v) => setState(() => _categoryId = v),
        ),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<Frequency>(
                initialValue: _freq,
                isExpanded: true,
                decoration: InputDecoration(labelText: l.recurringFrequency),
                items: [
                  DropdownMenuItem(value: Frequency.daily, child: Text(l.freqDaily)),
                  DropdownMenuItem(value: Frequency.weekly, child: Text(l.freqWeekly)),
                  DropdownMenuItem(value: Frequency.monthly, child: Text(l.freqMonthly)),
                  DropdownMenuItem(value: Frequency.yearly, child: Text(l.freqYearly)),
                ],
                onChanged: (v) => setState(() => _freq = v ?? _freq),
              ),
            ),
            const SizedBox(width: QtSpace.s3),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _interval,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l.recurringInterval),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return (n == null || n < 1 || n > 366) ? l.errRateInvalid : null;
                },
              ),
            ),
          ],
        ),
        DateField(label: l.recurringStart, value: _start, onChanged: (d) => setState(() => _start = d)),
        DateField(
          label: l.recurringUntil,
          value: _until,
          onChanged: (d) => setState(() => _until = d),
          onCleared: () => setState(() => _until = null),
        ),
        if (_kind == TxnKind.expense)
          SwitchListTile(
            value: _isBill,
            onChanged: (v) => setState(() => _isBill = v),
            title: Text(l.recurringIsBill),
            contentPadding: EdgeInsets.zero,
          ),
        if (_isBill && _kind == TxnKind.expense)
          TextFormField(
            controller: _remind,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l.recurringRemind),
            validator: (v) {
              final n = int.tryParse(v ?? '');
              return (n == null || n < 0 || n > 30) ? l.errRemindRange : null;
            },
          ),
        SwitchListTile(
          value: _auto,
          onChanged: (v) => setState(() => _auto = v),
          title: Text(l.recurringAuto),
          subtitle: _auto ? null : Text(l.recurringAutoOff),
          contentPadding: EdgeInsets.zero,
        ),
        if (_editing != null)
          SwitchListTile(
            value: _paused,
            onChanged: (v) => setState(() => _paused = v),
            title: Text(l.recurringPaused),
            contentPadding: EdgeInsets.zero,
          ),
        TextFormField(
          controller: _note,
          maxLength: 500,
          decoration: InputDecoration(labelText: l.txnNote),
        ),
      ],
    );
  }
}
