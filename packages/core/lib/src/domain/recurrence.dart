import 'package:meta/meta.dart';

import '../sync/sync_record.dart';
import 'civil_date.dart';
import 'models.dart';

enum Frequency { daily, weekly, monthly, yearly }

/// Quy tắc lặp (tập con RRULE): FREQ, INTERVAL, BYDAY (tuần), BYMONTHDAY (tháng, -1 = ngày cuối), COUNT, UNTIL.
/// Ngày vượt cuối tháng được kẹp về ngày cuối tháng (31 ⇒ 30/4, 28 hoặc 29/2).
@immutable
final class RecurrenceRule {
  RecurrenceRule({
    required this.frequency,
    required this.start,
    this.interval = 1,
    this.weekdays = const [],
    this.monthDay,
    this.count,
    this.until,
  }) {
    if (interval < 1 || interval > 366) throw ArgumentError.value(interval, 'interval');
    if (weekdays.any((d) => d < 1 || d > 7)) throw ArgumentError.value(weekdays, 'weekdays');
    if (monthDay != null && (monthDay! == 0 || monthDay! < -1 || monthDay! > 31)) {
      throw ArgumentError.value(monthDay, 'monthDay');
    }
    if (count != null && count! < 1) throw ArgumentError.value(count, 'count');
  }

  final Frequency frequency;
  final CivilDate start;
  final int interval;
  final List<int> weekdays;
  final int? monthDay;
  final int? count;
  final CivilDate? until;

  static const _maxIterations = 100000;

  CivilDate _monthly(CivilDate anchor, int monthsAhead) {
    final base = anchor.addMonths(monthsAhead, preferredDay: 1);
    final want = monthDay ?? start.day;
    final last = CivilDate.daysInMonth(base.year, base.month);
    final day = want == -1 ? last : (want > last ? last : want);
    return CivilDate(base.year, base.month, day);
  }

  /// Toàn bộ lần xuất hiện (theo thứ tự) nằm trong [range].
  List<CivilDate> occurrences(DateRange range) {
    final result = <CivilDate>[];
    var produced = 0;
    bool accept(CivilDate d) {
      if (d < start) return true;
      if (until != null && d > until!) return false;
      if (count != null && produced >= count!) return false;
      produced++;
      if (range.contains(d)) result.add(d);
      return d <= range.end;
    }

    switch (frequency) {
      case Frequency.daily:
        for (var i = 0; i < _maxIterations; i++) {
          if (!accept(start.addDays(i * interval))) break;
        }
      case Frequency.weekly:
        final days = weekdays.isEmpty ? [start.weekday] : ([...weekdays]..sort());
        final weekStart = start.addDays(1 - start.weekday);
        outer:
        for (var w = 0; w < _maxIterations; w++) {
          final monday = weekStart.addDays(w * 7 * interval);
          for (final d in days) {
            if (!accept(monday.addDays(d - 1))) break outer;
          }
        }
      case Frequency.monthly:
        for (var i = 0; i < _maxIterations; i++) {
          if (!accept(_monthly(start, i * interval))) break;
        }
      case Frequency.yearly:
        for (var i = 0; i < _maxIterations; i++) {
          if (!accept(start.addMonths(i * 12 * interval))) break;
        }
    }
    return result;
  }

  /// Lần xuất hiện kế tiếp vào hoặc sau [from], nếu còn.
  CivilDate? nextOnOrAfter(CivilDate from) {
    final found = occurrences(DateRange(from, from.addDays(366 * interval + 7)));
    return found.isEmpty ? null : found.first;
  }

  Map<String, Object?> toJson() => {
    'freq': frequency.name,
    'start': start.toString(),
    'interval': interval,
    'weekdays': weekdays,
    'monthDay': monthDay,
    'count': count,
    'until': until?.toString(),
  };

