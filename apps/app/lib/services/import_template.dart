import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show immutable;
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../domain/vn_search.dart';
import 'export.dart';

/// Tệp mẫu nhập dữ liệu của Quly Thu Chi: mỗi dòng một giao dịch, ví/danh mục tạo tự động theo tên. Dùng để chuyển
/// dữ liệu từ app khác (dán cột từ bảng xuất của app cũ vào tệp mẫu) hoặc nhập lại tệp đã xuất.
enum TemplateField {
  date,
  type,
  amount,
  currency,
  wallet,
  category,
  parent,
  toWallet,
  fee,
  payee,
  note,
  tags,
  withheld,
}

/// Tiêu đề cột của tệp mẫu (vi, en) - cột nhận cả hai, không phân biệt hoa thường/dấu, bỏ phần trong ngoặc.
const templateHeaders = <TemplateField, (String, String)>{
  TemplateField.date: ('Ngày (dd/mm/yyyy)', 'Date (dd/mm/yyyy)'),
  TemplateField.type: ('Loại', 'Type'),
  TemplateField.amount: ('Số tiền', 'Amount'),
  TemplateField.currency: ('Tiền tệ', 'Currency'),
  TemplateField.wallet: ('Ví', 'Wallet'),
  TemplateField.category: ('Danh mục', 'Category'),
  TemplateField.parent: ('Danh mục cha', 'Parent category'),
  TemplateField.toWallet: ('Ví nhận', 'To wallet'),
  TemplateField.fee: ('Phí', 'Fee'),
  TemplateField.payee: ('Người nhận/trả', 'Payee'),
  TemplateField.note: ('Ghi chú', 'Note'),
  TemplateField.tags: ('Thẻ', 'Tags'),
  TemplateField.withheld: ('Thuế khấu trừ', 'Tax withheld'),
};

const _aliases = <TemplateField, List<String>>{
  TemplateField.date: ['ngay', 'date', 'ngay giao dich'],
  TemplateField.type: ['loai', 'type', 'thu/chi', 'kind'],
  TemplateField.amount: ['so tien', 'amount'],
  TemplateField.currency: ['tien te', 'currency', 'don vi tien'],
  TemplateField.wallet: ['vi', 'wallet', 'tai khoan', 'account'],
  TemplateField.category: ['danh muc', 'category', 'nhom'],
  TemplateField.parent: ['danh muc cha', 'parent category', 'nhom cha'],
  TemplateField.toWallet: ['vi nhan', 'to wallet', 'tai khoan nhan'],
  TemplateField.fee: ['phi', 'fee'],
  TemplateField.payee: ['nguoi nhan/tra', 'nguoi nhan', 'nguoi tra', 'payee', 'doi tac'],
  TemplateField.note: ['ghi chu', 'note', 'mo ta', 'description'],
  TemplateField.tags: ['the', 'tags', 'nhan'],
  TemplateField.withheld: ['thue khau tru', 'tax withheld', 'thue tncn'],
};

String _norm(String h) => normalizeVi(h.replaceAll(RegExp(r'\(.*?\)'), '')).trim();

/// Ánh xạ cột theo tiêu đề; null nếu không phải tệp mẫu (thiếu ngày, loại, số tiền hoặc ví).
Map<TemplateField, int>? detectTemplate(List<String> header) {
  final out = <TemplateField, int>{};
  for (var i = 0; i < header.length; i++) {
    final h = _norm(header[i]);
    for (final MapEntry(key: f, value: names) in _aliases.entries) {
      if (!out.containsKey(f) && names.contains(h)) {
        out[f] = i;
        break;
      }
    }
  }
  const required = [TemplateField.date, TemplateField.type, TemplateField.amount, TemplateField.wallet];
  return required.every(out.containsKey) ? out : null;
}

enum _Kind { expense, income, transfer, adjustment }

_Kind? _kindOf(String s) {
  final t = normalizeVi(s);
  if (t.isEmpty) return null;
  if (const ['chi', 'chi tieu', 'expense', 'out', '-'].contains(t)) return _Kind.expense;
  if (const ['thu', 'thu nhap', 'income', 'in', '+'].contains(t)) return _Kind.income;
  if (const ['chuyen', 'chuyen vi', 'chuyen khoan', 'transfer'].contains(t)) return _Kind.transfer;
  if (const ['dieu chinh', 'dieu chinh so du', 'adjustment', 'adjust'].contains(t)) return _Kind.adjustment;
  return null;
}

