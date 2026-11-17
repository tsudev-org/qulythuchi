import 'package:flutter/foundation.dart' show immutable;
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../state/ledger_repository.dart';

/// Kỳ báo cáo đặt sẵn.
enum ReportPreset { thisMonth, lastMonth, last3Months, thisYear, custom }

DateRange presetRange(ReportPreset p, CivilDate today, {DateRange? custom}) {
  final monthStart = CivilDate(today.year, today.month, 1);
  return switch (p) {
    ReportPreset.thisMonth => DateRange(monthStart, monthStart.addMonths(1).addDays(-1)),
    ReportPreset.lastMonth => DateRange(monthStart.addMonths(-1), monthStart.addDays(-1)),
    ReportPreset.last3Months => DateRange(monthStart.addMonths(-2), monthStart.addMonths(1).addDays(-1)),
    ReportPreset.thisYear => DateRange(CivilDate(today.year, 1, 1), CivilDate(today.year, 12, 31)),
    ReportPreset.custom => custom ?? DateRange(monthStart, today),
  };
}

/// Kỳ liền trước cùng độ dài để so sánh. Kỳ trọn tháng (từ ngày 1 tới cuối tháng) lùi theo số tháng (tháng 3 so
/// với tháng 2 dù khác số ngày); kỳ khác lùi theo số ngày.
DateRange previousRange(DateRange r) {
  final monthAligned = r.start.day == 1 && r.end.addDays(1).day == 1;
  if (monthAligned) {
    final months = (r.end.year - r.start.year) * 12 + r.end.month - r.start.month + 1;
    return DateRange(r.start.addMonths(-months), r.start.addDays(-1));
  }
  return DateRange(r.start.addDays(-r.days), r.start.addDays(-1));
}

/// Thay đổi so với kỳ trước theo phần vạn; null khi kỳ trước bằng 0 (không chia được).
int? changeBp(Money current, Money previous) =>
    previous.isPositive ? (current - previous).basisPointsOf(previous) : null;

@immutable
final class PeriodSummary {
  const PeriodSummary({required this.income, required this.expense, required this.missing});
  final Money income;
  final Money expense;

  /// Tiền tệ có giao dịch nhưng chưa có tỉ giá về tiền tệ báo cáo (bị loại khỏi tổng).
  final Set<Currency> missing;

  Money get net => income - expense;

  /// Tỉ lệ tiết kiệm theo phần vạn (null nếu không có thu).
  int? get savingsRateBp => income.isPositive ? net.basisPointsOf(income) : null;
}

@immutable
final class MonthPoint {
  const MonthPoint(this.month, this.income, this.expense);
  final CivilDate month;
  final Money income;
  final Money expense;
}

@immutable
final class CategoryShare {
  const CategoryShare({required this.categoryId, required this.amount, required this.shareBp});

  /// Id danh mục cấp cha; null = chưa phân loại; [otherId] = gộp "Khác".
  final String? categoryId;
  final Money amount;
  final int shareBp;

  static const otherId = '__other__';
}

/// Phép tính báo cáo trên dữ liệu đã giải mã. Mọi số tiền quy về [base] bằng tỉ giá hiện có (`Money.convert`, không
/// `double`). Giao dịch chờ, giao dịch "không tính báo cáo", chuyển ví và điều chỉnh số dư bị loại khỏi thu/chi.
final class Reports {
  Reports(this.data, this.base);
  final LedgerData data;
  final Currency base;

  final Map<String, Currency?> _walletCurrency = {};

  Currency? _currencyOf(String walletId) =>
      _walletCurrency.putIfAbsent(walletId, () => data.wallet(walletId)?.currency);

  /// Quy đổi số tiền (đơn vị nhỏ nhất của [from]) sang [base]; null nếu thiếu tỉ giá.
  Money? toBase(int minor, Currency from) {
    if (from == base) return Money(minor, base);
    final r = data.rate(from, base);
    return r == null ? null : Money(minor, from).convert(base, r);
  }

  static bool countsAsFlow(Txn t) =>
      !t.pending && !t.excludeFromReports && (t.kind == TxnKind.income || t.kind == TxnKind.expense);

  PeriodSummary summary(DateRange range) {
    var income = Money.zero(base);
    var expense = Money.zero(base);
    final missing = <Currency>{};
    for (final t in data.txns) {
      if (!countsAsFlow(t) || !range.contains(t.date)) continue;
      final cur = _currencyOf(t.walletId);
      if (cur == null) continue;
      final m = toBase(t.amount, cur);
      if (m == null) {
        missing.add(cur);
        continue;
      }
      if (t.kind == TxnKind.income) {
        income += m;
      } else {
        expense += m;
      }
    }
    return PeriodSummary(income: income, expense: expense, missing: missing);
  }

  /// [count] tháng kết thúc ở tháng chứa [last], cũ trước.
  List<MonthPoint> monthly(CivilDate last, int count) {
    final end = CivilDate(last.year, last.month, 1);
    return [
      for (var i = count - 1; i >= 0; i--)
        () {
          final start = end.addMonths(-i);
          final s = summary(DateRange(start, start.addMonths(1).addDays(-1)));
          return MonthPoint(start, s.income, s.expense);
        }(),
    ];
  }

