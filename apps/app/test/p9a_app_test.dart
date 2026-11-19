import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:qulythuchi/domain/default_categories.dart';
import 'package:qulythuchi/state/ledger_repository.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import 'helpers.dart';

void main() {
  for (final (name, size) in [('điện thoại', Size(390, 844)), ('máy tính', Size(1280, 800))]) {
    testWidgets('P9a: số dư theo tháng, khoản thu, thuế, QR không tràn ($name)', (tester) async {
      final sodium = await tester.runAsync(testSodium);
      final services = makeServices(sodium!);
      services.vault.createAccount(testPassword);
      final repo = LedgerRepository(services.store, services.vault)..seedDefaultCategories(DefaultCategoryLocale.vi);
      final w = repo.saveWallet(
        Wallet(
          id: repo.newId(),
          name: 'Ngân hàng',
          type: WalletType.bank,
          currency: Currency.vnd,
          openingBalance: 1000000,
        ),
      );
      final today = CivilDate.fromDateTime(DateTime.now());
      final lastMonth = CivilDate(today.year, today.month, 1).addMonths(-1);
      repo.saveTxn(Txn(id: repo.newId(), walletId: w.id, kind: TxnKind.income, amount: 500000, date: lastMonth));
      final freelance = repo.load().categories.firstWhere((c) => c.taxType == IncomeTaxType.casual);
      final plan = repo.saveIncomePlan(
        IncomePlan(
          id: repo.newId(),
          name: 'Website quán A',
          payer: 'Anh B',
          currency: Currency.vnd,
          total: 20000000,
          defaultWalletId: w.id,
          categoryId: freelance.id,
          withholdingBp: 1000,
          installments: [PlannedInstallment(date: today, amount: 6000000, label: 'Đặt cọc')],
        ),
      );
      await setSurface(tester, size);
      await pumpApp(tester, services);

      // Thẻ số dư theo tháng: đầu kỳ = 1.000.000 + 500.000 tháng trước.
      await scrollTo(tester, find.byKey(const Key('overview.period')));
      expect(find.byKey(const Key('period.opening.VND')), findsOneWidget);
      expect(
        find.descendant(of: find.byKey(const Key('period.opening.VND')), matching: find.textContaining('1.500.000')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      // Khoản thu: ghi lần nhận 6.000.000 ⇒ tự khấu trừ 600.000, thực nhận 5.400.000.
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/more/income/${plan.id}');
      await settle(tester);
      await tester.tap(find.byKey(const Key('income.receive')));
      await settle(tester);
      expect(find.textContaining('5.400.000'), findsWidgets);
      await tester.tap(find.byKey(const Key('income.receive.save')));
      await settle(tester);
      final t = repo.load().txns.firstWhere((t) => t.incomePlanId == plan.id);
      expect((t.amount, t.taxWithheld, t.categoryId, t.payee), (5400000, 600000, freelance.id, 'Anh B'));
      expect(tester.takeException(), isNull);

      GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/more/income');
      await settle(tester);
      await scrollTo(tester, find.text('Website quán A'));
      expect(find.text('Website quán A'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Thuế: lương gross 30 triệu, không người phụ thuộc ⇒ bảo hiểm 3.150.000, tính thuế 11.350.000 ⇒ thuế 635.000 (2026).
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/more/tax');
      await settle(tester);
      await scrollTo(tester, find.byKey(const Key('tax.salary')));
      await tester.enterText(find.byKey(const Key('tax.salary')), '30000000');
      await tester.pump();
      if (today.year >= 2026) {
        final tax = tester.widget<Text>(find.byKey(const Key('tax.calc.tax'))).data!;
        expect(tax, contains('635.000'));
      }
      expect(tester.takeException(), isNull);

      // QR: dán mã VietQR ⇒ đọc đúng; tab nhận tiền tạo được mã.
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/more/qr');
      await settle(tester);
      final code = VietQr.build(bin: '970436', account: '0011001234567', amount: 150000, message: 'Tien dien');
      await scrollTo(tester, find.byKey(const Key('qr.paste')));
      await tester.enterText(find.byKey(const Key('qr.paste')), code);
      await centerOn(tester, find.byKey(const Key('qr.read')));
      await tester.tap(find.byKey(const Key('qr.read')));
      await settle(tester);
      await scrollTo(tester, find.text('0011001234567'));
      expect(find.text('0011001234567'), findsOneWidget);
      expect(find.byKey(const Key('qr.openBank')), findsOneWidget);
      await centerOn(tester, find.byKey(const Key('qr.record')));
      await tester.tap(find.byKey(const Key('qr.record')));
      await settle(tester);
      expect(find.text('Tien dien'), findsWidgets, reason: 'ghi chú điền sẵn ở form giao dịch');
      expect(tester.takeException(), isNull);

      GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/more/qr');
      await settle(tester);
      // Nhánh "Thêm" giữ trạng thái màn QR ⇒ kết quả cũ còn đó, bấm "Quét lại".
      if (find.byKey(const Key('qr.reset')).evaluate().isNotEmpty) {
        await centerOn(tester, find.byKey(const Key('qr.reset')));
        await tester.tap(find.byKey(const Key('qr.reset')));
        await settle(tester);
      }
      await scrollTo(tester, find.byKey(const Key('qr.paste')));
      await tester.enterText(find.byKey(const Key('qr.paste')), '${code.substring(0, code.length - 4)}0000');
      await centerOn(tester, find.byKey(const Key('qr.read')));
      await tester.tap(find.byKey(const Key('qr.read')));
      await settle(tester);
      await scrollTo(tester, find.byKey(const Key('qr.error')));
      expect(find.byKey(const Key('qr.error')), findsOneWidget);
      await tester.tap(find.text('Mã nhận tiền'));
      await settle(tester);
      await tester.enterText(find.byKey(const Key('qr.recv.account')), '123456789');
      await tester.tap(find.byKey(const Key('qr.recv.build')));
      await settle(tester);
      await scrollTo(tester, find.byKey(const Key('qr.recv.image')));
      expect(find.byKey(const Key('qr.recv.image')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

/// Cuộn để [finder] nằm giữa vùng cuộn - tránh bị thanh điều hướng dưới che khi bấm.
Future<void> centerOn(WidgetTester tester, Finder finder) async {
  for (final m in tester.stateList<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))) {
    m.removeCurrentSnackBar();
  }
  await scrollTo(tester, finder);
  await Scrollable.ensureVisible(tester.element(finder.first), alignment: 0.5);
  await tester.pumpAndSettle();
}
