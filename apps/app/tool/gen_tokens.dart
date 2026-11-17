// Sinh lib/theme/tokens.g.dart từ .standards/tokens/design-tokens.json (nguồn giá trị duy nhất).
// Chạy: dart run tool/gen_tokens.dart && dart format lib/theme (CI so khớp bằng git diff).
import 'dart:convert';
import 'dart:io';

const _out = 'lib/theme/tokens.g.dart';
const _src = '../../.standards/tokens/design-tokens.json';
const _ext = 'design/tokens.qulythuchi.json';

String _camel(String k) {
  final parts = k.split('-');
  return parts.first + parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
}

String _color(String v) {
  final hex = RegExp(r'^#([0-9A-Fa-f]{6})$').firstMatch(v);
  if (hex != null) return 'Color(0xFF${hex.group(1)!.toUpperCase()})';
  final rgba = RegExp(r'^rgba\((\d+),\s*(\d+),\s*(\d+),\s*([\d.]+)\)$').firstMatch(v);
  if (rgba != null) {
    final a = (double.parse(rgba.group(4)!) * 255).round();
    String h(int x) => x.toRadixString(16).padLeft(2, '0').toUpperCase();
    return 'Color(0x${h(a)}${h(int.parse(rgba.group(1)!))}${h(int.parse(rgba.group(2)!))}${h(int.parse(rgba.group(3)!))})';
  }
  throw FormatException('Màu không đọc được', v);
}

double _px(String v) => double.parse(v.replaceAll('px', '').replaceAll('ms', ''));

String generate(Map<String, Object?> json) {
  final color = json['color']! as Map<String, Object?>;
  final light = (color['light']! as Map).cast<String, String>();
  final dark = (color['dark']! as Map).cast<String, String>();
  final keys = light.keys.toList();
  final b = StringBuffer()
    ..writeln('// TỆP SINH TỰ ĐỘNG bởi tool/gen_tokens.dart - KHÔNG SỬA TAY.')
    ..writeln('// Nguồn: .standards/tokens/design-tokens.json v${(json['meta']! as Map)['version']}')
    ..writeln()
    ..writeln("import 'dart:ui' show Color;")
    ..writeln()
    ..writeln('/// Bảng màu một chế độ (Sáng/Tối). Chế độ Ấm đã ngừng dùng (DESIGN_SYSTEM.md mục 1).')
    ..writeln('final class QtPalette {')
    ..writeln('  const QtPalette({');
  for (final k in keys) {
    b.writeln('    required this.${_camel(k)},');
  }
  b.writeln('  });');
  for (final k in keys) {
    b.writeln('  final Color ${_camel(k)};');
  }
  void palette(String name, Map<String, String> m) {
    b.writeln('  static const $name = QtPalette(');
    for (final k in keys) {
      b.writeln('    ${_camel(k)}: ${_color(m[k]!)},');
    }
    b.writeln('  );');
  }

  palette('light', light);
  palette('dark', dark);
  b.writeln('}');

  void numbers(String cls, String doc, Map<String, Object?> m, {String prefix = ''}) {
    b
      ..writeln()
      ..writeln('/// $doc')
      ..writeln('abstract final class $cls {');
    m.forEach((k, v) {
      if (v is String) b.writeln('  static const double ${prefix.isEmpty ? _camel(k) : '$prefix$k'} = ${_px(v)};');
    });
    b.writeln('}');
  }

  final ext = jsonDecode(File(_ext).readAsStringSync()) as Map<String, Object?>;
  final chart = ext['chart']! as Map<String, Object?>;
  final cLight = (chart['light']! as Map).cast<String, String>();
  final cDark = (chart['dark']! as Map).cast<String, String>();
  final cKeys = cLight.keys.toList();
  b
    ..writeln()
    ..writeln('/// Màu biểu đồ (token mở rộng: design/tokens.qulythuchi.json, đã kiểm bằng validate_palette).')
    ..writeln('final class QtChartPalette {')
    ..writeln('  const QtChartPalette({');
  for (final k in cKeys) {
    b.writeln('    required this.${_camel(k)},');
  }
  b.writeln('  });');
  for (final k in cKeys) {
    b.writeln('  final Color ${_camel(k)};');
  }
  for (final (name, m) in [('light', cLight), ('dark', cDark)]) {
    b.writeln('  static const $name = QtChartPalette(');
    for (final k in cKeys) {
      b.writeln('    ${_camel(k)}: ${_color(m[k]!)},');
    }
    b.writeln('  );');
  }
  b
    ..writeln()
    ..writeln('  /// Dải tuần tự 5 bậc (thấp → cao).')
    ..writeln('  List<Color> get sequential => [seq1, seq2, seq3, seq4, seq5];')
    ..writeln('}');

  final typo = json['typography']! as Map<String, Object?>;
  numbers('QtRadius', 'Bo góc (px).', (json['radius']! as Map).cast());
  numbers('QtSpace', 'Khoảng cách bội số 4px.', (json['spacing']! as Map).cast(), prefix: 's');
  numbers('QtFontSize', 'Cỡ chữ (px).', (typo['font-size']! as Map).cast());
  final motion = (json['motion']! as Map).cast<String, String>()..remove('easing');
  numbers('QtMotion', 'Thời lượng chuyển động (ms).', motion);
  final lh = (typo['line-height']! as Map).cast<String, String>();
  b
    ..writeln()
    ..writeln('/// Chiều cao dòng (hệ số).')
    ..writeln('abstract final class QtLineHeight {');
  lh.forEach((k, v) => b.writeln('  static const double ${_camel(k)} = $v;'));
  b.writeln('}');
  return b.toString();
}

void main() {
  final json = jsonDecode(File(_src).readAsStringSync()) as Map<String, Object?>;
  final code = generate(json);
  File(_out).writeAsStringSync(code);
}
