import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart' show Pdfrx;
import 'package:qulythuchi/services/export.dart';
import 'package:qulythuchi/services/import_csv.dart';
import 'package:qulythuchi/services/import_pdf.dart';

/// ADR-0020: PDF do chính app xuất (nhiều trang, chữ tiếng Việt, cột số căn phải) đọc lại phải ra đúng bảng - chạy PDFium
/// thật (native assets; máy Linux cần clang như job CI App).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // flutter test không có plugin path_provider ⇒ đặt sẵn thư mục đệm cho pdfrx (app thật lấy từ path_provider).
  setUpAll(() => Pdfrx.cacheDirectoryPath = Directory.systemTemp.createTempSync('qlt-pdfrx').path);

  test('khứ hồi: xuất PDF giao dịch rồi nhập lại ra đúng dòng, cột, ngày, số tiền', () async {
    final rows = <ExportRow>[
      for (var i = 0; i < 60; i++)
        [
          '2026-11-${(i % 28 + 1).toString().padLeft(2, '0')}',
          'Tiền mặt',
          i.isEven ? 'Chi' : 'Thu',
          i.isEven ? 'Ăn uống' : 'Lương',
          '',
          exportNumber(i.isEven ? '-${50000 + i * 1000}' : '${1000000 + i}'),
          'VND',
          'Giao dịch số $i đường Nguyễn Huệ',
          '',
        ],
    ];
    final t = ExportTable([
      'Ngày',
      'Ví',
      'Loại',
      'Danh mục',
      'Mục con',
      'Số tiền',
      'Tiền tệ',
      'Ghi chú',
      'Người nhận',
    ], rows);
    final pdf = await toPdf(t, title: 'Giao dịch', subtitle: '01/11/2026 - 28/11/2026');
    expect(isPdf(pdf), isTrue);

    final table = await parsePdfStatement(pdf, askPassword: (_) async => null);
    final h = findHeaderRow(table);
    expect(table[h], containsAll(['Ngày', 'Loại', 'Số tiền', 'Ghi chú']));
    final body = table.sublist(h + 1).where((r) => RegExp(r'^\d{2}/11/2026$').hasMatch(r.first)).toList();
    expect(body.length, 60, reason: 'mọi giao dịch trên mọi trang, tiêu đề lặp đã bỏ');
    final date = table[h].indexOf('Ngày'), amount = table[h].indexOf('Số tiền'), note = table[h].indexOf('Ghi chú');
    expect(body.first[date], '01/11/2026');
    expect(body.first[amount].replaceAll(RegExp(r'[^\d-]'), ''), '-50000');
    expect(body.first[note], 'Giao dịch số 0 đường Nguyễn Huệ');
    expect(body[1][amount].replaceAll(RegExp(r'[^\d-]'), ''), '1000001');
  });

  test('không phải PDF / PDF hỏng', () async {
    expect(isPdf(Uint8List.fromList('a,b\n1,2'.codeUnits)), isFalse);
    await expectLater(
      parsePdfStatement(Uint8List.fromList('%PDF-1.7 hỏng'.codeUnits), askPassword: (_) async => null),
      throwsA(isA<FormatException>()),
    );
  });
}
