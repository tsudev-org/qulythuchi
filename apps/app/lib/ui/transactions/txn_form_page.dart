import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../../state/ledger_repository.dart';
import '../../state/providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../widgets/amount_field.dart';
import '../widgets/common.dart';

enum _Mode { expense, income, transfer, adjustment }

/// Thêm/sửa giao dịch. [txnId] null = thêm mới.
class TxnFormPage extends ConsumerStatefulWidget {
  const TxnFormPage({
    super.key,
    this.txnId,
    this.initialKind,
    this.initialGoalId,
    this.initialAmount,
    this.initialNote,
    this.initialPayee,
    this.initialIncomePlanId,
    this.initialCurrency,
  });
  final String? txnId;
  final String? initialKind;

  /// Điền sẵn từ QR thanh toán / khoản thu: số tiền (đơn vị nhỏ nhất, theo tiền tệ ví đầu tiên), ghi chú, người nhận.
  final int? initialAmount;
  final String? initialNote;
  final String? initialPayee;
  final String? initialIncomePlanId;

  /// Mã tiền tệ của [initialAmount]: chọn ví đầu tiên cùng tiền tệ.
  final String? initialCurrency;

  /// Mở từ "Góp tiền" của mục tiêu.
  final String? initialGoalId;

  @override
  ConsumerState<TxnFormPage> createState() => _TxnFormPageState();
}

