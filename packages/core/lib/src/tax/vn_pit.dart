import 'package:meta/meta.dart';

import '../domain/civil_date.dart';
import '../domain/models.dart';

/// Một bậc thuế lũy tiến THEO THÁNG: phần thu nhập tính thuế tới [upTo] (VND; null = không giới hạn) chịu [rateBp].
@immutable
final class PitBracket {
  const PitBracket(this.upTo, this.rateBp);
  final int? upTo;

  /// Thuế suất, phần vạn (500 = 5%).
  final int rateBp;
}

/// Bộ quy tắc thuế TNCN Việt Nam áp dụng cho một kỳ tính thuế (năm). Mọi số tiền là VND.
///
/// CHỈ ĐỂ THAM KHẢO: app ước tính, không thay tư vấn thuế. Số liệu có [source] và [verifiedOn]; khi văn bản mới ban
/// hành, thêm bộ quy tắc MỚI với [fromYear] mới thay vì sửa bộ cũ (quyết toán năm cũ vẫn dùng quy tắc cũ).
@immutable
final class VnPitRules {
  const VnPitRules({
    required this.fromYear,
    required this.personalDeduction,
    required this.dependentDeduction,
    required this.brackets,
    required this.casualWithholdingThreshold,
    required this.casualWithholdingBp,
    required this.businessExemptRevenue,
    required this.insuranceRateBp,
    required this.insuranceSalaryCap,
    required this.nonResidentRateBp,
    required this.source,
    required this.verifiedOn,
  });

  /// Áp dụng từ kỳ tính thuế (năm) này.
  final int fromYear;

  /// Giảm trừ bản thân mỗi tháng.
  final int personalDeduction;

  /// Giảm trừ mỗi người phụ thuộc mỗi tháng.
  final int dependentDeduction;
  final List<PitBracket> brackets;

  /// Thu nhập vãng lai mỗi lần chi trả từ mức này trở lên bị khấu trừ [casualWithholdingBp].
  final int casualWithholdingThreshold;
  final int casualWithholdingBp;

  /// Doanh thu năm của hộ/cá nhân kinh doanh từ mức này trở xuống không phải nộp thuế TNCN.
  final int businessExemptRevenue;

  /// Tỉ lệ bảo hiểm bắt buộc người lao động đóng (BHXH 8% + BHYT 1,5% + BHTN 1%).
  final int insuranceRateBp;

  /// Mức lương tối đa làm căn cứ đóng BHXH/BHYT (20 lần lương cơ sở) - ước tính.
  final int insuranceSalaryCap;

  /// Cá nhân không cư trú: thuế suất toàn phần trên tiền lương.
  final int nonResidentRateBp;
  final String source;
  final String verifiedOn;

  /// Bộ quy tắc cho kỳ tính thuế [year] (bộ mới nhất có `fromYear <= year`).
  static VnPitRules forYear(int year) {
    var best = all.first;
    for (final r in all) {
      if (r.fromYear <= year && r.fromYear >= best.fromYear) best = r;
    }
    return best;
  }

  /// Từ cũ tới mới.
  static const all = [rules2020, rules2026];

  /// Nghị quyết 954/2020/UBTVQH14 (giảm trừ 11 triệu/4,4 triệu), biểu 7 bậc của Luật Thuế TNCN 2007 (sửa đổi 2012).
  static const rules2020 = VnPitRules(
    fromYear: 2020,
    personalDeduction: 11000000,
    dependentDeduction: 4400000,
    brackets: [
      PitBracket(5000000, 500),
      PitBracket(10000000, 1000),
      PitBracket(18000000, 1500),
      PitBracket(32000000, 2000),
      PitBracket(52000000, 2500),
      PitBracket(80000000, 3000),
      PitBracket(null, 3500),
    ],
    casualWithholdingThreshold: 2000000,
    casualWithholdingBp: 1000,
    businessExemptRevenue: 100000000,
    insuranceRateBp: 1050,
    insuranceSalaryCap: 46800000,
    nonResidentRateBp: 2000,
    source: 'Luật Thuế TNCN 2007 (sửa đổi 2012, 2014); Nghị quyết 954/2020/UBTVQH14; Thông tư 111/2013/TT-BTC',
    verifiedOn: '2026-11-19',
  );

