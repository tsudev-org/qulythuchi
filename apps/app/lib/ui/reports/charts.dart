import 'dart:math' as math;

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../widgets/common.dart';

/// Số gọn cho trục: vi "1,5tr" / "500k"; en "1.5M" / "500K". Chỉ để đọc trục, số chính xác ở phần đọc/bảng.
String compactMoney(Money m, AppLocale locale) {
  final major = m.minor.abs() / _pow10(m.currency.minorDigits);
  final sign = m.isNegative ? '-' : '';
  String fmt(double v, String unit) {
    final s = v >= 10 ? v.round().toString() : v.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    return '$sign${locale == AppLocale.vi ? s.replaceAll('.', ',') : s}$unit';
  }

  if (major >= 1e9) return fmt(major / 1e9, locale == AppLocale.vi ? 'tỷ' : 'B');
  if (major >= 1e6) return fmt(major / 1e6, locale == AppLocale.vi ? 'tr' : 'M');
  if (major >= 1e3) return fmt(major / 1e3, locale == AppLocale.vi ? 'k' : 'K');
  return fmt(major, '');
}

int _pow10(int n) => n == 0 ? 1 : 10 * _pow10(n - 1);

/// Mốc trục "đẹp" (0, bước 1/2/5 × 10^n) phủ [0, maxMinor].
List<int> niceTicks(int maxMinor, {int count = 4}) {
  if (maxMinor <= 0) return [0];
  final raw = maxMinor / count;
  final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
  final step = [1, 2, 5, 10].map((f) => f * mag).firstWhere((s) => s >= raw).round();
  return [for (var v = 0; v <= maxMinor + step - 1; v += step) v];
}

/// Thẻ biểu đồ: tiêu đề, phần đọc số đang chọn, biểu đồ hoặc bảng (bật/tắt).
class ChartCard extends StatefulWidget {
  const ChartCard({super.key, required this.title, required this.chart, required this.table, this.legend});
  final String title;
  final Widget chart;
  final Widget table;
  final Widget? legend;

  @override
  State<ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<ChartCard> {
  bool _table = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(QtSpace.s4, QtSpace.s2, QtSpace.s2, QtSpace.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
                  ),
                ),
                IconButton(
                  tooltip: _table ? l.reportShowChart : l.reportShowTable,
                  icon: Icon(_table ? Icons.bar_chart : Icons.table_rows_outlined),
                  onPressed: () => setState(() => _table = !_table),
                ),
              ],
            ),
            if (widget.legend != null && !_table) ...[widget.legend!, const SizedBox(height: QtSpace.s2)],
            Padding(
              padding: const EdgeInsets.only(right: QtSpace.s2),
              child: _table ? widget.table : widget.chart,
            ),
          ],
        ),
      ),
    );
  }
}

/// Chú giải: ô màu + chữ (chữ dùng màu chữ, không dùng màu chuỗi).
class ChartLegend extends StatelessWidget {
  const ChartLegend({super.key, required this.items});
  final List<(Color, String)> items;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: QtSpace.s4,
    runSpacing: QtSpace.s1,
    children: [
      for (final (color, label) in items)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(width: QtSpace.s1),
            Text(
              label,
              style: TextStyle(color: context.palette.textSecondary, fontSize: QtFontSize.sm),
            ),
          ],
        ),
    ],
  );
}

/// Bảng dữ liệu thay thế cho biểu đồ (trình đọc màn hình, in, mù màu).
class DataTableView extends StatelessWidget {
  const DataTableView({super.key, required this.headers, required this.rows});
  final List<String> headers;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      headingRowHeight: 40,
      dataRowMinHeight: 36,
      dataRowMaxHeight: 44,
      columns: [for (var i = 0; i < headers.length; i++) DataColumn(label: Text(headers[i]), numeric: i > 0)],
      rows: [
        for (final r in rows) DataRow(cells: [for (final c in r) DataCell(Text(c))]),
      ],
    ),
  );
}

/// Chọn mục theo vị trí ngang: chạm (điện thoại) hoặc rê chuột (máy tính); phím trái/phải khi có focus.
class _Scrubber extends StatefulWidget {
  const _Scrubber({required this.count, required this.selected, required this.onSelect, required this.child});
  final int count;
  final int? selected;
  final ValueChanged<int> onSelect;
  final Widget child;

  @override
  State<_Scrubber> createState() => _ScrubberState();
}

