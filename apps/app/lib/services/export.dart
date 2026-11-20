import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../state/ledger_repository.dart';
import '../theme/brand.dart';

/// Một dòng xuất: giá trị chuỗi hoặc số (số tiền đã ở đơn vị chính, chuỗi thập phân dấu chấm).
typedef ExportRow = List<Object>;

enum ExportFormat { csv, xlsx, pdf }

final class ExportTable {
  ExportTable(this.headers, this.rows);
  final List<String> headers;
  final List<ExportRow> rows;
}

/// Số tiền đơn vị nhỏ nhất ⇒ chuỗi thập phân máy đọc được ("-1234.50"), không dùng double.
String decimalString(int minor, int digits) {
  final neg = minor < 0;
  final s = minor.abs().toString().padLeft(digits + 1, '0');
  final v = digits == 0 ? s : '${s.substring(0, s.length - digits)}.${s.substring(s.length - digits)}';
  return neg ? '-$v' : v;
}

/// Bảng giao dịch để xuất. Ngày ISO (YYYY-MM-DD) cho máy đọc; số tiền có dấu (chi âm).
ExportTable transactionsTable(
  LedgerData data,
  Iterable<Txn> txns,
  List<String> headers,
  String Function(TxnKind) kindName,
) {
  final rows = <ExportRow>[];
  for (final t in txns) {
    final w = data.wallet(t.walletId);
    final cur = w?.currency ?? Currency.vnd;
    final cat = data.category(t.categoryId);
    final parent = cat?.parentId == null ? null : data.category(cat!.parentId);
    final signed = switch (t.kind) {
      TxnKind.expense => -t.amount,
      TxnKind.transferOut => -(t.amount + t.fee),
      _ => t.amount,
    };
    rows.add([
      t.date.toString(),
      w?.name ?? '',
      kindName(t.kind),
      parent?.name ?? cat?.name ?? '',
      parent == null ? '' : (cat?.name ?? ''),
      _Num(decimalString(signed, cur.minorDigits)),
      cur.code,
      t.note ?? '',
      t.payee ?? '',
    ]);
  }
  return ExportTable(headers, rows);
}

/// Ô số dạng chuỗi thập phân (ví dụ từ [decimalString]).
Object exportNumber(String decimal) => _Num(decimal);

/// Ô số (để XLSX ghi kiểu số, CSV không thêm dấu nháy chống công thức).
final class _Num {
  const _Num(this.value);
  final String value;
  @override
  String toString() => value;
}

/// Chống "CSV injection": ô chữ bắt đầu bằng = + - @ (hoặc tab/CR) bị bảng tính hiểu là công thức.
String _safeText(String s) => RegExp(r'^[=+\-@\t\r]').hasMatch(s) ? "'$s" : s;

String _csvCell(Object v) {
  final s = v is _Num ? v.value : _safeText(v.toString());
  return RegExp(r'[",\r\n]').hasMatch(s) ? '"${s.replaceAll('"', '""')}"' : s;
}

/// CSV UTF-8 có BOM (Excel đọc đúng tiếng Việt), phân tách dấu phẩy, xuống dòng CRLF (RFC 4180).
Uint8List toCsv(ExportTable t) {
  final b = StringBuffer('\uFEFF')..write('${t.headers.map(_csvCell).join(',')}\r\n');
  for (final r in t.rows) {
    b.write('${r.map(_csvCell).join(',')}\r\n');
  }
  return Uint8List.fromList(utf8.encode(b.toString()));
}

