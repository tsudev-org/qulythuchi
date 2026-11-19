import 'package:meta/meta.dart';

import '../money/currency.dart';
import '../money/money.dart';
import 'civil_date.dart';
import 'models.dart';

/// Phép tính sổ sách thuần (không trạng thái). Số dư KHÔNG lưu - luôn tính từ giao dịch (ADR-0004).
abstract final class Ledger {
  /// Số dư ví tới hết ngày [asOf] (null = mọi giao dịch).
  static Money walletBalance(Wallet wallet, Iterable<Txn> txns, {CivilDate? asOf}) {
    var total = Money(wallet.openingBalance, wallet.currency);
    for (final t in txns) {
      if (t.walletId != wallet.id) continue;
      if (asOf != null && t.date > asOf) continue;
      total += Money(t.balanceEffect, wallet.currency);
    }
    return total;
  }

  /// Hạn mức còn lại của thẻ tín dụng = hạn mức + số dư (số dư âm khi đang nợ).
  static Money? creditAvailable(Wallet wallet, Iterable<Txn> txns) {
    if (wallet.type != WalletType.credit || wallet.creditLimit == null) return null;
    return Money(wallet.creditLimit!, wallet.currency) + walletBalance(wallet, txns);
  }

  /// Tập id danh mục gồm các danh mục được chọn và mọi danh mục con cháu.
  static Set<String> withDescendants(Iterable<Category> categories, Iterable<String> ids) {
    final children = <String, List<String>>{};
    for (final c in categories) {
      if (c.parentId != null) (children[c.parentId!] ??= []).add(c.id);
    }
    final result = <String>{};
    final stack = [...ids];
    while (stack.isNotEmpty) {
      final id = stack.removeLast();
      if (result.add(id)) stack.addAll(children[id] ?? const []);
    }
    return result;
  }

  /// Kỳ ngân sách chứa ngày [day].
  static DateRange budgetRange(Budget b, CivilDate day) {
    switch (b.period) {
      case BudgetPeriod.custom:
        final start = b.customStart ?? day;
        return DateRange(start, b.customEnd ?? start);
      case BudgetPeriod.weekly:
        final startWeekday = b.startDay.clamp(1, 7);
        final back = (day.weekday - startWeekday) % 7;
        final start = day.addDays(-back);
        return DateRange(start, start.addDays(6));
      case BudgetPeriod.yearly:
        return DateRange(CivilDate(day.year, 1, 1), CivilDate(day.year, 12, 31));
      case BudgetPeriod.monthly:
        final want = b.startDay.clamp(1, 31);
        CivilDate startOf(int y, int m) {
          final last = CivilDate.daysInMonth(y, m);
          return CivilDate(y, m, want > last ? last : want);
        }
        var start = startOf(day.year, day.month);
        if (day < start) {
          final prev = CivilDate(day.year, day.month, 1).addMonths(-1);
          start = startOf(prev.year, prev.month);
        }
        final nextMonth = CivilDate(start.year, start.month, 1).addMonths(1);
        return DateRange(start, startOf(nextMonth.year, nextMonth.month).addDays(-1));
    }
  }

  static int _spentIn(Budget b, DateRange range, Iterable<Txn> txns, Set<String>? categoryIds, Set<String> walletIds) {
    var spent = 0;
    for (final t in txns) {
      if (t.pending || t.excludeFromReports || !range.contains(t.date) || !walletIds.contains(t.walletId)) continue;
      if (categoryIds != null && (t.categoryId == null || !categoryIds.contains(t.categoryId))) continue;
      if (t.kind == TxnKind.expense) spent += t.amount;
      if (t.kind == TxnKind.income && categoryIds != null) spent -= t.amount; // hoàn tiền vào đúng danh mục
    }
    return spent;
  }