class _TxnFormPageState extends ConsumerState<TxnFormPage> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _fee = TextEditingController();
  final _received = TextEditingController();
  final _note = TextEditingController();
  final _payee = TextEditingController();
  final _withheld = TextEditingController();
  String? _incomePlanId;

  _Mode _mode = _Mode.expense;
  String? _walletId;
  String? _toWalletId;
  String? _categoryId;
  CivilDate _date = todayCivil();
  Txn? _editing;
  String? _transferId;
  bool _missing = false;
  String? _eventId;
  String? _goalId;

  @override
  void initState() {
    super.initState();
    // Toast của trang trước không được che nút Lưu.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    });
    final data = ref.read(ledgerProvider);
    // Ví chung chỉ xem không được chọn để ghi.
    final active = data.wallets.where((w) => !w.archived && data.canWrite(w.id)).toList();
    _walletId = active.firstOrNull?.id;
    _mode = switch (widget.initialKind) {
      'income' => _Mode.income,
      'transfer' => _Mode.transfer,
      _ => _Mode.expense,
    };
    if (data.goal(widget.initialGoalId) != null) _goalId = widget.initialGoalId;
    final plan = data.incomePlan(widget.initialIncomePlanId);
    if (plan != null) {
      _mode = _Mode.income;
      _incomePlanId = plan.id;
      _categoryId = plan.categoryId;
      _payee.text = plan.payer ?? '';
      _note.text = plan.name;
      if (data.wallet(plan.defaultWalletId) != null) _walletId = plan.defaultWalletId;
    }
    if (widget.initialCurrency != null) {
      final w = active.where((w) => w.currency.code == widget.initialCurrency).firstOrNull;
      if (w != null) _walletId = w.id;
    }
    if (widget.initialNote != null) _note.text = widget.initialNote!;
    if (widget.initialPayee != null) _payee.text = widget.initialPayee!;
    if (widget.initialAmount != null && widget.txnId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final cur = ref.read(ledgerProvider).wallet(_walletId)?.currency ?? Currency.vnd;
        _amount.text = formatMoney(Money(widget.initialAmount!, cur), locale: context.appLocale, withSymbol: false);
      });
    }
    if (widget.txnId != null) {
      final t = data.txn(widget.txnId!);
      if (t == null) {
        _missing = true;
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _fill(t, data));
    }
  }

  /// Điền biểu mẫu khi sửa (cần context để định dạng theo ngôn ngữ).
  void _fill(Txn t, LedgerData data) {
    final locale = context.appLocale;
    String fmt(int minor, String? walletId) =>
        formatMoney(Money(minor, data.wallet(walletId)?.currency ?? Currency.vnd), locale: locale, withSymbol: false);
    setState(() {
      _editing = t;
      _date = t.date;
      _note.text = t.note ?? '';
      _eventId = t.eventId;
      _goalId = t.goalId ?? data.counterpart(t)?.goalId;
      switch (t.kind) {
        case TxnKind.transferOut || TxnKind.transferIn:
          _mode = _Mode.transfer;
          _transferId = t.transferId;
          final other = data.counterpart(t);
          final out = t.kind == TxnKind.transferOut ? t : other;
          final inn = t.kind == TxnKind.transferIn ? t : other;
          _walletId = out?.walletId ?? t.counterWalletId;
          _toWalletId = inn?.walletId ?? t.counterWalletId;
          if (out != null) {
            _amount.text = fmt(out.amount, out.walletId);
            if (out.fee > 0) _fee.text = fmt(out.fee, out.walletId);
          }
          if (inn != null) _received.text = fmt(inn.amount, inn.walletId);
          if (out == null && inn != null) _amount.text = fmt(inn.amount, inn.walletId);
        case TxnKind.adjustment:
          _mode = _Mode.adjustment;
          _walletId = t.walletId;
          _amount.text = fmt(t.amount, t.walletId);
        case TxnKind.expense || TxnKind.income:
          _mode = t.kind == TxnKind.income ? _Mode.income : _Mode.expense;
          _walletId = t.walletId;
          _categoryId = t.categoryId;
          _payee.text = t.payee ?? '';
          _amount.text = fmt(t.amount, t.walletId);
          _incomePlanId = t.incomePlanId;
          if (t.taxWithheld > 0) _withheld.text = fmt(t.taxWithheld, t.walletId);
      }
    });
  }

  @override
  void dispose() {
    for (final c in [_amount, _fee, _received, _note, _payee, _withheld]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _trimOrNull(String s) => s.trim().isEmpty ? null : s.trim();

  void _save() {
    if (!_form.currentState!.validate()) return;
    final data = ref.read(ledgerProvider);
    final notifier = ref.read(ledgerProvider.notifier);
    final locale = context.appLocale;
    final wallet = data.wallet(_walletId);
    try {
      if (wallet == null) throw const LedgerException('walletMissing');
      final amount = AmountField.tryValue(_amount.text, wallet.currency, locale)!;
      if (_mode == _Mode.transfer) {
        final to = data.wallet(_toWalletId);
        if (to == null) throw const LedgerException('walletMissing');
        final fee = AmountField.tryValue(_fee.text, wallet.currency, locale);
        final received = to.currency == wallet.currency
            ? null
            : AmountField.tryValue(_received.text, to.currency, locale)?.minor;
        notifier.saveTransfer(
          transferId: _transferId,
          fromWalletId: wallet.id,
          toWalletId: to.id,
          amount: amount.minor,
          received: received,
          fee: fee?.minor ?? 0,
          date: _date,
          note: _trimOrNull(_note.text),
          goalId: _goalId,
          eventId: _eventId,
        );
      } else {
        final base = _editing;
        notifier.saveTxn(
          Txn(
            id: base?.id ?? notifier.newId(),
            walletId: wallet.id,
            kind: switch (_mode) {
              _Mode.income => TxnKind.income,
              _Mode.adjustment => TxnKind.adjustment,
              _ => TxnKind.expense,
            },
            amount: amount.minor,
            date: _date,
            categoryId: _mode == _Mode.adjustment ? null : _categoryId,
            note: _trimOrNull(_note.text),
            payee: _mode == _Mode.adjustment ? null : _trimOrNull(_payee.text),
            tags: base?.tags ?? const [],
            eventId: _mode == _Mode.adjustment ? base?.eventId : _eventId,
            debtId: base?.debtId,
            goalId: _mode == _Mode.adjustment ? base?.goalId : _goalId,
            recurringId: base?.recurringId,
            source: base?.source ?? TxnSource.manual,
            pending: base?.pending ?? false,
            excludeFromReports: base?.excludeFromReports ?? false,
            attachmentIds: base?.attachmentIds ?? const [],
            incomePlanId: _mode == _Mode.income ? _incomePlanId : null,
            taxWithheld: _mode == _Mode.income
                ? (AmountField.tryValue(_withheld.text, wallet.currency, locale)?.minor ?? 0)
                : 0,
          ),
        );
      }
      context.toast(context.l10n.saved);
      _close();
    } on Object catch (e) {
      context.toast(errorMessage(context, e));
    }
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/transactions');
    }
  }

  Future<void> _delete() async {
    final t = _editing;
    if (t == null) return;
    final l = context.l10n;
    final ok = await confirmDialog(
      context,
      message: t.transferId != null ? l.txnDeleteTransferConfirm : l.txnDeleteConfirm,
    );
    if (!ok || !mounted) return;
    ref.read(ledgerProvider.notifier).deleteTxn(t.id);
    context.toast(l.deleted);
    _close();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_date.year, _date.month, _date.day),
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = CivilDate.fromDateTime(picked));
  }

  List<DropdownMenuItem<String?>> _categoryItems(LedgerData data, CategoryKind kind) {
    final l = context.l10n;
    final roots = data.categories.where((c) => c.kind == kind && c.parentId == null && !c.archived);
    return [
      DropdownMenuItem(value: null, child: Text(l.uncategorized)),
      for (final r in roots) ...[
        DropdownMenuItem(
          value: r.id,
          child: Row(
            children: [
              Icon(categoryIcon(r.icon), size: 20),
              const SizedBox(width: QtSpace.s2),
              Flexible(child: Text(r.name, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
        for (final c in data.categories.where((c) => c.parentId == r.id && !c.archived))
          DropdownMenuItem(
            value: c.id,
            child: Padding(
              padding: const EdgeInsets.only(left: QtSpace.s6),
              child: Text(c.name, overflow: TextOverflow.ellipsis),
            ),
          ),
      ],
    ];
  }

  List<DropdownMenuItem<String>> _walletItems(LedgerData data, {String? keep}) => [
    for (final w in data.wallets.where((w) => (!w.archived && data.canWrite(w.id)) || w.id == keep))
      DropdownMenuItem(
        value: w.id,
        child: Text('${w.name} (${w.currency.code})', overflow: TextOverflow.ellipsis),
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final data = ref.watch(ledgerProvider);
    if (_missing) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(icon: Icons.search_off, title: l.noResults, body: ''),
      );
    }
    final wallet = data.wallet(_walletId);
    final toWallet = data.wallet(_toWalletId);
    final currency = wallet?.currency ?? Currency.vnd;
    final isTransfer = _mode == _Mode.transfer;
    final needReceived = isTransfer && toWallet != null && wallet != null && toWallet.currency != wallet.currency;
    final catKind = _mode == _Mode.income ? CategoryKind.income : CategoryKind.expense;
    final catItems = _categoryItems(data, catKind);
    final validCat = catItems.any((i) => i.value == _categoryId) ? _categoryId : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing == null ? l.txnNew : l.txnEdit),
        actions: [
          if (_editing != null)
            IconButton(tooltip: l.actionDelete, icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: PageBody(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(QtSpace.s4),
            children: [
              if (_editing != null && (data.txn(_editing!.id)?.pending ?? false)) ...[
                Card(
                  child: ListTile(
                    leading: Icon(Icons.hourglass_top, color: context.palette.warning),
                    title: Text(l.pendingBanner),
                    trailing: FilledButton(
                      onPressed: () {
                        ref.read(ledgerProvider.notifier).confirmPending(_editing!.id);
                        context.toast(l.saved);
                      },
                      child: Text(l.pendingConfirm),
                    ),
                  ),
                ),
                const SizedBox(height: QtSpace.s4),
              ],
              if (_mode != _Mode.adjustment)
                SegmentedButton<_Mode>(
                  segments: [
                    ButtonSegment(value: _Mode.expense, label: Text(l.txnExpense), icon: const Icon(Icons.north_east)),
                    ButtonSegment(value: _Mode.income, label: Text(l.txnIncome), icon: const Icon(Icons.south_west)),
                    ButtonSegment(
                      value: _Mode.transfer,
                      label: Text(l.txnTransfer),
                      icon: const Icon(Icons.swap_horiz),
                      // Đổi loại của một vế chuyển ví đã lưu dễ gây lệch dữ liệu ⇒ khóa khi sửa.
                      enabled: _editing == null || _transferId != null,
                    ),
                  ],
                  selected: {_mode},
                  showSelectedIcon: false,
                  onSelectionChanged: (_editing != null && _transferId != null)
                      ? null
                      : (s) => setState(() {
                          _mode = s.first;
                          _categoryId = null;
                        }),
                )
              else
                Text(l.txnAdjustment, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: QtSpace.s4),
              AmountField(
                fieldKey: const Key('amount'),
                controller: _amount,
                currency: currency,
                label: l.txnAmount,
                allowNegative: _mode == _Mode.adjustment,
                autofocus: _editing == null && widget.txnId == null,
              ),
              const SizedBox(height: QtSpace.s4),
              DropdownButtonFormField<String>(
                key: ValueKey('from-$_walletId'),
                initialValue: _walletId,
                isExpanded: true,
                decoration: InputDecoration(labelText: isTransfer ? l.txnFromWallet : l.txnWallet),
                items: _walletItems(data, keep: _walletId),
                validator: (v) => v == null ? l.errWalletMissing : null,
                onChanged: (v) => setState(() => _walletId = v),
              ),
              const SizedBox(height: QtSpace.s4),
              if (isTransfer) ...[
                DropdownButtonFormField<String>(
                  key: ValueKey('to-$_toWalletId'),
                  initialValue: _toWalletId,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.txnToWallet),
                  items: _walletItems(data, keep: _toWalletId),
                  validator: (v) => v == null ? l.errWalletMissing : (v == _walletId ? l.errSameWallet : null),
                  onChanged: (v) => setState(() => _toWalletId = v),
                ),
                const SizedBox(height: QtSpace.s4),
                if (needReceived) ...[
                  AmountField(
                    controller: _received,
                    currency: toWallet.currency,
                    label: l.txnReceived(toWallet.currency.code),
                  ),
                  const SizedBox(height: QtSpace.s4),
                ],
                AmountField(controller: _fee, currency: currency, label: l.txnFee, allowZero: true),
                const SizedBox(height: QtSpace.s4),
              ] else if (_mode != _Mode.adjustment) ...[
                DropdownButtonFormField<String?>(
                  key: ValueKey('cat-$catKind-$validCat'),
                  initialValue: validCat,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.txnCategory),
                  items: catItems,
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
                const SizedBox(height: QtSpace.s4),
              ],
              if (_mode != _Mode.adjustment && data.events.any((e) => !e.archived || e.id == _eventId)) ...[
                DropdownButtonFormField<String?>(
                  initialValue: data.event(_eventId) == null ? null : _eventId,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.txnEvent),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l.none)),
                    for (final e in data.events.where((e) => !e.archived || e.id == _eventId))
                      DropdownMenuItem(
                        value: e.id,
                        child: Text(e.name, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => setState(() => _eventId = v),
                ),
                const SizedBox(height: QtSpace.s4),
              ],
              if (_mode != _Mode.adjustment && data.goals.isNotEmpty) ...[
                DropdownButtonFormField<String?>(
                  initialValue: data.goal(_goalId) == null ? null : _goalId,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.txnGoal),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l.none)),
                    for (final g in data.goals)
                      DropdownMenuItem(
                        value: g.id,
                        child: Text(g.name, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => setState(() => _goalId = v),
                ),
                const SizedBox(height: QtSpace.s4),
              ],
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(QtRadius.md),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l.txnDate,
                    suffixIcon: const Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(formatDate(_date)),
                ),
              ),
              const SizedBox(height: QtSpace.s4),
              if (_mode == _Mode.income) ...[
                if (data.incomePlans.isNotEmpty) ...[
                  DropdownButtonFormField<String?>(
                    initialValue: data.incomePlan(_incomePlanId) == null ? null : _incomePlanId,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l.incomePlanField),
                    items: [
                      DropdownMenuItem(value: null, child: Text(l.none)),
                      for (final ip in data.incomePlans.where(
                        (x) => x.status == IncomePlanStatus.active || x.id == _incomePlanId,
                      ))
                        DropdownMenuItem(
                          value: ip.id,
                          child: Text(ip.name, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) => setState(() {
                      _incomePlanId = v;
                      final ip = data.incomePlan(v);
                      if (ip != null) {
                        _categoryId ??= ip.categoryId;
                        if (_payee.text.trim().isEmpty) _payee.text = ip.payer ?? '';
                      }
                    }),
                  ),
                  const SizedBox(height: QtSpace.s4),
                ],
                if (data.wallet(_walletId) != null) ...[
                  AmountField(
                    controller: _withheld,
                    currency: data.wallet(_walletId)!.currency,
                    label: l.txnTaxWithheld,
                    allowZero: true,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: QtSpace.s1),
                    child: Text(l.txnTaxWithheldHelp, style: Theme.of(context).textTheme.bodySmall),
                  ),
                  const SizedBox(height: QtSpace.s4),
                ],
              ],
              if (_mode == _Mode.expense || _mode == _Mode.income) ...[
                TextFormField(
                  controller: _payee,
                  textInputAction: TextInputAction.next,
                  maxLength: 120,
                  decoration: InputDecoration(labelText: l.txnPayee, counterText: ''),
                ),
                const SizedBox(height: QtSpace.s4),
              ],
              TextFormField(
                controller: _note,
                maxLines: 3,
                minLines: 1,
                maxLength: 500,
                decoration: InputDecoration(labelText: l.txnNote),
              ),
              const SizedBox(height: QtSpace.s6),
              FilledButton(onPressed: _save, child: Text(l.actionSave)),
            ],
          ),
        ),
      ),
    );
  }
}
