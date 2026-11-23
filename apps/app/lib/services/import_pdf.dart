import 'dart:typed_data';

import 'package:pdfrx/pdfrx.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

/// Nhập sao kê ngân hàng dạng PDF (ADR-0020): PDFium (gói `pdfrx`, ghim phiên bản) CHỈ dùng để lấy chữ kèm toạ độ;
/// dựng bảng ở lõi (`pdfGlyphsToRows`), rồi đi tiếp luồng ghép cột như CSV/XLSX. Không hiển thị, không chạy JavaScript
/// của PDF, không tải gì qua mạng. Tệp và mật khẩu chỉ nằm trong bộ nhớ, không ghi ra đĩa, không ghi log.
const maxPdfBytes = 15 * 1024 * 1024;
const maxPdfPages = 200;

/// Tệp bắt đầu bằng `%PDF`.
bool isPdf(Uint8List bytes) =>
    bytes.length > 4 && bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46;

/// Đọc PDF thành dòng × cột. [askPassword] được gọi khi tệp có mật khẩu (`retry` = lần trước sai); trả `null` = huỷ.
/// Lỗi: `FormatException('too_big' | 'empty' | 'password')`.
Future<List<List<String>>> parsePdfStatement(
  Uint8List bytes, {
  required Future<String?> Function(bool retry) askPassword,
}) async {
  if (bytes.length > maxPdfBytes) throw const FormatException('too_big');
  await pdfrxFlutterInitialize();
  var asked = 0;
  var cancelled = false;
  final PdfDocument doc;
  try {
    doc = await PdfDocument.openData(
      bytes,
      sourceName: 'sao-ke-${bytes.length}',
      passwordProvider: () async {
        final p = await askPassword(asked++ > 0);
        if (p == null) cancelled = true;
        return p;
      },
    );
  } on PdfPasswordException {
    throw FormatException(cancelled ? 'cancelled' : 'password');
  } on Object {
    if (cancelled) throw const FormatException('cancelled');
    throw const FormatException('empty');
  }
  try {
    if (doc.pages.length > maxPdfPages) throw const FormatException('too_big');
    final glyphs = <PdfGlyph>[];
    for (final page in doc.pages) {
      final t = await page.loadText();
      if (t == null) continue;
      final n = t.fullText.length < t.charRects.length ? t.fullText.length : t.charRects.length;
      for (var i = 0; i < n; i++) {
        final r = t.charRects[i];
        glyphs.add(PdfGlyph(t.fullText[i], page.pageNumber, r.left, r.top, r.right, r.bottom));
        if (glyphs.length > maxPdfGlyphs) throw const FormatException('too_big');
      }
    }
    final rows = pdfGlyphsToRows(glyphs);
    // PDF chỉ là ảnh quét (không có lớp chữ) ⇒ không đọc được: hướng người dùng sang OCR/bản CSV.
    if (rows.isEmpty) throw const FormatException('no_text');
    return rows;
  } finally {
    await doc.dispose();
  }
}