class _ScrubberState extends State<_Scrubber> {
  void _at(Offset p, double width) {
    if (widget.count == 0) return;
    widget.onSelect((p.dx / width * widget.count).floor().clamp(0, widget.count - 1));
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => Focus(
      onKeyEvent: (node, e) {
        if (e is! KeyDownEvent) return KeyEventResult.ignored;
        final cur = widget.selected ?? widget.count - 1;
        if (e.logicalKey == LogicalKeyboardKey.arrowLeft) {
          widget.onSelect((cur - 1).clamp(0, widget.count - 1));
          return KeyEventResult.handled;
        }
        if (e.logicalKey == LogicalKeyboardKey.arrowRight) {
          widget.onSelect((cur + 1).clamp(0, widget.count - 1));
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        onHover: (e) => _at(e.localPosition, c.maxWidth),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _at(d.localPosition, c.maxWidth),
          onHorizontalDragUpdate: (d) => _at(d.localPosition, c.maxWidth),
          child: widget.child,
        ),
      ),
    ),
  );
}

/// Cột đôi theo kỳ (thu/chi): một trục, nét mảnh, đầu cột bo 4px nằm trên đường gốc, khe 2px giữa hai cột.
class PairedBarChart extends StatefulWidget {
  const PairedBarChart({
    super.key,
    required this.labels,
    required this.a,
    required this.b,
    required this.readout,
    this.height = 200,
  });

  final List<String> labels;
  final List<Money> a;
  final List<Money> b;

  /// Dòng đọc số cho mục [i].
  final String Function(int i) readout;
  final double height;

  @override
  State<PairedBarChart> createState() => _PairedBarChartState();
}

class _PairedBarChartState extends State<PairedBarChart> {
  int? _sel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = context.chartPalette;
    final n = widget.labels.length;
    final sel = _sel ?? (n == 0 ? null : n - 1);
    final maxV = [...widget.a, ...widget.b].fold<int>(0, (m, x) => math.max(m, x.minor));
    final ticks = niceTicks(maxV);
    final cur = widget.a.isEmpty ? Currency.vnd : widget.a.first.currency;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(sel == null ? '' : widget.readout(sel), style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: QtSpace.s2),
        ExcludeSemantics(
          child: _Scrubber(
            count: n,
            selected: sel,
            onSelect: (i) => setState(() => _sel = i),
            child: SizedBox(
              height: widget.height,
              child: CustomPaint(
                painter: _BarsPainter(
                  a: [for (final m in widget.a) m.minor],
                  b: [for (final m in widget.b) m.minor],
                  labels: widget.labels,
                  ticks: ticks,
                  tickLabel: (v) => compactMoney(Money(v, cur), context.appLocale),
                  colorA: c.series1,
                  colorB: c.series2,
                  grid: p.border,
                  axis: p.borderStrong,
                  text: p.textSecondary,
                  highlight: p.bgHover,
                  selected: sel,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

const _axisLabelWidth = 44.0;
const _bottomLabelHeight = 20.0;

TextPainter _tp(String s, Color color, {double size = QtFontSize.xs}) => TextPainter(
  text: TextSpan(
    text: s,
    style: TextStyle(color: color, fontSize: size, fontFamily: 'Inter'),
  ),
  textDirection: TextDirection.ltr,
)..layout();

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.a,
    required this.b,
    required this.labels,
    required this.ticks,
    required this.tickLabel,
    required this.colorA,
    required this.colorB,
    required this.grid,
    required this.axis,
    required this.text,
    required this.highlight,
    required this.selected,
  });

  final List<int> a;
  final List<int> b;
  final List<String> labels;
  final List<int> ticks;
  final String Function(int) tickLabel;
  final Color colorA, colorB, grid, axis, text, highlight;
  final int? selected;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(_axisLabelWidth, 6, size.width, size.height - _bottomLabelHeight);
    final top = ticks.last == 0 ? 1 : ticks.last;
    double y(int v) => plot.bottom - v / top * plot.height;
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final t in ticks) {
      canvas.drawLine(Offset(plot.left, y(t)), Offset(plot.right, y(t)), gridPaint);
      final tp = _tp(tickLabel(t), text);
      tp.paint(canvas, Offset(plot.left - tp.width - 6, y(t) - tp.height / 2));
    }
    final n = labels.length;
    if (n == 0) return;
    final slot = plot.width / n;
    final barW = math.min(18.0, (slot - 10) / 2 - 1);
    for (var i = 0; i < n; i++) {
      final x0 = plot.left + slot * i;
      if (i == selected) {
        canvas.drawRect(Rect.fromLTWH(x0, plot.top, slot, plot.height), Paint()..color = highlight);
      }
      final cx = x0 + slot / 2;
      for (final (v, color, left) in [(a[i], colorA, cx - 1 - barW), (b[i], colorB, cx + 1)]) {
        if (v <= 0) continue;
        final h = math.max(2.0, plot.bottom - y(v));
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(left, plot.bottom - h, barW, h),
            topLeft: const Radius.circular(4),
            topRight: const Radius.circular(4),
          ),
          Paint()..color = color,
        );
      }
      final tp = _tp(labels[i], text);
      tp.paint(canvas, Offset(cx - tp.width / 2, plot.bottom + 4));
    }
    canvas.drawLine(
      Offset(plot.left, plot.bottom),
      Offset(plot.right, plot.bottom),
      Paint()
        ..color = axis
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_BarsPainter old) => true;
}

