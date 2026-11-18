import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show immutable;
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../domain/vn_search.dart';
import 'auto_import.dart';

export 'package:qulythuchi_core/qulythuchi_core.dart' show DateOrder;

const maxImportBytes = 5 * 1024 * 1024;
const maxImportRows = 20000;

/// Đọc CSV theo RFC 4180 (ô có ngoặc kép, xuống dòng trong ô), tự nhận dấu phân tách `,` `;` hoặc tab.
List<List<String>> parseCsv(Uint8List bytes) {
  if (bytes.length > maxImportBytes) throw const FormatException('too_big');
  var text = utf8.decode(bytes, allowMalformed: true);
  if (text.startsWith('\uFEFF')) text = text.substring(1);
  // Sao kê ngân hàng thường mở đầu bằng vài dòng thông tin không có dấu phân tách ⇒ đoán theo dòng có nhiều ô nhất
  // trong 30 dòng đầu; hòa ⇒ ưu tiên dấu phẩy.
  final head = text.split(RegExp(r'\r?\n')).take(30).toList();
  int most(String sep) => head.fold(0, (m, l) => l.split(sep).length > m ? l.split(sep).length : m);
  final sep = [',', ';', '\t'].reduce((a, b) => most(b) > most(a) ? b : a);
  final rows = <List<String>>[];
  var row = <String>[];
  final cell = StringBuffer();
  var quoted = false;
  for (var i = 0; i < text.length; i++) {
    final ch = text[i];
    if (quoted) {
      if (ch == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        cell.write(ch);
      }
    } else if (ch == '"' && cell.isEmpty) {
      quoted = true;
    } else if (ch == sep) {
      row.add(cell.toString().trim());
      cell.clear();
    } else if (ch == '\n' || ch == '\r') {
      if (ch == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      row.add(cell.toString().trim());
      cell.clear();
      if (row.any((c) => c.isNotEmpty)) rows.add(row);
      row = <String>[];
      if (rows.length > maxImportRows + 1) throw const FormatException('too_big');
    } else {
      cell.write(ch);
    }
  }
  row.add(cell.toString().trim());
  if (row.any((c) => c.isNotEmpty)) rows.add(row);
  return rows;
}

/// Đọc ngày (xem [parseDateText] của lõi).
CivilDate? parseDate(String s, DateOrder order) => parseDateText(s, order);

/// Đọc số tiền bất kể kiểu phân tách (xem [parseAmountText] của lõi). Không dùng double.
int? parseAmount(String s, Currency currency) => parseAmountText(s, currency);

/// Đoán cột theo tên tiêu đề (vi/en, không dấu).
@immutable
final class ColumnGuess {
  const ColumnGuess({this.date, this.amount, this.note, this.category, this.type, this.debit, this.credit});
  final int? date;
  final int? amount;

  /// Sao kê ngân hàng: cột ghi nợ (tiền ra) và ghi có (tiền vào) tách riêng.
  final int? debit;
  final int? credit;
  final int? note;
  final int? category;
  final int? type;
}

ColumnGuess guessColumns(List<String> header) {
  final taken = <int>{};
  int? find(List<String> keys) {
    for (final k in keys) {
      for (var i = 0; i < header.length; i++) {
        if (taken.contains(i)) continue;
        if (normalizeVi(header[i]).contains(k)) {
          taken.add(i);
          return i;
        }
      }
    }
    return null;
  }

  // Thứ tự quan trọng: cột ghi nợ/ghi có trước, để "Số tiền ghi nợ" không bị nhận là cột số tiền chung.
  final debit = find(['ghi no', 'debit', 'tien ra', 'so tien rut', 'withdrawal', 'phat sinh no', 'no tk']);
  final credit = find(['ghi co', 'credit', 'tien vao', 'so tien gui', 'deposit', 'phat sinh co', 'co tk']);
  final date = find([
    'ngay giao dich',
    'ngay gd',
    'ngay hach toan',
    'transaction date',
    'ngay',
    'date',
    'thoi gian',
    'time',
  ]);
  find(['so du', 'balance']); // bỏ qua cột số dư
  return ColumnGuess(
    date: date,
    debit: debit,
    credit: credit,
    amount: find(['so tien', 'amount', 'gia tri', 'value', 'tien']),
    note: find(['ghi chu', 'note', 'mo ta', 'description', 'noi dung', 'dien giai', 'memo', 'chi tiet']),
    category: find(['danh muc', 'category', 'nhom', 'hang muc']),
    type: find(['loai', 'type', 'thu/chi', 'kind']),
  );
}

/// Sao kê ngân hàng thường có vài dòng thông tin tài khoản trước bảng: chỉ số dòng tiêu đề đầu tiên (trong 30 dòng
/// đầu) đoán ra được cột ngày và cột số tiền/ghi nợ/ghi có; không thấy ⇒ 0.
int findHeaderRow(List<List<String>> rows) {
  for (var i = 0; i < rows.length && i < 30; i++) {
    final g = guessColumns(rows[i]);
    if (g.date != null && (g.amount != null || g.debit != null || g.credit != null)) return i;
  }
  return 0;
}

/// Loại theo chữ: "thu/income/credit/+" ⇒ true (thu), "chi/expense/debit/-" ⇒ false; không rõ ⇒ null.
bool? parseIncomeFlag(String s) {
  final t = normalizeVi(s);
  if (t.isEmpty) return null;
  if (RegExp(r'^(thu|thu nhap|income|credit|in|\+)$').hasMatch(t) || t.startsWith('thu ')) return true;
  if (RegExp(r'^(chi|chi tieu|expense|debit|out|-)$').hasMatch(t) || t.startsWith('chi ')) return false;
  return null;
}

/// Cách người dùng ghép cột. [negativeIsExpense]: số âm = chi, số dương = thu (khi không có cột loại hoặc ô loại
/// không rõ); tắt thì mọi dòng không rõ loại là khoản chi.
@immutable
final class ImportMapping {
  const ImportMapping({
    required this.date,
    this.amount,
    this.note,
    this.category,
    this.type,
    this.order = DateOrder.dmy,
    this.negativeIsExpense = true,
    this.hasHeader = true,
    this.debit,
    this.credit,
    this.headerRow = 0,
    this.pending = false,
  });
  final int date;

  /// Cột số tiền chung; bị bỏ qua ở dòng có giá trị ở [debit]/[credit].
  final int? amount;
  final int? debit;
  final int? credit;

  /// Số dòng đứng trước dòng tiêu đề (thông tin tài khoản của sao kê) - bỏ qua.
  final int headerRow;

  /// Nhập vào hàng chờ "Cần xác nhận" thay vì ghi thẳng.
  final bool pending;
  final int? note;
  final int? category;
  final int? type;
  final DateOrder order;
  final bool negativeIsExpense;
  final bool hasHeader;
}

/// Kết quả chuyển dòng CSV thành giao dịch: dòng lỗi chỉ được đếm, không ghi nội dung ra log.
final class ImportResult {
  ImportResult(this.txns, this.skipped, {this.duplicates = 0});
  final List<Txn> txns;
  final int skipped;

  /// Dòng trùng giao dịch đã có (cùng ví, ngày, số tiền, nội dung) - không nhập lại.
  final int duplicates;
}

/// Chuyển dòng CSV/XLSX thành giao dịch thu/chi của ví [wallet]. Danh mục ghép theo tên không dấu (con trước, rồi
/// cha) đúng loại thu/chi; không có cột danh mục/không khớp ⇒ [suggester] gợi ý từ nội dung. Dòng trùng với giao
/// dịch đã có trong [existing] (theo [txnFingerprint], đếm theo số lần) bị bỏ, để nhập lại cùng sao kê không nhân đôi.
/// Ghi chú cắt 500 ký tự.
ImportResult buildImportTxns(
  List<List<String>> rows,
  ImportMapping m,
  Wallet wallet,
  List<Category> categories,
  String Function() newId, {
  Iterable<Txn> existing = const [],
  LedgerCategorySuggester? suggester,
  TxnSource source = TxnSource.import,
}) {
  final byName = <(CategoryKind, String), String>{};
  // Danh mục con ghi sau để thắng khi trùng tên với danh mục cha.
  for (final c in [...categories.where((c) => c.parentId == null), ...categories.where((c) => c.parentId != null)]) {
    byName[(c.kind, normalizeVi(c.name))] = c.id;
  }
  final seen = <String, int>{};
  for (final t in existing) {
    if (t.walletId != wallet.id) continue;
    final f = txnFingerprint(t.date, signedAmountOf(t), t.note);
    seen[f] = (seen[f] ?? 0) + 1;
  }
  final out = <Txn>[];
  var skipped = 0, duplicates = 0;
  String cell(List<String> r, int? i) => i == null || i >= r.length ? '' : r[i];
  for (final r in rows.skip(m.headerRow + (m.hasHeader ? 1 : 0))) {
    final date = parseDate(cell(r, m.date), m.order);
    final debit = parseAmount(cell(r, m.debit), wallet.currency)?.abs() ?? 0;
    final credit = parseAmount(cell(r, m.credit), wallet.currency)?.abs() ?? 0;
    int? amount;
    bool? flag;
    if (debit != 0 || credit != 0) {
      amount = credit - debit;
      flag = amount > 0;
    } else {
      amount = parseAmount(cell(r, m.amount), wallet.currency);
      flag = m.type == null ? null : parseIncomeFlag(cell(r, m.type));
    }
    if (date == null || amount == null || amount == 0) {
      skipped++;
      continue;
    }
    final income = flag ?? (m.negativeIsExpense && amount > 0);
    final kind = income ? TxnKind.income : TxnKind.expense;
    final catName = normalizeVi(cell(r, m.category));
    var note = cell(r, m.note);
    if (note.length > 500) note = note.substring(0, 500);
    final f = txnFingerprint(date, income ? amount.abs() : -amount.abs(), note.isEmpty ? null : note);
    if ((seen[f] ?? 0) > 0) {
      seen[f] = seen[f]! - 1;
      duplicates++;
      continue;
    }
    out.add(
      Txn(
        id: newId(),
        walletId: wallet.id,
        kind: kind,
        amount: amount.abs(),
        date: date,
        categoryId:
            (catName.isEmpty ? null : byName[(income ? CategoryKind.income : CategoryKind.expense, catName)]) ??
            suggester?.suggest(note, kind),
        note: note.isEmpty ? null : note,
        source: source,
        pending: m.pending,
      ),
    );
  }
  return ImportResult(out, skipped, duplicates: duplicates);
}
