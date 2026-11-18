import '../domain/civil_date.dart';
import '../money/currency.dart';
import '../money/money.dart';

/// Chuẩn hóa chuỗi tiếng Việt để so khớp: chữ thường, bỏ dấu, đ → d, gộp khoảng trắng (SEARCH_AND_FILTER mục 3).
String foldVi(String input) {
  final lower = input.toLowerCase();
  final b = StringBuffer();
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    b.write(_foldMap[ch] ?? ch);
  }
  return b.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

const _foldGroups = {
  'a': 'àáạảãâầấậẩẫăằắặẳẵ',
  'e': 'èéẹẻẽêềếệểễ',
  'i': 'ìíịỉĩ',
  'o': 'òóọỏõôồốộổỗơờớợởỡ',
  'u': 'ùúụủũưừứựửữ',
  'y': 'ỳýỵỷỹ',
  'd': 'đ',
};

final Map<String, String> _foldMap = {
  for (final e in _foldGroups.entries)
    for (final ch in e.value.split('')) ch: e.key,
  // Dấu tổ hợp (chuỗi chưa chuẩn hóa NFC): bỏ đi.
  for (final c in ['̀', '́', '̃', '̉', '̣', '̂', '̆', '̛']) c: '',
};

/// Thứ tự ngày trong chuỗi số.
enum DateOrder { dmy, mdy, ymd }

/// Đọc ngày "17/11/2026", "17-11-2026", "2026-11-17", "11/17/2026" (theo [order]); bỏ phần giờ nếu có.
CivilDate? parseDateText(String s, [DateOrder order = DateOrder.dmy]) {
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
/// Với tiền tệ không có số lẻ (VND), mọi dấu chấm/phẩy là phân tách nghìn, riêng đuôi ".00"/",00" bị bỏ.
/// Không dùng double.
int? parseAmountText(String s, Currency currency) {
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
  if (currency.minorDigits == 0) {
    // "50,000.00" của một số ngân hàng: phần lẻ toàn số 0 ⇒ bỏ.
    t = t.replaceFirst(RegExp(r'[.,]0{1,2}$'), '');
  }
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

/// Bỏ dấu + chữ thường nhưng GIỮ nguyên độ dài (không gộp khoảng trắng) để vị trí khớp với chuỗi gốc.
/// Chuỗi đầu vào nên ở dạng NFC; ký tự làm đổi độ dài khi viết thường ⇒ trả lại [foldVi] từng ký tự an toàn nhất có thể.
String foldViSameLength(String input) {
  final b = StringBuffer();
  for (final unit in input.split('')) {
    final lower = unit.toLowerCase();
    final mapped = _foldMap[lower] ?? lower;
    b.write(mapped.length == 1 ? mapped : unit);
  }
  return b.toString();
}
