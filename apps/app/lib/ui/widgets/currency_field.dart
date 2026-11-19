import 'package:flutter/material.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../../domain/vn_search.dart';
import '../../theme/tokens.g.dart';
import 'common.dart';

/// Ô chọn tiền tệ: chạm để mở hộp tìm kiếm trong toàn bộ ISO 4217 (tiền tệ hay dùng đứng đầu).
class CurrencyField extends StatelessWidget {
  const CurrencyField({super.key, required this.value, required this.onChanged, this.label, this.helperText});
  final Currency value;
  final ValueChanged<Currency>? onChanged;
  final String? label;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return InkWell(
      onTap: onChanged == null
          ? null
          : () async {
              final c = await pickCurrency(context, selected: value);
              if (c != null) onChanged!(c);
            },
      borderRadius: BorderRadius.circular(QtRadius.md),
      child: InputDecorator(
        isEmpty: false,
        decoration: InputDecoration(
          labelText: label ?? context.l10n.walletCurrency,
          helperText: helperText,
          enabled: onChanged != null,
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text('${value.code} · ${value.displayName(lang)} (${value.symbol})', overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

/// Hộp chọn tiền tệ có ô tìm (mã, tên vi/en, không dấu).
Future<Currency?> pickCurrency(BuildContext context, {Currency? selected}) => showDialog<Currency>(
  context: context,
  builder: (ctx) => _CurrencyDialog(selected: selected),
);

class _CurrencyDialog extends StatefulWidget {
  const _CurrencyDialog({this.selected});
  final Currency? selected;

  @override
  State<_CurrencyDialog> createState() => _CurrencyDialogState();
}

class _CurrencyDialogState extends State<_CurrencyDialog> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final q = normalizeVi(_q);
    bool match(Currency c) =>
        q.isEmpty ||
        c.code.toLowerCase().contains(q) ||
        normalizeVi(c.name).contains(q) ||
        normalizeVi(c.nameVi).contains(q);
    final popular = q.isEmpty ? Currency.known : const <Currency>[];
    final rest = [
      for (final c in Currency.all)
        if (match(c) && !popular.contains(c)) c,
    ];
    Widget tile(Currency c) => ListTile(
      dense: true,
      selected: c == widget.selected,
      leading: SizedBox(
        width: 48,
        child: Text(c.code, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      title: Text(c.displayName(lang), overflow: TextOverflow.ellipsis),
      trailing: Text(c.symbol),
      onTap: () => Navigator.pop(context, c),
    );
    return AlertDialog(
      title: Text(l.currencyPick),
      contentPadding: const EdgeInsets.fromLTRB(QtSpace.s4, QtSpace.s3, QtSpace.s4, 0),
      content: SizedBox(
        width: 440,
        height: 520,
        child: Column(
          children: [
            TextField(
              key: const Key('currency.search'),
              autofocus: true,
              decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.currencySearch),
              onChanged: (v) => setState(() => _q = v),
            ),
            const SizedBox(height: QtSpace.s2),
            Expanded(
              child: ListView(
                children: [
                  if (popular.isNotEmpty) ...[
                    _Header(l.currencyPopular),
                    for (final c in popular) tile(c),
                    _Header(l.currencyAll(Currency.all.length)),
                  ],
                  for (final c in rest) tile(c),
                  if (popular.isEmpty && rest.isEmpty)
                    Padding(padding: const EdgeInsets.all(QtSpace.s4), child: Text(l.currencyNone)),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l.actionCancel))],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(QtSpace.s2, QtSpace.s3, QtSpace.s2, QtSpace.s1),
    child: Text(text, style: Theme.of(context).textTheme.labelLarge),
  );
}