  /// Tình trạng ngân sách trong kỳ chứa [today]. Chỉ tính ví cùng tiền tệ với ngân sách.
  static BudgetStatus budgetStatus(
    Budget b, {
    required Iterable<Txn> txns,
    required Iterable<Category> categories,
    required Iterable<Wallet> wallets,
    required CivilDate today,
  }) {
    final range = budgetRange(b, today);
    final walletIds = {
      for (final w in wallets)
        if (w.currency == b.currency && (b.walletIds.isEmpty || b.walletIds.contains(w.id))) w.id,
    };
    final categoryIds = b.categoryIds.isEmpty ? null : withDescendants(categories, b.categoryIds);
    final txnList = txns.toList();
    final spent = _spentIn(b, range, txnList, categoryIds, walletIds);
    var carried = 0;
    if (b.rollover && b.period != BudgetPeriod.custom) {
      final prev = budgetRange(b, range.start.addDays(-1));
      carried = b.amount - _spentIn(b, prev, txnList, categoryIds, walletIds);
    }
    return BudgetStatus(
      range: range,
      limit: Money(b.amount + carried, b.currency),
      spent: Money(spent, b.currency),
      alertAtBp: b.alertAtBp,
      today: today,
    );
  }

  /// Số tiền đã trả/thu của khoản nợ và số còn lại.
  static DebtStatus debtStatus(Debt d, Wallet wallet, Iterable<Txn> txns) {
    var paid = 0;
    for (final t in txns) {
      if (t.debtId != d.id || t.pending) continue;
      final isRepayment = d.kind == DebtKind.lend ? t.kind == TxnKind.income : t.kind == TxnKind.expense;
      if (isRepayment) paid += t.amount;
    }
    final remaining = d.principal - paid;
    return DebtStatus(
      paid: Money(paid, wallet.currency),
      remaining: Money(remaining < 0 ? 0 : remaining, wallet.currency),
    );
  }

  /// Tiến độ mục tiêu: số đã góp và mức cần góp mỗi tháng để kịp hạn.
  static GoalStatus goalStatus(Goal g, Iterable<Txn> txns, CivilDate today) {
    var saved = g.startingAmount;
    for (final t in txns) {
      if (t.goalId != g.id || t.pending) continue;
      saved += switch (t.kind) {
        TxnKind.income || TxnKind.transferIn => t.amount,
        TxnKind.expense || TxnKind.transferOut => -t.amount,
        TxnKind.adjustment => t.amount,
      };
    }
    final remaining = g.target - saved;
    int? perMonth;
    if (g.deadline != null && remaining > 0) {
      final months = (g.deadline!.year - today.year) * 12 + (g.deadline!.month - today.month) + 1;
      perMonth = months <= 0 ? remaining : (remaining + months - 1) ~/ months;
    }
    return GoalStatus(
      saved: Money(saved, g.currency),
      remaining: Money(remaining < 0 ? 0 : remaining, g.currency),
      progressBp: g.target <= 0 ? 10000 : (saved * 10000 ~/ g.target).clamp(0, 10000),
      monthlyNeeded: perMonth == null ? null : Money(perMonth, g.currency),
    );
  }

  /// Tóm tắt một kỳ cho các ví [wallets], gộp theo tiền tệ: số dư đầu kỳ (= cuối kỳ trước, tức số dư được CHUYỂN
  /// sang), thu, chi, chuyển ví ròng, điều chỉnh, cuối kỳ. Giao dịch chờ xác nhận không tính. Chuyển giữa hai ví cùng
  /// nằm trong [wallets] triệt tiêu nhau (chỉ còn phí).
  static List<PeriodSummary> periodSummary(Iterable<Wallet> wallets, Iterable<Txn> txns, DateRange range) {
    final byId = {for (final w in wallets) w.id: w};
    final acc = <Currency, _PeriodAcc>{};
    for (final w in byId.values) {
      (acc[w.currency] ??= _PeriodAcc()).opening += w.openingBalance;
    }
    for (final t in txns) {
      final w = byId[t.walletId];
      if (w == null || t.pending) continue;
      final a = acc[w.currency]!;
      if (t.date < range.start) {
        a.opening += t.balanceEffect;
        continue;
      }
      if (t.date > range.end) continue;
      switch (t.kind) {
        case TxnKind.income:
          a.income += t.amount;
          a.withheld += t.taxWithheld;
        case TxnKind.expense:
          a.expense += t.amount;
        case TxnKind.transferIn:
          a.transfer += t.amount;
        case TxnKind.transferOut:
          a.transfer -= t.amount;
          a.fees += t.fee;
        case TxnKind.adjustment:
          a.adjustment += t.amount;
      }
    }
    return [
      for (final MapEntry(key: c, value: a) in acc.entries)
        PeriodSummary(
          range: range,
          currency: c,
          opening: Money(a.opening, c),
          income: Money(a.income, c),
          expense: Money(a.expense, c),
          transferNet: Money(a.transfer, c),
          fees: Money(a.fees, c),
          adjustment: Money(a.adjustment, c),
          taxWithheld: Money(a.withheld, c),
        ),
    ];
  }