  /// Luật Thuế TNCN số 109/2025/QH15 (thông qua 10/12/2025): biểu 5 bậc, giảm trừ 15,5 triệu/6,2 triệu áp dụng cho
  /// tiền lương từ kỳ tính thuế 2026; ngưỡng doanh thu hộ kinh doanh 500 triệu/năm; Nghị định 253/2026/NĐ-CP nâng
  /// ngưỡng khấu trừ vãng lai lên 5 triệu/lần.
  static const rules2026 = VnPitRules(
    fromYear: 2026,
    personalDeduction: 15500000,
    dependentDeduction: 6200000,
    brackets: [
      PitBracket(10000000, 500),
      PitBracket(30000000, 1000),
      PitBracket(60000000, 2000),
      PitBracket(100000000, 3000),
      PitBracket(null, 3500),
    ],
    casualWithholdingThreshold: 5000000,
    casualWithholdingBp: 1000,
    businessExemptRevenue: 500000000,
    insuranceRateBp: 1050,
    insuranceSalaryCap: 46800000,
    nonResidentRateBp: 2000,
    source: 'Luật Thuế TNCN 109/2025/QH15; Nghị quyết 110/2025/UBTVQH15; Nghị định 253/2026/NĐ-CP',
    verifiedOn: '2026-11-19',
  );

  /// Giảm trừ gia cảnh mỗi tháng.
  int familyDeduction(int dependents) => personalDeduction + dependentDeduction * dependents;

  /// Bảo hiểm bắt buộc ước tính mỗi tháng từ lương đóng bảo hiểm [salary].
  int estimatedInsurance(int salary) {
    final base = salary > insuranceSalaryCap ? insuranceSalaryCap : salary;
    return _bp(base, insuranceRateBp);
  }

  /// Thuế lũy tiến trên thu nhập tính thuế của MỘT tháng.
  int progressiveMonthly(int taxable) => _progressive(taxable, 1);

  /// Thuế lũy tiến trên thu nhập tính thuế cả NĂM (biểu tháng nhân 12 - cách quyết toán).
  int progressiveYearly(int taxable) => _progressive(taxable, 12);

  int _progressive(int taxable, int months) {
    if (taxable <= 0) return 0;
    var tax = 0, lower = 0;
    for (final b in brackets) {
      final upper = b.upTo == null ? null : b.upTo! * months;
      final slice = (upper == null || taxable < upper ? taxable : upper) - lower;
      if (slice <= 0) break;
      tax += _bp(slice, b.rateBp);
      if (upper == null || taxable <= upper) break;
      lower = upper;
    }
    return tax;
  }

  /// Ước tính thuế một tháng lương: [gross] = tổng thu nhập chịu thuế từ tiền lương của tháng.
  MonthlyPit monthly({required int gross, int dependents = 0, int? insurance, int charity = 0, bool resident = true}) {
    if (!resident) {
      final tax = _bp(gross, nonResidentRateBp);
      return MonthlyPit(gross: gross, insurance: 0, deduction: 0, taxable: gross, tax: tax, net: gross - tax);
    }
    final ins = insurance ?? estimatedInsurance(gross);
    final deduction = familyDeduction(dependents) + charity;
    final taxable = gross - ins - deduction;
    final tax = progressiveMonthly(taxable);
    return MonthlyPit(
      gross: gross,
      insurance: ins,
      deduction: deduction,
      taxable: taxable < 0 ? 0 : taxable,
      tax: tax,
      net: gross - ins - tax,
    );
  }

  /// Lương gộp (gross) cần có để thực nhận [net] mỗi tháng (tìm nhị phân, sai số 1 đồng).
  int grossForNet(int net, {int dependents = 0, int? insurance}) {
    var lo = net, hi = net * 2 + 200000000;
    while (lo < hi) {
      final mid = lo + (hi - lo) ~/ 2;
      if (monthly(gross: mid, dependents: dependents, insurance: insurance).net >= net) {
        hi = mid;
      } else {
        lo = mid + 1;
      }
    }
    return lo;
  }

  static int _bp(int amount, int bp) => (amount * bp + 5000) ~/ 10000;
}

