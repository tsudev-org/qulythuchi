import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulythuchi/services/reminders.dart';
import 'package:qulythuchi/state/ledger_repository.dart';
import 'package:qulythuchi/state/providers.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import 'helpers.dart';

/// Tài khoản đã mở khóa, 1 ví, 1 hóa đơn định kỳ đã đến hạn (chờ xác nhận), 1 hóa đơn sắp tới, 1 ngân sách vượt.
Future<AppServices> _seeded(WidgetTester tester) async {
  final sodium = await tester.runAsync(testSodium);
  final services = makeServices(sodium!);
  services.vault.createAccount(testPassword);
  final repo = LedgerRepository(services.store, services.vault);
  final today = CivilDate.fromDateTime(DateTime.now());
  final w = repo.saveWallet(
    Wallet(id: repo.newId(), name: 'Tiền mặt', type: WalletType.cash, currency: Currency.vnd, openingBalance: 2000000),
  );
  repo.saveRecurring(
    Recurring(
      id: repo.newId(),
      walletId: w.id,
      name: 'Tiền nhà',
      kind: TxnKind.expense,
      amount: 1500000,
      rule: RecurrenceRule(frequency: Frequency.monthly, start: today.addDays(-1)),
    ),
  );
  repo.saveRecurring(
    Recurring(
      id: repo.newId(),
      walletId: w.id,
      name: 'Điện',
      kind: TxnKind.expense,
      amount: 400000,
      rule: RecurrenceRule(frequency: Frequency.monthly, start: today.addDays(3)),
      isBill: true,
      autoCreate: true,
    ),
  );
  repo.saveTxn(Txn(id: repo.newId(), walletId: w.id, kind: TxnKind.expense, amount: 900000, date: today));
  repo.saveBudget(
    Budget(
      id: repo.newId(),
      name: 'Chi tiêu tháng',
      amount: 500000,
      currency: Currency.vnd,
      period: BudgetPeriod.monthly,
    ),
  );
  return services;
}

