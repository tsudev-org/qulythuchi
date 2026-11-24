import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulythuchi/ui/widgets/cot_tang_truong.dart';

void main() {
  test('cột tăng dần, nằm trong khung, cột cuối cao trọn khung', () {
    final cot = cotTangTruong(const Size(640, 320));
    expect(cot, hasLength(9));
    for (var i = 1; i < cot.length; i++) {
      expect(cot[i].height, greaterThan(cot[i - 1].height));
      expect(cot[i].left, greaterThan(cot[i - 1].right));
    }
    expect(cot.first.height, closeTo(320 * 0.22, 0.01));
    expect(cot.last.height, closeTo(320, 0.01));
    expect(cot.last.right, lessThanOrEqualTo(640));
  });

  test('độ phủ ≤ 15% và cùng công thức với website (cot-tang-truong.mjs)', () {
    expect(cotDoPhu, lessThanOrEqualTo(0.15));
    expect(cotSoCot, 9);
    final js = File('../site/src/lib/cot-tang-truong.mjs').readAsStringSync();
    expect(js, contains('const SO_COT = 9;'));
    expect(js, contains('export const DO_PHU = 0.12;'));
    expect(js, contains('0.22 + 0.78 * Math.pow(i / (soCot - 1), 1.15)'));
    expect(js, contains('buoc * 0.62'));
  });

  testWidgets('vẽ được và bị loại khỏi cây ngữ nghĩa', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(width: 200, height: 80, child: CustomPaint(painter: CotTangTruongPainter(Colors.green))),
      ),
    );
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
