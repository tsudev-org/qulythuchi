import 'dart:convert';

/// JSON chuẩn tắc: khóa sắp xếp, không khoảng trắng. Cùng dữ liệu ⇒ cùng byte trên mọi nền tảng.
/// Chỉ nhận null, bool, int, String, List, `Map<String, ...>`. Số thực bị từ chối (tiền là số nguyên).
String canonicalJson(Object? value) {
  final buffer = StringBuffer();
  _write(buffer, value);
  return buffer.toString();
}

void _write(StringBuffer out, Object? value) {
  switch (value) {
    case null:
      out.write('null');
    case final bool b:
      out.write(b ? 'true' : 'false');
    case final int i:
      out.write(i.toString());
    case double _:
      throw ArgumentError('Số thực không được phép trong bản ghi (dùng số nguyên)');
    case final String s:
      out.write(jsonEncode(s));
    case final List<Object?> list:
      out.write('[');
      for (var i = 0; i < list.length; i++) {
        if (i > 0) out.write(',');
        _write(out, list[i]);
      }
      out.write(']');
    case final Map<String, Object?> map:
      final keys = map.keys.toList()..sort();
      out.write('{');
      for (var i = 0; i < keys.length; i++) {
        if (i > 0) out.write(',');
        out
          ..write(jsonEncode(keys[i]))
          ..write(':');
        _write(out, map[keys[i]]);
      }
      out.write('}');
    default:
      throw ArgumentError('Kiểu không hỗ trợ trong bản ghi: ${value.runtimeType}');
  }
}