void main() {
  for (final (name, size) in [('điện thoại', const Size(360, 800)), ('máy tính', const Size(1280, 800))]) {
    testWidgets('Tổng quan: chờ xác nhận, hóa đơn sắp tới, ngân sách vượt ($name)', (tester) async {
      final services = await _seeded(tester);
      await setSurface(tester, size);
      await pumpApp(tester, services);

      expect(find.text('Chờ xác nhận (1)'), findsOneWidget);
      expect(find.text('Hóa đơn sắp đến hạn'), findsOneWidget);
      await scrollTo(tester, find.text('Ngân sách cần chú ý'));
      expect(find.text('Ngân sách cần chú ý'), findsOneWidget);
      await scrollTo(tester, find.text('Đã vượt hạn mức'));
      expect(find.text('Đã vượt hạn mức'), findsWidgets);

      await tapVisible(tester, find.widgetWithText(FilledButton, 'Xác nhận'));
      expect(find.textContaining('Chờ xác nhận ('), findsNothing);

      await tapVisible(tester, find.widgetWithText(TextButton, 'Đã trả'));
      expect(find.text('Hóa đơn sắp đến hạn'), findsNothing);
      // 2.000.000 - 900.000 - 1.500.000 - 400.000
      await scrollTo(tester, find.textContaining('-800.000'));
      expect(find.textContaining('-800.000'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Kế hoạch: tạo ngân sách, xem 6 hũ, tạo mục tiêu ($name)', (tester) async {
      final services = await _seeded(tester);
      await setSurface(tester, size);
      await pumpApp(tester, services);

      await tester.tap(find.byIcon(Icons.savings_outlined).first);
      await settle(tester);
      expect(find.text('Chi tiêu tháng'), findsOneWidget);

      await tester.tap(find.byTooltip('Ngân sách mới'));
      await settle(tester);
      await tester.enterText(textField('Tên ngân sách'), 'Ăn uống');
      await tester.enterText(textField('Hạn mức mỗi kỳ'), '3.000.000');
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Lưu'));
      expect(find.text('Ăn uống'), findsOneWidget);

      await tester.tap(find.text('6 hũ'));
      await settle(tester);
      await tester.enterText(textField('Thử chia một khoản thu'), '10.000.000');
      await tester.pump();
      expect(find.textContaining('5.500.000'), findsOneWidget); // Thiết yếu 55%
      expect(find.textContaining('500.000'), findsWidgets);

      await tester.tap(find.text('Mục tiêu'));
      await settle(tester);
      await tester.tap(find.byTooltip('Mục tiêu mới'));
      await settle(tester);
      await tester.enterText(textField('Tên mục tiêu'), 'Xe máy');
      await tester.enterText(textField('Số tiền cần'), '30.000.000');
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Lưu'));
      expect(find.text('Xe máy'), findsOneWidget);
      expect(find.text('Góp tiền'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Thêm: sổ nợ (tạo + ghi thu nợ), tỉ giá, sự kiện, định kỳ', (tester) async {
    final services = await _seeded(tester);
    await setSurface(tester, const Size(360, 800));
    await pumpApp(tester, services);

    await tester.tap(find.byIcon(Icons.more_horiz).first);
    await settle(tester);
    await tester.tap(find.text('Sổ nợ / cho vay'));
    await settle(tester);
    await tester.tap(find.byTooltip('Khoản nợ mới'));
    await settle(tester);
    await tester.enterText(textField('Người vay / cho vay'), 'Anh Nam');
    await tester.enterText(textField('Số tiền gốc'), '300.000');
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Lưu'));
    expect(find.text('Anh Nam'), findsOneWidget);
    await tester.tap(find.text('Anh Nam'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Ghi nhận thu nợ'));
    await settle(tester);
    await tester.enterText(find.byType(TextFormField).last, '300.000');
    await tester.tap(find.widgetWithText(FilledButton, 'Lưu').last);
    await settle(tester);
    expect(find.text('Đã tất toán'), findsOneWidget);

    final container = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    final data = container.read(ledgerProvider);
    final debt = data.debts.single;
    expect(Ledger.debtStatus(debt, data.wallets.single, data.txns).settled, isTrue);
    expect(tester.takeException(), isNull);
  });

  test('nhắc hóa đơn: đúng giờ, bỏ mốc đã qua, bỏ khoản tạm dừng/không phải hóa đơn', () {
    final now = DateTime(2026, 11, 17, 10);
    final rule = RecurrenceRule(frequency: Frequency.monthly, start: CivilDate(2026, 11, 20));
    Recurring rec({bool bill = true, bool paused = false}) => Recurring(
      id: '00000000-0000-4000-8000-000000000001',
      walletId: '00000000-0000-4000-8000-000000000002',
      name: 'x',
      kind: TxnKind.expense,
      amount: 1,
      rule: rule,
      isBill: bill,
      paused: paused,
      remindDaysBefore: 2,
    );
    final times = reminderTimes(LedgerData(recurrings: [rec()]), now);
    expect(times.first, DateTime(2026, 11, 18, 9));
    expect(times.length, 2); // 20/11 và 20/12 (trong 60 ngày)
    expect(reminderTimes(LedgerData(recurrings: [rec(bill: false)]), now), isEmpty);
    expect(reminderTimes(LedgerData(recurrings: [rec(paused: true)]), now), isEmpty);
    // Hôm nay 10 giờ đã qua mốc 9 giờ của nhắc cho 19/11 ⇒ bỏ.
    expect(reminderTimes(LedgerData(recurrings: [rec()]), DateTime(2026, 11, 18, 10)).first, DateTime(2026, 12, 18, 9));
    final w = Wallet(id: rec().walletId, name: 'v', type: WalletType.cash, currency: Currency.vnd);
    final debt = Debt(
      id: '00000000-0000-4000-8000-000000000003',
      walletId: w.id,
      kind: DebtKind.borrow,
      counterparty: 'y',
      principal: 100,
      startDate: CivilDate(2026, 11, 1),
      dueDate: CivilDate(2026, 11, 30),
    );
    expect(reminderTimes(LedgerData(wallets: [w], debts: [debt]), now), [DateTime(2026, 11, 29, 9)]);
  });
}
