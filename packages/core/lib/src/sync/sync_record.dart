import 'dart:convert';

import 'package:meta/meta.dart';

import 'canonical_json.dart';
import 'hlc.dart';

/// Một trường của bản ghi kèm dấu thời gian ghi.
@immutable
final class FieldEntry {
  const FieldEntry(this.value, this.hlc);
  final Object? value;
  final Hlc hlc;
}

/// Tài liệu đồng bộ: mỗi trường một HLC, hợp nhất "ghi sau thắng" theo từng trường (ADR-0004).
/// Bản rõ của tài liệu này được mã hóa trước khi rời thiết bị.
@immutable
final class SyncRecord {
  SyncRecord({required this.id, required this.type, required this.walletId, Map<String, FieldEntry>? fields})
    : fields = Map.unmodifiable(fields ?? const {}) {
    if (!_idPattern.hasMatch(id)) throw ArgumentError.value(id, 'id', 'id phải là UUID chữ thường');
    if (!_typePattern.hasMatch(type)) throw ArgumentError.value(type, 'type');
    if (walletId != null && !_idPattern.hasMatch(walletId!)) throw ArgumentError.value(walletId, 'walletId');
  }

  static final _idPattern = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');
  static final _typePattern = RegExp(r'^[a-z][a-z_]{1,31}$');
  static final _fieldPattern = RegExp(r'^_?[a-zA-Z][a-zA-Z0-9]{0,47}$');

  /// Tên trường đánh dấu đã xóa (bia mộ).
  static const deletedField = '_deleted';
  static const formatVersion = 1;

  final String id;
  final String type;

  /// Ví chứa bản ghi (quyết định khóa ví dùng để mã hóa). null = bản ghi cấp tài khoản.
  final String? walletId;
  final Map<String, FieldEntry> fields;

  bool get isDeleted => fields[deletedField]?.value == true;

  Object? operator [](String name) => fields[name]?.value;

  /// Ghi một trường với dấu thời gian mới từ [clock].
  SyncRecord set(String name, Object? value, HlcClock clock) {
    if (!_fieldPattern.hasMatch(name)) throw ArgumentError.value(name, 'name');
    canonicalJson(value); // kiểm kiểu sớm
    return SyncRecord(
      id: id,
      type: type,
      walletId: walletId,
      fields: {...fields, name: FieldEntry(value, clock.tick())},
    );
  }

  /// Ghi nhiều trường cùng lúc (mỗi trường một HLC tăng dần).
  SyncRecord setAll(Map<String, Object?> values, HlcClock clock) {
    var result = this;
    final keys = values.keys.toList()..sort();
    for (final k in keys) {
      result = result.set(k, values[k], clock);
    }
    return result;
  }

  SyncRecord markDeleted(HlcClock clock) => set(deletedField, true, clock);

  /// Hợp nhất: từng trường, HLC lớn hơn thắng. Giao hoán, kết hợp, lũy đẳng.
  SyncRecord merge(SyncRecord other) {
    if (other.id != id || other.type != type || other.walletId != walletId) {
      throw ArgumentError('Không thể hợp nhất hai bản ghi khác danh tính');
    }
    final merged = <String, FieldEntry>{...fields};
    other.fields.forEach((name, entry) {
      final mine = merged[name];
      if (mine == null || _wins(entry, mine)) merged[name] = entry;
    });
    return SyncRecord(id: id, type: type, walletId: walletId, fields: merged);
  }

  static bool _wins(FieldEntry candidate, FieldEntry current) {
    final c = candidate.hlc.compareTo(current.hlc);
    if (c != 0) return c > 0;
    // Cùng HLC chỉ xảy ra khi dữ liệu bị sửa ngoài luồng; chọn theo byte để vẫn tất định.
    return canonicalJson(candidate.value).compareTo(canonicalJson(current.value)) > 0;
  }

  /// HLC lớn nhất trong bản ghi (để cập nhật đồng hồ khi nhận về).
  Hlc? get maxHlc {
    Hlc? best;
    for (final e in fields.values) {
      if (best == null || e.hlc > best) best = e.hlc;
    }
    return best;
  }

  /// Giá trị đơn giản của các trường (không HLC), bỏ bia mộ.
  Map<String, Object?> get values => {
    for (final e in fields.entries)
      if (e.key != deletedField) e.key: e.value.value,
  };

  /// Byte bản rõ chuẩn tắc để đem mã hóa.
  List<int> toBytes() => utf8.encode(
    canonicalJson({
      'v': formatVersion,
      'id': id,
      't': type,
      'w': walletId,
      'f': {
        for (final e in fields.entries) e.key: [e.value.value, e.value.hlc.toString()],
      },
    }),
  );

  /// Đọc bản rõ. Dữ liệu hỏng/không đúng kiểu ⇒ [FormatException].
  static SyncRecord fromBytes(List<int> bytes) {
    try {
      return _fromBytes(bytes);
    } on FormatException {
      rethrow;
    } on Object {
      throw const FormatException('Bản ghi đồng bộ hỏng');
    }
  }

  static SyncRecord _fromBytes(List<int> bytes) {
    final Object? decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, Object?> || decoded['v'] != formatVersion) {
      throw const FormatException('Bản ghi đồng bộ sai định dạng');
    }
    final rawFields = decoded['f'];
    if (rawFields is! Map<String, Object?>) throw const FormatException('Thiếu trường f');
    final fields = <String, FieldEntry>{};
    rawFields.forEach((name, raw) {
      if (raw is! List<Object?> || raw.length != 2 || raw[1] is! String) {
        throw FormatException('Trường hỏng', name);
      }
      if (!_fieldPattern.hasMatch(name)) throw FormatException('Tên trường không hợp lệ', name);
      canonicalJson(raw[0]); // từ chối số thực, kiểu lạ
      fields[name] = FieldEntry(raw[0], Hlc.parse(raw[1]! as String));
    });
    return SyncRecord(
      id: decoded['id']! as String,
      type: decoded['t']! as String,
      walletId: decoded['w'] as String?,
      fields: fields,
    );
  }
}
