import 'currency.dart';
import 'money.dart';

/// Ngôn ngữ hiển thị được hỗ trợ.
enum AppLocale { vi, en }

const _nbsp = ' ';

String _group(String digits, String separator) {
  final buffer = StringBuffer();
  final lead = digits.length % 3;
  for (var i = 0; i < digits.length; i++) {
    if (i != 0 && (i - lead) % 3 == 0) buffer.write(separator);
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Định dạng tiền: vi `1.234.567 ₫`, en `₫1,234,567`. [withSymbol] false chỉ in số.
String formatMoney(Money money, {AppLocale locale = AppLocale.vi, bool withSymbol = true, bool plusSign = false}) {
  final digitsCount = money.currency.minorDigits;
  final raw = money.minor.abs().toString().padLeft(digitsCount + 1, '0');
  final intPart = raw.substring(0, raw.length - digitsCount);
  final fracPart = raw.substring(raw.length - digitsCount);
  final groupSep = locale == AppLocale.vi ? '.' : ',';
  final decimalSep = locale == AppLocale.vi ? ',' : '.';
  var number = _group(intPart, groupSep);
  if (digitsCount > 0) number = '$number$decimalSep$fracPart';
  final sign = money.isNegative ? '-' : (plusSign && money.isPositive ? '+' : '');
  if (!withSymbol) return '$sign$number';
  final symbol = money.currency.symbol;
  return locale == AppLocale.vi ? '$sign$number$_nbsp$symbol' : '$sign$symbol$number';
}

/// Đọc chuỗi số theo ngôn ngữ ("1.234.567", "1.234,5" với vi; "1,234.5" với en) thành [Money].
/// Từ chối nếu số chữ số lẻ vượt quá của tiền tệ, thay vì lặng lẽ làm tròn.
Money parseMoney(String input, Currency currency, {AppLocale locale = AppLocale.vi}) {
  var text = input.trim().replaceAll(RegExp(r'[\s ]'), '');
  for (final c in Currency.known) {
    text = text.replaceAll(c.symbol, '');
  }
  if (!RegExp(r'[0-9.,\-+]').hasMatch(currency.symbol)) text = text.replaceAll(currency.symbol, '');
  text = text.replaceAll(currency.code, '');
  var negative = false;
  if (text.startsWith('-')) {
    negative = true;
    text = text.substring(1);
  } else if (text.startsWith('+')) {
    text = text.substring(1);
  }
  final groupSep = locale == AppLocale.vi ? '.' : ',';
  final decimalSep = locale == AppLocale.vi ? ',' : '.';
  final pattern = RegExp(
    '^(\\d{1,3}(?:${RegExp.escape(groupSep)}\\d{3})*|\\d+)(?:${RegExp.escape(decimalSep)}(\\d+))?\$',
  );
  final match = pattern.firstMatch(text);
  if (match == null) throw FormatException('Số tiền không hợp lệ', input);
  final intDigits = match.group(1)!.replaceAll(groupSep, '');
  final frac = match.group(2) ?? '';
  if (frac.length > currency.minorDigits) {
    throw FormatException('${currency.code} chỉ có ${currency.minorDigits} chữ số thập phân', input);
  }
  final minorText = '$intDigits${frac.padRight(currency.minorDigits, '0')}';
  final value = BigInt.parse(minorText);
  if (value > BigInt.from(Money.maxSafe)) throw const MoneyOverflowException();
  final minor = value.toInt();
  return Money(negative ? -minor : minor, currency);
}
