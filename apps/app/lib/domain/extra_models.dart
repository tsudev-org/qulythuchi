import 'package:flutter/foundation.dart' show immutable;
import 'package:qulythuchi_core/qulythuchi_core.dart';

/// Loại bản ghi riêng của app (ngoài `RecordTypes` của lõi).
abstract final class AppRecordTypes {
  /// Tỉ giá nhập tay: 1 [FxRate.from] = [FxRate.rate] [FxRate.to].
  static const fxRate = 'fx_rate';
}

/// Tỉ giá dạng chuỗi thập phân (không dùng double - `Money.convert` của lõi).
@immutable
final class FxRate {
  const FxRate({required this.id, required this.from, required this.to, required this.rate, required this.date});
  final String id;
  final Currency from;
  final Currency to;
  final String rate;
  final CivilDate date;

  static final ratePattern = RegExp(r'^(\d{1,15})(?:\.(\d{1,12}))?$');

  /// Chuẩn hóa chuỗi người dùng nhập ("25.450,5" vi hoặc "25,450.5" en) về dạng "25450.5". Sai ⇒ null.
  static String? normalize(String input, AppLocale locale) {
    var t = input.trim().replaceAll(RegExp(r'\s'), '');
    if (locale == AppLocale.vi) {
      t = t.replaceAll('.', '').replaceAll(',', '.');
    } else {
      t = t.replaceAll(',', '');
    }
    final m = ratePattern.firstMatch(t);
    if (m == null) return null;
    if (BigInt.parse('${m.group(1)}${m.group(2) ?? ''}') == BigInt.zero) return null;
    return t;
  }

  Map<String, Object?> toValues() => {'from': from.code, 'to': to.code, 'rate': rate, 'date': date.toString()};

  static FxRate? fromRecord(SyncRecord r) {
    final v = r.values;
    try {
      final rate = v['rate'] as String? ?? '';
      if (!ratePattern.hasMatch(rate)) return null;
      return FxRate(
        id: r.id,
        from: Currency.of(v['from']! as String),
        to: Currency.of(v['to']! as String),
        rate: rate,
        date: CivilDate.parse(v['date']! as String),
      );
    } on Object {
      return null;
    }
  }
}

/// Lưu/đọc [JarPlan] (lõi chưa có `toValues`).
abstract final class JarPlanCodec {
  static Map<String, Object?> toValues(JarPlan p) => {
    'jars': [for (final j in p.jars) j.toJson()],
  };

  static JarPlan? fromRecord(SyncRecord r) {
    try {
      final list = r.values['jars']! as List;
      return JarPlan([
        for (final e in list.cast<Map<Object?, Object?>>())
          Jar(e['key']! as String, e['name']! as String, e['bp']! as int),
      ]);
    } on Object {
      return null;
    }
  }
}
