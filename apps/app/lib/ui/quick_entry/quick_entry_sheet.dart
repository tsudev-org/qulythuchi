import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../../services/auto_import.dart';
import '../../services/capture.dart';
import '../../state/capture_providers.dart';
import '../../state/providers.dart';
import '../../theme/tokens.g.dart';
import '../data/data_page.dart' show txnKindName;
import '../widgets/common.dart';

/// Cách mở màn ghi nhanh.
enum QuickEntryMode { type, voice, scan }

/// Mở màn "Ghi nhanh": gõ hoặc nói một câu ("ăn trưa 50 nghìn"), hoặc quét hóa đơn; xem trước rồi lưu.
Future<void> showQuickEntry(BuildContext context, {QuickEntryMode mode = QuickEntryMode.type}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => QuickEntrySheet(mode: mode),
    );

class QuickEntrySheet extends ConsumerStatefulWidget {
  const QuickEntrySheet({super.key, this.mode = QuickEntryMode.type});
  final QuickEntryMode mode;

  @override
  ConsumerState<QuickEntrySheet> createState() => _QuickEntrySheetState();
}

class _QuickEntrySheetState extends ConsumerState<QuickEntrySheet> {
  final _text = TextEditingController();
  String? _walletId;
  TxnSource _source = TxnSource.manual;
  CivilDate? _receiptDate;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.mode == QuickEntryMode.voice) _voice();
      if (widget.mode == QuickEntryMode.scan) _scan(fromCamera: true);
    });
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _voice() async {
    final l = context.l10n;
    final voice = ref.read(voiceInputProvider);
    if (!voice.supported) return;
    final localeId = context.appLocale == AppLocale.en ? 'en-US' : 'vi-VN';
    setState(() => _busy = true);
    try {
      var r = await voice.listen(localeId: localeId, allowOsService: false);
      if (r.status == VoiceStatus.needsConsent && mounted) {
        final ok = await confirmDialog(
          context,
          message: l.voiceConsent,
          confirmLabel: l.voiceConsentOk,
          destructive: false,
        );
        if (!ok || !mounted) return;
        r = await voice.listen(localeId: localeId, allowOsService: true);
      }
      if (!mounted) return;
      switch (r.status) {
        case VoiceStatus.ok:
          _text.text = r.text ?? '';
          _source = TxnSource.voice;
        case VoiceStatus.denied:
          context.toast(l.voiceDenied);
        case VoiceStatus.unavailable:
          context.toast(l.voiceUnavailable);
        case VoiceStatus.needsConsent || VoiceStatus.cancelled:
          break;
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _scan({required bool fromCamera}) async {
    final l = context.l10n;
    final scanner = ref.read(receiptScannerProvider);
    if (!scanner.supported) return;
    setState(() => _busy = true);
    try {
      final r = await scanner.scan(fromCamera: fromCamera);
      if (r == null || !mounted) return;
      final info = parseReceiptText(r.text);
      if (info.total == null) {
        context.toast(l.scanNoTotal);
        return;
      }
      // Câu tương đương để dùng chung bộ đọc + xem trước; ngày lấy từ hóa đơn.
      _text.text = '${info.merchant ?? l.scanDefaultNote} ${info.total}đ';
      _receiptDate = info.date;
      _source = TxnSource.ocr;
    } on Object {
      if (mounted) context.toast(l.scanFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final data = ref.watch(ledgerProvider);
    final wallets = data.wallets.where((w) => !w.archived && w.currency == Currency.vnd).toList();
    if (_walletId == null || wallets.every((w) => w.id != _walletId)) _walletId = wallets.firstOrNull?.id;
    final wallet = data.wallet(_walletId);
    final today = CivilDate.fromDateTime(DateTime.now());
    final parsed = parseQuickEntry(_text.text, today);
    final entry = parsed == null || _receiptDate == null
        ? parsed
        : QuickEntry(kind: parsed.kind, amount: parsed.amount, date: _receiptDate!, note: parsed.note);
    final suggester = LedgerCategorySuggester(data);
    final txn = entry == null || wallet == null
        ? null
        : txnFromQuickEntry(entry, wallet, suggester, '', source: _source);
    final voice = ref.watch(voiceInputProvider);
    final scanner = ref.watch(receiptScannerProvider);
    final dup = txn == null ? const <Txn>[] : possibleDuplicates(txn, data.txns);

    return Padding(
      padding: EdgeInsets.only(
        left: QtSpace.s4,
        right: QtSpace.s4,
        top: QtSpace.s4,
        bottom: MediaQuery.viewInsetsOf(context).bottom + QtSpace.s4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.quickTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: QtSpace.s3),
          if (wallets.isEmpty)
            Text(l.quickNeedVndWallet)
          else ...[
            TextField(
              key: const Key('quick.text'),
              controller: _text,
              autofocus: widget.mode == QuickEntryMode.type,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l.quickLabel,
                hintText: l.quickHint,
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (voice.supported)
                      IconButton(
                        tooltip: l.voiceStart,
                        onPressed: _busy ? null : _voice,
                        icon: const Icon(Icons.mic_none),
                      ),
                    if (scanner.supported)
                      IconButton(
                        tooltip: l.scanReceipt,
                        onPressed: _busy ? null : () => _scan(fromCamera: true),
                        icon: const Icon(Icons.document_scanner_outlined),
                      ),
                  ],
                ),
              ),
              onChanged: (_) {
                if (_source == TxnSource.ocr) _receiptDate = null;
                _source = _source == TxnSource.voice ? TxnSource.voice : TxnSource.manual;
              },
            ),
            const SizedBox(height: QtSpace.s3),
            DropdownButtonFormField<String>(
              initialValue: _walletId,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.txnWallet),
              items: [for (final w in wallets) DropdownMenuItem(value: w.id, child: Text(w.name))],
              onChanged: (v) => setState(() => _walletId = v),
            ),
            const SizedBox(height: QtSpace.s3),
            if (_busy) const LinearProgressIndicator(),
            if (txn != null)
              Card(
                child: ListTile(
                  key: const Key('quick.preview'),
                  title: Text(
                    txn.note ?? data.category(txn.categoryId)?.name ?? l.uncategorized,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    [
                      txnKindName(l, txn.kind),
                      formatDate(txn.date),
                      data.category(txn.categoryId)?.name ?? l.uncategorized,
                    ].join(' · '),
                  ),
                  trailing: MoneyText(
                    Money(txn.kind == TxnKind.expense ? -txn.amount : txn.amount, Currency.vnd),
                    signed: true,
                    colored: true,
                  ),
                ),
              )
            else if (_text.text.trim().isNotEmpty)
              Text(l.quickNoAmount, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            if (dup.isNotEmpty) Text(l.quickMaybeDuplicate),
            const SizedBox(height: QtSpace.s3),
            FilledButton(
              key: const Key('quick.save'),
              onPressed: txn == null || _busy
                  ? null
                  : () {
                      final notifier = ref.read(ledgerProvider.notifier);
                      try {
                        notifier.saveTxn(
                          txnFromQuickEntry(entry!, wallet!, suggester, notifier.newId(), source: _source),
                        );
                        Navigator.pop(context);
                        context.toast(l.quickSaved);
                      } on Object catch (e) {
                        context.toast(errorMessage(context, e));
                      }
                    },
              child: Text(l.actionSave),
            ),
          ],
        ],
      ),
    );
  }
}
