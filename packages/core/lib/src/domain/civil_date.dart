import 'package:meta/meta.dart';

/// Ngày lịch không có giờ và múi giờ (giao dịch ghi theo ngày người dùng thấy).
@immutable
final class CivilDate implements Comparable<CivilDate> {
  CivilDate(this.year, this.month, this.day) {
    if (year < 1900 || year > 9999 || month < 1 || month > 12 || day < 1 || day > daysInMonth(year, month)) {
      throw ArgumentError('Ngày không hợp lệ: $year-$month-$day');
    }
  }

  factory CivilDate.fromDateTime(DateTime dt) => CivilDate(dt.year, dt.month, dt.day);

  /// Đọc `YYYY-MM-DD`.
  factory CivilDate.parse(String iso) {
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(iso);
    if (m == null) throw FormatException('Ngày phải dạng YYYY-MM-DD', iso);
    return CivilDate(int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!));
  }

  final int year;
  final int month;
  final int day;

  static bool isLeap(int y) => (y % 4 == 0 && y % 100 != 0) || y % 400 == 0;

  static int daysInMonth(int y, int m) =>
      const [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][m - 1] + (m == 2 && isLeap(y) ? 1 : 0);

  DateTime get _utc => DateTime.utc(year, month, day);

  /// Thứ trong tuần theo ISO: 1 = Thứ Hai ... 7 = Chủ Nhật.
  int get weekday => _utc.weekday;

  CivilDate addDays(int days) => CivilDate.fromDateTime(_utc.add(Duration(days: days)));

  /// Cộng tháng, ngày vượt cuối tháng thì kẹp về ngày cuối (31/1 + 1 tháng = 28 hoặc 29/2).
  CivilDate addMonths(int months, {int? preferredDay}) {
    final total = year * 12 + (month - 1) + months;
    final y = total ~/ 12;
    final m = total % 12 + 1;
    final want = preferredDay ?? day;
    final d = want > daysInMonth(y, m) ? daysInMonth(y, m) : want;
    return CivilDate(y, m, d);
  }

  int daysUntil(CivilDate other) => other._utc.difference(_utc).inDays;

  @override
  int compareTo(CivilDate other) => _utc.compareTo(other._utc);

  bool operator <(CivilDate o) => compareTo(o) < 0;
  bool operator <=(CivilDate o) => compareTo(o) <= 0;
  bool operator >(CivilDate o) => compareTo(o) > 0;
  bool operator >=(CivilDate o) => compareTo(o) >= 0;

  @override
  bool operator ==(Object other) =>
      other is CivilDate && other.year == year && other.month == month && other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

/// Khoảng ngày đóng hai đầu [start, end].
@immutable
final class DateRange {
  DateRange(this.start, this.end) {
    if (end < start) throw ArgumentError('Ngày kết thúc trước ngày bắt đầu');
  }
  final CivilDate start;
  final CivilDate end;

  bool contains(CivilDate d) => d >= start && d <= end;
  int get days => start.daysUntil(end) + 1;

  @override
  bool operator ==(Object other) => other is DateRange && other.start == start && other.end == end;
  @override
  int get hashCode => Object.hash(start, end);
  @override
  String toString() => '$start..$end';
}
