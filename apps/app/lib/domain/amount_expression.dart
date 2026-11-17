import 'package:qulythuchi_core/qulythuchi_core.dart';

/// Máy tính trong ô số tiền: `50.000 + 25.000`, `120.000 × 3`, `300.000 ÷ 4`.
///
/// Số hạng cộng/trừ là SỐ TIỀN (đọc bằng [parseMoney] ⇒ số nguyên đơn vị nhỏ nhất); nhân/chia chỉ với SỐ NGUYÊN.
/// Chia làm tròn nửa về số chẵn. Không bao giờ dùng `double`.
Money evaluateAmount(String input, Currency currency, {AppLocale locale = AppLocale.vi}) {
  final text = input.replaceAll('*', '×').replaceAll('x', '×').replaceAll('/', '÷').replaceAll('−', '-');
  final tokens = RegExp(r'[+\-×÷]|[^+\-×÷]+')
      .allMatches(text)
      .map((m) => m.group(0)!.trim())
      .where((t) => t.isNotEmpty);
  final list = tokens.toList();
  if (list.isEmpty) throw FormatException('Trống', input);

  var total = 0;
  var i = 0;
  var sign = 1;
  if (list[0] == '-' || list[0] == '+') {
    sign = list[0] == '-' ? -1 : 1;
    i = 1;
    if (i >= list.length) throw FormatException('Biểu thức sai', input);
  }
  while (i < list.length) {
    if (_isOp(list[i])) throw FormatException('Biểu thức sai', input);
    var term = parseMoney(list[i], currency, locale: locale).minor;
    i++;
    while (i < list.length && (list[i] == '×' || list[i] == '÷')) {
      final op = list[i];
      if (i + 1 >= list.length || _isOp(list[i + 1])) throw FormatException('Biểu thức sai', input);
      final factor = _parseFactor(list[i + 1], locale);
      if (factor == null) throw FormatException('Chỉ nhân/chia với số nguyên', input);
      if (op == '×') {
        term = _checked(BigInt.from(term) * BigInt.from(factor));
      } else {
        if (factor == 0) throw FormatException('Chia cho 0', input);
        term = _divRoundHalfEven(term, factor);
      }
      i += 2;
    }
    total = _checked(BigInt.from(total) + BigInt.from(sign * term));
    if (i < list.length) {
      if (list[i] != '+' && list[i] != '-') throw FormatException('Biểu thức sai', input);
      sign = list[i] == '-' ? -1 : 1;
      i++;
      if (i >= list.length) throw FormatException('Biểu thức sai', input);
    }
  }
  return Money(total, currency);
}

/// Thừa số nhân/chia: số nguyên thuần ("3") hoặc có phân nhóm nghìn đúng ngôn ngữ ("1.000"). "1,5" ⇒ null.
int? _parseFactor(String raw, AppLocale locale) {
  final t = raw.replaceAll(RegExp(r'\s'), '');
  final sep = RegExp.escape(locale == AppLocale.vi ? '.' : ',');
  if (!RegExp('^(\\d+|\\d{1,3}(?:$sep\\d{3})+)\$').hasMatch(t)) return null;
  return int.tryParse(t.replaceAll(locale == AppLocale.vi ? '.' : ',', ''));
}

bool _isOp(String t) => t == '+' || t == '-' || t == '×' || t == '÷';

/// Biểu thức có chứa phép tính (để giao diện hiện kết quả xem trước).
bool hasOperator(String input) => RegExp(r'.[+\-×÷*/x]').hasMatch(input.trim());

int _checked(BigInt v) {
  if (v.abs() > BigInt.from(Money.maxSafe)) throw const MoneyOverflowException();
  return v.toInt();
}

int _divRoundHalfEven(int a, int b) {
  final neg = (a < 0) != (b < 0);
  final x = a.abs(), y = b.abs();
  var q = x ~/ y;
  final r = x - q * y;
  if (r * 2 > y || (r * 2 == y && q.isOdd)) q++;
  return neg ? -q : q;
}
