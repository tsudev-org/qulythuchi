import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../../state/providers.dart';
import '../../theme/tokens.g.dart';
import '../widgets/amount_field.dart';
import '../widgets/common.dart';
import 'wallets_page.dart';

class WalletFormPage extends ConsumerStatefulWidget {
  const WalletFormPage({super.key, this.walletId});
  final String? walletId;

  @override
  ConsumerState<WalletFormPage> createState() => _WalletFormPageState();
}

class _WalletFormPageState extends ConsumerState<WalletFormPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _opening = TextEditingController();
  final _limit = TextEditingController();
  WalletType _type = WalletType.cash;
  Currency _currency = Currency.vnd;
  bool _archived = false;
  bool _exclude = false;
  Wallet? _editing;

  @override
  void initState() {
    super.initState();
    // Toast của trang trước không được che nút Lưu.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    });
    if (widget.walletId != null) {
      final w = ref.read(ledgerProvider).wallet(widget.walletId);
      if (w != null) {
        _editing = w;
        _name.text = w.name;
        _type = w.type;
        _currency = w.currency;
        _archived = w.archived;
        _exclude = w.excludeFromTotal;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final loc = context.appLocale;
          setState(() {
            if (w.openingBalance != 0) {
              _opening.text = formatMoney(w.opening, locale: loc, withSymbol: false);
            }
            if (w.creditLimit != null) {
              _limit.text = formatMoney(Money(w.creditLimit!, w.currency), locale: loc, withSymbol: false);
            }
          });
        });
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _opening.dispose();
    _limit.dispose();
    super.dispose();
  }

  void _close() => context.canPop() ? context.pop() : context.go('/wallets');

  void _save() {
    if (!_form.currentState!.validate()) return;
    final loc = context.appLocale;
    final notifier = ref.read(ledgerProvider.notifier);
    final base = _editing;
    try {
      notifier.saveWallet(
        Wallet(
          id: base?.id ?? notifier.newId(),
          name: _name.text.trim(),
          type: _type,
          currency: _currency,
          openingBalance: AmountField.tryValue(_opening.text, _currency, loc)?.minor ?? 0,
          creditLimit: _type == WalletType.credit ? AmountField.tryValue(_limit.text, _currency, loc)?.minor : null,
          statementDay: base?.statementDay,
          dueDay: base?.dueDay,
          archived: _archived,
          excludeFromTotal: _exclude,
          icon: base?.icon,
          color: base?.color,
          sortOrder: base?.sortOrder ?? 0,
        ),
      );
      context.toast(context.l10n.saved);
      _close();
    } on Object catch (e) {
      context.toast(errorMessage(context, e));
    }
  }

  Future<void> _delete() async {
    final w = _editing;
    if (w == null) return;
    final l = context.l10n;
    if (!await confirmDialog(context, message: l.walletDeleteConfirm(w.name)) || !mounted) return;
    try {
      ref.read(ledgerProvider.notifier).deleteWallet(w.id);
      context.toast(l.deleted);
      _close();
    } on Object catch (e) {
      context.toast(errorMessage(context, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final data = ref.watch(ledgerProvider);
    final hasTxns = _editing != null && data.txns.any((t) => t.walletId == _editing!.id);
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing == null ? l.walletNew : l.walletEdit),
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
              if (_editing != null) ...[
                Card(
                  child: ListTile(
                    title: Text(l.walletBalance),
                    trailing: MoneyText(
                      data.balance(data.wallet(_editing!.id) ?? _editing!),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                const SizedBox(height: QtSpace.s4),
              ],
              TextFormField(
                controller: _name,
                autofocus: _editing == null,
                maxLength: 60,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: l.walletName, counterText: ''),
                validator: (v) => (v == null || v.trim().isEmpty) ? l.errNameRequired : null,
              ),
              const SizedBox(height: QtSpace.s4),
              DropdownButtonFormField<WalletType>(
                initialValue: _type,
                isExpanded: true,
                decoration: InputDecoration(labelText: l.walletType),
                items: [
                  for (final t in WalletType.values)
                    DropdownMenuItem(
                      value: t,
                      child: Row(
                        children: [
                          Icon(walletTypeIcon(t), size: 20),
                          const SizedBox(width: QtSpace.s2),
                          Text(walletTypeLabel(l, t)),
                        ],
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: QtSpace.s4),
              DropdownButtonFormField<Currency>(
                initialValue: _currency,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l.walletCurrency,
                  helperText: hasTxns ? l.errCurrencyLocked : null,
                ),
                items: [
                  for (final c in selectableCurrencies)
                    DropdownMenuItem(value: c, child: Text('${c.code} (${c.symbol})')),
                ],
                onChanged: hasTxns ? null : (v) => setState(() => _currency = v ?? _currency),
              ),
              const SizedBox(height: QtSpace.s4),
              AmountField(
                controller: _opening,
                currency: _currency,
                label: l.walletOpening,
                allowZero: true,
                allowNegative: true,
              ),
              if (_type == WalletType.credit) ...[
                const SizedBox(height: QtSpace.s4),
                AmountField(controller: _limit, currency: _currency, label: l.walletCreditLimit, allowZero: true),
              ],
              const SizedBox(height: QtSpace.s2),
              SwitchListTile(
                value: _exclude,
                onChanged: (v) => setState(() => _exclude = v),
                title: Text(l.walletExcludeTotal),
                contentPadding: EdgeInsets.zero,
              ),
              if (_editing != null)
                SwitchListTile(
                  value: _archived,
                  onChanged: (v) => setState(() => _archived = v),
                  title: Text(l.walletArchived),
                  contentPadding: EdgeInsets.zero,
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
