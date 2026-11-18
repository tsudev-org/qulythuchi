import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:qulythuchi/domain/default_categories.dart';
import 'package:qulythuchi/state/ledger_repository.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import 'helpers.dart';

void main() {
  for (final (name, size) in [('điện thoại', Size(390, 844)), ('máy tính', Size(1280, 800))]) {
    testWidgets('Ghi nhanh + màn Tự nhập hiển thị không tràn ($name)', (tester) async {
      final sodium = await tester.runAsync(testSodium);
      final services = makeServices(sodium!);
      services.vault.createAccount(testPassword);
      final repo = LedgerRepository(services.store, services.vault)..seedDefaultCategories(DefaultCategoryLocale.vi);
      repo.saveWallet(Wallet(id: repo.newId(), name: 'Tiền mặt', type: WalletType.cash, currency: Currency.vnd));
      await setSurface(tester, size);
      await pumpApp(tester, services);

      await tester.tap(find.byKey(const Key('overview.quick')));
      await settle(tester);
      await tester.enterText(find.byKey(const Key('quick.text')), 'hôm qua ăn trưa 50 nghìn');
      await tester.pump();
      expect(find.byKey(const Key('quick.preview')), findsOneWidget);
      expect(find.textContaining('Ăn ngoài'), findsWidgets, reason: 'gợi ý danh mục theo luật mặc định');
      await tester.tap(find.byKey(const Key('quick.save')));
      await settle(tester);
      final t = repo.load().txns.single;
      expect((t.amount, t.kind, t.note, t.pending), (50000, TxnKind.expense, 'ăn trưa', false));
      expect(t.date, CivilDate.fromDateTime(DateTime.now()).addDays(-1));
      expect(tester.takeException(), isNull);

      GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/more/auto-import');
      await settle(tester);
      expect(find.text('Tự nhập'), findsWidgets);
      // Máy test không phải Android: thông báo ngân hàng báo rõ chỉ có trên Android; email cần đăng nhập.
      expect(find.textContaining('Chỉ có trên Android'), findsOneWidget);
      await scrollTo(tester, find.text('Đăng nhập đồng bộ để dùng'));
      expect(find.text('Đăng nhập đồng bộ để dùng'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
