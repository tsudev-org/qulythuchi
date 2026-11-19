import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulythuchi/domain/default_categories.dart';
import 'package:qulythuchi/state/ledger_repository.dart';
import 'package:qulythuchi/state/providers.dart';
import 'package:qulythuchi/state/sync_controller.dart';
import 'package:qulythuchi/sync/pkce.dart';
import 'package:qulythuchi/sync/shared_wallets.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import 'fake_sync_server.dart';
import 'helpers.dart';

/// Ví chung (P9, ADR-0015): engine + mật mã THẬT, máy chủ giả theo hợp đồng `services/sync-api`.
final class Device {
  Device(this.services, this.c);
  final AppServices services;
  final ProviderContainer c;
  SyncController get sync => c.read(syncProvider.notifier);
  SyncState get state => c.read(syncProvider);
  LedgerNotifier get ledger => c.read(ledgerProvider.notifier);
  LedgerData get data => c.read(ledgerProvider);
  SharedOverview? get shared => c.read(sharedWalletsProvider).overview;
}

Future<Device> device(FakeSyncServer server, String user, {bool withAccount = true}) async {
  final services = makeServices(await testSodium());
  final c = ProviderContainer(
    overrides: [
      servicesProvider.overrideWithValue(services),
      syncConfigProvider.overrideWithValue(
        SyncConfig(
          httpClient: server.client,
          login: (s) async {
            final req = LoginRequest.create('http://127.0.0.1:5000/callback');
            return (callback: LoginCallback.ok('code:$user:${req.challenge}'), request: req, platform: 'linux');
          },
          autoSync: false,
        ),
      ),
    ],
  );
  addTearDown(c.dispose);
  final d = Device(services, c);
  if (withAccount) {
    c.read(sessionProvider.notifier).createAccount(testPassword, DefaultCategoryLocale.vi);
    c.read(sessionProvider.notifier).finishOnboarding();
    d.data;
  }
  await d.sync.signIn();
  return d;
}

final today = CivilDate(2026, 11, 19);

Txn spend(Device d, String walletId, int amount, {String? note, String? categoryId}) => d.ledger.saveTxn(
  Txn(
    id: d.ledger.newId(),
    walletId: walletId,
    kind: TxnKind.expense,
    amount: amount,
    date: today,
    note: note,
    categoryId: categoryId,
  ),
);

/// An tạo ví "Chi tiêu nhà", chia sẻ và mời [who] với quyền [role]; [who] nhận; An hoàn tất; [who] đồng bộ.
Future<(Device, Device, Wallet)> family(FakeSyncServer server, {WalletRole role = WalletRole.editor}) async {
  final an = await device(server, 'an');
  final w = an.ledger.saveWallet(
    Wallet(id: an.ledger.newId(), name: 'Chi tiêu nhà', type: WalletType.cash, currency: Currency.vnd),
  );
  final food = an.data.categories.firstWhere((c) => c.kind == CategoryKind.expense && c.parentId != null);
  spend(an, w.id, 120000, note: 'Chợ sáng', categoryId: food.id);
  await an.sync.syncNow();
  await an.sync.shareWallet(w.id);
  final code = await an.sync.createInvite(w.id, role);

  final binh = await device(server, 'binh');
  await binh.sync.syncNow();
  final preview = await binh.sync.previewInvite(InviteCode.parse(code.link('https://qulythuchi.tsudev.com'))!);
  expect(preview.walletId, w.id);
  expect(preview.role, role);
  expect(preview.state, 'open');
  await binh.sync.acceptInvite(preview);
  expect(binh.shared!.pending.single.walletId, w.id);

  await an.sync.syncNow(); // hoàn tất: kiểm bằng chứng, chia khóa
  await binh.sync.syncNow();
  return (an, binh, w);
}

