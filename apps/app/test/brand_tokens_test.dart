import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulythuchi/theme/app_theme.dart';
import 'package:qulythuchi/theme/tokens.g.dart';

import '../tool/gen_tokens.dart' show productRadius;

/// Bản sắc qulythuchi (tsudev-standards v5.0.0, DESIGN_SYSTEM.md mục 1.2): màu nhấn và bo góc lấy từ
/// `.standards/tokens/products/`, không khai lại tại repo.
Color _hex(String v) => Color(int.parse('FF${v.substring(1)}', radix: 16));

void main() {
  final product =
      jsonDecode(File('../../.standards/tokens/products/qulythuchi.json').readAsStringSync()) as Map<String, Object?>;
  final colors = product['colors']! as Map<String, Object?>;

  test('màu nhấn Sáng/Tối khớp products/qulythuchi.json', () {
    for (final (mode, p) in [('light', QtPalette.light), ('dark', QtPalette.dark)]) {
      final c = (colors[mode]! as Map).cast<String, String>();
      expect(p.primary, _hex(c['primary']!), reason: mode);
      expect(p.onPrimary, _hex(c['on-primary']!), reason: mode);
      expect(p.textLink, _hex(c['text-link']!), reason: mode);
      expect(p.focusRing, _hex(c['focus-ring']!), reason: mode);
      expect(p.accent, _hex(c['accent']!), reason: mode);
    }
    // Hue 160 - xanh lục bảo của ví (phiếu STD50).
    expect(QtPalette.dark.primary, const Color(0xFF39BA81));
    expect(QtPalette.light.primary, const Color(0xFF05794F));
  });

  test('bo góc bộ mem: 6/10/14, nút 10', () {
    final css = File('../../.standards/tokens/products.css').readAsStringSync();
    final r = productRadius(css, 'qulythuchi');
    expect(r, {'sm': '6px', 'md': '10px', 'lg': '14px', 'control': '10px'});
    expect((QtRadius.sm, QtRadius.md, QtRadius.lg, QtRadius.control), (6.0, 10.0, 14.0, 10.0));
    expect(QtBrand.shape, product['shape']);
  });

  test('tiêu đề h1-h3 dùng font bản sắc, thân bài Inter; nút bo theo radius-control', () {
    expect(QtBrand.fontDisplay, product['fontDisplay']);
    for (final b in [Brightness.light, Brightness.dark]) {
      final t = buildTheme(b);
      expect(t.textTheme.headlineMedium!.fontFamily, 'Be Vietnam Pro');
      expect(t.textTheme.headlineSmall!.fontFamily, 'Be Vietnam Pro');
      expect(t.textTheme.titleLarge!.fontFamily, 'Be Vietnam Pro');
      expect(t.textTheme.bodyMedium!.fontFamily, 'Inter');
      final shape = t.filledButtonTheme.style!.shape!.resolve({})! as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(QtRadius.control));
    }
  });
}
