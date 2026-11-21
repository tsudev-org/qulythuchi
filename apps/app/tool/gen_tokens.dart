// Sinh lib/theme/tokens.g.dart từ .standards/tokens/design-tokens.json (lớp nền chung) gộp đè bởi lớp bản sắc
// .standards/tokens/products/qulythuchi.json (màu nhấn) + .standards/tokens/products.css (bộ bo góc) - DESIGN_SYSTEM.md
// mục 1.2.1. Không khai lại màu nhấn tại repo này.
// Chạy: dart run tool/gen_tokens.dart && dart format lib/theme (CI so khớp bằng git diff).
import 'dart:convert';
import 'dart:io';

const _out = 'lib/theme/tokens.g.dart';
const _src = '../../.standards/tokens/design-tokens.json';
const _ext = 'design/tokens.qulythuchi.json';
const _product = '../../.standards/tokens/products/qulythuchi.json';
const _productCss = '../../.standards/tokens/products.css';
const productId = 'qulythuchi';

/// Bo góc của bản sắc: đọc khối `:root[data-product="<id>"]` trong products.css (bản sinh từ `shape`).
Map<String, String> productRadius(String css, String id) {
  final block = RegExp(':root\\[data-product="${RegExp.escape(id)}"\\] \\{([^}]*)\\}').firstMatch(css);
  if (block == null) throw FormatException('products.css thiếu khối data-product="$id"');
  return {
    for (final m in RegExp(r'--radius-([a-z]+):\s*([0-9.]+px);').allMatches(block.group(1)!)) m.group(1)!: m.group(2)!,
  };
}

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

String generate(Map<String, Object?> json, Map<String, Object?> product, String productCss) {
  final color = json['color']! as Map<String, Object?>;
  final colors = product['colors']! as Map<String, Object?>;
  Map<String, String> merged(String mode) {
    final base = Map<String, String>.of((color[mode]! as Map).cast<String, String>());
    final over = (colors[mode]! as Map).cast<String, String>();
    for (final k in over.keys) {
      if (!base.containsKey(k)) throw FormatException('Vai trò bản sắc lạ (không có ở lớp nền)', k);
    }
    return base..addAll(over);
  }

  final light = merged('light');
  final dark = merged('dark');
  final keys = light.keys.toList();
  final b = StringBuffer()
    ..writeln('// TỆP SINH TỰ ĐỘNG bởi tool/gen_tokens.dart - KHÔNG SỬA TAY.')
    ..writeln(
      '// Nguồn: .standards/tokens/design-tokens.json v${(json['meta']! as Map)['version']}'
      ' + products/${product['id']}.json',
    )
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
  final radius = Map<String, Object?>.of((json['radius']! as Map).cast())
    ..addAll(productRadius(productCss, '${product['id']}'));
  numbers('QtRadius', 'Bo góc (px) - bộ `${product['shape']}` của bản sắc; `control` cho nút.', radius);
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
  b
    ..writeln()
    ..writeln('/// Bản sắc sản phẩm (DESIGN_SYSTEM.md mục 1.2): font tiêu đề h1-h3 + số liệu lớn, bố cục, hoạ tiết.')
    ..writeln('abstract final class QtBrand {')
    ..writeln("  static const id = '${product['id']}';")
    ..writeln("  static const fontDisplay = '${product['fontDisplay']}';")
    ..writeln("  static const layout = '${product['layout']}';")
    ..writeln("  static const shape = '${product['shape']}';")
    ..writeln("  static const motif = '${product['motif']}';")
    ..writeln('}');
  return b.toString();
}

void main() {
  final json = jsonDecode(File(_src).readAsStringSync()) as Map<String, Object?>;
  final product = jsonDecode(File(_product).readAsStringSync()) as Map<String, Object?>;
  if (product['id'] != productId) throw FormatException('Sai tệp bản sắc', _product);
  final code = generate(json, product, File(_productCss).readAsStringSync());
  File(_out).writeAsStringSync(code);
}