  /// Tiến độ khoản thu nhiều đợt, tính từ các giao dịch thu có `incomePlanId` = [p.id].
  static IncomePlanProgress incomePlanProgress(IncomePlan p, Iterable<Txn> txns, CivilDate today) {
    final receipts = [
      for (final t in txns)
        if (t.incomePlanId == p.id && t.kind == TxnKind.income && !t.pending) t,
    ]..sort((a, b) => a.date.compareTo(b.date));
    var net = 0, withheld = 0;
    for (final t in receipts) {
      net += t.amount;
      withheld += t.taxWithheld;
    }
    final gross = net + withheld;
    // Đợt dự kiến: lần lượt "trả" bằng số đã nhận (trước thuế), đợt đầu tiên chưa đủ là đợt kế tiếp.
    var cover = gross;
    PlannedInstallment? next;
    var overdue = 0;
    for (final i in p.installments) {
      if (cover >= i.amount) {
        cover -= i.amount;
        continue;
      }
      next ??= i;
      if (i.date < today) overdue += i.amount - cover;
      cover = 0;
    }
    final remaining = p.total <= 0 ? 0 : (p.total - gross).clamp(0, p.total);
    return IncomePlanProgress(
      receipts: receipts,
      received: Money(net, p.currency),
      withheld: Money(withheld, p.currency),
      gross: Money(gross, p.currency),
      remaining: Money(remaining, p.currency),
      progressBp: p.total <= 0 ? null : (gross * 10000 ~/ p.total).clamp(0, 10000),
      nextInstallment: next,
      overdue: Money(overdue, p.currency),
    );
  }

  /// "Cộng thu": tổng thu trong [range] gộp theo [key] (người trả, danh mục, khoản thu...), theo tiền tệ ví.
  /// Trả danh sách giảm dần theo số tiền thực nhận.
  static List<IncomeGroup> incomeBy(
    Iterable<Wallet> wallets,
    Iterable<Txn> txns,
    DateRange range,
    String? Function(Txn) key,
  ) {
    final cur = {for (final w in wallets) w.id: w.currency};
    final groups = <(String?, Currency), _IncomeAcc>{};
    for (final t in txns) {
      final c = cur[t.walletId];
      if (c == null || t.kind != TxnKind.income || t.pending || t.excludeFromReports || !range.contains(t.date)) {
        continue;
      }
      final a = groups[(key(t), c)] ??= _IncomeAcc();
      a.net += t.amount;
      a.withheld += t.taxWithheld;
      a.count++;
      if (a.last == null || t.date > a.last!) a.last = t.date;
    }
    final out = [
      for (final MapEntry(key: (k, c), value: a) in groups.entries)
        IncomeGroup(
          key: k,
          received: Money(a.net, c),
          withheld: Money(a.withheld, c),
          count: a.count,
          lastDate: a.last!,
        ),
    ]..sort((a, b) => b.received.minor.compareTo(a.received.minor));
    return out;
  }

  /// Tổng chi theo danh mục trong khoảng ngày (cho báo cáo), chỉ các ví trong [walletIds].
  static Map<String?, int> expenseByCategory(Iterable<Txn> txns, DateRange range, Set<String> walletIds) {
    final result = <String?, int>{};
    for (final t in txns) {
      if (t.kind != TxnKind.expense || t.pending || t.excludeFromReports) continue;
      if (!range.contains(t.date) || !walletIds.contains(t.walletId)) continue;
      result[t.categoryId] = (result[t.categoryId] ?? 0) + t.amount;
    }
    return result;
  }
}

