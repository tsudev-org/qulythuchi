import 'package:meta/meta.dart';

/// Tiền tệ theo ISO 4217 với số chữ số thập phân của đơn vị nhỏ nhất.
@immutable
final class Currency {
  const Currency._(this.code, this.minorDigits, this.symbol);

  /// Mã ISO 4217 ba chữ cái in hoa, ví dụ `VND`.
  final String code;

  /// Số chữ số sau dấu thập phân (VND 0, USD 2).
  final int minorDigits;

  /// Ký hiệu hiển thị, ví dụ `₫`.
  final String symbol;

  static const vnd = Currency._('VND', 0, '₫');
  static const usd = Currency._('USD', 2, r'$');
  static const eur = Currency._('EUR', 2, '€');
  static const jpy = Currency._('JPY', 0, '¥');
  static const krw = Currency._('KRW', 0, '₩');
  static const cny = Currency._('CNY', 2, 'CN¥');
  static const thb = Currency._('THB', 2, '฿');
  static const sgd = Currency._('SGD', 2, r'S$');
  static const gbp = Currency._('GBP', 2, '£');
  static const aud = Currency._('AUD', 2, r'A$');
  static const cad = Currency._('CAD', 2, r'C$');
  static const twd = Currency._('TWD', 2, r'NT$');
  static const hkd = Currency._('HKD', 2, r'HK$');
  static const myr = Currency._('MYR', 2, 'RM');
  static const lak = Currency._('LAK', 2, '₭');
  static const khr = Currency._('KHR', 2, '៛');
  static const chf = Currency._('CHF', 2, 'CHF');

  /// Các tiền tệ có sẵn, VND đứng đầu.
  static const List<Currency> known = [
    vnd, usd, eur, jpy, krw, cny, thb, sgd, gbp, aud, cad, twd, hkd, myr, lak, khr, chf, //
  ];

  static final _codePattern = RegExp(r'^[A-Z]{3}$');

  /// Tra tiền tệ theo mã. Mã lạ (hợp lệ ISO) cần truyền [minorDigits].
  static Currency of(String code, {int? minorDigits}) {
    for (final c in known) {
      if (c.code == code) return c;
    }
    if (!_codePattern.hasMatch(code)) {
      throw ArgumentError.value(code, 'code', 'Mã tiền tệ phải là 3 chữ cái in hoa');
    }
    if (minorDigits == null || minorDigits < 0 || minorDigits > 4) {
      throw ArgumentError.value(minorDigits, 'minorDigits', 'Tiền tệ lạ cần số chữ số thập phân 0-4');
    }
    return Currency._(code, minorDigits, code);
  }

  @override
  bool operator ==(Object other) => other is Currency && other.code == code && other.minorDigits == minorDigits;

  @override
  int get hashCode => Object.hash(code, minorDigits);

  @override
  String toString() => code;
}
