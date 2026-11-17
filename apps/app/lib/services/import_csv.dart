import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show immutable;
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../domain/vn_search.dart';

const maxImportBytes = 5 * 1024 * 1024;
const maxImportRows = 20000;

/// Đọc CSV theo RFC 4180 (ô có ngoặc kép, xuống dòng trong ô), tự nhận dấu phân tách `,` `;` hoặc tab.
List<List<String>> parseCsv(Uint8List bytes) {
  if (bytes.length > maxImportBytes) throw const FormatException('too_big');
  var text = utf8.decode(bytes, allowMalformed: true);
  if (text.startsWith('\uFEFF')) text = text.substring(1);
  final firstLine = text.split(RegExp(r'\r?\n')).first;
  final sep = [',', ';', '\t'].reduce((a, b) => firstLine.split(b).length >= firstLine.split(a).length ? b : a);
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

enum DateOrder { dmy, mdy, ymd }

/// Đọc ngày "17/11/2026", "17-11-2026", "2026-11-17", "11/17/2026" (theo [order]); bỏ phần giờ nếu có.
CivilDate? parseDate(String s, DateOrder order) {
  final m = RegExp(r'^(\d{1,4})[/.\-](\d{1,2})[/.\-](\d{1,4})').firstMatch(s.trim());
  if (m == null) return null;
  final a = int.parse(m.group(1)!), b = int.parse(m.group(2)!), c = int.parse(m.group(3)!);
  try {
    if (m.group(1)!.length == 4) return CivilDate(a, b, c);
    final year = c < 100 ? 2000 + c : c;
    return order == DateOrder.mdy ? CivilDate(year, a, b) : CivilDate(year, b, a);
  } on Object {
    return null;
  }
}

/// Đọc số tiền bất kể kiểu phân tách: "1.234.567", "1,234,567.89", "-50.000 ₫", "(1.200)" (âm), "1 234,5".
/// Với tiền tệ không có số lẻ (VND), mọi dấu chấm/phẩy là phân tách nghìn. Không dùng double.
int? parseAmount(String s, Currency currency) {
  var t = s.trim();
  var negative = false;
  if (t.startsWith('(') && t.endsWith(')')) {
    negative = true;
    t = t.substring(1, t.length - 1);
  }
  t = t.replaceAll(RegExp(r'[^\d.,\-+]'), '');
  if (t.startsWith('-')) {
    negative = !negative;
    t = t.substring(1);
  } else if (t.startsWith('+')) {
    t = t.substring(1);
  }
  if (t.endsWith('-')) {
    negative = !negative;
    t = t.substring(0, t.length - 1);
  }
  if (t.isEmpty || !RegExp(r'^[\d.,]+$').hasMatch(t)) return null;
  var intPart = t;
  var frac = '';
  if (currency.minorDigits > 0) {
    final last = t.lastIndexOf(RegExp(r'[.,]'));
    if (last >= 0) {
      final tail = t.substring(last + 1);
      final sepCount = RegExp(r'[.,]').allMatches(t).length;
      final sameSep = t.split(t[last]).length - 1;
      // Dấu cuối là phần lẻ nếu: theo sau ≤ số lẻ của tiền tệ, hoặc khác loại với các dấu trước đó.
      if (tail.length <= currency.minorDigits || (sepCount > sameSep && tail.length != 3)) {
        intPart = t.substring(0, last);
        frac = tail;
      }
    }
  }
  intPart = intPart.replaceAll(RegExp(r'[.,]'), '');
  if (intPart.isEmpty) intPart = '0';
  if (frac.length > currency.minorDigits) return null;
  final v = BigInt.parse('$intPart${frac.padRight(currency.minorDigits, '0')}');
  if (v > BigInt.from(Money.maxSafe)) return null;
  return negative ? -v.toInt() : v.toInt();
}

/// Đoán cột theo tên tiêu đề (vi/en, không dấu).
@immutable
final class ColumnGuess {
  const ColumnGuess({this.date, this.amount, this.note, this.category, this.type});
  final int? date;
  final int? amount;
  final int? note;
  final int? category;
  final int? type;
}

ColumnGuess guessColumns(List<String> header) {
  int? find(List<String> keys) {
    for (var i = 0; i < header.length; i++) {
      final h = normalizeVi(header[i]);
      if (keys.any(h.contains)) return i;
    }
    return null;
  }

  return ColumnGuess(
    date: find(['ngay', 'date', 'thoi gian', 'time']),
    amount: find(['so tien', 'amount', 'gia tri', 'value', 'tien']),
    note: find(['ghi chu', 'note', 'mo ta', 'description', 'noi dung', 'memo']),
    category: find(['danh muc', 'category', 'nhom', 'hang muc']),
    type: find(['loai', 'type', 'thu/chi', 'kind']),
  );
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
    required this.amount,
    this.note,
    this.category,
    this.type,
    this.order = DateOrder.dmy,
    this.negativeIsExpense = true,
    this.hasHeader = true,
  });
  final int date;
  final int amount;
  final int? note;
  final int? category;
  final int? type;
  final DateOrder order;
  final bool negativeIsExpense;
  final bool hasHeader;
}

/// Kết quả chuyển dòng CSV thành giao dịch: dòng lỗi chỉ được đếm, không ghi nội dung ra log.
final class ImportResult {
  ImportResult(this.txns, this.skipped);
  final List<Txn> txns;
  final int skipped;
}

/// Chuyển dòng CSV thành giao dịch thu/chi của ví [wallet]. Danh mục ghép theo tên không dấu (con trước, rồi cha)
/// đúng loại thu/chi; không khớp thì để trống. Ghi chú cắt 500 ký tự.
ImportResult buildImportTxns(
  List<List<String>> rows,
  ImportMapping m,
  Wallet wallet,
  List<Category> categories,
  String Function() newId,
) {
  final byName = <(CategoryKind, String), String>{};
  // Danh mục con ghi sau để thắng khi trùng tên với danh mục cha.
  for (final c in [...categories.where((c) => c.parentId == null), ...categories.where((c) => c.parentId != null)]) {
    byName[(c.kind, normalizeVi(c.name))] = c.id;
  }
  final out = <Txn>[];
  var skipped = 0;
  String cell(List<String> r, int? i) => i == null || i >= r.length ? '' : r[i];
  for (final r in rows.skip(m.hasHeader ? 1 : 0)) {
    final date = parseDate(cell(r, m.date), m.order);
    final amount = parseAmount(cell(r, m.amount), wallet.currency);
    if (date == null || amount == null || amount == 0) {
      skipped++;
      continue;
    }
    final flag = m.type == null ? null : parseIncomeFlag(cell(r, m.type));
    final income = flag ?? (m.negativeIsExpense && amount > 0);
    final kind = income ? TxnKind.income : TxnKind.expense;
    final catName = normalizeVi(cell(r, m.category));
    final note = cell(r, m.note);
    out.add(
      Txn(
        id: newId(),
        walletId: wallet.id,
        kind: kind,
        amount: amount.abs(),
        date: date,
        categoryId: catName.isEmpty ? null : byName[(income ? CategoryKind.income : CategoryKind.expense, catName)],
        note: note.isEmpty ? null : (note.length > 500 ? note.substring(0, 500) : note),
        source: TxnSource.import,
      ),
    );
  }
  return ImportResult(out, skipped);
}
