/// Dựng bảng (dòng × cột) từ chữ của sao kê ngân hàng dạng PDF (ADR-0020).
///
/// Đầu vào là từng ký tự kèm hộp bao theo toạ độ PDF (gốc ở góc dưới trái, `top > bottom`) - lấy bằng PDFium ở tầng
/// app. Lõi KHÔNG đọc tệp PDF, chỉ làm phần hình học nên chạy được và test được ở mọi nền tảng:
///
/// 1. Ký tự ⇒ **từ** (cùng dòng chữ, khoảng hở ngang nhỏ hơn ~0,3 chiều cao chữ, không qua khoảng trắng).
/// 2. Từ ⇒ **dòng** (tâm dọc lệch nhau dưới ~0,5 chiều cao chữ), xếp trên xuống, trái sang phải.
/// 3. **Ranh giới cột** từ hồ sơ chiếu theo trục x của các dòng giao dịch (có ngày + số tiền) trên MỌI trang: vạch x nào gần
///    như không dòng nào phủ là khe giữa hai cột. Cột căn phải (số tiền) cũng đúng vì không dựa vào mép trái.
/// 4. Dòng xuống hàng của diễn giải (không có ngày, không có số tiền) được **gộp** vào giao dịch phía trên; dòng tiêu
///    đề cột lặp lại ở đầu mỗi trang bị bỏ.
///
/// Kết quả đi tiếp vào luồng ghép cột của CSV/XLSX (`findHeaderRow`, `guessColumns`, `buildImportTxns` ở app).
library;

import 'dart:math' as math;

/// Một ký tự trên trang [page] (đánh số từ 1) với hộp bao PDF.
final class PdfGlyph {
  const PdfGlyph(this.text, this.page, this.left, this.top, this.right, this.bottom);
  final String text;
  final int page;
  final double left;
  final double top;
  final double right;
  final double bottom;
}

/// Giới hạn để tệp lạ/độc không làm treo app.
const maxPdfGlyphs = 2000000;
const maxPdfRows = 20000;

final class _Word {
  _Word(this.page, this.left, this.top, this.right, this.bottom);
  final int page;
  double left, top, right, bottom;
  final StringBuffer text = StringBuffer();
  double get height => top - bottom;
  double get centerY => (top + bottom) / 2;
}

final class _Line {
  _Line(this.page, this.centerY, this.height);
  final int page;
  double centerY;
  double height;
  final words = <_Word>[];
}

final _dateRe = RegExp(r'(^|\D)(\d{1,2}[/.-]\d{1,2}[/.-](\d{4}|\d{2})|\d{4}-\d{2}-\d{2})(\D|$)');
// Số tiền: có dấu phân cách nghìn hoặc thập phân, hoặc ≥ 4 chữ số liền.
final _amountRe = RegExp(r'^[-+(]?\d{1,3}([.,\s]\d{3})+([.,]\d{1,2})?\)?$|^[-+(]?\d{4,9}([.,]\d{1,2})?\)?$');

/// Chuyển ký tự có toạ độ thành bảng ô chữ. Trả về danh sách dòng; mọi dòng có cùng số cột (ô trống là `''`).
List<List<String>> pdfGlyphsToRows(List<PdfGlyph> glyphs) {
  if (glyphs.length > maxPdfGlyphs) throw const FormatException('too_big');
  final lines = _buildLines(_buildWords(glyphs));
  if (lines.isEmpty) return const [];
  final bounds = _columnBounds(lines);
  final rows = <List<String>>[];
  List<String>? header;
  var started = false; // đã gặp dòng giao dịch đầu tiên (có ngày)
  for (final line in lines) {
    final cells = List.filled(bounds.length + 1, '');
    for (final w in line.words) {
      final cx = (w.left + w.right) / 2;
      var col = 0;
      while (col < bounds.length && cx > bounds[col]) {
        col++;
      }
      cells[col] = cells[col].isEmpty ? w.text.toString() : '${cells[col]} ${w.text}';
    }
    final joined = cells.join('\u0001');
    // Tiêu đề cột lặp lại ở đầu trang sau.
    if (header != null && joined == header.join('\u0001')) continue;
    final hasDate = cells.any((c) => _dateRe.hasMatch(c));
    final hasAmount = cells.any((c) => _amountRe.hasMatch(c.replaceAll(' ', ''))) || _isTxn(line);
    // Giao dịch = có ngày VÀ có số tiền; dòng chỉ có ngày (vd. "Từ 01/11/2026 - 28/11/2026" ở đầu trang) không phải.
    final txn = hasDate && hasAmount;
    if (!started && !txn && cells.where((c) => c.isNotEmpty).length >= 3) header = cells;
    if (txn) started = true;
    if (started && !hasDate && !hasAmount && rows.isNotEmpty) {
      // Dòng xuống hàng của diễn giải ⇒ nối vào ô cùng cột của giao dịch phía trên.
      final prev = rows.last;
      for (var i = 0; i < cells.length; i++) {
        if (cells[i].isNotEmpty) prev[i] = prev[i].isEmpty ? cells[i] : '${prev[i]} ${cells[i]}';
      }
      continue;
    }
    rows.add(cells);
    if (rows.length > maxPdfRows + 1) throw const FormatException('too_big');
  }
  // Bỏ cột trống hoàn toàn.
  final used = List.generate(bounds.length + 1, (i) => rows.any((r) => r[i].isNotEmpty));
  return [
    for (final r in rows)
      [
        for (var i = 0; i < r.length; i++)
          if (used[i]) r[i],
      ],
  ];
}