enum BudgetState { ok, warning, over }

@immutable
final class BudgetStatus {
  const BudgetStatus({
    required this.range,
    required this.limit,
    required this.spent,
    required this.alertAtBp,
    required this.today,
  });

  final DateRange range;
  final Money limit;
  final Money spent;
  final int alertAtBp;
  final CivilDate today;

  Money get remaining => limit - spent;
  int get usedBp => limit.isZero ? (spent.isPositive ? 10000 : 0) : spent.basisPointsOf(limit);

  BudgetState get state {
    if (spent > limit) return BudgetState.over;
    if (usedBp >= alertAtBp) return BudgetState.warning;
    return BudgetState.ok;
  }

  /// Mức được tiêu mỗi ngày còn lại của kỳ để không vượt ngân sách.
  Money get dailyAllowance {
    final daysLeft = today.daysUntil(range.end) + 1;
    if (daysLeft <= 0 || !remaining.isPositive) return Money.zero(limit.currency);
    return Money(remaining.minor ~/ daysLeft, limit.currency);
  }
}

@immutable
final class DebtStatus {
  const DebtStatus({required this.paid, required this.remaining});
  final Money paid;
  final Money remaining;
  bool get settled => remaining.isZero;
}

@immutable
final class GoalStatus {
  const GoalStatus({required this.saved, required this.remaining, required this.progressBp, this.monthlyNeeded});
  final Money saved;
  final Money remaining;
  final int progressBp;
  final Money? monthlyNeeded;
}

final class _PeriodAcc {
  int opening = 0, income = 0, expense = 0, transfer = 0, fees = 0, adjustment = 0, withheld = 0;
}

final class _IncomeAcc {
  int net = 0, withheld = 0, count = 0;
  CivilDate? last;
}

/// Tóm tắt kỳ của một tiền tệ. `closing = opening + income - expense + transferNet - fees + adjustment`.
@immutable
final class PeriodSummary {
  const PeriodSummary({
    required this.range,
    required this.currency,
    required this.opening,
    required this.income,
    required this.expense,
    required this.transferNet,
    required this.fees,
    required this.adjustment,
    required this.taxWithheld,
  });

  final DateRange range;
  final Currency currency;

  /// Số dư đầu kỳ = số dư cuối kỳ trước được chuyển sang.
  final Money opening;
  final Money income;
  final Money expense;

  /// Chuyển vào/ra với ví NGOÀI tập đang xem (ròng).
  final Money transferNet;
  final Money fees;
  final Money adjustment;

  /// Thuế TNCN bên trả đã khấu trừ trên các khoản thu của kỳ (không ảnh hưởng số dư).
  final Money taxWithheld;

  /// Chênh lệch thu - chi trong kỳ.
  Money get net => income - expense;
  Money get closing => opening + income - expense + transferNet - fees + adjustment;

  /// Tỉ lệ để dành (phần vạn) = (thu - chi) / thu; null khi không có thu.
  int? get savingRateBp => income.isZero ? null : (net.minor * 10000 ~/ income.minor);
}

@immutable
final class IncomePlanProgress {
  const IncomePlanProgress({
    required this.receipts,
    required this.received,
    required this.withheld,
    required this.gross,
    required this.remaining,
    required this.progressBp,
    required this.nextInstallment,
    required this.overdue,
  });

  /// Các lần đã nhận, cũ trước.
  final List<Txn> receipts;

  /// Thực nhận (sau thuế khấu trừ).
  final Money received;
  final Money withheld;

  /// Thực nhận + thuế khấu trừ - so với tổng thỏa thuận.
  final Money gross;

  /// Còn phải thu theo tổng thỏa thuận (0 nếu không chốt tổng).
  final Money remaining;
  final int? progressBp;
  final PlannedInstallment? nextInstallment;

  /// Phần của các đợt đã quá hạn mà chưa nhận.
  final Money overdue;
}

@immutable
final class IncomeGroup {
  const IncomeGroup({
    required this.key,
    required this.received,
    required this.withheld,
    required this.count,
    required this.lastDate,
  });
  final String? key;
  final Money received;
  final Money withheld;
  final int count;
  final CivilDate lastDate;
}
