import 'package:meta/meta.dart';

import '../domain/civil_date.dart';
import '../money/currency.dart';
import 'vn_text.dart';

/// Thông tin đọc từ văn bản OCR của một hóa đơn.
@immutable
final class ReceiptInfo {
  const ReceiptInfo({this.total, this.date, this.merchant});

  /// Tổng thanh toán (đơn vị nhỏ nhất), null nếu không tìm thấy.
  final int? total;
  final CivilDate? date;

  /// Dòng tên cửa hàng đoán được (dòng chữ đầu tiên đủ dài).
  final String? merchant;
}

// Nhãn tổng tiền theo độ ưu tiên giảm dần (đã bỏ dấu).
const _totalLabels = [
  ['tong thanh toan', 'thanh toan', 'tong cong', 'tong tien thanh toan', 'khach phai tra', 'can thanh toan'],
  ['tong tien', 'tong', 'total', 'grand total', 'amount due', 'thanh tien'],
];
const _excludeLabels = [
  'tien mat',
  'tien khach dua',
  'tien thua',
  'tra lai',
  'cash',
  'change',
  'tien hang',
  'vat',
  'giam gia',
];

final _amountInLine = RegExp(r'(\d{1,3}(?:[.,]\d{3})+|\d{4,})(?:[.,]\d{1,2})?\s*(?:d|vnd|dong)?\b');

/// Tìm tổng tiền, ngày, cửa hàng trong văn bản OCR (nhiều dòng). Tổng = số cuối dòng có nhãn tổng ưu tiên cao nhất;
/// không có nhãn ⇒ số lớn nhất không nằm trên dòng tiền khách đưa/tiền thừa.
ReceiptInfo parseReceiptText(String text, {Currency currency = Currency.vnd}) {
  final lines = text.split(RegExp(r'\r?\n')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
  final folded = [for (final l in lines) foldVi(l)];

  int? lastAmount(int i) {
    // Số có thể nằm ở dòng kế tiếp khi máy in canh hai cột.
    for (final k in [i, i + 1]) {
      if (k >= lines.length) break;
      final ms = _amountInLine.allMatches(folded[k]).toList();
      if (ms.isEmpty) continue;
      final v = parseAmountText(ms.last.group(0)!.replaceAll(RegExp(r'[^\d.,]'), ''), currency);
      if (v != null && v > 0) return v;
    }
    return null;
  }

  int? total;
  for (final group in _totalLabels) {
    for (var i = 0; i < folded.length && total == null; i++) {
      final l = folded[i];
      if (_excludeLabels.any(l.contains) && !group.any((g) => l.startsWith(g))) continue;
      if (group.any((g) => RegExp('(^|[^a-z])${RegExp.escape(g)}([^a-z]|\$)').hasMatch(l))) total = lastAmount(i);
    }
    if (total != null) break;
  }
  if (total == null) {
    for (var i = 0; i < folded.length; i++) {
      if (_excludeLabels.any(folded[i].contains)) continue;
      for (final m in _amountInLine.allMatches(folded[i])) {
        final v = parseAmountText(m.group(0)!.replaceAll(RegExp(r'[^\d.,]'), ''), currency);
        // Bỏ số trông như mã số thuế/số điện thoại (≥ 9 chữ số không phân tách).
        if (v == null || RegExp(r'^\d{9,}$').hasMatch(m.group(1)!)) continue;
        if (total == null || v > total) total = v;
      }
    }
  }

  CivilDate? date;
  for (final l in folded) {
    final m = RegExp(r'(\d{1,2}[/\-.]\d{1,2}[/\-.]\d{2,4})').firstMatch(l);
    if (m != null) {
      date = parseDateText(m.group(1)!);
      if (date != null) break;
    }
  }

  String? merchant;
  for (var i = 0; i < lines.length && i < 5; i++) {
    final letters = RegExp(r'\p{L}', unicode: true).allMatches(lines[i]).length;
    if (letters >= 3 && letters * 2 >= lines[i].length && !folded[i].startsWith('hoa don')) {
      merchant = lines[i].length > 80 ? lines[i].substring(0, 80) : lines[i];
      break;
    }
  }
  return ReceiptInfo(total: total, date: date, merchant: merchant);
}