/// Dòng giao dịch: có một từ là ngày và một từ là số tiền.
bool _isTxn(_Line l) =>
    l.words.any((w) => _dateRe.hasMatch(w.text.toString())) &&
    l.words.any((w) => _amountRe.hasMatch(w.text.toString()));

List<_Word> _buildWords(List<PdfGlyph> glyphs) {
  final words = <_Word>[];
  _Word? cur;
  for (final g in glyphs) {
    final t = g.text;
    if (t.isEmpty || t.trim().isEmpty || g.top <= g.bottom) {
      cur = null; // khoảng trắng / xuống dòng / ký tự không có hộp ⇒ hết từ
      continue;
    }
    final h = g.top - g.bottom;
    final c = cur;
    final sameLine =
        c != null && c.page == g.page && ((g.top + g.bottom) / 2 - c.centerY).abs() < 0.5 * math.max(h, c.height);
    final gap = c == null ? double.infinity : g.left - c.right;
    if (c != null && sameLine && gap < 0.3 * math.max(h, c.height) && gap > -0.5 * h) {
      c.text.write(t);
      c.right = math.max(c.right, g.right);
      c.top = math.max(c.top, g.top);
      c.bottom = math.min(c.bottom, g.bottom);
    } else {
      cur = _Word(g.page, g.left, g.top, g.right, g.bottom)..text.write(t);
      words.add(cur);
    }
  }
  return words;
}

List<_Line> _buildLines(List<_Word> words) {
  final sorted = [...words]
    ..sort((a, b) {
      final p = a.page.compareTo(b.page);
      return p != 0 ? p : b.centerY.compareTo(a.centerY);
    });
  final lines = <_Line>[];
  for (final w in sorted) {
    final last = lines.isEmpty ? null : lines.last;
    if (last != null &&
        last.page == w.page &&
        (w.centerY - last.centerY).abs() < 0.5 * math.max(w.height, last.height)) {
      last.words.add(w);
    } else {
      lines.add(_Line(w.page, w.centerY, w.height)..words.add(w));
    }
  }
  for (final l in lines) {
    l.words.sort((a, b) => a.left.compareTo(b.left));
  }
  return lines;
}

/// Toạ độ x của khe giữa các cột (tăng dần).
List<double> _columnBounds(List<_Line> lines) {
  // Bảng do các dòng GIAO DỊCH (có ngày) định nghĩa; tiêu đề sao kê, thông tin tài khoản, chân trang không được làm
  // lấp khe cột. Không dòng nào có ngày ⇒ dùng mọi dòng ≥ 3 từ.
  bool dated(_Line l) => _isTxn(l);
  var rich = lines.where(dated).toList();
  // Thêm dòng tiêu đề cột (dòng ≥ 3 từ ngay trước dòng có ngày đầu tiên của mỗi trang): tiêu đề có đủ mọi cột kể cả
  // cột mà mọi giao dịch đều để trống (vd. cả kỳ không có khoản "Ghi có").
  if (rich.isNotEmpty) {
    for (var i = 0; i < lines.length; i++) {
      if (!dated(lines[i]) || (i > 0 && lines[i - 1].page == lines[i].page && dated(lines[i - 1]))) continue;
      for (var j = i - 1; j >= 0 && lines[j].page == lines[i].page; j--) {
        if (lines[j].words.length >= 3) {
          rich.add(lines[j]);
          break;
        }
      }
    }
  }
  if (rich.isEmpty) rich = lines.where((l) => l.words.length >= 3).toList();
  if (rich.isEmpty) return const [];
  var minX = double.infinity, maxX = -double.infinity;
  for (final l in rich) {
    minX = math.min(minX, l.words.first.left);
    maxX = math.max(maxX, l.words.map((w) => w.right).reduce(math.max));
  }
  final width = (maxX - minX).ceil() + 1;
  if (width <= 1 || width > 20000) return const [];
  final cover = List.filled(width, 0);
  for (final l in rich) {
    for (final w in l.words) {
      for (var x = (w.left - minX).floor(); x <= (w.right - minX).ceil() && x < width; x++) {
        if (x >= 0) cover[x]++;
      }
    }
  }
  final limit = math.max(1, (rich.length * 0.04).floor());
  final avgH =
      rich.expand((l) => l.words).map((w) => w.height).reduce((a, b) => a + b) / rich.expand((l) => l.words).length;
  final minGap = math.max(2.0, avgH * 0.6);
  final bounds = <double>[];
  var start = -1;
  for (var x = 0; x <= width; x++) {
    final empty = x < width && cover[x] < limit;
    if (empty && start < 0) start = x;
    if (!empty && start >= 0) {
      if (start > 0 && x < width && x - start >= minGap) bounds.add(minX + (start + x) / 2);
      start = -1;
    }
  }
  return bounds;
}