void main() {
  late FakeSyncServer server;
  setUp(() => server = FakeSyncServer());

  test('chia sẻ, mời, nhận: thành viên thấy ví + giao dịch + tên danh mục; máy chủ chỉ có bản mã', () async {
    final (an, binh, w) = await family(server);
    expect(an.data.isShared(w.id), isTrue);
    expect(an.data.canManage(w.id), isTrue);
    expect(binh.data.wallets.map((x) => x.name), ['Chi tiêu nhà']);
    expect(binh.data.canWrite(w.id), isTrue);
    expect(binh.data.canManage(w.id), isFalse);
    final t = binh.data.txns.single;
    expect(t.note, 'Chợ sáng');
    expect(binh.data.category(t.categoryId)?.name, an.data.category(t.categoryId)!.name);
    expect(binh.data.skipped, 0);
    // Bản ghi đã rời không gian tài khoản của An; không có bản rõ trên máy chủ.
    expect(server.user('an').records.values.where((r) => r['wallet_id'] == w.id), isEmpty);
    final dump = jsonEncode([
      server.wallets[w.id]!.records,
      server.wallets[w.id]!.shares.map((k, v) => MapEntry(k, v.values.toList())),
      server.invites,
    ]);
    for (final secret in ['Chợ', 'Chi tiêu nhà', '120000']) {
      expect(dump.contains(secret), isFalse, reason: secret);
    }
    final ov = an.shared!.wallet(w.id)!;
    expect(ov.members.map((m) => m.role), [WalletRole.owner, WalletRole.editor]);
    expect(ov.invites, isEmpty);

    // Bình ghi, An thấy.
    spend(binh, w.id, 45000, note: 'Bánh mì');
    await binh.sync.syncNow();
    expect(binh.state.pending, 0);
    await an.sync.syncNow();
    expect(an.data.txns.map((x) => x.note), containsAll(['Chợ sáng', 'Bánh mì']));
    // Người ghi không sửa được thông tin ví.
    expect(
      () => binh.ledger.saveWallet(Wallet(id: w.id, name: 'Của Bình', type: WalletType.cash, currency: Currency.vnd)),
      throwsA(isA<LedgerException>().having((e) => e.code, 'code', 'ownerOnly')),
    );
  });

  test('người xem: thấy dữ liệu, không ghi được; hạ/nâng quyền có hiệu lực ở lượt đồng bộ sau', () async {
    final (an, binh, w) = await family(server, role: WalletRole.viewer);
    expect(binh.data.txns, hasLength(1));
    expect(binh.data.canWrite(w.id), isFalse);
    expect(() => spend(binh, w.id, 1000), throwsA(isA<LedgerException>().having((e) => e.code, 'code', 'readOnly')));
    await an.sync.changeRole(w.id, 'binh', WalletRole.editor);
    await binh.sync.syncNow();
    expect(binh.data.canWrite(w.id), isTrue);
    spend(binh, w.id, 1000, note: 'Được ghi rồi');
    await binh.sync.syncNow();
    expect(server.wallets[w.id]!.records, hasLength(4)); // ví + giao dịch An + danh mục An + giao dịch Bình
  });

  test('thu hồi = xoay khóa: người bị thu hồi mất ví trên máy; người còn lại đọc tiếp bằng khóa mới', () async {
    final (an, binh, w) = await family(server);
    final code = await an.sync.createInvite(w.id, WalletRole.editor);
    final chi = await device(server, 'chi');
    await chi.sync.syncNow();
    await chi.sync.acceptInvite(await chi.sync.previewInvite(code));
    await an.sync.syncNow();
    await chi.sync.syncNow();
    expect(chi.data.txns, hasLength(1));

    await an.sync.removeMember(w.id, 'binh');
    await an.sync.syncNow();
    final sw = server.wallets[w.id]!;
    expect(sw.keyVer, 2);
    expect(sw.members.keys, unorderedEquals(['an', 'chi']));
    // Chủ ví đã mã hóa lại và đẩy mọi bản ghi bằng phiên bản mới.
    expect(sw.records.values.map((r) => r['key_ver']).toSet(), {2});

    spend(an, w.id, 300000, note: 'Tiền điện');
    await an.sync.syncNow();
    await binh.sync.syncNow();
    expect(binh.data.wallets, isEmpty);
    expect(binh.data.txns, isEmpty);
    expect(binh.services.store.walletRecords(w.id), isEmpty);
    await chi.sync.syncNow();
    expect(chi.data.txns.map((x) => x.note), containsAll(['Chợ sáng', 'Tiền điện']));
    expect(chi.data.skipped, 0);
    // Chi ghi bằng khóa mới được.
    spend(chi, w.id, 5000, note: 'Gửi xe');
    await chi.sync.syncNow();
    expect(chi.state.pending, 0);
  });

  test('thành viên tự rời ⇒ chủ ví tự xoay khóa ở lượt đồng bộ sau', () async {
    final (an, binh, w) = await family(server);
    await binh.sync.leaveWallet(w.id);
    expect(binh.data.wallets, isEmpty);
    expect(server.wallets[w.id]!.needsRotation, isTrue);
    await an.sync.syncNow();
    expect(server.wallets[w.id]!.keyVer, 2);
    expect(server.wallets[w.id]!.needsRotation, isFalse);
  });

  test('máy chủ độc tráo khóa công khai của người nhận ⇒ chủ ví hủy lời mời, không chia khóa', () async {
    final an = await device(server, 'an');
    final w = an.ledger.saveWallet(
      Wallet(id: an.ledger.newId(), name: 'Nhà', type: WalletType.cash, currency: Currency.vnd),
    );
    await an.sync.syncNow();
    await an.sync.shareWallet(w.id);
    final code = await an.sync.createInvite(w.id, WalletRole.editor);
    final mallory = await device(server, 'mallory');
    await mallory.sync.syncNow();
    final binh = await device(server, 'binh');
    await binh.sync.syncNow();
    await binh.sync.acceptInvite(await binh.sync.previewInvite(code));
    server.tamperAccepted = (a) => a['kem_pk'] = server.user('mallory').bundle!['kemPk'];
    await an.sync.syncNow();
    expect(an.c.read(sharedWalletsProvider).badInvites, 1);
    expect(server.wallets[w.id]!.members.keys, ['an']);
    expect(server.invites, isEmpty);
  });

  test('thiết bị thứ hai của chủ ví: nhận ví chung, hoàn tất lời mời tạo ở máy kia', () async {
    final an = await device(server, 'an');
    final w = an.ledger.saveWallet(
      Wallet(id: an.ledger.newId(), name: 'Nhà', type: WalletType.cash, currency: Currency.vnd),
    );
    spend(an, w.id, 70000, note: 'Gạo');
    await an.sync.syncNow();
    await an.sync.shareWallet(w.id);
    final code = await an.sync.createInvite(w.id, WalletRole.viewer);

    final an2 = await device(server, 'an', withAccount: false);
    await an2.sync.adoptRemote((await an2.sync.fetchRemoteAccount())!, password: testPassword);
    await an2.sync.syncNow();
    expect(an2.data.isShared(w.id), isTrue);
    expect(an2.data.txns.single.note, 'Gạo');

    final binh = await device(server, 'binh');
    await binh.sync.syncNow();
    await binh.sync.acceptInvite(await binh.sync.previewInvite(code));
    await an2.sync.syncNow(); // máy thứ hai hoàn tất bằng bí mật đồng bộ từ máy thứ nhất
    await binh.sync.syncNow();
    expect(binh.data.txns.single.note, 'Gạo');
    expect(binh.data.canWrite(w.id), isFalse);
  });
}
