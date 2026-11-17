import 'package:flutter/material.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../../domain/amount_expression.dart';
import '../../theme/app_theme.dart';
import 'common.dart';

/// Ô số tiền có máy tính (`50.000+25.000`, `120.000x3`). Kết quả luôn là số nguyên đơn vị nhỏ nhất.
class AmountField extends StatefulWidget {
  const AmountField({
    super.key,
    required this.controller,
    required this.currency,
    required this.label,
    this.allowZero = false,
    this.allowNegative = false,
    this.autofocus = false,
    this.fieldKey,
  });

  final TextEditingController controller;
  final Currency currency;
  final String label;
  final bool allowZero;
  final bool allowNegative;
  final bool autofocus;
  final Key? fieldKey;

  /// Đọc giá trị (null nếu trống hoặc sai).
  static Money? tryValue(String text, Currency currency, AppLocale locale) {
    if (text.trim().isEmpty) return null;
    try {
      return evaluateAmount(text, currency, locale: locale);
    } on Object {
      return null;
    }
  }

  @override
  State<AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<AmountField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = widget.controller.text;
    final value = AmountField.tryValue(text, widget.currency, context.appLocale);
    String? helper = l.txnAmountHint;
    if (value != null && hasOperator(text)) {
      helper = l.txnAmountResult(formatMoney(value, locale: context.appLocale));
    }
    return TextFormField(
      key: widget.fieldKey,
      controller: widget.controller,
      autofocus: widget.autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
      textInputAction: TextInputAction.next,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: helper,
        helperStyle: TextStyle(color: context.palette.textSecondary),
        suffixText: widget.currency.symbol,
      ),
      validator: (_) {
        final t = widget.controller.text;
        if (t.trim().isEmpty && widget.allowZero) return null;
        final v = AmountField.tryValue(t, widget.currency, context.appLocale);
        if (v == null) return l.txnAmountInvalid;
        if (v.isNegative && !widget.allowNegative) return l.txnAmountPositive;
        if (v.isZero && !widget.allowZero) return l.txnAmountPositive;
        return null;
      },
    );
  }
}
