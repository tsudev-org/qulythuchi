import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:qulythuchi/domain/default_categories.dart';
import 'package:qulythuchi/state/providers.dart';
import 'package:qulythuchi/state/sync_controller.dart';
import 'package:qulythuchi/sync/pkce.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import 'fake_sync_server.dart';
import 'helpers.dart';
import 'p9a_app_test.dart' show centerOn;

SyncConfig _config(FakeSyncServer server, String user) => SyncConfig(
  httpClient: server.client,
  login: (s) async {
    final req = LoginRequest.create('http://127.0.0.1:5000/callback');
    return (callback: LoginCallback.ok('code:$user:${req.challenge}'), request: req, platform: 'linux');
  },
  autoSync: false,
);

/// Một thiết bị chạy không giao diện (tạo tài khoản, đăng nhập) trên [services] - app dựng sau dùng lại CSDL + token.
Future<ProviderContainer> _headless(AppServices services, FakeSyncServer server, String user) async {
  final c = ProviderContainer(
    overrides: [
      servicesProvider.overrideWithValue(services),
      syncConfigProvider.overrideWithValue(_config(server, user)),
    ],
  );
  addTearDown(c.dispose);
  if (!services.vault.hasAccount) {
    c.read(sessionProvider.notifier).createAccount(testPassword, DefaultCategoryLocale.vi);
    c.read(sessionProvider.notifier).finishOnboarding();
  }
  c.read(ledgerProvider);
  await c.read(syncProvider.notifier).signIn();
  await c.read(syncProvider.notifier).syncNow();
  return c;
}

void _go(WidgetTester tester, String path) => GoRouter.of(tester.element(find.byType(Scaffold).first)).go(path);

