// Chặn tái phát UI1: biểu tượng đang chọn trên thanh điều hướng từng bị vẽ trắng (onSecondaryContainer) trên viên
// chỉ báo nhạt. Đo màu IconTheme THẬT mà NavigationBar/NavigationRail truyền xuống, so với nền thật (viên chỉ báo
// hoặc nền thanh), yêu cầu tương phản ≥ 3:1 (WCAG 1.4.11) ở cả Sáng và Tối.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulythuchi/theme/app_theme.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

Widget _probe(Map<String, Color?> out, String key, IconData icon) => Builder(
  builder: (c) {
    out[key] = IconTheme.of(c).color;
    return Icon(icon);
  },
);

void main() {
  for (final b in Brightness.values) {
    final theme = buildTheme(b);

    testWidgets('NavigationBar ${b.name}: biểu tượng chọn/không chọn đủ tương phản', (t) async {
      final out = <String, Color?>{};
      await t.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            bottomNavigationBar: NavigationBar(
              selectedIndex: 0,
              destinations: [
                NavigationDestination(icon: _probe(out, 'sel', Icons.home), label: 'A'),
                NavigationDestination(icon: _probe(out, 'unsel', Icons.list), label: 'B'),
              ],
            ),
          ),
        ),
      );
      final nav = theme.navigationBarTheme;
      final indicator = nav.indicatorColor!;
      final bar = nav.backgroundColor!;
      expect(indicator.a, 1.0, reason: 'viên chỉ báo phải đục để tương phản đo được');
      expect(_contrast(out['sel']!, indicator), greaterThanOrEqualTo(3.0), reason: 'chọn: ${out['sel']}');
      expect(_contrast(out['unsel']!, bar), greaterThanOrEqualTo(3.0), reason: 'không chọn: ${out['unsel']}');
      expect(out['sel'], isNot(const Color(0xFFFFFFFF)));
    });

    testWidgets('NavigationRail ${b.name}: biểu tượng chọn/không chọn đủ tương phản', (t) async {
      final out = <String, Color?>{};
      await t.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: 0,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    NavigationRailDestination(icon: _probe(out, 'sel', Icons.home), label: const Text('A')),
                    NavigationRailDestination(icon: _probe(out, 'unsel', Icons.list), label: const Text('B')),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      final rail = theme.navigationRailTheme;
      expect(_contrast(out['sel']!, rail.indicatorColor!), greaterThanOrEqualTo(3.0), reason: 'chọn: ${out['sel']}');
      expect(_contrast(out['unsel']!, rail.backgroundColor!), greaterThanOrEqualTo(3.0));
    });
  }
}
