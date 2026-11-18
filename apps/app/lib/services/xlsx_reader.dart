import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import 'import_csv.dart' show maxImportBytes, maxImportRows;

/// Giới hạn kích thước sau giải nén (chống "bom zip").
const _maxXmlBytes = 40 * 1024 * 1024;

/// Đọc trang tính ĐẦU TIÊN của tệp XLSX thành bảng chuỗi (đủ cho sao kê ngân hàng xuất ra Excel). Ô ngày kiểu số
/// (số sê-ri Excel) chỉ đổi sang `YYYY-MM-DD` khi ô có định dạng ngày; số thường giữ nguyên chữ số.
/// Không chạy công thức, không đọc macro. Tệp hỏng/quá lớn ⇒ [FormatException].
List<List<String>> parseXlsx(Uint8List bytes) {
  if (bytes.length > maxImportBytes) throw const FormatException('too_big');
  final Archive zip;
  try {
    zip = ZipDecoder().decodeBytes(bytes);
  } on Object {
    throw const FormatException('bad_xlsx');
  }
  String? read(String name) {
    final f = zip.findFile(name);
    if (f == null) return null;
    if (f.size > _maxXmlBytes) throw const FormatException('too_big');
    return utf8.decode(f.content, allowMalformed: true);
  }

  // Trang tính đầu theo workbook.xml.rels; mặc định sheet1.xml.
  var sheetPath = 'xl/worksheets/sheet1.xml';
  final wb = read('xl/workbook.xml');
  final rels = read('xl/_rels/workbook.xml.rels');
  if (wb != null && rels != null) {
    final rid = RegExp(r'<sheet\b[^>]*\br:id="([^"]+)"').firstMatch(wb)?.group(1);
    if (rid != null) {
      final rel = RegExp('<Relationship\\b[^>]*Id="${RegExp.escape(rid)}"[^>]*/?>').firstMatch(rels)?.group(0);
      final target = rel == null ? null : RegExp(r'Target="([^"]+)"').firstMatch(rel)?.group(1);
      if (target != null) sheetPath = target.startsWith('/') ? target.substring(1) : 'xl/$target';
    }
  }
  final sheet = read(sheetPath);
  if (sheet == null) throw const FormatException('bad_xlsx');

  final shared = <String>[];
  final sst = read('xl/sharedStrings.xml');
  if (sst != null) {
    for (final si in RegExp(r'<si\b[^>]*>([\s\S]*?)</si>').allMatches(sst)) {
      shared.add(_texts(si.group(1)!));
    }
  }
  final dateStyles = _dateStyleIndexes(read('xl/styles.xml'));

  final rows = <List<String>>[];
  for (final row in RegExp(r'<row\b[^>]*>([\s\S]*?)</row>').allMatches(sheet)) {
    final cells = <int, String>{};
    for (final c in RegExp(r'<c\b([^>]*?)(?:/>|>([\s\S]*?)</c>)').allMatches(row.group(1)!)) {
      final attrs = c.group(1)!;
      final body = c.group(2) ?? '';
      final ref = RegExp(r'\br="([A-Z]+)\d+"').firstMatch(attrs)?.group(1);
      final col = ref == null ? cells.length : _colIndex(ref);
      if (col > 200) continue;
      final type = RegExp(r'\bt="([^"]+)"').firstMatch(attrs)?.group(1);
      final style = int.tryParse(RegExp(r'\bs="(\d+)"').firstMatch(attrs)?.group(1) ?? '');
      final v = RegExp(r'<v>([\s\S]*?)</v>').firstMatch(body)?.group(1);
      String text;
      if (type == 's') {
        final i = int.tryParse(v ?? '');
        text = i != null && i >= 0 && i < shared.length ? shared[i] : '';
      } else if (type == 'inlineStr') {
        text = _texts(body);
      } else {
        text = _unescape(v ?? '');
        if (type == null && style != null && dateStyles.contains(style)) text = _serialDate(text) ?? text;
      }
      cells[col] = text.trim();
    }
    if (cells.isEmpty) continue;
    final width = cells.keys.reduce((a, b) => a > b ? a : b) + 1;
    final r = [for (var i = 0; i < width; i++) cells[i] ?? ''];
    if (r.any((x) => x.isNotEmpty)) rows.add(r);
    if (rows.length > maxImportRows + 30) throw const FormatException('too_big');
  }
  return rows;
}

String _texts(String xml) =>
    _unescape(RegExp(r'<t\b[^>]*>([\s\S]*?)</t>').allMatches(xml).map((m) => m.group(1)!).join());

String _unescape(String s) => s
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAllMapped(RegExp(r'&#(\d+);'), (m) => String.fromCharCode(int.parse(m.group(1)!)))
    .replaceAll('&amp;', '&');

int _colIndex(String letters) {
  var n = 0;
  for (final u in letters.codeUnits) {
    n = n * 26 + (u - 64);
  }
  return n - 1;
}

/// Chỉ số kiểu ô (cellXfs) có định dạng ngày: mã dựng sẵn 14-22, 45-47 hoặc numFmt tự định nghĩa chứa d/m/y.
Set<int> _dateStyleIndexes(String? styles) {
  if (styles == null) return const {};
  final custom = <int>{};
  for (final m in RegExp(r'<numFmt\b[^>]*numFmtId="(\d+)"[^>]*formatCode="([^"]*)"').allMatches(styles)) {
    final code = m.group(2)!.toLowerCase().replaceAll(RegExp(r'\[[^\]]*\]|"[^"]*"'), '');
    if (code.contains('d') && code.contains('y')) custom.add(int.parse(m.group(1)!));
  }
  final xfs = RegExp(r'<cellXfs\b[^>]*>([\s\S]*?)</cellXfs>').firstMatch(styles)?.group(1) ?? '';
  final out = <int>{};
  var i = 0;
  for (final xf in RegExp(r'<xf\b[^>]*?/?>').allMatches(xfs)) {
    final id = int.tryParse(RegExp(r'numFmtId="(\d+)"').firstMatch(xf.group(0)!)?.group(1) ?? '') ?? 0;
    if ((id >= 14 && id <= 22) || (id >= 45 && id <= 47) || custom.contains(id)) out.add(i);
    i++;
  }
  return out;
}

/// Số sê-ri Excel (hệ 1900) ⇒ `YYYY-MM-DD`; bỏ phần giờ.
String? _serialDate(String v) {
  final whole = int.tryParse(v.split('.').first);
  if (whole == null || whole < 1 || whole > 2958465) return null;
  // 1899-12-30 là gốc thực tế (Excel coi 1900 là năm nhuận).
  return CivilDate.fromDateTime(DateTime.utc(1899, 12, 30).add(Duration(days: whole))).toString();
}