/// Kết quả lập kế hoạch nhập: ví/danh mục cần tạo, giao dịch (gồm cặp chuyển ví), số dòng bỏ qua/trùng.
@immutable
final class TemplatePlan {
  const TemplatePlan({
    required this.newWallets,
    required this.newCategories,
    required this.txns,
    required this.skippedRows,
    required this.duplicates,
  });
  final List<Wallet> newWallets;

  /// Cha đứng trước con.
  final List<Category> newCategories;
  final List<Txn> txns;

  /// Số thứ tự dòng (tính từ 1, gồm dòng tiêu đề) bị bỏ vì thiếu/sai dữ liệu.
  final List<int> skippedRows;
  final int duplicates;

  int get rowCount => txns.where((t) => t.kind != TxnKind.transferIn).length;
}

/// Lập kế hoạch nhập từ [rows] (dòng 0 là tiêu đề). Không ghi gì. Tiền tệ của ví mới: cột Tiền tệ, nếu trống thì
/// [defaultCurrency]. Số tiền đọc theo tiền tệ của ví. Dòng trùng giao dịch đã có (cùng ví, ngày, số tiền, ghi chú)
/// bị bỏ để nhập lại cùng tệp không nhân đôi.
TemplatePlan planTemplateImport(
  List<List<String>> rows,
  Map<TemplateField, int> cols, {
  required List<Wallet> wallets,
  required List<Category> categories,
  required Iterable<Txn> existing,
  required String Function() newId,
  required Currency defaultCurrency,
  DateOrder order = DateOrder.dmy,
}) {
  String cell(List<String> r, TemplateField f) {
    final i = cols[f];
    return i == null || i >= r.length ? '' : r[i].trim();
  }

  final walletByName = {for (final w in wallets) normalizeVi(w.name): w};
  final newWallets = <Wallet>[];
  Wallet? walletFor(String name, String currencyCode) {
    final key = normalizeVi(name);
    if (key.isEmpty) return null;
    final found = walletByName[key];
    if (found != null) return found;
    Currency cur;
    try {
      cur = currencyCode.isEmpty ? defaultCurrency : Currency.of(currencyCode.toUpperCase());
    } on ArgumentError {
      return null;
    }
    final w = Wallet(id: newId(), name: name.trim(), type: WalletType.other, currency: cur);
    walletByName[key] = w;
    newWallets.add(w);
    return w;
  }

  final catByKey = <(CategoryKind, String, String), Category>{};
  final parentName = {for (final c in categories) c.id: c.name};
  for (final c in categories) {
    catByKey[(c.kind, normalizeVi(c.parentId == null ? '' : parentName[c.parentId] ?? ''), normalizeVi(c.name))] = c;
  }
  // Tên duy nhất trong cùng loại ⇒ khớp dù tệp không ghi danh mục cha.
  final byNameOnly = <(CategoryKind, String), Category?>{};
  for (final c in categories) {
    final k = (c.kind, normalizeVi(c.name));
    byNameOnly[k] = byNameOnly.containsKey(k) ? null : c;
  }
  final newCategories = <Category>[];
  String? categoryFor(CategoryKind kind, String name, String parent) {
    final n = normalizeVi(name), pn = normalizeVi(parent);
    if (n.isEmpty) return null;
    final exact = catByKey[(kind, pn, n)];
    if (exact != null) return exact.id;
    if (pn.isEmpty && byNameOnly[(kind, n)] != null) return byNameOnly[(kind, n)]!.id;
    String? parentId;
    if (pn.isNotEmpty) {
      var p = catByKey[(kind, '', pn)];
      if (p == null) {
        p = Category(id: newId(), name: parent.trim(), kind: kind);
        catByKey[(kind, '', pn)] = p;
        newCategories.add(p);
      }
      parentId = p.id;
    }
    final c = Category(id: newId(), name: name.trim(), kind: kind, parentId: parentId);
    catByKey[(kind, pn, n)] = c;
    newCategories.add(c);
    return c.id;
  }

  final seen = <String, int>{};
  for (final t in existing) {
    final f = '${t.walletId}|${txnFingerprint(t.date, signedAmountOf(t), t.note)}';
    seen[f] = (seen[f] ?? 0) + 1;
  }

  final txns = <Txn>[];
  final skipped = <int>[];
  var duplicates = 0;
  for (var i = 1; i < rows.length; i++) {
    final r = rows[i];
    if (r.every((c) => c.trim().isEmpty)) continue;
    final date = parseDateText(cell(r, TemplateField.date), order);
    final kind = _kindOf(cell(r, TemplateField.type));
    final wallet = walletFor(cell(r, TemplateField.wallet), cell(r, TemplateField.currency));
    if (date == null || kind == null || wallet == null) {
      skipped.add(i + 1);
      continue;
    }
    final amount = parseAmountText(cell(r, TemplateField.amount), wallet.currency);
    if (amount == null || amount == 0 || (kind != _Kind.adjustment && amount < 0 && kind != _Kind.expense)) {
      skipped.add(i + 1);
      continue;
    }
    var note = cell(r, TemplateField.note);
    if (note.length > 500) note = note.substring(0, 500);
    final payee = cell(r, TemplateField.payee);
    final tags = [
      for (final t in cell(r, TemplateField.tags).split(RegExp(r'[,;#]')))
        if (t.trim().isNotEmpty) t.trim(),
    ];
    if (kind == _Kind.transfer) {
      final to = walletFor(cell(r, TemplateField.toWallet), cell(r, TemplateField.currency));
      if (to == null || to.id == wallet.id || to.currency != wallet.currency) {
        skipped.add(i + 1);
        continue;
      }
      final fee = parseAmountText(cell(r, TemplateField.fee), wallet.currency)?.abs() ?? 0;
      final tid = newId();
      final value = amount.abs();
      final f = '${wallet.id}|${txnFingerprint(date, -value, note.isEmpty ? null : note)}';
      if ((seen[f] ?? 0) > 0) {
        seen[f] = seen[f]! - 1;
        duplicates++;
        continue;
      }
      txns
        ..add(
          Txn(
            id: newId(),
            walletId: wallet.id,
            kind: TxnKind.transferOut,
            amount: value,
            fee: fee,
            date: date,
            note: note.isEmpty ? null : note,
            transferId: tid,
            counterWalletId: to.id,
            source: TxnSource.import,
          ),
        )
        ..add(
          Txn(
            id: newId(),
            walletId: to.id,
            kind: TxnKind.transferIn,
            amount: value,
            date: date,
            note: note.isEmpty ? null : note,
            transferId: tid,
            counterWalletId: wallet.id,
            source: TxnSource.import,
          ),
        );
      continue;
    }
    final TxnKind tk = switch (kind) {
      _Kind.income => TxnKind.income,
      _Kind.adjustment => TxnKind.adjustment,
      _ => TxnKind.expense,
    };
    final value = tk == TxnKind.adjustment ? amount : amount.abs();
    final signed = switch (tk) {
      TxnKind.income || TxnKind.adjustment => value,
      _ => -value,
    };
    final f = '${wallet.id}|${txnFingerprint(date, signed, note.isEmpty ? null : note)}';
    if ((seen[f] ?? 0) > 0) {
      seen[f] = seen[f]! - 1;
      duplicates++;
      continue;
    }
    final catKind = tk == TxnKind.income ? CategoryKind.income : CategoryKind.expense;
    final withheld = tk == TxnKind.income
        ? (parseAmountText(cell(r, TemplateField.withheld), wallet.currency)?.abs() ?? 0)
        : 0;
    txns.add(
      Txn(
        id: newId(),
        walletId: wallet.id,
        kind: tk,
        amount: value,
        date: date,
        categoryId: tk == TxnKind.adjustment
            ? null
            : categoryFor(catKind, cell(r, TemplateField.category), cell(r, TemplateField.parent)),
        note: note.isEmpty ? null : note,
        payee: payee.isEmpty || tk == TxnKind.adjustment ? null : payee,
        tags: tags,
        taxWithheld: withheld,
        source: TxnSource.import,
      ),
    );
  }
  return TemplatePlan(
    newWallets: newWallets,
    newCategories: newCategories,
    txns: txns,
    skippedRows: skipped,
    duplicates: duplicates,
  );
}

