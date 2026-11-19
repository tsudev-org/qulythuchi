import 'package:meta/meta.dart';

import 'iso4217.dart';

/// Tiền tệ theo ISO 4217 với số chữ số thập phân của đơn vị nhỏ nhất.
@immutable
final class Currency {
  const Currency._(this.code, this.minorDigits, this.symbol, [this.numeric = 0, this.name = '', this.nameVi = '']);

  /// Mã ISO 4217 ba chữ cái in hoa, ví dụ `VND`.
  final String code;

  /// Số chữ số sau dấu thập phân (VND 0, USD 2).
  final int minorDigits;

  /// Ký hiệu hiển thị, ví dụ `₫`.
  final String symbol;

  /// Mã số ISO 4217 (VND = 704); 0 nếu không rõ (tiền tệ tự khai).
  final int numeric;

  /// Tên tiếng Anh theo ISO; rỗng với tiền tệ tự khai.
  final String name;

  /// Tên tiếng Việt (rỗng ⇒ dùng [name]).
  final String nameVi;

  /// Tên hiển thị theo ngôn ngữ (`vi` hoặc khác).
  String displayName(String languageCode) =>
      languageCode == 'vi' && nameVi.isNotEmpty ? nameVi : (name.isEmpty ? code : name);

  static const vnd = Currency._('VND', 0, '₫', 704, 'Dong', 'Đồng Việt Nam');
  static const usd = Currency._('USD', 2, r'$', 840, 'US Dollar', 'Đô la Mỹ');
  static const eur = Currency._('EUR', 2, '€', 978, 'Euro', 'Euro');
  static const jpy = Currency._('JPY', 0, '¥', 392, 'Yen', 'Yên Nhật');
  static const krw = Currency._('KRW', 0, '₩', 410, 'Won', 'Won Hàn Quốc');
  static const cny = Currency._('CNY', 2, 'CN¥', 156, 'Yuan Renminbi', 'Nhân dân tệ');
  static const thb = Currency._('THB', 2, '฿', 764, 'Baht', 'Baht Thái');
  static const sgd = Currency._('SGD', 2, r'S$', 702, 'Singapore Dollar', 'Đô la Singapore');
  static const gbp = Currency._('GBP', 2, '£', 826, 'Pound Sterling', 'Bảng Anh');
  static const aud = Currency._('AUD', 2, r'A$', 36, 'Australian Dollar', 'Đô la Úc');
  static const cad = Currency._('CAD', 2, r'C$', 124, 'Canadian Dollar', 'Đô la Canada');
  static const twd = Currency._('TWD', 2, r'NT$', 901, 'New Taiwan Dollar', 'Đô la Đài Loan');
  static const hkd = Currency._('HKD', 2, r'HK$', 344, 'Hong Kong Dollar', 'Đô la Hồng Kông');
  static const myr = Currency._('MYR', 2, 'RM', 458, 'Malaysian Ringgit', 'Ringgit Malaysia');
  static const lak = Currency._('LAK', 2, '₭', 418, 'Lao Kip', 'Kíp Lào');
  static const khr = Currency._('KHR', 2, '៛', 116, 'Riel', 'Riel Campuchia');
  static const chf = Currency._('CHF', 2, 'CHF', 756, 'Swiss Franc', 'Franc Thụy Sĩ');

  /// Các tiền tệ hay dùng (chọn nhanh), VND đứng đầu. Toàn bộ ISO 4217: [all].
  static const List<Currency> known = [
    vnd, usd, eur, jpy, krw, cny, thb, sgd, gbp, aud, cad, twd, hkd, myr, lak, khr, chf, //
  ];

  /// Mọi tiền tệ đang lưu hành theo ISO 4217, xếp theo mã.
  static final List<Currency> all = List.unmodifiable(_parseTable());

  static final Map<String, Currency> _byCode = {for (final c in all) c.code: c};
  static final Map<int, Currency> _byNumeric = {
    for (final c in all)
      if (c.numeric != 0) c.numeric: c,
  };

  static List<Currency> _parseTable() {
    final popular = {for (final c in known) c.code: c};
    final out = <Currency>[];
    for (final line in iso4217Table.split('\n')) {
      if (line.trim().isEmpty) continue;
      final f = line.split('|');
      out.add(popular[f[0]] ?? Currency._(f[0], int.parse(f[2]), f[3], int.parse(f[1]), f[4], f[5]));
    }
    return out;
  }

  /// Tra theo mã số ISO 4217 (QR EMVCo thẻ 53), ví dụ `704` ⇒ VND. Null nếu không có trong bảng.
  static Currency? byNumeric(int numeric) => _byNumeric[numeric];

  /// Mã có trong bảng ISO 4217 hay không.
  static bool isIso(String code) => _byCode.containsKey(code);

  /// Tìm theo mã/tên (không phân biệt hoa thường, bỏ dấu tiếng Việt do tầng gọi xử lý nếu cần).
  static List<Currency> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return [
      for (final c in all)
        if (c.code.toLowerCase().contains(q) ||
            c.name.toLowerCase().contains(q) ||
            c.nameVi.toLowerCase().contains(q) ||
            c.symbol.toLowerCase() == q)
          c,
    ];
  }

  static final _codePattern = RegExp(r'^[A-Z]{3}$');

  /// Tra tiền tệ theo mã (bảng ISO 4217 trước). Mã lạ (đúng khuôn 3 chữ cái) cần truyền [minorDigits].
  static Currency of(String code, {int? minorDigits}) {
    final iso = _byCode[code];
    if (iso != null) return iso;
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
