import 'package:qulythuchi_core/qulythuchi_core.dart';
import 'package:test/test.dart';

CivilDate d(String s) => CivilDate.parse(s);
const wid = '7c9e6679-7425-40de-944b-e07fc1f90ae7';
const wid2 = '16fd2706-8baf-433b-82eb-8c7fada847da';
var _n = 0;
String newId() => '00000000-0000-4000-8000-${(_n++).toString().padLeft(12, '0')}';

Txn tx(
  TxnKind kind,
  int amount,
  String date, {
  String? cat,
  String wallet = wid,
  int fee = 0,
  bool pending = false,
  String? debt,
  String? goal,
}) => Txn(
  id: newId(),
  walletId: wallet,
  kind: kind,
  amount: amount,
  date: d(date),
  categoryId: cat,
  fee: fee,
  pending: pending,
  debtId: debt,
  goalId: goal,
);

void main() {
  final wallet = Wallet(
    id: wid,
    name: 'Tiền mặt',
    type: WalletType.cash,
    currency: Currency.vnd,
    openingBalance: 1000000,
  );

  group('CivilDate', () {
    test('cộng tháng kẹp cuối tháng, năm nhuận, thứ', () {
      expect(d('2026-01-31').addMonths(1), d('2026-02-28'));
      expect(d('2028-01-31').addMonths(1), d('2028-02-29'));
      expect(d('2026-03-15').addMonths(-3), d('2025-12-15'));
      expect(d('2026-11-17').weekday, 2); // Thứ Ba
      expect(d('2026-12-31').addDays(1), d('2027-01-01'));
      expect(d('2026-01-01').daysUntil(d('2026-12-31')), 364);
      expect(() => CivilDate(2026, 2, 29), throwsArgumentError);
      expect(() => CivilDate.parse('17/11/2026'), throwsFormatException);
      expect(CivilDate.isLeap(2000) && !CivilDate.isLeap(1900), isTrue);
      expect(DateRange(d('2026-11-01'), d('2026-11-30')).days, 30);
      expect(() => DateRange(d('2026-11-02'), d('2026-11-01')), throwsArgumentError);
    });
  });

  group('Ledger', () {
    test('số dư ví: thu, chi, chuyển kèm phí, điều chỉnh, bỏ qua chờ xác nhận', () {
      final txns = [
        tx(TxnKind.income, 500000, '2026-11-01'),
        tx(TxnKind.expense, 200000, '2026-11-02'),
        tx(TxnKind.transferOut, 100000, '2026-11-03', fee: 3300),
        tx(TxnKind.transferIn, 100000, '2026-11-03', wallet: wid2),
        tx(TxnKind.adjustment, -1000, '2026-11-04'),
        tx(TxnKind.expense, 999999, '2026-11-05', pending: true),
      ];
      expect(Ledger.walletBalance(wallet, txns).minor, 1000000 + 500000 - 200000 - 103300 - 1000);
      expect(Ledger.walletBalance(wallet, txns, asOf: d('2026-11-01')).minor, 1500000);
    });

    test('thẻ tín dụng: hạn mức còn lại', () {
      final card = Wallet(id: wid, name: 'Thẻ', type: WalletType.credit, currency: Currency.vnd, creditLimit: 10000000);
      expect(Ledger.creditAvailable(card, [tx(TxnKind.expense, 3000000, '2026-11-01')])!.minor, 7000000);
      expect(Ledger.creditAvailable(wallet, const []), isNull);
    });

    test('kỳ ngân sách tháng bắt đầu ngày 25 và ngày 31', () {
      Budget b(int start, BudgetPeriod p) =>
          Budget(id: 'b', name: 'b', amount: 1, currency: Currency.vnd, period: p, startDay: start);
      expect(
        Ledger.budgetRange(b(25, BudgetPeriod.monthly), d('2026-11-17')),
        DateRange(d('2026-10-25'), d('2026-11-24')),
      );
      expect(
        Ledger.budgetRange(b(25, BudgetPeriod.monthly), d('2026-11-25')),
        DateRange(d('2026-11-25'), d('2026-12-24')),
      );
      expect(
        Ledger.budgetRange(b(31, BudgetPeriod.monthly), d('2026-02-28')),
        DateRange(d('2026-02-28'), d('2026-03-30')),
      );
      expect(
        Ledger.budgetRange(b(1, BudgetPeriod.monthly), d('2026-11-17')),
        DateRange(d('2026-11-01'), d('2026-11-30')),
      );
      expect(
        Ledger.budgetRange(b(1, BudgetPeriod.weekly), d('2026-11-17')),
        DateRange(d('2026-11-16'), d('2026-11-22')),
      );
      expect(
        Ledger.budgetRange(b(7, BudgetPeriod.weekly), d('2026-11-17')),
        DateRange(d('2026-11-15'), d('2026-11-21')),
      );
      expect(
        Ledger.budgetRange(b(1, BudgetPeriod.yearly), d('2026-11-17')),
        DateRange(d('2026-01-01'), d('2026-12-31')),
      );
    });

    test('ngân sách theo danh mục cha gồm danh mục con, cảnh báo, vượt, chuyển dư', () {
      const cats = [
        Category(id: 'food', name: 'Ăn uống', kind: CategoryKind.expense),
        Category(id: 'cafe', name: 'Cà phê', kind: CategoryKind.expense, parentId: 'food'),
        Category(id: 'fuel', name: 'Xăng', kind: CategoryKind.expense),
      ];
      final budget = Budget(
        id: 'b',
        name: 'Ăn',
        amount: 1000000,
        currency: Currency.vnd,
        period: BudgetPeriod.monthly,
        categoryIds: const ['food'],
        rollover: true,
      );
      final txns = [
        tx(TxnKind.expense, 300000, '2026-10-10', cat: 'food'), // kỳ trước: dư 700k
        tx(TxnKind.expense, 500000, '2026-11-02', cat: 'food'),
        tx(TxnKind.expense, 900000, '2026-11-03', cat: 'cafe'),
        tx(TxnKind.expense, 50000, '2026-11-03', cat: 'fuel'),
        tx(TxnKind.income, 100000, '2026-11-04', cat: 'food'), // hoàn tiền
      ];
      final s = Ledger.budgetStatus(budget, txns: txns, categories: cats, wallets: [wallet], today: d('2026-11-17'));
      expect(s.spent.minor, 1300000);
      expect(s.limit.minor, 1700000);
      expect(s.state, BudgetState.ok);
      expect(s.usedBp, 7647);
      expect(s.dailyAllowance.minor, 400000 ~/ 14);
      final noRoll = Ledger.budgetStatus(
        Budget(
          id: 'b',
          name: 'Ăn',
          amount: 1000000,
          currency: Currency.vnd,
          period: BudgetPeriod.monthly,
          categoryIds: const ['food'],
        ),
        txns: txns,
        categories: cats,
        wallets: [wallet],
        today: d('2026-11-17'),
      );
      expect(noRoll.state, BudgetState.over);
      expect(noRoll.dailyAllowance.minor, 0);
      final warn = Ledger.budgetStatus(
        Budget(id: 'b', name: 'Tất cả', amount: 1500000, currency: Currency.vnd, period: BudgetPeriod.monthly),
        txns: txns,
        categories: cats,
        wallets: [wallet],
        today: d('2026-11-17'),
      );
      expect(warn.spent.minor, 1450000);
      expect(warn.state, BudgetState.warning);
    });

    test('ngân sách bỏ ví khác tiền tệ', () {
      final usdWallet = Wallet(id: wid2, name: 'USD', type: WalletType.bank, currency: Currency.usd);
      final s = Ledger.budgetStatus(
        Budget(id: 'b', name: 'x', amount: 100, currency: Currency.vnd, period: BudgetPeriod.monthly),
        txns: [tx(TxnKind.expense, 50, '2026-11-02', wallet: wid2)],
        categories: const [],
        wallets: [wallet, usdWallet],
        today: d('2026-11-17'),
      );
      expect(s.spent.minor, 0);
    });

    test('nợ: cho vay thu về một phần; mục tiêu: tiến độ và mức góp tháng', () {
      final debt = Debt(
        id: 'debt1',
        walletId: wid,
        kind: DebtKind.lend,
        counterparty: 'An',
        principal: 5000000,
        startDate: d('2026-10-01'),
      );
      final st = Ledger.debtStatus(debt, wallet, [
        tx(TxnKind.expense, 5000000, '2026-10-01', debt: 'debt1'),
        tx(TxnKind.income, 2000000, '2026-11-01', debt: 'debt1'),
      ]);
      expect(st.paid.minor, 2000000);
      expect(st.remaining.minor, 3000000);
      expect(st.settled, isFalse);

      final goal = Goal(
        id: 'g1',
        name: 'Laptop',
        target: 30000000,
        currency: Currency.vnd,
        deadline: d('2027-04-30'),
        startingAmount: 6000000,
      );
      final gs = Ledger.goalStatus(goal, [tx(TxnKind.transferIn, 4000000, '2026-11-01', goal: 'g1')], d('2026-11-17'));
      expect(gs.saved.minor, 10000000);
      expect(gs.progressBp, 3333);
      expect(gs.monthlyNeeded!.minor, (20000000 + 5) ~/ 6); // 6 tháng: 11..4
    });

    test('chi theo danh mục', () {
      final m = Ledger.expenseByCategory(
        [
          tx(TxnKind.expense, 10, '2026-11-01', cat: 'a'),
          tx(TxnKind.expense, 5, '2026-11-02', cat: 'a'),
          tx(TxnKind.expense, 7, '2026-11-02'),
          tx(TxnKind.income, 99, '2026-11-02', cat: 'a'),
        ],
        DateRange(d('2026-11-01'), d('2026-11-30')),
        {wid},
      );
      expect(m, {'a': 15, null: 7});
    });
  });

  group('6 hũ', () {
    test('chia thu nhập đúng tỉ lệ, tổng khớp từng đồng', () {
      final parts = JarPlan.sixJars().allocate(Money(15000001, Currency.vnd));
      expect(parts['nec']!.minor, 8250001);
      expect(parts.values.fold<int>(0, (a, m) => a + m.minor), 15000001);
      expect(() => JarPlan(const [Jar('a', 'A', 5000)]), throwsArgumentError);
    });
  });

  group('Định kỳ', () {
    test('hằng tháng ngày 31 kẹp cuối tháng; ngày cuối tháng (-1)', () {
      final r = RecurrenceRule(frequency: Frequency.monthly, start: d('2026-01-31'));
      expect(r.occurrences(DateRange(d('2026-01-01'), d('2026-04-30'))), [
        d('2026-01-31'),
        d('2026-02-28'),
        d('2026-03-31'),
        d('2026-04-30'),
      ]);
      final last = RecurrenceRule(frequency: Frequency.monthly, start: d('2026-01-10'), monthDay: -1);
      expect(last.occurrences(DateRange(d('2026-02-01'), d('2026-02-28'))), [d('2026-02-28')]);
    });

    test('hằng tuần nhiều thứ, cách tuần, COUNT, UNTIL', () {
      final r = RecurrenceRule(
        frequency: Frequency.weekly,
        start: d('2026-11-17'),
        weekdays: const [1, 5],
        interval: 2,
        count: 3,
      );
      expect(r.occurrences(DateRange(d('2026-11-01'), d('2027-01-31'))), [
        d('2026-11-20'),
        d('2026-11-30'),
        d('2026-12-04'),
      ]);
      final u = RecurrenceRule(frequency: Frequency.daily, start: d('2026-11-28'), interval: 2, until: d('2026-12-03'));
      expect(u.occurrences(DateRange(d('2026-11-01'), d('2026-12-31'))), [
        d('2026-11-28'),
        d('2026-11-30'),
        d('2026-12-02'),
      ]);
      final y = RecurrenceRule(frequency: Frequency.yearly, start: d('2028-02-29'));
      expect(y.occurrences(DateRange(d('2028-01-01'), d('2029-12-31'))), [d('2028-02-29'), d('2029-02-28')]);
      expect(
        () => RecurrenceRule(frequency: Frequency.daily, start: d('2026-01-01'), interval: 0),
        throwsArgumentError,
      );
      expect(RecurrenceRule.fromJson(r.toJson()).occurrences(DateRange(d('2026-11-01'), d('2027-01-31'))).length, 3);
    });

    test('sinh giao dịch đến hạn, chờ xác nhận, nhắc hóa đơn', () {
      final rec = Recurring(
        id: 'r1',
        walletId: wid,
        name: 'Tiền điện',
        kind: TxnKind.expense,
        amount: 450000,
        isBill: true,
        rule: RecurrenceRule(frequency: Frequency.monthly, start: d('2026-09-05')),
        generatedThrough: d('2026-09-30'),
      );
      final made = rec.materialize(d('2026-11-17'), newId);
      expect(made.map((t) => t.date), [d('2026-10-05'), d('2026-11-05')]);
      expect(made.every((t) => t.pending && t.source == TxnSource.recurring && t.recurringId == 'r1'), isTrue);
      expect(rec.reminderFor(d('2026-12-04')), d('2026-12-05'));
      expect(rec.reminderFor(d('2026-12-01')), isNull);
    });
  });

  group('Ánh xạ bản ghi đồng bộ', () {
    test('mọi mô hình khứ hồi qua SyncRecord', () {
      final clock = HlcClock('a');
      SyncRecord rec(String type, String id, String? w, Map<String, Object?> v) =>
          SyncRecord(id: id, type: type, walletId: w).setAll(v, clock);
      const id = '0f8fad5b-d9cb-469f-a165-70867728950e';
      final w = Wallet(
        id: wid,
        name: 'Ví',
        type: WalletType.credit,
        currency: Currency.of('XYZ', minorDigits: 3),
        creditLimit: 5,
        dueDay: 10,
      );
      final w2 = Wallet.fromRecord(rec(RecordTypes.wallet, wid, wid, w.toValues()));
      expect(
        [w2.name, w2.type, w2.currency.minorDigits, w2.creditLimit, w2.dueDay],
        ['Ví', WalletType.credit, 3, 5, 10],
      );
      final t = Txn(
        id: id,
        walletId: wid,
        kind: TxnKind.transferOut,
        amount: 9,
        date: d('2026-11-17'),
        fee: 1,
        tags: const ['x'],
        source: TxnSource.ocr,
      );
      final t2 = Txn.fromRecord(rec(RecordTypes.transaction, id, wid, t.toValues()));
      expect(
        [t2.kind, t2.amount, t2.date, t2.fee, t2.tags, t2.source],
        [
          TxnKind.transferOut,
          9,
          d('2026-11-17'),
          1,
          ['x'],
          TxnSource.ocr,
        ],
      );
      final c2 = Category.fromRecord(
        rec(
          RecordTypes.category,
          id,
          null,
          const Category(id: id, name: 'C', kind: CategoryKind.income, parentId: 'p').toValues(),
        ),
      );
      expect([c2.kind, c2.parentId], [CategoryKind.income, 'p']);
      final b = Budget(
        id: id,
        name: 'B',
        amount: 5,
        currency: Currency.vnd,
        period: BudgetPeriod.custom,
        customStart: d('2026-11-01'),
        customEnd: d('2026-11-10'),
      );
      final b2 = Budget.fromRecord(rec(RecordTypes.budget, id, null, b.toValues()));
      expect([b2.period, b2.customEnd], [BudgetPeriod.custom, d('2026-11-10')]);
      final debt = Debt(
        id: id,
        walletId: wid,
        kind: DebtKind.borrow,
        counterparty: 'B',
        principal: 3,
        startDate: d('2026-01-01'),
        dueDate: d('2026-12-01'),
      );
      expect(Debt.fromRecord(rec(RecordTypes.debt, id, wid, debt.toValues())).dueDate, d('2026-12-01'));
      final g = Goal(id: id, name: 'G', target: 7, currency: Currency.usd, deadline: d('2027-01-01'));
      expect(Goal.fromRecord(rec(RecordTypes.goal, id, null, g.toValues())).currency, Currency.usd);
      final e = Event(id: id, name: 'Đà Lạt', start: d('2026-12-20'), budget: 9);
      expect(Event.fromRecord(rec(RecordTypes.event, id, null, e.toValues())).budget, 9);
      final r = Recurring(
        id: id,
        walletId: wid,
        name: 'N',
        kind: TxnKind.income,
        amount: 1,
        rule: RecurrenceRule(frequency: Frequency.monthly, start: d('2026-01-01')),
      );
      expect(Recurring.fromRecord(rec(RecordTypes.recurring, id, wid, r.toValues())).rule.frequency, Frequency.monthly);
      // dữ liệu hỏng/thiếu không làm sập app
      final broken = Txn.fromRecord(
        rec(RecordTypes.transaction, id, wid, {'kind': 'lạ', 'amount': 'x', 'date': 'hỏng'}),
      );
      expect([broken.kind, broken.amount], [TxnKind.expense, 0]);
    });
  });
}
