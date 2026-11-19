import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../../domain/extra_models.dart';
import '../../state/providers.dart';
import '../../state/settings.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../widgets/common.dart';
import '../widgets/currency_field.dart';
import '../widgets/form_fields.dart';

/// Tiền tệ quy đổi + tỉ giá nhập tay (tự cập nhật qua máy chủ riêng ở P5/P6).
class RatesPage extends ConsumerWidget {
  const RatesPage({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref, Currency base) async {
    final data = ref.read(ledgerProvider);
    final used = {for (final w in data.wallets) w.currency}..remove(base);
    var from = used.firstOrNull ?? Currency.known.firstWhere((c) => c != base);
    var date = todayCivil();
    final key = GlobalKey<FormState>();
    final locale = context.appLocale;
    final l = context.l10n;
    final result = await showDialog<(Currency, String, CivilDate)>(
      context: context,
      builder: (ctx) => ControllerScope(
        count: 1,
        builder: (ctx, c) => StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: Text(l.ratesNew),
            content: SizedBox(
              width: 420,
              child: Form(
                key: key,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<Currency>(
                      initialValue: from,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: l.ratesFrom),
                      items: [
                        for (final cur in Currency.all.where((x) => x != base))
                          DropdownMenuItem(value: cur, child: Text('${cur.code} (${cur.symbol})')),
                      ],
                      onChanged: (v) => setLocal(() => from = v ?? from),
                    ),
                    const SizedBox(height: QtSpace.s4),
                    TextFormField(
                      controller: c[0],
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: l.ratesValue(from.code, base.code)),
                      validator: (v) => FxRate.normalize(v ?? '', locale) == null ? l.ratesInvalid : null,
                    ),
                    const SizedBox(height: QtSpace.s4),
                    DateField(label: l.txnDate, value: date, onChanged: (d) => setLocal(() => date = d)),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.actionCancel)),
              FilledButton(
                onPressed: () {
                  if (!key.currentState!.validate()) return;
                  Navigator.pop(ctx, (from, FxRate.normalize(c[0].text, locale)!, date));
                },
                child: Text(l.actionSave),
              ),
            ],
          ),
        ),
      ),
    );
    if (result == null || !context.mounted) return;
    final n = ref.read(ledgerProvider.notifier);
    try {
      n.saveRate(FxRate(id: n.newId(), from: result.$1, to: base, rate: result.$2, date: result.$3));
      context.toast(l.saved);
    } on Object catch (e) {
      context.toast(errorMessage(context, e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final p = context.palette;
    final data = ref.watch(ledgerProvider);
    final base = Currency.of(ref.watch(settingsProvider.select((s) => s.baseCurrency)));
    final rates = data.rates.where((r) => r.to == base).toList();
    final missing = data.totalIn(base).missing;
    return Scaffold(
      appBar: AppBar(title: Text(l.moreRates)),
      floatingActionButton: FloatingActionButton(
        tooltip: l.ratesNew,
        onPressed: () => _add(context, ref, base),
        child: const Icon(Icons.add),
      ),
      body: PageBody(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(QtSpace.s4, QtSpace.s4, QtSpace.s4, 96),
          children: [
            CurrencyField(
              value: base,
              label: l.ratesBase,
              onChanged: (v) => ref.read(settingsProvider.notifier).setBaseCurrency(v.code),
            ),
            const SizedBox(height: QtSpace.s3),
            Text(l.ratesNote, style: TextStyle(color: p.textSecondary)),
            if (missing.isNotEmpty) ...[
              const SizedBox(height: QtSpace.s3),
              Row(
                children: [
                  Icon(Icons.warning_amber_outlined, color: p.warning),
                  const SizedBox(width: QtSpace.s2),
                  Expanded(child: Text(l.ratesMissing(missing.map((c) => c.code).join(', ')))),
                ],
              ),
            ],
            const SizedBox(height: QtSpace.s4),
            if (rates.isEmpty)
              EmptyState(icon: Icons.currency_exchange, title: l.emptyRatesTitle, body: l.emptyRatesBody)
            else
              Card(
                child: Column(
                  children: [
                    for (final r in rates)
                      ListTile(
                        title: Text('1 ${r.from.code} = ${_fmtRate(r.rate, context.appLocale)} ${r.to.code}'),
                        subtitle: Text(formatDate(r.date)),
                        trailing: IconButton(
                          tooltip: l.actionDelete,
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => ref.read(ledgerProvider.notifier).deleteRate(r.id),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "25450.5" ⇒ "25.450,5" (vi) / "25,450.5" (en).
String _fmtRate(String rate, AppLocale locale) {
  final parts = rate.split('.');
  final intPart = formatMoney(Money(int.parse(parts[0]), Currency.vnd), locale: locale, withSymbol: false);
  if (parts.length == 1) return intPart;
  return '$intPart${locale == AppLocale.vi ? ',' : '.'}${parts[1]}';
}
