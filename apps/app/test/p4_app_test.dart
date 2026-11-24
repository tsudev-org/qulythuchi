import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:qulythuchi/domain/default_categories.dart';
import 'package:qulythuchi/state/ledger_repository.dart';
import 'package:qulythuchi/state/providers.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import 'helpers.dart';

Future<AppServices> _seeded(WidgetTester tester) async {
  final sodium = await tester.runAsync(testSodium);
  final services = makeServices(sodium!);
  services.vault.createAccount(testPassword);
  final repo = LedgerRepository(services.store, services.vault)..seedDefaultCategories(DefaultCategoryLocale.vi);
  final today = CivilDate.fromDateTime(DateTime.now());
  final w = repo.saveWallet(
    Wallet(id: repo.newId(), name: 'Tiền mặt', type: WalletType.cash, currency: Currency.vnd, openingBalance: 2000000),
  );
  final cats = repo.snapshot().categories;
  final food = cats.firstWhere((c) => c.name == 'Ăn uống');
  final salary = cats.firstWhere((c) => c.kind == CategoryKind.income);
  repo
    ..saveTxn(
      Txn(id: repo.newId(), walletId: w.id, kind: TxnKind.income, amount: 10000000, date: today, categoryId: salary.id),
    )
    ..saveTxn(
      Txn(id: repo.newId(), walletId: w.id, kind: TxnKind.expense, amount: 50000, date: today, categoryId: food.id),
    );
  return services;
}

void main() {
  for (final (name, size) in [('điện thoại', const Size(360, 800)), ('máy tính', const Size(1280, 800))]) {
    testWidgets('Báo cáo + Dữ liệu hiển thị không tràn ($name)', (tester) async {
      final services = await _seeded(tester);
      await setSurface(tester, size);
      await pumpApp(tester, services);

      // Thẻ "An toàn để tiêu" trên Tổng quan.
      await scrollTo(tester, find.text('An toàn để tiêu tháng này'));
      expect(find.text('An toàn để tiêu tháng này'), findsOneWidget);

      final router = tester.element(find.byType(Scaffold).first);
      GoRouter.of(router).go('/more/reports');
      await settle(tester);
      expect(find.text('Báo cáo'), findsWidgets);
      await scrollTo(tester, find.text('Chi theo danh mục'));
      await tapVisible(tester, find.byTooltip('Xem dạng bảng').first);
      expect(find.byType(Table), findsWidgets);
      expect(tester.takeException(), isNull);

      GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/more/data');
      await settle(tester);
      expect(find.text('Xuất giao dịch'), findsWidgets);
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Xuất giao dịch'));
      // Luôn cảnh báo tệp không mã hóa trước khi lưu.
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Hủy'));
      await settle(tester);
      await scrollTo(tester, find.text('Tạo tệp sao lưu'));
      expect(find.text('Tạo tệp sao lưu'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('màn chào có lối khôi phục từ tệp sao lưu', (tester) async {
    final sodium = await tester.runAsync(testSodium);
    await pumpApp(tester, makeServices(sodium!));
    await scrollTo(tester, find.text('Khôi phục từ tệp sao lưu'));
    expect(find.text('Khôi phục từ tệp sao lưu'), findsOneWidget);
  });
}