  static RecurrenceRule fromJson(Map<String, Object?> j) => RecurrenceRule(
    frequency: Frequency.values.byName(j['freq']! as String),
    start: CivilDate.parse(j['start']! as String),
    interval: j['interval'] as int? ?? 1,
    weekdays: [for (final d in (j['weekdays'] as List? ?? const [])) d as int],
    monthDay: j['monthDay'] as int?,
    count: j['count'] as int?,
    until: j['until'] == null ? null : CivilDate.parse(j['until']! as String),
  );
}

/// Giao dịch định kỳ / hóa đơn: mẫu giao dịch + quy tắc lặp.
@immutable
final class Recurring {
  const Recurring({
    required this.id,
    required this.walletId,
    required this.name,
    required this.kind,
    required this.amount,
    required this.rule,
    this.categoryId,
    this.note,
    this.isBill = false,
    this.autoCreate = false,
    this.remindDaysBefore = 1,
    this.generatedThrough,
    this.paused = false,
  });

  final String id;
  final String walletId;
  final String name;
  final TxnKind kind;
  final int amount;
  final RecurrenceRule rule;
  final String? categoryId;
  final String? note;

  /// Hóa đơn: hiện trong lịch hóa đơn và nhắc trước hạn.
  final bool isBill;

  /// true: tự tạo giao dịch; false: tạo giao dịch chờ xác nhận.
  final bool autoCreate;
  final int remindDaysBefore;

  /// Đã sinh giao dịch tới hết ngày này.
  final CivilDate? generatedThrough;
  final bool paused;

  /// Các ngày cần sinh giao dịch, tính tới [today] (bao gồm).
  List<CivilDate> dueThrough(CivilDate today) {
    if (paused) return const [];
    final from = generatedThrough?.addDays(1) ?? rule.start;
    if (from > today) return const [];
    return rule.occurrences(DateRange(from, today));
  }

  /// Tạo các giao dịch đến hạn. [newId] sinh UUID cho từng giao dịch.
  List<Txn> materialize(CivilDate today, String Function() newId) => [
    for (final d in dueThrough(today))
      Txn(
        id: newId(),
        walletId: walletId,
        kind: kind,
        amount: amount,
        date: d,
        categoryId: categoryId,
        note: note ?? name,
        recurringId: id,
        source: TxnSource.recurring,
        pending: !autoCreate,
      ),
  ];

  /// Cần nhắc hôm nay? (có lần đến hạn trong [remindDaysBefore] ngày tới)
  CivilDate? reminderFor(CivilDate today) {
    if (paused) return null;
    final next = rule.nextOnOrAfter(today);
    if (next == null) return null;
    return today.daysUntil(next) <= remindDaysBefore ? next : null;
  }

  Map<String, Object?> toValues() => {
    'name': name,
    'kind': kind.name,
    'amount': amount,
    'rule': rule.toJson(),
    'categoryId': categoryId,
    'note': note,
    'isBill': isBill,
    'autoCreate': autoCreate,
    'remindDaysBefore': remindDaysBefore,
    'generatedThrough': generatedThrough?.toString(),
    'paused': paused,
  };

  static Recurring fromRecord(SyncRecord r) {
    final v = r.values;
    return Recurring(
      id: r.id,
      walletId: r.walletId ?? '',
      name: v['name'] as String? ?? '',
      kind: TxnKind.values.asNameMap()[v['kind']] ?? TxnKind.expense,
      amount: v['amount'] as int? ?? 0,
      rule: RecurrenceRule.fromJson((v['rule']! as Map).cast<String, Object?>()),
      categoryId: v['categoryId'] as String?,
      note: v['note'] as String?,
      isBill: v['isBill'] == true,
      autoCreate: v['autoCreate'] == true,
      remindDaysBefore: v['remindDaysBefore'] as int? ?? 1,
      generatedThrough: v['generatedThrough'] == null ? null : CivilDate.parse(v['generatedThrough']! as String),
      paused: v['paused'] == true,
    );
  }
}