@immutable
final class MonthlyPit {
  const MonthlyPit({
    required this.gross,
    required this.insurance,
    required this.deduction,
    required this.taxable,
    required this.tax,
    required this.net,
  });
  final int gross;
  final int insurance;
  final int deduction;
  final int taxable;
  final int tax;
  final int net;
}

/// Ước tính quyết toán thuế TNCN cả năm từ sổ thu chi.
@immutable
final class AnnualPitEstimate {
  const AnnualPitEstimate({
    required this.year,
    required this.rules,
    required this.salaryIncome,
    required this.casualIncome,
    required this.businessRevenue,
    required this.investmentIncome,
    required this.exemptIncome,
    required this.unclassifiedIncome,
    required this.withheld,
    required this.insurance,
    required this.deduction,
    required this.taxable,
    required this.tax,
    required this.monthsWithSalary,
  });

  final int year;
  final VnPitRules rules;

  /// Tổng thu nhập (trước thuế khấu trừ) theo nhóm, VND.
  final int salaryIncome;
  final int casualIncome;
  final int businessRevenue;
  final int investmentIncome;
  final int exemptIncome;
  final int unclassifiedIncome;

  /// Thuế đã bị khấu trừ tại nguồn trên lương + vãng lai.
  final int withheld;
  final int insurance;
  final int deduction;
  final int taxable;

  /// Thuế phải nộp cả năm trên lương + vãng lai theo biểu lũy tiến.
  final int tax;
  final int monthsWithSalary;

  /// Dương = còn phải nộp thêm; âm = nộp thừa, có thể đề nghị hoàn.
  int get balance => tax - withheld;

  /// Doanh thu kinh doanh vượt ngưỡng không chịu thuế.
  bool get businessOverThreshold => businessRevenue > rules.businessExemptRevenue;

  /// Tính từ giao dịch thu VND của năm [year]. Danh mục thu phân loại bằng [Category.taxType]. Bảo hiểm: lấy
  /// [TaxProfile.monthlyInsurance] × số tháng có lương, nếu trống thì ước tính 10,5% lương từng tháng trong hạn mức.
  /// Giảm trừ gia cảnh tính đủ 12 tháng (người dùng quyết toán cả năm).
  static AnnualPitEstimate fromLedger({
    required int year,
    required Iterable<Txn> txns,
    required Iterable<Category> categories,
    required Iterable<Wallet> wallets,
    TaxProfile profile = const TaxProfile(),
  }) {
    final rules = VnPitRules.forYear(year);
    final vndWallets = {
      for (final w in wallets)
        if (w.currency.code == 'VND') w.id,
    };
    final cats = {for (final c in categories) c.id: c};
    IncomeTaxType typeOf(String? id) {
      var c = cats[id];
      // Danh mục con chưa phân loại ⇒ theo danh mục cha.
      while (c != null && c.taxType == IncomeTaxType.unknown && c.parentId != null) {
        c = cats[c.parentId];
      }
      return c?.taxType ?? IncomeTaxType.unknown;
    }

    final sums = {for (final t in IncomeTaxType.values) t: 0};
    final salaryByMonth = <int, int>{};
    var withheld = 0;
    for (final t in txns) {
      if (t.kind != TxnKind.income || t.pending || t.date.year != year || !vndWallets.contains(t.walletId)) continue;
      final type = typeOf(t.categoryId);
      sums[type] = sums[type]! + t.grossAmount;
      if (type == IncomeTaxType.salary) {
        salaryByMonth[t.date.month] = (salaryByMonth[t.date.month] ?? 0) + t.grossAmount;
      }
      if (type == IncomeTaxType.salary || type == IncomeTaxType.casual) withheld += t.taxWithheld;
    }
    final resident = profile.residency == TaxResidency.resident;
    var insurance = 0;
    if (profile.monthlyInsurance != null) {
      insurance = profile.monthlyInsurance! * salaryByMonth.length;
    } else {
      for (final m in salaryByMonth.values) {
        insurance += rules.estimatedInsurance(m);
      }
    }
    final income = sums[IncomeTaxType.salary]! + sums[IncomeTaxType.casual]!;
    final int deduction, taxable, tax;
    if (resident) {
      deduction = (rules.familyDeduction(profile.dependents) + profile.monthlyCharity) * 12;
      final t = income - insurance - deduction;
      taxable = t < 0 ? 0 : t;
      tax = rules.progressiveYearly(taxable);
    } else {
      deduction = 0;
      insurance = 0;
      taxable = income;
      tax = VnPitRules._bp(income, rules.nonResidentRateBp);
    }
    return AnnualPitEstimate(
      year: year,
      rules: rules,
      salaryIncome: sums[IncomeTaxType.salary]!,
      casualIncome: sums[IncomeTaxType.casual]!,
      businessRevenue: sums[IncomeTaxType.business]!,
      investmentIncome: sums[IncomeTaxType.investment]!,
      exemptIncome: sums[IncomeTaxType.exempt]!,
      unclassifiedIncome: sums[IncomeTaxType.unknown]!,
      withheld: withheld,
      insurance: insurance,
      deduction: deduction,
      taxable: taxable,
      tax: tax,
      monthsWithSalary: salaryByMonth.length,
    );
  }
}

