import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../../l10n/app_localizations.dart';
import '../../services/auto_import.dart';
import '../../services/export.dart';
import '../../services/import_csv.dart';
import '../../services/xlsx_reader.dart';
import '../../state/ledger_repository.dart';
import '../../state/providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';

/// Lưu tệp: web tải xuống, nền tảng khác mở hộp thoại "Lưu thành". Trả về false khi người dùng hủy.
Future<bool> saveBytes(String name, String ext, Uint8List bytes, MimeType mime) async {
  if (kIsWeb) {
    await FileSaver.instance.saveFile(name: name, bytes: bytes, fileExtension: ext, mimeType: mime);
    return true;
  }
  final path = await FileSaver.instance.saveAs(name: name, bytes: bytes, fileExtension: ext, mimeType: mime);
  return path != null && path.isNotEmpty;
}

String _stamp() {
  final n = DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${n.year}${two(n.month)}${two(n.day)}-${two(n.hour)}${two(n.minute)}';
}

String txnKindName(AppLocalizations l, TxnKind k) => switch (k) {
  TxnKind.expense => l.txnExpense,
  TxnKind.income => l.txnIncome,
  TxnKind.transferIn || TxnKind.transferOut => l.txnTransfer,
  TxnKind.adjustment => l.txnAdjustment,
};

class DataPage extends ConsumerWidget {
  const DataPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.dataTitle)),
      body: PageBody(
        child: ListView(
          padding: const EdgeInsets.all(QtSpace.s4),
          children: const [
            _ExportCard(),
            SizedBox(height: QtSpace.s4),
            _ImportCard(),
            SizedBox(height: QtSpace.s4),
            _BackupCard(),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(QtSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
          const SizedBox(height: QtSpace.s3),
          for (final c in children) ...[c, const SizedBox(height: QtSpace.s3)],
        ],
      ),
    ),
  );
}