  /// Cơ cấu chi theo danh mục cấp cha, giảm dần; quá [maxRows] thì gộp phần đuôi thành "Khác".
  List<CategoryShare> categoryShares(DateRange range, {int maxRows = 8}) {
    final byParent = <String?, Money>{};
    for (final t in data.txns) {
      if (!countsAsFlow(t) || t.kind != TxnKind.expense || !range.contains(t.date)) continue;
      final cur = _currencyOf(t.walletId);
      final m = cur == null ? null : toBase(t.amount, cur);
      if (m == null) continue;
      final cat = data.category(t.categoryId);
      final key = cat == null ? null : (cat.parentId ?? cat.id);
      byParent[key] = (byParent[key] ?? Money.zero(base)) + m;
    }
    final total = byParent.values.fold(Money.zero(base), (a, b) => a + b);
    final sorted = byParent.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final rows = <CategoryShare>[];
    var other = Money.zero(base);
    for (var i = 0; i < sorted.length; i++) {
      if (i < maxRows - 1 || sorted.length == maxRows) {
        rows.add(
          CategoryShare(
            categoryId: sorted[i].key,
            amount: sorted[i].value,
            shareBp: total.isZero ? 0 : sorted[i].value.basisPointsOf(total),
          ),
        );
      } else {
        other += sorted[i].value;
      }
    }
    if (other.isPositive) {
      rows.add(CategoryShare(categoryId: CategoryShare.otherId, amount: other, shareBp: other.basisPointsOf(total)));
    }
    return rows;
  }

  /// Tài sản ròng (tổng số dư ví tính vào tổng, quy đổi theo tỉ giá hiện có) cuối mỗi tháng.
  List<(CivilDate, Money)> netWorth(CivilDate last, int count) {
    final end = CivilDate(last.year, last.month, 1);
    final wallets = data.wallets.where((w) => !w.excludeFromTotal).toList();
    return [
      for (var i = count - 1; i >= 0; i--)
        () {
          final monthEnd = end.addMonths(-i).addMonths(1).addDays(-1);
          final asOf = monthEnd > last ? last : monthEnd;
          var total = Money.zero(base);
          for (final w in wallets) {
            final m = toBase(Ledger.walletBalance(w, data.txns, asOf: asOf).minor, w.currency);
            if (m != null) total += m;
          }
          return (end.addMonths(-i), total);
        }(),
    ];
  }

  /// Chi tiêu từng ngày trong tháng chứa [month] (ngày 1..n).
  Map<int, Money> dailyExpense(CivilDate month) {
    final start = CivilDate(month.year, month.month, 1);
    final range = DateRange(start, start.addMonths(1).addDays(-1));
    final out = <int, Money>{};
    for (final t in data.txns) {
      if (!countsAsFlow(t) || t.kind != TxnKind.expense || !range.contains(t.date)) continue;
      final cur = _currencyOf(t.walletId);
      final m = cur == null ? null : toBase(t.amount, cur);
      if (m == null) continue;
      out[t.date.day] = (out[t.date.day] ?? Money.zero(base)) + m;
    }
    return out;
  }

  /// "An toàn để tiêu" trong phần còn lại của tháng: thu − chi đã có − hóa đơn chưa trả tới cuối tháng − mức cần góp
  /// cho mục tiêu tháng này. Âm ⇒ đã tiêu quá. [perDay] = phần dương chia đều cho số ngày còn lại (kể cả hôm nay).
  SafeToSpend safeToSpend(CivilDate today) {
    final monthStart = CivilDate(today.year, today.month, 1);
    final monthEnd = monthStart.addMonths(1).addDays(-1);
    final s = summary(DateRange(monthStart, today));
    var bills = Money.zero(base);
    for (final r in data.recurrings) {
      if (r.paused || r.kind != TxnKind.expense) continue;
      final cur = _currencyOf(r.walletId);
      if (cur == null) continue;
      final from = r.generatedThrough?.addDays(1) ?? r.rule.start;
      final start = from > today ? from : today;
      if (start > monthEnd) continue;
      final due = r.rule.occurrences(DateRange(start, monthEnd)).length;
      final m = toBase(r.amount * due, cur);
      if (m != null) bills += m;
    }
    // Giao dịch chờ xác nhận trong tháng cũng là khoản sắp chi.
    for (final t in data.txns) {
      if (!t.pending || t.kind != TxnKind.expense || t.date < monthStart || t.date > monthEnd) continue;
      final cur = _currencyOf(t.walletId);
      final m = cur == null ? null : toBase(t.amount, cur);
      if (m != null) bills += m;
    }
    var goals = Money.zero(base);
    for (final g in data.goals) {
      if (g.achieved) continue;
      final need = Ledger.goalStatus(g, data.txns, today).monthlyNeeded;
      final m = need == null ? null : toBase(need.minor, g.currency);
      if (m != null) goals += m;
    }
    final amount = s.income - s.expense - bills - goals;
    final daysLeft = today.daysUntil(monthEnd) + 1;
    return SafeToSpend(
      amount: amount,
      perDay: amount.isPositive ? Money(amount.minor ~/ daysLeft, base) : Money.zero(base),
      income: s.income,
      spent: s.expense,
      upcomingBills: bills,
      goals: goals,
    );
  }
}

@immutable
final class SafeToSpend {
  const SafeToSpend({
    required this.amount,
    required this.perDay,
    required this.income,
    required this.spent,
    required this.upcomingBills,
    required this.goals,
  });
  final Money amount;
  final Money perDay;
  final Money income;
  final Money spent;
  final Money upcomingBills;
  final Money goals;
}
