import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:qulythuchi/services/export.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PDF xuất ra nhúng logo sản phẩm + logo tsudev và liên kết nhà làm tsudev.com', () async {
    final t = ExportTable(
      ['Ngày', 'Ví', 'Loại', 'Danh mục', 'Mục con', 'Số tiền', 'Tiền tệ', 'Ghi chú', 'Người nhận'],
      [
        ['2026-11-20', 'Tiền mặt', 'Chi', 'Ăn uống', '', exportNumber('-50000'), 'VND', '', ''],
      ],
    );
    final pdf = await toPdf(t, title: 'Giao dịch', subtitle: '20/11/2026');
    final raw = latin1.decode(pdf);
    expect(raw.startsWith('%PDF'), isTrue);
    expect(RegExp(r'/Subtype\s*/Image').allMatches(raw).length, greaterThanOrEqualTo(2));
    expect(raw, contains('https://tsudev.com'));
  });
}
