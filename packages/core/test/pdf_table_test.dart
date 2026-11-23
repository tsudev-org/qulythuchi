import 'package:qulythuchi_core/qulythuchi_core.dart';
import 'package:test/test.dart';

/// Đặt chuỗi [s] trên trang [page], ký tự rộng 5, cao 10, đáy ở [y]. [right] ⇒ căn phải tại x.
List<PdfGlyph> put(String s, double x, double y, {int page = 1, bool right = false}) {
  final start = right ? x - s.length * 5 : x;
  return [for (var i = 0; i < s.length; i++) PdfGlyph(s[i], page, start + i * 5, y + 10, start + i * 5 + 4.6, y)];
}

List<PdfGlyph> header(double y, {int page = 1}) => [
  ...put('Ngày', 40, y, page: page),
  ...put('Diễn giải', 120, y, page: page),
  ...put('Ghi nợ', 400, y, page: page, right: true),
  ...put('Ghi có', 480, y, page: page, right: true),
  ...put('Số dư', 560, y, page: page, right: true),
];

List<PdfGlyph> txn(String date, String note, String debit, String credit, String bal, double y, {int page = 1}) => [
  ...put(date, 40, y, page: page),
  ...put(note, 120, y, page: page),
  if (debit.isNotEmpty) ...put(debit, 400, y, page: page, right: true),
  if (credit.isNotEmpty) ...put(credit, 480, y, page: page, right: true),
  ...put(bal, 560, y, page: page, right: true),
];

void main() {
  test('sao kê 2 trang: cột căn phải, diễn giải xuống dòng được gộp, tiêu đề lặp bị bỏ', () {
    final g = [
      ...put('SAO KÊ TÀI KHOẢN', 200, 780),
      ...put('Số TK: 0123456789', 40, 760),
      ...header(720),
      ...txn('01/11/2026', 'Chuyển tiền ăn trưa', '50.000', '', '1.950.000', 700),
      ...txn('02/11/2026', 'Lương tháng 10 công ty', '', '15.000.000', '16.950.000', 680),
      ...put('ABC chi nhánh Hà Nội', 120, 668),
      ...header(720, page: 2),
      ...txn('03/11/2026', 'Mua sắm', '1.200.000', '', '15.750.000', 700, page: 2),
      ...put('Tổng phát sinh', 120, 660, page: 2),
      ...put('1.250.000', 400, 660, page: 2, right: true),
    ];
    final rows = pdfGlyphsToRows(g);
    final hdr = rows.indexWhere((r) => r.contains('Ngày'));
    expect(hdr, greaterThanOrEqualTo(0));
    expect(rows[hdr], ['Ngày', 'Diễn giải', 'Ghi nợ', 'Ghi có', 'Số dư']);
    final body = rows.sublist(hdr + 1);
    expect(body, [
      ['01/11/2026', 'Chuyển tiền ăn trưa', '50.000', '', '1.950.000'],
      ['02/11/2026', 'Lương tháng 10 công ty ABC chi nhánh Hà Nội', '', '15.000.000', '16.950.000'],
      ['03/11/2026', 'Mua sắm', '1.200.000', '', '15.750.000'],
      ['', 'Tổng phát sinh', '1.250.000', '', ''],
    ]);
    // Tiêu đề trang 2 không xuất hiện lần nữa.
    expect(rows.where((r) => r.contains('Ngày')).length, 1);
  });

  test('ký tự xen khoảng trắng và thứ tự ký tự lộn xộn vẫn ra đúng từ, đúng dòng', () {
    final g = [...txn('05/11/2026', 'Phí SMS', '11.000', '', '100.000', 500), ...header(520)];
    final rows = pdfGlyphsToRows(g);
    expect(rows.first, ['Ngày', 'Diễn giải', 'Ghi nợ', 'Ghi có', 'Số dư']);
    expect(rows[1], ['05/11/2026', 'Phí SMS', '11.000', '', '100.000']);
  });

  test('rỗng, không có hộp, quá lớn', () {
    expect(pdfGlyphsToRows(const []), isEmpty);
    expect(pdfGlyphsToRows(const [PdfGlyph(' ', 1, 0, 0, 0, 0)]), isEmpty);
    expect(
      () => pdfGlyphsToRows(List.filled(maxPdfGlyphs + 1, const PdfGlyph('a', 1, 0, 10, 4, 0))),
      throwsFormatException,
    );
  });

  test('dòng nối chỉ có số tài khoản/tham chiếu dài vẫn được gộp vào diễn giải', () {
    final g = [
      ...header(720),
      ...txn('10/11/2026', 'CK den TK', '', '2.000.000', '3.000.000', 700),
      ...put('0123456789012', 120, 688),
      ...txn('11/11/2026', 'Rut tien ATM', '500.000', '', '2.500.000', 670),
    ];
    final rows = pdfGlyphsToRows(g);
    expect(rows[1], ['10/11/2026', 'CK den TK 0123456789012', '', '2.000.000', '3.000.000']);
    expect(rows[2].first, '11/11/2026');
  });

  test('ngày yyyy-mm-dd, một cột số tiền có dấu âm', () {
    final g = [
      ...put('Date', 40, 720),
      ...put('Description', 120, 720),
      ...put('Amount', 480, 720, right: true),
      ...put('2026-11-12', 40, 700),
      ...put('Coffee shop', 120, 700),
      ...put('-45,000', 480, 700, right: true),
      ...put('2026-11-13', 40, 680),
      ...put('Refund', 120, 680),
      ...put('120,000', 480, 680, right: true),
    ];
    expect(pdfGlyphsToRows(g), [
      ['Date', 'Description', 'Amount'],
      ['2026-11-12', 'Coffee shop', '-45,000'],
      ['2026-11-13', 'Refund', '120,000'],
    ]);
  });

  test('phụ đề chứa khoảng ngày phía trên bảng không bị coi là giao dịch', () {
    final g = [
      ...put('Giao dịch', 40, 760),
      ...put('01/11/2026 - 28/11/2026', 40, 745),
      ...header(720),
      ...txn('01/11/2026', 'Mua sắm', '200.000', '', '800.000', 700),
      ...txn('02/11/2026', 'Hoàn tiền', '', '50.000', '850.000', 680),
    ];
    final rows = pdfGlyphsToRows(g);
    final h = rows.indexWhere((r) => r.contains('Ngày'));
    expect(rows[h], ['Ngày', 'Diễn giải', 'Ghi nợ', 'Ghi có', 'Số dư']);
    expect(rows.sublist(h + 1), [
      ['01/11/2026', 'Mua sắm', '200.000', '', '800.000'],
      ['02/11/2026', 'Hoàn tiền', '', '50.000', '850.000'],
    ]);
  });
}