class _Warning extends StatelessWidget {
  const _Warning(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(child: Icon(Icons.warning_amber_rounded, color: p.warning)),
        const SizedBox(width: QtSpace.s2),
        Expanded(
          child: Text(text, style: TextStyle(color: p.textSecondary)),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ Xuất

class _ExportCard extends ConsumerStatefulWidget {
  const _ExportCard();

  @override
  ConsumerState<_ExportCard> createState() => _ExportCardState();
}

class _ExportCardState extends ConsumerState<_ExportCard> {
  ExportFormat _format = ExportFormat.csv;
  CivilDate? _from;
  CivilDate? _to;
  bool _busy = false;

  Future<void> _export() async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.exportTitle),
        content: Text(l.exportWarning),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.actionCancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.actionContinue)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final data = ref.read(ledgerProvider);
      final txns = data.txns.where((t) {
        if (_from != null && t.date < _from!) return false;
        if (_to != null && t.date > _to!) return false;
        return true;
      }).toList()..sort((a, b) => a.date.compareTo(b.date));
      final table = transactionsTable(data, txns, [
        l.txnDate,
        l.txnWallet,
        _kindHeader(l),
        l.txnCategory,
        l.exportColSubcategory,
        l.txnAmount,
        l.exportColCurrency,
        l.txnNote,
        l.txnPayee,
      ], (k) => txnKindName(l, k));
      final name = 'qulythuchi-${_stamp()}';
      final saved = switch (_format) {
        ExportFormat.csv => await saveBytes(name, 'csv', toCsv(table), MimeType.csv),
        ExportFormat.xlsx => await saveBytes(name, 'xlsx', toXlsx(table), MimeType.microsoftExcel),
        ExportFormat.pdf => await saveBytes(
          name,
          'pdf',
          await toPdf(
            table,
            title: l.exportTitle,
            subtitle: _from == null && _to == null
                ? l.exportAllTime
                : '${_from == null ? '…' : formatDate(_from!)} - ${_to == null ? '…' : formatDate(_to!)}',
          ),
          MimeType.pdf,
        ),
      };
      if (mounted) context.toast(saved ? l.exportDone(txns.length) : l.exportCancelled);
    } on Object {
      if (mounted) context.toast(l.errGeneric);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _kindHeader(AppLocalizations l) => '${l.txnIncome}/${l.txnExpense}';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _Section(
      title: l.exportTitle,
      children: [
        _Warning(l.exportWarning),
        Text(l.exportFormat),
        SegmentedButton<ExportFormat>(
          segments: const [
            ButtonSegment(value: ExportFormat.csv, label: Text('CSV')),
            ButtonSegment(value: ExportFormat.xlsx, label: Text('XLSX')),
            ButtonSegment(value: ExportFormat.pdf, label: Text('PDF')),
          ],
          selected: {_format},
          onSelectionChanged: (s) => setState(() => _format = s.first),
        ),
        Text(l.exportRange),
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
            const SizedBox(width: QtSpace.s2),
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
        FilledButton.icon(
          onPressed: _busy ? null : _export,
          icon: const Icon(Icons.download_outlined),
          label: Text(l.exportTitle),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ Nhập CSV

class _ImportCard extends ConsumerStatefulWidget {
  const _ImportCard();

  @override
  ConsumerState<_ImportCard> createState() => _ImportCardState();
}

class _ImportCardState extends ConsumerState<_ImportCard> {
  List<List<String>>? _rows;
  int? _date;
  int? _amount;
  int? _note;
  int? _category;
  int? _type;
  int? _debit;
  int? _credit;
  int _headerRow = 0;
  bool _pending = false;
  DateOrder _order = DateOrder.dmy;
  bool _negativeIsExpense = true;
  bool _hasHeader = true;
  String? _walletId;

  Future<void> _pick() async {
    final l = context.l10n;
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'CSV, XLSX',
          extensions: ['csv', 'txt', 'xlsx'],
          mimeTypes: ['text/csv', 'text/plain', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'],
          uniformTypeIdentifiers: [
            'public.comma-separated-values-text',
            'public.plain-text',
            'org.openxmlformats.spreadsheetml.sheet',
          ],
        ),
      ],
    );
    if (file == null || !mounted) return;
    try {
      if (await file.length() > maxImportBytes) throw const FormatException('too_big');
      final bytes = await file.readAsBytes();
      // XLSX là tệp zip (bắt đầu "PK").
      final rows = bytes.length > 2 && bytes[0] == 0x50 && bytes[1] == 0x4B ? parseXlsx(bytes) : parseCsv(bytes);
      if (rows.isEmpty) throw const FormatException('empty');
      final headerRow = findHeaderRow(rows);
      final g = guessColumns(rows[headerRow]);
      setState(() {
        _rows = rows;
        _headerRow = headerRow;
        _date = g.date ?? 0;
        _debit = g.debit;
        _credit = g.credit;
        _amount = g.amount ?? (g.debit != null || g.credit != null ? null : (rows[headerRow].length > 1 ? 1 : 0));
        _note = g.note;
        _category = g.category;
        _type = g.type;
        _hasHeader = g.date != null || g.amount != null || g.debit != null;
        // Sao kê ngân hàng (có dòng thông tin trước bảng hoặc cột ghi nợ/có): mặc định vào hàng chờ xác nhận.
        _pending = headerRow > 0 || g.debit != null || g.credit != null;
      });
    } on FormatException catch (e) {
      if (mounted) context.toast(e.message == 'too_big' ? l.importTooBig : l.importEmpty);
    } on Object {
      if (mounted) context.toast(l.importEmpty);
    }
  }

  ImportResult? _result(LedgerData data) {
    final rows = _rows;
    final wallet = data.wallet(_walletId);
    if (rows == null || wallet == null || _date == null || (_amount == null && _debit == null && _credit == null)) {
      return null;
    }
    final statement = _headerRow > 0 || _debit != null || _credit != null;
    return buildImportTxns(
      rows,
      ImportMapping(
        date: _date!,
        amount: _amount,
        debit: _debit,
        credit: _credit,
        note: _note,
        category: _category,
        type: _type,
        order: _order,
        negativeIsExpense: _negativeIsExpense,
        hasHeader: _hasHeader,
        headerRow: _headerRow,
        pending: _pending,
      ),
      wallet,
      data.categories,
      ref.read(ledgerProvider.notifier).newId,
      existing: data.txns,
      suggester: LedgerCategorySuggester(data),
      source: statement ? TxnSource.statement : TxnSource.import,
    );
  }

  void _run(ImportResult r) {
    final l = context.l10n;
    try {
      final n = ref.read(ledgerProvider.notifier).importTxns(r.txns);
      setState(() => _rows = null);
      context.toast(r.duplicates == 0 ? l.importDone(n, r.skipped) : l.importDoneDup(n, r.skipped, r.duplicates));
    } on Object {
      context.toast(l.errGeneric);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final data = ref.watch(ledgerProvider);
    final wallets = data.wallets.where((w) => !w.archived).toList();
    if (_walletId == null || data.wallet(_walletId) == null) _walletId = wallets.firstOrNull?.id;
    final rows = _rows;
    final header = rows == null || rows.isEmpty ? const <String>[] : rows[_headerRow.clamp(0, rows.length - 1)];
    final width = rows == null ? 0 : rows.map((r) => r.length).reduce((a, b) => a > b ? a : b);
    String colName(int i) => _hasHeader && i < header.length && header[i].isNotEmpty ? header[i] : '#${i + 1}';

    Widget col(String label, int? value, ValueChanged<int?> onChanged, {bool optional = true}) =>
        DropdownButtonFormField<int?>(
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(labelText: label),
          items: [
            if (optional) DropdownMenuItem<int?>(child: Text(l.importNone)),
            for (var i = 0; i < width; i++)
              DropdownMenuItem<int?>(
                value: i,
                child: Text(colName(i), overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) => setState(() => onChanged(v)),
        );

    final result = rows == null ? null : _result(data);
    return _Section(
      title: l.importTitle,
      children: [
        if (wallets.isEmpty)
          Text(l.importNeedWallet)
        else ...[
          OutlinedButton.icon(
            onPressed: _pick,
            icon: const Icon(Icons.upload_file_outlined),
            label: Text(l.importPick),
          ),
          if (rows != null) ...[
            Text(l.importMapping, style: Theme.of(context).textTheme.titleSmall),
            DropdownButtonFormField<String>(
              initialValue: _walletId,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.importWallet),
              items: [
                for (final w in wallets) DropdownMenuItem(value: w.id, child: Text('${w.name} (${w.currency.code})')),
              ],
              onChanged: (v) => setState(() => _walletId = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.importHasHeader),
              value: _hasHeader,
              onChanged: (v) => setState(() => _hasHeader = v),
            ),
            col(l.importColDate, _date, (v) => _date = v, optional: false),
            DropdownButtonFormField<DateOrder>(
              initialValue: _order,
              decoration: InputDecoration(labelText: l.importDateFormat),
              items: const [
                DropdownMenuItem(value: DateOrder.dmy, child: Text('DD/MM/YYYY')),
                DropdownMenuItem(value: DateOrder.mdy, child: Text('MM/DD/YYYY')),
                DropdownMenuItem(value: DateOrder.ymd, child: Text('YYYY-MM-DD')),
              ],
              onChanged: (v) => setState(() => _order = v ?? DateOrder.dmy),
            ),
            col(l.importColAmount, _amount, (v) => _amount = v),
            col(l.importColDebit, _debit, (v) => _debit = v),
            col(l.importColCredit, _credit, (v) => _credit = v),
            col(l.importColType, _type, (v) => _type = v),
            col(l.importColCategory, _category, (v) => _category = v),
            col(l.importColNote, _note, (v) => _note = v),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.importSignMode),
              value: _negativeIsExpense,
              onChanged: (v) => setState(() => _negativeIsExpense = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.importAsPending),
              subtitle: Text(l.importAsPendingHint),
              value: _pending,
              onChanged: (v) => setState(() => _pending = v),
            ),
            if (result != null) ...[
              Text(l.importPreview(result.txns.length < 5 ? result.txns.length : 5)),
              for (final t in result.txns.take(5))
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    t.note ?? data.category(t.categoryId)?.name ?? l.uncategorized,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('${formatDate(t.date)} · ${txnKindName(l, t.kind)}'),
                  trailing: MoneyText(
                    Money(t.kind == TxnKind.expense ? -t.amount : t.amount, data.wallet(t.walletId)!.currency),
                    signed: true,
                    colored: true,
                  ),
                ),
              FilledButton(
                onPressed: result.txns.isEmpty ? null : () => _run(result),
                child: Text(l.importRun(result.txns.length)),
              ),
            ],
          ],
        ],
      ],
    );
  }
}

// ------------------------------------------------------------------ Sao lưu

class _BackupCard extends ConsumerStatefulWidget {
  const _BackupCard();

  @override
  ConsumerState<_BackupCard> createState() => _BackupCardState();
}

class _BackupCardState extends ConsumerState<_BackupCard> {
  bool _busy = false;

  Future<void> _backup() async {
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      final vault = ref.read(servicesProvider).vault;
      final bytes = vault.createBackup(ref.read(ledgerProvider.notifier).newId());
      final saved = await saveBytes('qulythuchi-${_stamp()}', 'qtbak', bytes, MimeType.other);
      if (mounted) context.toast(saved ? l.backupDone : l.exportCancelled);
    } on Object {
      if (mounted) context.toast(l.errGeneric);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _Section(
      title: l.backupTitle,
      children: [
        Text(l.backupBody),
        Text(l.backupPrivacyNote, style: TextStyle(color: context.palette.textSecondary)),
        FilledButton.icon(
          onPressed: _busy ? null : _backup,
          icon: const Icon(Icons.lock_outline),
          label: Text(l.backupCreate),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ Khôi phục (màn chào)

/// Khôi phục từ tệp sao lưu trên thiết bị chưa có tài khoản. Không có dữ liệu nào rời thiết bị.
Future<void> restoreFromBackupFlow(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final file = await openFile(
    acceptedTypeGroups: const [
      XTypeGroup(label: 'Quly Thu Chi', extensions: ['qtbak'], uniformTypeIdentifiers: ['public.data']),
    ],
  );
  if (file == null || !context.mounted) return;
  final Uint8List bytes;
  try {
    bytes = await file.readAsBytes();
    // Kiểm sơ bộ định dạng trước khi hỏi mật khẩu.
    final doc = jsonDecode(utf8.decode(bytes));
    if (doc is! Map || doc['format'] != 'qulythuchi-backup') throw const FormatException('backup');
  } on Object {
    if (context.mounted) context.toast(l.restoreBackupInvalid);
    return;
  }
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (_) => _RestoreDialog(bytes: bytes),
  );
}

class _RestoreDialog extends ConsumerStatefulWidget {
  const _RestoreDialog({required this.bytes});
  final Uint8List bytes;

  @override
  ConsumerState<_RestoreDialog> createState() => _RestoreDialogState();
}

class _RestoreDialogState extends ConsumerState<_RestoreDialog> {
  bool _useWords = false;
  bool _busy = false;
  String? _error;

  Future<void> _submit(String input) async {
    final l = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final String? password = _useWords ? null : input;
      final List<String>? words = _useWords ? _words(input) : null;
      final n = await ref.read(sessionProvider.notifier).restoreBackup(widget.bytes, password: password, words: words);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text(l.restoreBackupDone(n))));
    } on FormatException {
      if (mounted) setState(() => _error = l.restoreBackupInvalid);
    } on Object {
      if (mounted) setState(() => _error = _useWords ? l.restoreInvalid : l.passwordWrong);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static List<String> _words(String s) => s.trim().toLowerCase().split(RegExp(r'\s+'));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ControllerScope(
      count: 1,
      builder: (context, c) => AlertDialog(
        title: Text(l.restoreFromBackup),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.restoreBackupBody),
              const SizedBox(height: QtSpace.s3),
              TextField(
                controller: c[0],
                obscureText: !_useWords,
                autofocus: true,
                minLines: _useWords ? 3 : 1,
                maxLines: _useWords ? 4 : 1,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: _useWords ? l.restoreWordsLabel : l.passwordLabel,
                  errorText: _error,
                ),
                onSubmitted: _busy || _useWords ? null : (v) => _submit(v),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _useWords,
                title: Text(l.restoreUseRecovery),
                onChanged: (v) => setState(() {
                  _useWords = v ?? false;
                  c[0].clear();
                  _error = null;
                }),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: Text(l.actionCancel)),
          FilledButton(onPressed: _busy ? null : () => _submit(c[0].text), child: Text(l.actionContinue)),
        ],
      ),
    );
  }
}
