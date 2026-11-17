import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../../domain/txn_filter.dart';
import '../../state/providers.dart';
import '../../state/settings.dart';
import '../../theme/tokens.g.dart';
import '../widgets/amount_field.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';

/// Lọc nhiều điều kiện; trả về bộ lọc mới (hoặc null nếu hủy). Có lưu thành bộ lọc đặt tên.
class FilterDialog extends ConsumerStatefulWidget {
  const FilterDialog({super.key, required this.initial});
  final TxnFilter initial;

  @override
  ConsumerState<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends ConsumerState<FilterDialog> {
  late final Set<FilterKind> _kinds = {...widget.initial.kinds};
  late List<String> _wallets = [...widget.initial.walletIds];
  late List<String> _cats = [...widget.initial.categoryIds];
  late bool _uncat = widget.initial.uncategorizedOnly;
  late CivilDate? _from = widget.initial.from;
  late CivilDate? _to = widget.initial.to;
  final _min = TextEditingController();
  final _max = TextEditingController();
  final _name = TextEditingController();
  late final Currency _base = Currency.of(ref.read(settingsProvider).baseCurrency);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = context.appLocale;
      if (widget.initial.minMinor != null) {
        _min.text = formatMoney(Money(widget.initial.minMinor!, _base), locale: loc, withSymbol: false);
      }
      if (widget.initial.maxMinor != null) {
        _max.text = formatMoney(Money(widget.initial.maxMinor!, _base), locale: loc, withSymbol: false);
      }
    });
  }

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    _name.dispose();
    super.dispose();
  }

  TxnFilter _build() {
    final loc = context.appLocale;
    return TxnFilter(
      kinds: _kinds,
      walletIds: _wallets.toSet(),
      categoryIds: _uncat ? const {} : _cats.toSet(),
      uncategorizedOnly: _uncat,
      from: _from,
      to: _to,
      minMinor: AmountField.tryValue(_min.text, _base, loc)?.minor,
      maxMinor: AmountField.tryValue(_max.text, _base, loc)?.minor,
    );
  }

  Future<void> _save() async {
    final l = context.l10n;
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => ControllerScope(
        count: 1,
        builder: (ctx, c) => AlertDialog(
          title: Text(l.filterSave),
          content: TextField(
            controller: c[0],
            autofocus: true,
            maxLength: 40,
            decoration: InputDecoration(labelText: l.filterSaveName),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.actionCancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, c[0].text.trim()), child: Text(l.actionSave)),
          ],
        ),
      ),
    );
    if (name == null || name.isEmpty || !mounted) return;
    final n = ref.read(ledgerProvider.notifier);
    final f = _build();
    n.saveFilter(SavedFilter(id: n.newId(), name: name, filter: f));
    Navigator.pop(context, f);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final data = ref.watch(ledgerProvider);
    final kindLabels = {
      FilterKind.expense: l.txnExpense,
      FilterKind.income: l.txnIncome,
      FilterKind.transfer: l.txnTransfer,
      FilterKind.adjustment: l.txnAdjustment,
    };
    final cats = [
      ...categoryOptions(data.categories, CategoryKind.expense),
      ...categoryOptions(data.categories, CategoryKind.income),
    ];
    return AlertDialog(
      title: Text(l.filterTitle),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.filterKinds, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: QtSpace.s1),
              Wrap(
                spacing: QtSpace.s2,
                runSpacing: QtSpace.s1,
                children: [
                  for (final k in FilterKind.values)
                    FilterChip(
                      label: Text(kindLabels[k]!),
                      selected: _kinds.contains(k),
                      onSelected: (on) => setState(() => on ? _kinds.add(k) : _kinds.remove(k)),
                    ),
                ],
              ),
              const SizedBox(height: QtSpace.s4),
              MultiSelectField(
                label: l.filterWallets,
                allLabel: l.filterAllWallets,
                options: [for (final w in data.wallets) (w.id, w.name, false)],
                selected: _wallets,
                onChanged: (v) => setState(() => _wallets = v),
              ),
              const SizedBox(height: QtSpace.s4),
              if (!_uncat)
                MultiSelectField(
                  label: l.filterCategories,
                  allLabel: l.filterAllCategories,
                  options: cats,
                  selected: _cats,
                  onChanged: (v) => setState(() => _cats = v),
                ),
              SwitchListTile(
                value: _uncat,
                onChanged: (v) => setState(() => _uncat = v),
                title: Text(l.filterUncategorized),
                contentPadding: EdgeInsets.zero,
              ),
              Row(
                children: [
                  Expanded(
                    child: DateField(
                      label: l.budgetFrom,
                      value: _from,
                      onChanged: (d) => setState(() => _from = d),
                      onCleared: () => setState(() => _from = null),
                    ),
                  ),
                  const SizedBox(width: QtSpace.s3),
                  Expanded(
                    child: DateField(
                      label: l.budgetTo,
                      value: _to,
                      onChanged: (d) => setState(() => _to = d),
                      onCleared: () => setState(() => _to = null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: QtSpace.s4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AmountField(controller: _min, currency: _base, label: l.filterMin, allowZero: true),
                  ),
                  const SizedBox(width: QtSpace.s3),
                  Expanded(
                    child: AmountField(controller: _max, currency: _base, label: l.filterMax, allowZero: true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, TxnFilter.empty), child: Text(l.filterClear)),
        TextButton(onPressed: _save, child: Text(l.filterSave)),
        FilledButton(onPressed: () => Navigator.pop(context, _build()), child: Text(l.filterApply)),
      ],
    );
  }
}