enum TaxDeadlineKind {
  /// Cá nhân tự quyết toán thuế TNCN năm trước.
  selfSettlement,

  /// Tổ chức trả thu nhập quyết toán thay (người lao động ủy quyền) - nhắc nộp giấy ủy quyền sớm.
  authorizeEmployer,

  /// Hộ/cá nhân kinh doanh: khai thuế theo quý (khi doanh thu vượt ngưỡng).
  businessQuarterly,
}

@immutable
final class TaxDeadline {
  const TaxDeadline(this.kind, this.date, this.forYear);
  final TaxDeadlineKind kind;
  final CivilDate date;

  /// Kỳ tính thuế (năm) mà hạn này thuộc về.
  final int forYear;
}

/// Lịch hạn thuế cá nhân Việt Nam (Luật Quản lý thuế 38/2019/QH14 điều 44): hạn rơi vào thứ Bảy/Chủ nhật được dời
/// sang thứ Hai (ngày nghỉ lễ do người dùng tự đối chiếu).
abstract final class VnTaxCalendar {
  static CivilDate _workday(CivilDate d) {
    var x = d;
    while (x.weekday >= 6) {
      x = x.addDays(1);
    }
    return x;
  }

  /// Hạn cá nhân tự quyết toán năm [year]: ngày cuối cùng của tháng thứ 4 kể từ khi kết thúc năm (30/4 năm sau).
  static CivilDate selfSettlementDeadline(int year) => _workday(CivilDate(year + 1, 4, 30));

  /// Hạn tổ chức trả thu nhập quyết toán thay: ngày cuối tháng thứ 3 (31/3 năm sau).
  static CivilDate employerSettlementDeadline(int year) => _workday(CivilDate(year + 1, 3, 31));

  /// Hạn khai thuế quý của hộ kinh doanh: ngày cuối tháng đầu quý sau.
  static CivilDate businessQuarterDeadline(int year, int quarter) {
    final next = CivilDate(year, quarter * 3, 1).addMonths(1);
    return _workday(CivilDate(next.year, next.month, CivilDate.daysInMonth(next.year, next.month)));
  }

  /// Các hạn sắp tới trong [days] ngày kể từ [today] (đã sắp xếp).
  static List<TaxDeadline> upcoming(CivilDate today, {int days = 120, bool business = false}) {
    final until = today.addDays(days);
    final out = <TaxDeadline>[];
    for (final y in [today.year - 1, today.year]) {
      out
        ..add(TaxDeadline(TaxDeadlineKind.authorizeEmployer, employerSettlementDeadline(y).addDays(-30), y))
        ..add(TaxDeadline(TaxDeadlineKind.selfSettlement, selfSettlementDeadline(y), y));
      if (business) {
        for (var q = 1; q <= 4; q++) {
          out.add(TaxDeadline(TaxDeadlineKind.businessQuarterly, businessQuarterDeadline(y, q), y));
        }
      }
    }
    return [
      for (final d in out)
        if (d.date >= today && d.date <= until) d,
    ]..sort((a, b) => a.date.compareTo(b.date));
  }
}
