import 'package:flutter_test/flutter_test.dart';
import 'package:qulythuchi/domain/extra_models.dart';
import 'package:qulythuchi/state/ledger_repository.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import 'helpers.dart';

void main() {
  late LedgerRepository repo;
  late Wallet cash;
  late Wallet usd;
  final today = CivilDate(2026, 11, 17);

  setUp(() async {
    final services = makeServices(await testSodium());
    services.vault.createAccount(testPassword);
    repo = LedgerRepository(services.store, services.vault);
    cash = repo.saveWallet(
      Wallet(
        id: repo.newId(),
        name: 'Tiền mặt',
        type: WalletType.cash,
        currency: Currency.vnd,
        openingBalance: 1000000,
      ),
    );
    usd = repo.saveWallet(Wallet(id: repo.newId(), name: 'USD', type: WalletType.bank, currency: Currency.usd));
  });

  /// Mở lại từ CSDL (giải mã lại) để chắc dữ liệu thật sự được lưu.
  LedgerData reload() => repo.load();

  test('định kỳ: sinh giao dịch đến hạn, chờ xác nhận, không sinh lặp', () {
    final rec = repo.saveRecurring(
      Recurring(
        id: repo.newId(),
        walletId: cash.id,
        name: 'Internet',
        kind: TxnKind.expense,
        amount: 220000,
        rule: RecurrenceRule(frequency: Frequency.monthly, start: CivilDate(2026, 9, 5)),
        isBill: true,
      ),
    );
    expect(repo.materializeRecurring(today), 3); // 05/09, 05/10, 05/11
    expect(repo.materializeRecurring(today), 0, reason: 'không sinh lại');
    var data = reload();
    expect(data.pendingTxns, hasLength(3));
    expect(data.balance(cash).minor, 1000000, reason: 'giao dịch chờ không tính số dư');
    expect(data.recurring(rec.id)!.generatedThrough, today);

    repo.confirmPending(data.pendingTxns.first.id);
    data = reload();
    expect(data.pendingTxns, hasLength(2));
    expect(data.balance(cash).minor, 1000000 - 220000);
  });

  test('hóa đơn: trả trước hạn tạo giao dịch thật và dời mốc', () {
    final rec = repo.saveRecurring(
      Recurring(
        id: repo.newId(),
        walletId: cash.id,
        name: 'Điện',
        kind: TxnKind.expense,
        amount: 500000,
        rule: RecurrenceRule(frequency: Frequency.monthly, start: CivilDate(2026, 11, 20)),
        isBill: true,
        autoCreate: true,
      ),
    );
    expect(rec.reminderFor(CivilDate(2026, 11, 19)), CivilDate(2026, 11, 20));
    repo.payBill(rec.id, CivilDate(2026, 11, 20), paidOn: today, amount: 480000);
    final data = reload();
    expect(data.balance(cash).minor, 1000000 - 480000);
    expect(data.recurring(rec.id)!.generatedThrough, CivilDate(2026, 11, 20));
    // Tới ngày 20 không sinh thêm khoản cho kỳ đã trả.
    expect(repo.materializeRecurring(CivilDate(2026, 11, 25)), 0);
  });

  test('ngân sách: lưu, kiểm tra hợp lệ, trạng thái theo kỳ', () {
    expect(
      () => repo.saveBudget(
        Budget(id: repo.newId(), name: 'Ăn', amount: 0, currency: Currency.vnd, period: BudgetPeriod.monthly),
      ),
      throwsA(isA<LedgerException>()),
    );
    final b = repo.saveBudget(
      Budget(id: repo.newId(), name: 'Chi tháng', amount: 300000, currency: Currency.vnd, period: BudgetPeriod.monthly),
    );
    repo.saveTxn(Txn(id: repo.newId(), walletId: cash.id, kind: TxnKind.expense, amount: 250000, date: today));
    final data = reload();
    final st = Ledger.budgetStatus(
      data.budget(b.id)!,
      txns: data.txns,
      categories: data.categories,
      wallets: data.wallets,
      today: today,
    );
    expect(st.state, BudgetState.warning);
  });

  test('nợ: giải ngân không vào báo cáo, trả dần tới tất toán', () {
    final d = repo.saveDebt(
      Debt(
        id: repo.newId(),
        walletId: cash.id,
        kind: DebtKind.lend,
        counterparty: 'Anh Nam',
        principal: 400000,
        startDate: today,
      ),
      recordDisbursement: true,
    );
    repo.recordDebtPayment(d.id, 150000, today);
    var data = reload();
    expect(data.balance(cash).minor, 1000000 - 400000 + 150000);
    expect(Ledger.debtStatus(data.debt(d.id)!, cash, data.txns).remaining.minor, 250000);
    expect(data.txns.where((t) => t.debtId == d.id).every((t) => t.excludeFromReports), isTrue);
    repo.recordDebtPayment(d.id, 250000, today);
    data = reload();
    expect(Ledger.debtStatus(data.debt(d.id)!, cash, data.txns).settled, isTrue);
  });

  test('mục tiêu + sự kiện + chuyển ví gắn mục tiêu', () {
    final saving = repo.saveWallet(
      Wallet(id: repo.newId(), name: 'Tiết kiệm', type: WalletType.saving, currency: Currency.vnd),
    );
    final g = repo.saveGoal(Goal(id: repo.newId(), name: 'Xe máy', target: 30000000, currency: Currency.vnd));
    final e = repo.saveEvent(Event(id: repo.newId(), name: 'Đà Lạt', start: today, budget: 5000000));
    repo.saveTransfer(fromWalletId: cash.id, toWalletId: saving.id, amount: 500000, date: today, goalId: g.id);
    repo.saveTxn(
      Txn(id: repo.newId(), walletId: cash.id, kind: TxnKind.expense, amount: 120000, date: today, eventId: e.id),
    );
    final data = reload();
    expect(Ledger.goalStatus(data.goal(g.id)!, data.txns, today).saved.minor, 500000);
    expect(data.eventSpending(e.id)[Currency.vnd]!.minor, 120000);
    expect(
      () => repo.saveEvent(Event(id: repo.newId(), name: 'Sai', start: today, end: CivilDate(2026, 1, 1))),
      throwsA(isA<LedgerException>()),
    );
  });

  test('6 hũ: lưu một kế hoạch duy nhất, chia khớp từng đồng', () {
    repo.saveJarPlan(JarPlan.sixJars());
    repo.saveJarPlan(JarPlan(const [Jar('a', 'A', 7000), Jar('b', 'B', 3000)]));
    final data = reload();
    expect(data.jarPlan!.jars, hasLength(2));
    final parts = data.jarPlan!.allocate(Money(1000001, Currency.vnd));
    expect(parts.values.fold<int>(0, (a, m) => a + m.minor), 1000001);
  });

  test('tỉ giá: chuẩn hóa nhập, quy đổi tổng, thiếu tỉ giá báo riêng', () {
    expect(FxRate.normalize('25.450,5', AppLocale.vi), '25450.5');
    expect(FxRate.normalize('25,450.5', AppLocale.en), '25450.5');
    expect(FxRate.normalize('0', AppLocale.vi), isNull);
    expect(FxRate.normalize('-3', AppLocale.vi), isNull);
    repo.saveTxn(Txn(id: repo.newId(), walletId: usd.id, kind: TxnKind.income, amount: 1050, date: today)); // $10.50
    var data = reload();
    expect(data.totalIn(Currency.vnd).missing, [Currency.usd]);
    repo.saveRate(FxRate(id: repo.newId(), from: Currency.usd, to: Currency.vnd, rate: '25000', date: today));
    repo.saveRate(
      FxRate(id: repo.newId(), from: Currency.usd, to: Currency.vnd, rate: '26000', date: today.addDays(1)),
    );
    data = reload();
    final r = data.totalIn(Currency.vnd);
    expect(r.missing, isEmpty);
    expect(r.total.minor, 1000000 + 273000, reason: 'dùng tỉ giá mới nhất 26.000');
  });
}