/// Đường một chuỗi (tài sản ròng): nét 2px, điểm chọn có đánh dấu ≥ 8px viền nền 2px.
class LineChart extends StatefulWidget {
  const LineChart({super.key, required this.labels, required this.values, required this.readout, this.height = 180});
  final List<String> labels;
  final List<Money> values;
  final String Function(int i) readout;
  final double height;

  @override
  State<LineChart> createState() => _LineChartState();
}

class _LineChartState extends State<LineChart> {
  int? _sel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final n = widget.values.length;
    final sel = _sel ?? (n == 0 ? null : n - 1);
    final minV = widget.values.fold<int>(0, (m, x) => math.min(m, x.minor));
    final maxV = widget.values.fold<int>(0, (m, x) => math.max(m, x.minor));
    final cur = widget.values.isEmpty ? Currency.vnd : widget.values.first.currency;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(sel == null ? '' : widget.readout(sel), style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: QtSpace.s2),
        ExcludeSemantics(
          child: _Scrubber(
            count: n,
            selected: sel,
            onSelect: (i) => setState(() => _sel = i),
            child: SizedBox(
              height: widget.height,
              child: CustomPaint(
                painter: _LinePainter(
                  values: [for (final m in widget.values) m.minor],
                  labels: widget.labels,
                  minV: minV,
                  maxV: maxV,
                  tickLabel: (v) => compactMoney(Money(v, cur), context.appLocale),
                  line: context.chartPalette.series1,
                  surface: p.bgSurface,
                  grid: p.border,
                  axis: p.borderStrong,
                  text: p.textSecondary,
                  selected: sel,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.values,
    required this.labels,
    required this.minV,
    required this.maxV,
    required this.tickLabel,
    required this.line,
    required this.surface,
    required this.grid,
    required this.axis,
    required this.text,
    required this.selected,
  });

  final List<int> values;
  final List<String> labels;
  final int minV, maxV;
  final String Function(int) tickLabel;
  final Color line, surface, grid, axis, text;
  final int? selected;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(_axisLabelWidth, 8, size.width, size.height - _bottomLabelHeight);
    final pos = niceTicks(maxV);
    final neg = minV < 0 ? niceTicks(-minV).map((v) => -v).toList() : <int>[];
    final ticks = {...neg, ...pos}.toList()..sort();
    final lo = ticks.first, hi = ticks.last == lo ? lo + 1 : ticks.last;
    double y(int v) => plot.bottom - (v - lo) / (hi - lo) * plot.height;
    for (final t in ticks) {
      canvas.drawLine(
        Offset(plot.left, y(t)),
        Offset(plot.right, y(t)),
        Paint()
          ..color = t == 0 ? axis : grid
          ..strokeWidth = 1,
      );
      final tp = _tp(tickLabel(t), text);
      tp.paint(canvas, Offset(plot.left - tp.width - 6, y(t) - tp.height / 2));
    }
    final n = values.length;
    if (n == 0) return;
    final slot = plot.width / n;
    Offset at(int i) => Offset(plot.left + slot * i + slot / 2, y(values[i]));
    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < n; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
    for (var i = 0; i < n; i++) {
      final tp = _tp(labels[i], text);
      tp.paint(canvas, Offset(at(i).dx - tp.width / 2, plot.bottom + 4));
    }
    if (selected != null) {
      final c = at(selected!);
      canvas.drawLine(
        Offset(c.dx, plot.top),
        Offset(c.dx, plot.bottom),
        Paint()
          ..color = axis
          ..strokeWidth = 1,
      );
      canvas.drawCircle(c, 6, Paint()..color = surface);
      canvas.drawCircle(c, 4.5, Paint()..color = line);
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => true;
}

/// Thanh ngang một màu (độ lớn), nhãn chữ + giá trị + phần trăm; chạm để xem giao dịch.
class HorizontalBars extends StatelessWidget {
  const HorizontalBars({super.key, required this.rows});

  /// (nhãn, giá trị hiển thị, phần vạn so với hàng lớn nhất, phần trăm của tổng, khi chạm)
  final List<(String, String, int, String, VoidCallback?)> rows;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = context.chartPalette.series1;
    return Column(
      children: [
        for (final (label, value, bp, pct, onTap) in rows)
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(QtRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: QtSpace.s2),
              child: Semantics(
                button: onTap != null,
                label: '$label, $value, $pct',
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
                        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
                        SizedBox(
                          width: 52,
                          child: Text(
                            pct,
                            textAlign: TextAlign.end,
                            style: TextStyle(color: p.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: QtSpace.s1),
                    LayoutBuilder(
                      builder: (context, c) => Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          height: 8,
                          width: math.max(4, c.maxWidth * bp / 10000),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Lịch chi tiêu tháng: ô theo ngày, màu dải tuần tự 5 bậc theo mức chi (ngưỡng phân vị), có số ngày.
class SpendingCalendar extends StatefulWidget {
  const SpendingCalendar({super.key, required this.month, required this.daily, required this.readout});
  final CivilDate month;
  final Map<int, Money> daily;
  final String Function(int day) readout;

  @override
  State<SpendingCalendar> createState() => _SpendingCalendarState();
}

class _SpendingCalendarState extends State<SpendingCalendar> {
  int? _sel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ramp = context.chartPalette.sequential;
    final l = context.l10n;
    final days = CivilDate.daysInMonth(widget.month.year, widget.month.month);
    final lead = CivilDate(widget.month.year, widget.month.month, 1).weekday - 1;
    final values = widget.daily.values.map((m) => m.minor).where((v) => v > 0).toList()..sort();
    int level(int v) {
      if (v <= 0 || values.isEmpty) return -1;
      final rank = values.indexWhere((x) => x >= v);
      return (rank * 5 ~/ values.length).clamp(0, 4);
    }

    final weekdays = [
      l.weekdayShort1,
      l.weekdayShort2,
      l.weekdayShort3,
      l.weekdayShort4,
      l.weekdayShort5,
      l.weekdayShort6,
      l.weekdayShort7,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(
            _sel == null ? l.reportTapDay : widget.readout(_sel!),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: QtSpace.s2),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          children: [
            for (final w in weekdays)
              Center(
                child: Text(
                  w,
                  style: TextStyle(color: p.textSecondary, fontSize: QtFontSize.xs),
                ),
              ),
            for (var i = 0; i < lead; i++) const SizedBox.shrink(),
            for (var d = 1; d <= days; d++)
              Builder(
                builder: (context) {
                  final lv = level(widget.daily[d]?.minor ?? 0);
                  final bg = lv < 0 ? p.bgSubtle : ramp[lv];
                  final fg = bg.computeLuminance() > 0.35 ? QtPalette.light.textPrimary : QtPalette.dark.textPrimary;
                  return Semantics(
                    button: true,
                    label: widget.readout(d),
                    excludeSemantics: true,
                    child: InkWell(
                      onTap: () => setState(() => _sel = d),
                      borderRadius: BorderRadius.circular(QtRadius.sm),
                      child: Container(
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(QtRadius.sm),
                          border: _sel == d ? Border.all(color: p.focusRing, width: 2) : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$d',
                          style: TextStyle(color: fg, fontSize: QtFontSize.sm),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: QtSpace.s2),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              l.reportLess,
              style: TextStyle(color: p.textSecondary, fontSize: QtFontSize.xs),
            ),
            const SizedBox(width: QtSpace.s1),
            for (final c in [p.bgSubtle, ...ramp])
              Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.only(left: 2),
                decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
              ),
            const SizedBox(width: QtSpace.s1),
            Text(
              l.reportMore,
              style: TextStyle(color: p.textSecondary, fontSize: QtFontSize.xs),
            ),
          ],
        ),
      ],
    );
  }
}
