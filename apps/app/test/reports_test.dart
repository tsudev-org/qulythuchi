import 'package:flutter_test/flutter_test.dart';
import 'package:qulythuchi/domain/extra_models.dart';
import 'package:qulythuchi/domain/reports.dart';
import 'package:qulythuchi/state/ledger_repository.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

const _w1 = '00000000-0000-4000-8000-0000000000a1';
const _w2 = '00000000-0000-4000-8000-0000000000a2';
var _n = 0;
String _id() => '00000000-0000-4000-8000-${(++_n).toString().padLeft(12, '0')}';

Txn _t(String w, TxnKind k, int amount, CivilDate d, {String? cat, bool pending = false, bool exclude = false}) => Txn(
  id: _id(),
  walletId: w,
  kind: k,
  amount: amount,
  date: d,
  categoryId: cat,
  pending: pending,
  excludeFromReports: exclude,
);

void main() {
  final today = CivilDate(2026, 11, 17);
  final vnd = Wallet(id: _w1, name: 'VND', type: WalletType.cash, currency: Currency.vnd, openingBalance: 1000000);
  final usd = Wallet(id: _w2, name: 'USD', type: WalletType.bank, currency: Currency.usd);
  const food = Category(id: '00000000-0000-4000-8000-0000000000c1', name: 'Ăn', kind: CategoryKind.expense);
  const cafe = Category(
    id: '00000000-0000-4000-8000-0000000000c2',
    name: 'Cà phê',
    kind: CategoryKind.expense,
    parentId: '00000000-0000-4000-8000-0000000000c1',
  );

  LedgerData data({List<Txn> txns = const [], List<FxRate> rates = const [], List<Recurring> rec = const []}) =>
      LedgerData(wallets: [vnd, usd], categories: const [food, cafe], txns: txns, rates: rates, recurrings: rec);

  test('tổng hợp kỳ: loại chờ/không báo cáo/chuyển ví; thiếu tỉ giá báo riêng', () {
    final d = data(
      txns: [
        _t(_w1, TxnKind.income, 10000000, today),
        _t(_w1, TxnKind.expense, 300000, today, cat: cafe.id),
        _t(_w1, TxnKind.expense, 999, today, pending: true),
        _t(_w1, TxnKind.expense, 777, today, exclude: true),
        _t(_w1, TxnKind.transferOut, 555, today),
        _t(_w2, TxnKind.expense, 1000, today), // 10 USD
        _t(_w1, TxnKind.expense, 50000, CivilDate(2026, 10, 31)),
      ],
    );
    final r = Reports(d, Currency.vnd).summary(presetRange(ReportPreset.thisMonth, today));
    expect(r.income.minor, 10000000);
    expect(r.expense.minor, 300000);
    expect(r.missing, {Currency.usd});
    expect(r.savingsRateBp, 9700);
  });

  test('quy đổi theo tỉ giá, cơ cấu gộp về danh mục cha + "Khác"', () {
    final d = data(
      txns: [
        _t(_w1, TxnKind.expense, 100000, today, cat: cafe.id),
        _t(_w1, TxnKind.expense, 50000, today, cat: food.id),
        _t(_w2, TxnKind.expense, 1000, today), // 10 USD -> 250.000
      ],
      rates: [FxRate(id: _id(), from: Currency.usd, to: Currency.vnd, rate: '25000', date: today)],
    );
    final rep = Reports(d, Currency.vnd);
    final shares = rep.categoryShares(presetRange(ReportPreset.thisMonth, today));
    expect(shares.first.categoryId, isNull); // chưa phân loại 250.000 lớn nhất
    expect(shares[1].categoryId, food.id);
    expect(shares[1].amount.minor, 150000);
    expect(shares.fold<int>(0, (a, s) => a + s.amount.minor), 400000);
    final two = rep.categoryShares(presetRange(ReportPreset.thisMonth, today), maxRows: 1);
    expect(two.single.categoryId, CategoryShare.otherId);
  });

  test('chuỗi tháng, tài sản ròng, chi theo ngày', () {
    final d = data(
      txns: [
        _t(_w1, TxnKind.expense, 200000, CivilDate(2026, 10, 5)),
        _t(_w1, TxnKind.income, 500000, today),
        _t(_w1, TxnKind.expense, 100000, today),
      ],
    );
    final rep = Reports(d, Currency.vnd);
    final m = rep.monthly(today, 3);
    expect(m.map((p) => p.month), [CivilDate(2026, 9, 1), CivilDate(2026, 10, 1), CivilDate(2026, 11, 1)]);
    expect(m[1].expense.minor, 200000);
    final nw = rep.netWorth(today, 2);
    expect(nw[0].$2.minor, 800000);
    expect(nw[1].$2.minor, 1200000);
    expect(rep.dailyExpense(today)[17]!.minor, 100000);
  });

  test('an toàn để tiêu: trừ hóa đơn còn lại trong tháng', () {
    final rec = Recurring(
      id: _id(),
      walletId: _w1,
      name: 'Điện',
      kind: TxnKind.expense,
      amount: 400000,
      rule: RecurrenceRule(frequency: Frequency.monthly, start: CivilDate(2026, 11, 25)),
      isBill: true,
    );
    final d = data(
      txns: [_t(_w1, TxnKind.income, 3000000, today), _t(_w1, TxnKind.expense, 1000000, today)],
      rec: [rec],
    );
    final s = Reports(d, Currency.vnd).safeToSpend(today);
    expect(s.amount.minor, 3000000 - 1000000 - 400000);
    expect(s.perDay.minor, 1600000 ~/ 14); // 17..30 = 14 ngày
  });

  test('kỳ trước để so sánh: trọn tháng lùi theo tháng, kỳ tự chọn lùi theo ngày', () {
    expect(
      previousRange(DateRange(CivilDate(2026, 3, 1), CivilDate(2026, 3, 31))),
      DateRange(CivilDate(2026, 2, 1), CivilDate(2026, 2, 28)),
    );
    expect(
      previousRange(DateRange(CivilDate(2026, 1, 1), CivilDate(2026, 12, 31))),
      DateRange(CivilDate(2025, 1, 1), CivilDate(2025, 12, 31)),
    );
    expect(
      previousRange(DateRange(CivilDate(2026, 11, 10), CivilDate(2026, 11, 16))),
      DateRange(CivilDate(2026, 11, 3), CivilDate(2026, 11, 9)),
    );
    expect(changeBp(Money(150, Currency.vnd), Money(100, Currency.vnd)), 5000);
    expect(changeBp(Money(150, Currency.vnd), Money(0, Currency.vnd)), isNull);
  });
}