/// Chờ thao tác mạng/mật mã thật chạy xong rồi dựng lại khung hình.
Future<void> _wait(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  for (final (name, size) in [('điện thoại', Size(390, 844)), ('máy tính', Size(1280, 800))]) {
    testWidgets('P9 chủ ví: chia sẻ, mời, đổi quyền, thu hồi - không tràn ($name)', (tester) async {
      final sodium = await tester.runAsync(testSodium);
      final server = FakeSyncServer();
      final an = makeServices(sodium!);
      final binh = makeServices(sodium);
      late String walletId;
      await tester.runAsync(() async {
        final c = await _headless(an, server, 'an');
        final w = c
            .read(ledgerProvider.notifier)
            .saveWallet(
              Wallet(
                id: c.read(ledgerProvider.notifier).newId(),
                name: 'Chi tiêu nhà',
                type: WalletType.cash,
                currency: Currency.vnd,
              ),
            );
        walletId = w.id;
        await c.read(syncProvider.notifier).syncNow();
        await _headless(binh, server, 'binh');
      });
      await setSurface(tester, size);
      await pumpApp(tester, an, extra: [syncConfigProvider.overrideWithValue(_config(server, 'an'))]);

      _go(tester, '/wallets/$walletId');
      await settle(tester);
      await centerOn(tester, find.byKey(const Key('wallet.members')));
      await tester.tap(find.byKey(const Key('wallet.members')));
      await settle(tester);
      expect(find.byKey(const Key('share.start')), findsOneWidget);
      await tester.tap(find.byKey(const Key('share.start')));
      await _wait(tester);
      expect(server.wallets.keys, [walletId]);
      expect(find.byKey(const Key('share.member.an')), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Mời người ghi: chọn quyền ⇒ hộp mã mời có mã + QR.
      await centerOn(tester, find.byKey(const Key('share.invite')));
      await tester.tap(find.byKey(const Key('share.invite')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('share.role.editor')));
      await _wait(tester);
      final code = tester.widget<SelectableText>(find.byKey(const Key('share.code'))).data!;
      expect(InviteCode.parse(code), isNotNull);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Sao chép mã'));
      await settle(tester);

      // Bình nhận (không giao diện), chủ ví đồng bộ ⇒ Bình thành thành viên.
      await tester.runAsync(() async {
        final cb = ProviderContainer(
          overrides: [
            servicesProvider.overrideWithValue(binh),
            syncConfigProvider.overrideWithValue(_config(server, 'binh')),
          ],
        );
        addTearDown(cb.dispose);
        final s = cb.read(syncProvider.notifier);
        await s.acceptInvite(await s.previewInvite(InviteCode.parse(code)!));
      });
      final ctl = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first)).read(syncProvider.notifier);
      await tester.runAsync(ctl.syncNow);
      await _wait(tester);
      expect(server.wallets[walletId]!.members.keys, unorderedEquals(['an', 'binh']));
      expect(find.byKey(const Key('share.member.binh')), findsOneWidget);
      expect(find.textContaining('Mã an toàn'), findsWidgets);

      // Hạ quyền rồi thu hồi.
      await centerOn(tester, find.byKey(const Key('share.menu.binh')));
      await tester.tap(find.byKey(const Key('share.menu.binh')));
      await settle(tester);
      await tester.tap(find.text('Đổi thành Người xem'));
      await _wait(tester);
      expect(server.wallets[walletId]!.members['binh'], 'viewer');
      await centerOn(tester, find.byKey(const Key('share.menu.binh')));
      await tester.tap(find.byKey(const Key('share.menu.binh')));
      await settle(tester);
      await tester.tap(find.text('Thu hồi quyền').last);
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Thu hồi quyền'));
      await _wait(tester);
      expect(server.wallets[walletId]!.members.keys, ['an']);
      expect(server.wallets[walletId]!.keyVer, 2);
      expect(find.byKey(const Key('share.member.binh')), findsNothing);
      expect(tester.takeException(), isNull);

      // Danh sách ví có huy hiệu ví chung.
      _go(tester, '/wallets');
      await settle(tester);
      expect(find.textContaining('Ví chung'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('P9 thành viên: dán mã, tham gia, thấy ví chỉ xem, rời ví - không tràn ($name)', (tester) async {
      final sodium = await tester.runAsync(testSodium);
      final server = FakeSyncServer();
      final an = makeServices(sodium!);
      final binh = makeServices(sodium);
      late String walletId;
      late String code;
      late ProviderContainer ownerC;
      await tester.runAsync(() async {
        ownerC = await _headless(an, server, 'an');
        final repo = ownerC.read(ledgerProvider.notifier);
        final w = repo.saveWallet(
          Wallet(id: repo.newId(), name: 'Quỹ gia đình', type: WalletType.cash, currency: Currency.vnd),
        );
        walletId = w.id;
        repo.saveTxn(
          Txn(
            id: repo.newId(),
            walletId: w.id,
            kind: TxnKind.expense,
            amount: 250000,
            date: CivilDate.fromDateTime(DateTime.now()),
            note: 'Đi chợ cuối tuần',
          ),
        );
        final s = ownerC.read(syncProvider.notifier);
        await s.syncNow();
        await s.shareWallet(w.id);
        code = (await s.createInvite(w.id, WalletRole.viewer)).link('https://qulythuchi.tsudev.com');
        await _headless(binh, server, 'binh');
      });
      await setSurface(tester, size);
      await pumpApp(tester, binh, extra: [syncConfigProvider.overrideWithValue(_config(server, 'binh'))]);

      _go(tester, '/wallets');
      await settle(tester);
      await tester.tap(find.byKey(const Key('wallets.join')));
      await settle(tester);
      await tester.enterText(find.byKey(const Key('join.code')), 'Mời bạn: $code');
      await tester.tap(find.byKey(const Key('join.preview')));
      await _wait(tester);
      expect(find.textContaining('Người xem'), findsWidgets);
      await centerOn(tester, find.byKey(const Key('join.accept')));
      await tester.tap(find.byKey(const Key('join.accept')));
      await _wait(tester);
      expect(find.text('Đang chờ chủ ví xác nhận'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.runAsync(ownerC.read(syncProvider.notifier).syncNow);
      final ctl = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first)).read(syncProvider.notifier);
      await tester.runAsync(ctl.syncNow);
      await _wait(tester);
      _go(tester, '/wallets');
      await settle(tester);
      expect(find.text('Quỹ gia đình'), findsOneWidget);
      expect(find.textContaining('Ví chung (Người xem)'), findsOneWidget);
      _go(tester, '/transactions');
      await settle(tester);
      expect(find.textContaining('Đi chợ cuối tuần'), findsWidgets);
      expect(tester.takeException(), isNull);

      // Thông tin ví chỉ đọc; vào thành viên ⇒ rời ví.
      _go(tester, '/wallets/$walletId');
      await settle(tester);
      expect(find.text('Lưu'), findsNothing);
      await centerOn(tester, find.byKey(const Key('wallet.members')));
      await tester.tap(find.byKey(const Key('wallet.members')));
      await _wait(tester);
      await centerOn(tester, find.byKey(const Key('share.leave')));
      await tester.tap(find.byKey(const Key('share.leave')));
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Rời ví chung'));
      await _wait(tester);
      expect(server.wallets[walletId]!.members.keys, ['an']);
      _go(tester, '/wallets');
      await settle(tester);
      expect(find.text('Quỹ gia đình'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