String _xml(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');

String _colName(int i) {
  var n = i + 1;
  var s = '';
  while (n > 0) {
    final r = (n - 1) % 26;
    s = String.fromCharCode(65 + r) + s;
    n = (n - 1) ~/ 26;
  }
  return s;
}

/// XLSX tối giản (Office Open XML: 1 trang tính, chuỗi nội tuyến, số thật). Không cần thư viện bảng tính.
Uint8List toXlsx(ExportTable t, {String sheetName = 'Giao dich'}) {
  String row(int r, List<Object> cells) {
    final b = StringBuffer('<row r="${r + 1}">');
    for (var c = 0; c < cells.length; c++) {
      final ref = '${_colName(c)}${r + 1}';
      final v = cells[c];
      if (v is _Num) {
        b.write('<c r="$ref"><v>${v.value}</v></c>');
      } else {
        b.write('<c r="$ref" t="inlineStr"><is><t xml:space="preserve">${_xml(_safeText(v.toString()))}</t></is></c>');
      }
    }
    return (b..write('</row>')).toString();
  }

  final sheet = StringBuffer(
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>',
  )..write(row(0, t.headers));
  for (var i = 0; i < t.rows.length; i++) {
    sheet.write(row(i + 1, t.rows[i]));
  }
  sheet.write('</sheetData></worksheet>');

  final files = <String, String>{
    '[Content_Types].xml':
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
        '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
        '</Types>',
    '_rels/.rels':
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
        '</Relationships>',
    'xl/workbook.xml':
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
        '<sheets><sheet name="${_xml(sheetName)}" sheetId="1" r:id="rId1"/></sheets></workbook>',
    'xl/_rels/workbook.xml.rels':
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>'
        '</Relationships>',
    'xl/worksheets/sheet1.xml': sheet.toString(),
  };
  final archive = Archive();
  files.forEach((name, content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  });
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

/// PDF khổ A4 ngang, font Inter (đủ dấu tiếng Việt), ngày DD/MM/YYYY. Đầu trang mang logo sản phẩm, chân trang
/// mang khối nhà làm tsudev (BRAND_ASSETS.md mục 15.5) - ảnh nhúng thẳng vào tệp, không tải ngoài.
Future<Uint8List> toPdf(ExportTable t, {required String title, required String subtitle}) async {
  final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-Regular.ttf'));
  final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-SemiBold.ttf'));
  final logo = pw.MemoryImage((await rootBundle.load(brandLogoAsset)).buffer.asUint8List());
  final tsudev = pw.MemoryImage((await rootBundle.load(tsudevLogoAsset)).buffer.asUint8List());
  String dmy(String iso) {
    final p = iso.split('-');
    return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : iso;
  }

  const muted = PdfColors.grey700;
  final doc = pw.Document(title: title, creator: 'Quly Thu Chi', producer: 'Quly Thu Chi - tsudev.com');
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
      header: (_) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Image(logo, width: 30, height: 30),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(title, style: pw.TextStyle(font: bold, fontSize: 16)),
                  pw.Text(subtitle, style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ),
            pw.Text(
              'Quly Thu Chi',
              style: pw.TextStyle(font: bold, fontSize: 9, color: muted),
            ),
          ],
        ),
      ),
      footer: (ctx) => pw.Row(
        children: [
          pw.UrlLink(
            destination: 'https://tsudev.com',
            child: pw.Row(
              children: [
                pw.Image(tsudev, width: 10, height: 10),
                pw.SizedBox(width: 4),
                pw.Text('TsuDEV · tsudev.com', style: const pw.TextStyle(fontSize: 8, color: muted)),
              ],
            ),
          ),
          pw.Spacer(),
          pw.Text('${ctx.pageNumber}/${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
      build: (_) => [
        pw.TableHelper.fromTextArray(
          headers: t.headers,
          data: [
            for (final r in t.rows) [dmy(r[0].toString()), for (final c in r.skip(1)) c.toString()],
          ],
          headerStyle: pw.TextStyle(font: bold, fontSize: 8),
          cellStyle: const pw.TextStyle(fontSize: 8),
          cellAlignments: {5: pw.Alignment.centerRight},
          border: pw.TableBorder.all(width: 0.3, color: PdfColors.grey500),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
        ),
      ],
    ),
  );
  return doc.save();
}
