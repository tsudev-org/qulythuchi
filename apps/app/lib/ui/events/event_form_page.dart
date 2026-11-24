// ignore: deprecated_member_use
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
import '../widgets/edit_page.dart';
import '../widgets/form_fields.dart';

class EventFormPage extends ConsumerStatefulWidget {
  const EventFormPage({super.key, this.eventId});
  final String? eventId;

  @override
  ConsumerState<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends ConsumerState<EventFormPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _budget = TextEditingController();
  Event? _editing;
  CivilDate _start = todayCivil();
  CivilDate? _end;
  bool _archived = false;

  /// Ngân sách sự kiện tính theo tiền tệ quy đổi (lõi lưu số nguyên, không kèm tiền tệ).
  late final Currency _currency = Currency.of(ref.read(settingsProvider).baseCurrency);

  @override
  void initState() {
    super.initState();
    hideToastSoon(context);
    final e = ref.read(ledgerProvider).event(widget.eventId);
    if (e != null) {
      _editing = e;
      _name.text = e.name;
      _start = e.start;
      _end = e.end;
      _archived = e.archived;
      if (e.budget != null) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _budget.text = formatMoney(Money(e.budget!, _currency), locale: context.appLocale, withSymbol: false),
        );
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _budget.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final n = ref.read(ledgerProvider.notifier);
    try {
      n.saveEvent(
        Event(
          id: _editing?.id ?? n.newId(),
          name: _name.text.trim(),
          start: _start,
          end: _end,
          budget: AmountField.tryValue(_budget.text, _currency, context.appLocale)?.minor,
          archived: _archived,
        ),
      );
      context.toast(context.l10n.saved);
      closePage(context, '/more/events');
    } on Object catch (e) {
      context.toast(errorMessage(context, e));
    }
  }

  Future<void> _delete() async {
    final e = _editing!;
    final l = context.l10n;
    if (!await confirmDialog(context, message: l.eventDeleteConfirm(e.name)) || !mounted) return;
    ref.read(ledgerProvider.notifier).deleteEvent(e.id);
    context.toast(l.deleted);
    closePage(context, '/more/events');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    final data = ref.watch(ledgerProvider);
    final id = _editing?.id;
    final txns = id == null ? const <Txn>[] : data.txns.where((t) => t.eventId == id).toList();
    final spent = id == null ? const <Currency, Money>{} : data.eventSpending(id);
    final budget = _editing?.budget;
    final spentBase = spent[_currency];
    return EditPage(
      title: _editing == null ? l.eventNew : l.eventEdit,
      formKey: _form,
      onSave: _save,
      onDelete: _editing == null ? null : _delete,
      children: [
        if (spent.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(QtSpace.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final m in spent.values)
                    Text(
                      l.eventSpent(formatMoney(m, locale: context.appLocale)),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  if (budget != null && budget > 0 && spentBase != null) ...[
                    const SizedBox(height: QtSpace.s2),
                    ProgressBar(
                      basisPoints: spentBase.basisPointsOf(Money(budget, _currency)),
                      color: spentBase.minor > budget ? p.danger : p.primary,
                      semanticLabel: l.eventBudget,
                    ),
                  ],
                ],
              ),
            ),
          ),
        TextFormField(
          controller: _name,
          autofocus: _editing == null,
          maxLength: 80,
          decoration: InputDecoration(labelText: l.eventName, counterText: ''),
          validator: (v) => (v == null || v.trim().isEmpty) ? l.errNameRequired : null,
        ),
        DateField(label: l.eventStart, value: _start, onChanged: (d) => setState(() => _start = d)),
        DateField(
          label: l.eventEnd,
          value: _end,
          onChanged: (d) => setState(() => _end = d),
          onCleared: () => setState(() => _end = null),
        ),
        AmountField(
          controller: _budget,
          currency: _currency,
          label: '${l.eventBudget} (${_currency.code})',
          allowZero: true,
        ),
        if (_editing != null)
          SwitchListTile(
            value: _archived,
            onChanged: (v) => setState(() => _archived = v),
            title: Text(l.walletArchivedBadge),
            contentPadding: EdgeInsets.zero,
          ),
        if (txns.isNotEmpty) ...[
          Semantics(header: true, child: Text(l.eventTxns, style: Theme.of(context).textTheme.titleMedium)),
          Card(
            child: Column(
              children: [for (final t in txns) TxnTile(txn: t, data: data, showDate: true)],
            ),
          ),
        ],
      ],
    );
  }
}
