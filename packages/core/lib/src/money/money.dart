import 'package:meta/meta.dart';

import 'currency.dart';

/// Lỗi khi số tiền vượt phạm vi an toàn (±2^53-1) - giữ kết quả giống hệt nhau trên web (JS) và máy gốc.
final class MoneyOverflowException implements Exception {
  const MoneyOverflowException();
  @override
  String toString() => 'MoneyOverflowException: số tiền vượt phạm vi an toàn';
}

/// Lỗi khi tính toán giữa hai tiền tệ khác nhau.
final class CurrencyMismatchException implements Exception {
  const CurrencyMismatchException(this.a, this.b);
  final Currency a;
  final Currency b;
  @override
  String toString() => 'CurrencyMismatchException: $a khác $b';
}

/// Số tiền: số nguyên đơn vị nhỏ nhất + tiền tệ. KHÔNG BAO GIỜ dùng số thực cho tiền.
@immutable
final class Money implements Comparable<Money> {
  Money(this.minor, this.currency) {
    _check(minor);
  }

  const Money._unchecked(this.minor, this.currency);

  /// Giới hạn an toàn chung cho mọi nền tảng (Number.MAX_SAFE_INTEGER).
  static const int maxSafe = 9007199254740991;

  /// Số đơn vị nhỏ nhất (đồng với VND, cent với USD).
  final int minor;
  final Currency currency;

  static Money zero(Currency currency) => Money._unchecked(0, currency);

  static void _check(int value) {
    if (value > maxSafe || value < -maxSafe) throw const MoneyOverflowException();
  }

  bool get isZero => minor == 0;
  bool get isNegative => minor < 0;
  bool get isPositive => minor > 0;

  void _same(Money other) {
    if (other.currency != currency) throw CurrencyMismatchException(currency, other.currency);
  }

  Money operator +(Money other) {
    _same(other);
    return Money(minor + other.minor, currency);
  }

  Money operator -(Money other) {
    _same(other);
    return Money(minor - other.minor, currency);
  }

  Money operator -() => Money._unchecked(-minor, currency);

  /// Nhân với số nguyên (ví dụ số kỳ).
  Money times(int factor) {
    final result = BigInt.from(minor) * BigInt.from(factor);
    if (result.abs() > BigInt.from(maxSafe)) throw const MoneyOverflowException();
    return Money(result.toInt(), currency);
  }

  Money abs() => isNegative ? -this : this;

  /// Chia theo tỉ lệ nguyên không mất đồng nào: phần dư chia cho các phần có phần lẻ lớn nhất,
  /// hòa thì phần đứng trước được trước. Tổng các phần luôn bằng số gốc.
  List<Money> allocate(List<int> ratios) {
    if (ratios.isEmpty) throw ArgumentError.value(ratios, 'ratios', 'Cần ít nhất một tỉ lệ');
    if (ratios.any((r) => r < 0)) throw ArgumentError.value(ratios, 'ratios', 'Tỉ lệ không được âm');
    final total = ratios.fold<int>(0, (a, b) => a + b);
    if (total == 0) throw ArgumentError.value(ratios, 'ratios', 'Tổng tỉ lệ phải lớn hơn 0');
    final sign = minor < 0 ? -1 : 1;
    final amount = BigInt.from(minor.abs());
    final bigTotal = BigInt.from(total);
    final shares = <int>[];
    final remainders = <BigInt>[];
    var allocated = BigInt.zero;
    for (final r in ratios) {
      final scaled = amount * BigInt.from(r);
      final share = scaled ~/ bigTotal;
      shares.add(share.toInt());
      remainders.add(scaled.remainder(bigTotal));
      allocated += share;
    }
    var left = (amount - allocated).toInt();
    final order = List<int>.generate(ratios.length, (i) => i)
      ..sort((a, b) {
        final c = remainders[b].compareTo(remainders[a]);
        return c != 0 ? c : a.compareTo(b);
      });
    for (final i in order) {
      if (left == 0) break;
      shares[i] += 1;
      left -= 1;
    }
    return [for (final s in shares) Money(sign * s, currency)];
  }

  /// Tỉ lệ phần vạn (basis points) của [whole], làm tròn xuống. Dùng cho thanh tiến độ ngân sách.
  int basisPointsOf(Money whole) {
    _same(whole);
    if (whole.minor == 0) return 0;
    return (BigInt.from(minor) * BigInt.from(10000) ~/ BigInt.from(whole.minor)).toInt();
  }

  /// Quy đổi theo tỉ giá dạng chuỗi thập phân ("25450.5" nghĩa là 1 đơn vị [currency] = 25450.5 [to]).
  /// Làm tròn nửa về số chẵn (banker's rounding) để không lệch có hệ thống.
  Money convert(Currency to, String rate) {
    final match = RegExp(r'^(\d{1,15})(?:\.(\d{1,12}))?$').firstMatch(rate);
    if (match == null) throw FormatException('Tỉ giá không hợp lệ', rate);
    final frac = match.group(2) ?? '';
    final rateNum = BigInt.parse('${match.group(1)}$frac');
    final rateDen = BigInt.from(10).pow(frac.length);
    final numerator = BigInt.from(minor) * rateNum * BigInt.from(10).pow(to.minorDigits);
    final denominator = rateDen * BigInt.from(10).pow(currency.minorDigits);
    final result = _roundHalfEven(numerator, denominator);
    if (result.abs() > BigInt.from(maxSafe)) throw const MoneyOverflowException();
    return Money(result.toInt(), to);
  }

  static BigInt _roundHalfEven(BigInt n, BigInt d) {
    final negative = n.isNegative;
    final absN = n.abs();
    var q = absN ~/ d;
    final r = absN.remainder(d);
    final twice = r * BigInt.two;
    if (twice > d || (twice == d && q.isOdd)) q += BigInt.one;
    return negative ? -q : q;
  }

  @override
  int compareTo(Money other) {
    _same(other);
    return minor.compareTo(other.minor);
  }

  bool operator <(Money other) => compareTo(other) < 0;
  bool operator >(Money other) => compareTo(other) > 0;
  bool operator <=(Money other) => compareTo(other) <= 0;
  bool operator >=(Money other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) => other is Money && other.minor == minor && other.currency == currency;

  @override
  int get hashCode => Object.hash(minor, currency);

  @override
  String toString() => '$minor ${currency.code} (minor)';
}
