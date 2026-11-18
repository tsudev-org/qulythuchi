import 'package:meta/meta.dart';

import '../domain/civil_date.dart';
import '../domain/models.dart';
import 'spoken_amount.dart';
import 'vn_text.dart';

/// Kết quả đọc một câu ghi nhanh: "ăn trưa 50 nghìn", "hôm qua đổ xăng 80k", "nhận lương 15 triệu".
@immutable
final class QuickEntry {
  const QuickEntry({required this.kind, required this.amount, required this.date, required this.note});

  /// Chỉ `income` hoặc `expense`.
  final TxnKind kind;

  /// Đồng (VND), dương.
  final int amount;
  final CivilDate date;

  /// Phần còn lại của câu sau khi bỏ số tiền, từ chỉ ngày và từ đệm; có thể rỗng.
  final String note;
}

// Từ khóa thu nhập (đã bỏ dấu, so theo cụm từ).
// "bán", "lãi" bỏ dấu trùng "bạn", "lại" nên chỉ nhận theo cụm.
const _incomeKeywords = [
  'nhan',
  'luong',
  'thuong',
  'duoc cho',
  'duoc tang',
  'duoc tra',
  'hoan tien',
  'ban do',
  'ban hang',
  'ban duoc',
  'tien lai',
  'lai suat',
  'lai tiet kiem',
  'cashback',
  'income',
  'salary',
  'received',
];

const _expenseKeywords = ['chi', 'tra', 'mua', 'tieu', 'dong', 'nap', 'spent', 'paid', 'buy'];

// Từ đệm quanh số tiền, bỏ khỏi ghi chú.
const _fillers = {'het', 'mat', 'la', 'gia', 'khoang', 'tien', 'tong', 'tat ca', 'cho', 'voi', 'chi', 'thu'};

const _relativeDays = [
  ('hom kia', -2),
  ('hom qua', -1),
  ('toi qua', -1),
  ('sang qua', -1),
  ('trua qua', -1),
  ('chieu qua', -1),
  ('dem qua', -1),
  ('hom nay', 0),
  ('sang nay', 0),
  ('trua nay', 0),
  ('chieu nay', 0),
  ('toi nay', 0),
  ('yesterday', -1),
  ('today', 0),
];

bool _hasPhrase(String folded, String phrase) => RegExp('(^| )${RegExp.escape(phrase)}( |\$)').hasMatch(folded);

/// Đọc câu ghi nhanh. Không tìm thấy số tiền ⇒ null. [today] là ngày hiện tại theo giờ địa phương.
QuickEntry? parseQuickEntry(String text, CivilDate today) {
  final tokens = text.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  final found = findSpokenAmount(text);
  if (found == null) return null;

  final folded = foldVi(text);
  final explicitPlus = tokens.isNotEmpty && tokens.first.startsWith('+');
  final startsWithThu = folded.startsWith('thu ');
  final income =
      explicitPlus ||
      startsWithThu ||
      (_incomeKeywords.any((k) => _hasPhrase(folded, k)) &&
          !_expenseKeywords.any((k) => _hasPhrase(folded, k) && !_incomeKeywords.contains(k)));

  // Ngày: "hôm qua", "hôm kia", hoặc "ngày 15/11" / "15/11/2026".
  var date = today;
  final dropped = <int>{for (var k = found.startToken; k < found.endToken; k++) k};
  final foldedTokens = [for (final t in tokens) foldVi(t).replaceAll(RegExp(r'[^\w/]'), '')];
  for (final (phrase, delta) in _relativeDays) {
    final parts = phrase.split(' ');
    for (var k = 0; k + parts.length <= foldedTokens.length; k++) {
      var ok = true;
      for (var p = 0; p < parts.length; p++) {
        if (foldedTokens[k + p] != parts[p]) ok = false;
      }
      if (ok) {
        date = today.addDays(delta);
        for (var p = 0; p < parts.length; p++) {
          dropped.add(k + p);
        }
      }
    }
  }
  for (var k = 0; k < foldedTokens.length; k++) {
    final m = RegExp(r'^(\d{1,2})/(\d{1,2})(?:/(\d{2,4}))?$').firstMatch(foldedTokens[k]);
    if (m == null || dropped.contains(k)) continue;
    final day = int.parse(m.group(1)!), month = int.parse(m.group(2)!);
    var year = m.group(3) == null ? today.year : int.parse(m.group(3)!);
    if (year < 100) year += 2000;
    try {
      var d = CivilDate(year, month, day);
      // "15/12" nói vào tháng 1 ⇒ năm trước.
      if (m.group(3) == null && d.compareTo(today) > 0) d = CivilDate(year - 1, month, day);
      date = d;
      dropped.add(k);
      if (k > 0 && foldedTokens[k - 1] == 'ngay') dropped.add(k - 1);
    } on Object {
      continue;
    }
  }

  // Bỏ từ đệm sát số tiền ("hết 50k", "mất 30 nghìn").
  for (final edge in [found.startToken - 1, found.endToken]) {
    if (edge >= 0 && edge < foldedTokens.length && _fillers.contains(foldedTokens[edge])) dropped.add(edge);
  }
  final note = [
    for (var k = 0; k < tokens.length; k++)
      if (!dropped.contains(k)) tokens[k],
  ].join(' ').replaceAll(RegExp(r'^[\s,.;:+\-]+|[\s,.;:]+$'), '').trim();

  return QuickEntry(
    kind: income ? TxnKind.income : TxnKind.expense,
    amount: found.amount,
    date: date,
    note: note.length > 200 ? note.substring(0, 200) : note,
  );
}