/// Bảng mẫu (tiêu đề + 6 dòng ví dụ) theo ngôn ngữ [vi].
ExportTable templateTable({required bool vi}) {
  final headers = [for (final f in TemplateField.values) vi ? templateHeaders[f]!.$1 : templateHeaders[f]!.$2];
  List<String> row(Map<TemplateField, String> m) => [for (final f in TemplateField.values) m[f] ?? ''];
  final rows = vi
      ? [
          row({
            TemplateField.date: '01/11/2026',
            TemplateField.type: 'Thu',
            TemplateField.amount: '15.000.000',
            TemplateField.currency: 'VND',
            TemplateField.wallet: 'Ngân hàng',
            TemplateField.category: 'Lương',
            TemplateField.payee: 'Công ty A',
            TemplateField.note: 'Lương tháng 10',
          }),
          row({
            TemplateField.date: '05/11/2026',
            TemplateField.type: 'Thu',
            TemplateField.amount: '4.500.000',
            TemplateField.wallet: 'Ngân hàng',
            TemplateField.category: 'Freelance, dịch vụ',
            TemplateField.payee: 'Khách B',
            TemplateField.note: 'Đợt 1 dự án web',
            TemplateField.withheld: '500.000',
          }),
          row({
            TemplateField.date: '06/11/2026',
            TemplateField.type: 'Chi',
            TemplateField.amount: '65.000',
            TemplateField.wallet: 'Tiền mặt',
            TemplateField.category: 'Ăn ngoài',
            TemplateField.parent: 'Ăn uống',
            TemplateField.note: 'Phở',
            TemplateField.tags: 'gia đình',
          }),
          row({
            TemplateField.date: '07/11/2026',
            TemplateField.type: 'Chuyển',
            TemplateField.amount: '2.000.000',
            TemplateField.wallet: 'Ngân hàng',
            TemplateField.toWallet: 'Tiền mặt',
            TemplateField.fee: '0',
            TemplateField.note: 'Rút tiền',
          }),
          row({
            TemplateField.date: '08/11/2026',
            TemplateField.type: 'Chi',
            TemplateField.amount: '12,50',
            TemplateField.currency: 'USD',
            TemplateField.wallet: 'Thẻ USD',
            TemplateField.category: 'Giải trí',
            TemplateField.note: 'Đăng ký phần mềm',
          }),
          row({
            TemplateField.date: '30/11/2026',
            TemplateField.type: 'Điều chỉnh',
            TemplateField.amount: '-20.000',
            TemplateField.wallet: 'Tiền mặt',
            TemplateField.note: 'Khớp số dư thực tế',
          }),
        ]
      : [
          row({
            TemplateField.date: '01/11/2026',
            TemplateField.type: 'Income',
            TemplateField.amount: '3,000.00',
            TemplateField.currency: 'USD',
            TemplateField.wallet: 'Bank',
            TemplateField.category: 'Salary',
            TemplateField.payee: 'Company A',
          }),
          row({
            TemplateField.date: '06/11/2026',
            TemplateField.type: 'Expense',
            TemplateField.amount: '12.50',
            TemplateField.wallet: 'Bank',
            TemplateField.category: 'Eating out',
            TemplateField.parent: 'Food & drinks',
            TemplateField.note: 'Lunch',
          }),
          row({
            TemplateField.date: '07/11/2026',
            TemplateField.type: 'Transfer',
            TemplateField.amount: '200.00',
            TemplateField.wallet: 'Bank',
            TemplateField.toWallet: 'Cash',
            TemplateField.currency: 'USD',
          }),
        ];
  return ExportTable(headers, rows);
}

/// Tệp mẫu CSV (UTF-8 có BOM để Excel đọc đúng tiếng Việt).
Uint8List templateCsv({required bool vi}) {
  final t = templateTable(vi: vi);
  String esc(String s) => RegExp(r'[",\n\r]').hasMatch(s) ? '"${s.replaceAll('"', '""')}"' : s;
  final b = StringBuffer('\uFEFF')..writeln(t.headers.map(esc).join(','));
  for (final r in t.rows) {
    b.writeln(r.map((c) => esc('$c')).join(','));
  }
  return Uint8List.fromList(utf8.encode(b.toString()));
}

Uint8List templateXlsx({required bool vi}) => toXlsx(templateTable(vi: vi), sheetName: vi ? 'Mau nhap' : 'Template');
