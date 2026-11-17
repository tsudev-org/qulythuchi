import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulythuchi/domain/default_categories.dart';
import 'package:qulythuchi/state/ledger_repository.dart';
import 'package:qulythuchi/state/providers.dart';
import 'package:qulythuchi/state/sync_controller.dart';
import 'package:qulythuchi/sync/pinned_roots.g.dart';
import 'package:qulythuchi/sync/pkce.dart';
import 'package:qulythuchi/sync/sync_engine.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import 'fake_sync_server.dart';
import 'helpers.dart';

/// Một thiết bị = một CSDL + kho khóa + ProviderContainer riêng, cùng nói chuyện với [FakeSyncServer].
final class Device {
  Device(this.services, this.c);
  final AppServices services;
  final ProviderContainer c;
  SyncController get sync => c.read(syncProvider.notifier);
  SyncState get state => c.read(syncProvider);
  LedgerNotifier get ledger => c.read(ledgerProvider.notifier);
  LedgerData get data => c.read(ledgerProvider);
}

LoginRunner fakeLogin(String user) => (server) async {
  final req = LoginRequest.create('http://127.0.0.1:5000/callback');
  return (callback: LoginCallback.ok('code:$user:${req.challenge}'), request: req, platform: 'linux');
};

Future<Device> device(FakeSyncServer server, String user, {bool withAccount = true}) async {
  final services = makeServices(await testSodium());
  final c = ProviderContainer(
    overrides: [
      servicesProvider.overrideWithValue(services),
      syncConfigProvider.overrideWithValue(
        SyncConfig(httpClient: server.client, login: fakeLogin(user), autoSync: false),
      ),
    ],
  );
  addTearDown(c.dispose);
  final d = Device(services, c);
  if (withAccount) {
    c.read(sessionProvider.notifier).createAccount(testPassword, DefaultCategoryLocale.vi);
    c.read(sessionProvider.notifier).finishOnboarding();
    d.data; // dựng ledger
  }
  return d;
}

final today = CivilDate(2026, 11, 18);

Wallet cashOf(Device d) =>
    d.ledger.saveWallet(Wallet(id: d.ledger.newId(), name: 'Tiền mặt', type: WalletType.cash, currency: Currency.vnd));

Txn spend(Device d, Wallet w, int amount, {String? id, String? note}) => d.ledger.saveTxn(
  Txn(id: id ?? d.ledger.newId(), walletId: w.id, kind: TxnKind.expense, amount: amount, date: today, note: note),
);

void main() {
  late FakeSyncServer server;
  setUp(() => server = FakeSyncServer());

  test('PKCE S256 khớp cài đặt độc lập (python hashlib)', () {
    // verifier/challenge tính bằng Python: base64url(sha256(v)) bỏ "=".
    const v = 'dBjftJeZ4CVP-mJ0kZvZ9-kXg3X2l1UwO-lyBAd-MmY';
    expect(
      base64Url.encode(sha256.convert(ascii.encode(v)).bytes).replaceAll('=', ''),
      'AWMW92YGelwFvvW5IuTNAUDTE2O4Jap4rW7_UryY9ZE',
    );
    final r = LoginRequest.create('http://127.0.0.1:5000/callback');
    expect(r.verifier.length, greaterThanOrEqualTo(43));
    expect(RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(r.challenge), isTrue);
    final url = r.startUrl(Uri.parse('https://qulythuchi.tsudev.com'));
    expect(url.path, '/auth/app/start');
    expect(url.queryParameters['code_challenge_method'], 'S256');
    expect(r.parseCallback(Uri.parse('http://127.0.0.1:5000/callback?state=khac&code=x')), isNull, reason: 'sai state');
    expect(r.parseCallback(Uri.parse('http://127.0.0.1:5000/callback?state=${r.state}&code=abc'))!.code, 'abc');
    expect(
      r.parseCallback(Uri.parse('http://127.0.0.1:5000/callback?state=${r.state}&error=access_denied'))!.error,
      'access_denied',
    );
  });

  test('tập CA ghim: mỗi khối PEM khớp vân tay DER đã ghi', () {
    final blocks = RegExp(r'-----BEGIN CERTIFICATE-----([\s\S]*?)-----END CERTIFICATE-----')
        .allMatches(pinnedRootsPem)
        .toList();
    expect(blocks, hasLength(pinnedRootInfo.length));
    for (var i = 0; i < blocks.length; i++) {
      final der = base64.decode(blocks[i].group(1)!.replaceAll(RegExp(r'\s'), ''));
      expect(sha256.convert(der).toString(), pinnedRootInfo[i].$3, reason: pinnedRootInfo[i].$1);
    }
    expect(
      pinnedRootInfo.map((e) => e.$1),
      containsAll(['GTS_Root_R4', 'ISRG_Root_X1', 'SSL.com_TLS_RSA_Root_CA_2022']),
    );
  });

  test('hai thiết bị: máy mới nhận tài khoản bằng mật khẩu, thấy đủ dữ liệu; máy chủ chỉ có bản mã', () async {
    final a = await device(server, 'u1');
    final w = cashOf(a);
    spend(a, w, 50000, note: 'Phở bò');
    expect(await a.sync.signIn(), isNull);
    await a.sync.syncNow();
    expect(a.state.phase, SyncPhase.idle);
    expect(a.state.pending, 0);
    final u = server.user('u1');
    expect(u.bundle, isNotNull);
    expect(u.walletKeys.keys, containsAll([w.id, '00000000-0000-4000-8000-000000000000']));
    expect(u.records.length, a.services.store.allRecords().length);
    // Không có bản rõ nào trên máy chủ.
    final dump = jsonEncode([u.records, u.walletKeys, u.bundle]);
    for (final secret in ['Phở', 'Ph\\u1edf', 'Tiền mặt', '50000']) {
      expect(dump.contains(secret), isFalse, reason: secret);
    }

    final b = await device(server, 'u1', withAccount: false);
    expect(await b.sync.signIn(), isNull);
    final remote = await b.sync.fetchRemoteAccount();
    expect(remote, isNotNull);
    await expectLater(b.sync.adoptRemote(remote!, password: 'sai-mat-khau-roi'), throwsA(isA<EnvelopeException>()));
    expect(b.services.vault.hasAccount, isFalse, reason: 'sai mật khẩu không để lại tài khoản dở');
    await b.sync.adoptRemote(remote, password: testPassword);
    expect(b.c.read(sessionProvider), SessionStatus.unlocked);
    expect(b.data.wallets.map((x) => x.name), contains('Tiền mặt'));
    expect(b.data.txns.single.note, 'Phở bò');
    expect(b.data.categories, isNotEmpty);
    expect(b.data.skipped, 0);
  });

  test('máy mới mở bằng 24 từ', () async {
    final a = await device(server, 'u1', withAccount: false);
    final words = a.c.read(sessionProvider.notifier).createAccount(testPassword, DefaultCategoryLocale.vi);
    a.c.read(sessionProvider.notifier).finishOnboarding();
    await a.sync.signIn();
    await a.sync.syncNow();
    final b = await device(server, 'u1', withAccount: false);
    await b.sync.signIn();
    await b.sync.adoptRemote((await b.sync.fetchRemoteAccount())!, words: words);
    expect(b.data.categories, isNotEmpty);
  });

  test('sửa đồng thời hai trường khác nhau trên hai máy ⇒ hội tụ, giữ cả hai; xóa lan truyền', () async {
    final a = await device(server, 'u1');
    final w = cashOf(a);
    final t = spend(a, w, 10000, note: 'ban đầu');
    await a.sync.signIn();
    await a.sync.syncNow();
    final b = await device(server, 'u1', withAccount: false);
    await b.sync.signIn();
    await b.sync.adoptRemote((await b.sync.fetchRemoteAccount())!, password: testPassword);

    // A sửa ghi chú, B sửa số tiền - chưa ai đồng bộ.
    spend(a, w, 10000, id: t.id, note: 'ghi chú từ A');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    spend(b, w, 25000, id: t.id, note: 'ban đầu');
    await a.sync.syncNow();
    await b.sync.syncNow(); // kéo bản A, hợp nhất, đẩy bản hợp nhất
    await a.sync.syncNow();
    for (final d in [a, b]) {
      final x = d.data.txn(t.id)!;
      expect(x.note, 'ghi chú từ A');
      expect(x.amount, 25000);
      expect(d.state.pending, 0);
    }

    b.ledger.deleteTxn(t.id);
    await b.sync.syncNow();
    expect(server.user('u1').records[t.id]!['deleted'], isTrue, reason: 'cờ bia mộ gửi lên máy chủ');
    await a.sync.syncNow();
    expect(a.data.txn(t.id), isNull);
  });

  test('đẩy lại lũy đẳng: lượt thứ hai không gửi gì, kéo về bản của chính mình không ghi lại', () async {
    final a = await device(server, 'u1');
    spend(a, cashOf(a), 1000);
    await a.sync.signIn();
    await a.sync.syncNow();
    final rev = server.user('u1').rev;
    server.paths.clear();
    await a.sync.syncNow();
    expect(server.user('u1').rev, rev);
    expect(server.paths.where((p) => p.contains('/sync/push')), isEmpty);
  });

  test('máy có tài khoản cục bộ KHÁC khóa chủ ⇒ chặn, không đẩy bản ghi nào', () async {
    final a = await device(server, 'u1');
    await a.sync.signIn();
    await a.sync.syncNow();
    final records = server.user('u1').records.length;
    final c = await device(server, 'u1');
    spend(c, cashOf(c), 999);
    await c.sync.signIn();
    await c.sync.syncNow();
    expect(c.state.phase, SyncPhase.blocked);
    expect(c.state.block, SyncBlock.differentAccount);
    expect(server.user('u1').records.length, records);
    expect(c.data.txns, hasLength(1), reason: 'dữ liệu máy C còn nguyên');
  });

  test('máy chủ tráo gói khóa sau khi đã ghim ⇒ identityChanged', () async {
    final a = await device(server, 'u1');
    await a.sync.signIn();
    await a.sync.syncNow();
    final other = await device(FakeSyncServer(), 'x');
    server.user('u1').bundle = other.services.vault.bundleJson;
    await a.sync.syncNow();
    expect(a.state.block, SyncBlock.identityChanged);
  });

  test('máy chủ quay lui rev ⇒ rollback, dừng đồng bộ', () async {
    final a = await device(server, 'u1');
    final w = cashOf(a);
    spend(a, w, 1);
    await a.sync.signIn();
    await a.sync.syncNow();
    server.user('u1').rev = 0; // khôi phục CSDL máy chủ từ bản cũ
    spend(a, w, 2);
    await a.sync.syncNow();
    expect(a.state.block, SyncBlock.rollback);
  });

  test('bản ghi bị tráo ví/hỏng trên máy chủ bị bỏ qua, không ghi đè bản cục bộ', () async {
    final a = await device(server, 'u1');
    final w = cashOf(a);
    final t = spend(a, w, 7000);
    await a.sync.signIn();
    await a.sync.syncNow();
    final u = server.user('u1');
    final rec = u.records[t.id]!;
    final bytes = base64.decode(rec['sealed']! as String)..[60] ^= 1;
    u.records[t.id] = {...rec, 'sealed': base64.encode(bytes), 'rev': ++u.rev};
    await a.sync.syncNow();
    expect(a.data.txn(t.id)!.amount, 7000);
  });

  test(
    'đổi mật khẩu ở máy A ⇒ máy B mở được bằng mật khẩu mới sau khi đồng bộ (gói khóa xác thực bằng khóa chủ)',
    () async {
      final a = await device(server, 'u1');
      await a.sync.signIn();
      await a.sync.syncNow();
      final b = await device(server, 'u1', withAccount: false);
      await b.sync.signIn();
      await b.sync.adoptRemote((await b.sync.fetchRemoteAccount())!, password: testPassword);

      a.services.vault.changePassword(testPassword, 'mat-khau-moi-123');
      await a.sync.syncNow();
      expect(a.services.vault.bundleDirty, isFalse);
      await b.sync.syncNow();
      b.c.read(sessionProvider.notifier).lock();
      await b.c.read(sessionProvider.notifier).unlockWithPassword('mat-khau-moi-123');
      expect(b.c.read(sessionProvider), SessionStatus.unlocked);
      b.c.read(sessionProvider.notifier).lock();
      await b.c.read(sessionProvider.notifier).unlockWithPassword('mat-khau-moi-123');
      expect(b.services.vault.isUnlocked, isTrue, reason: 'gói mới đã thành gói cục bộ');
      b.c.read(sessionProvider.notifier).lock();
      await expectLater(
        b.c.read(sessionProvider.notifier).unlockWithPassword(testPassword),
        throwsA(isA<EnvelopeException>()),
      );
    },
  );

  test('token: access hết hạn ⇒ refresh xoay vòng; refresh bị dùng lại ⇒ thu hồi, về trạng thái đăng xuất', () async {
    final a = await device(server, 'u1');
    await a.sync.signIn();
    final firstRefresh = await a.sync.api.tokens.readRefresh();
    server.expireAccessTokens();
    spend(a, cashOf(a), 5);
    await a.sync.syncNow();
    expect(a.state.phase, SyncPhase.idle);
    expect(await a.sync.api.tokens.readRefresh(), isNot(firstRefresh), reason: 'refresh đã xoay');
    expect(a.services.keyStorage.supported, isTrue);

    // Kẻ gian dùng lại refresh cũ ⇒ máy chủ thu hồi thiết bị.
    await a.sync.api.tokens.writeRefresh(firstRefresh!);
    server.expireAccessTokens();
    await a.sync.api.forceRefreshForTest().catchError((_) {});
    expect(a.state.signedIn, isFalse);
    expect(a.state.error, 'device_revoked');
    expect(await a.sync.api.tokens.readRefresh(), isNull);
  });

  test('thiết bị bị thu hồi từ máy khác ⇒ lượt đồng bộ sau về đăng xuất, dữ liệu cục bộ giữ nguyên', () async {
    final a = await device(server, 'u1');
    final b = await device(server, 'u1', withAccount: false);
    await a.sync.signIn();
    await a.sync.syncNow();
    await b.sync.signIn();
    await b.sync.adoptRemote((await b.sync.fetchRemoteAccount())!, password: testPassword);
    final devices = await a.sync.devices();
    expect(devices, hasLength(2));
    final other = devices.firstWhere((d) => d['current'] != true);
    await a.sync.revokeDevice(other['id']! as String);
    await b.sync.syncNow();
    expect(b.state.signedIn, isFalse);
    expect(b.data.categories, isNotEmpty);
  });

  test('máy đã gắn tài khoản tsudev u1 không đăng nhập được u2', () async {
    final a = await device(server, 'u1');
    await a.sync.signIn();
    await a.sync.syncNow();
    await a.sync.signOut();
    // Đăng xuất có chủ ý bỏ ràng buộc ⇒ đăng nhập u2 được (sẽ đẩy toàn bộ lên u2).
    final c = await device(server, 'u1');
    await c.sync.signIn();
    await c.sync.syncNow();
    expect(c.state.block, SyncBlock.differentAccount);
    final d = Device(
      c.services,
      ProviderContainer(
        overrides: [
          servicesProvider.overrideWithValue(c.services),
          syncConfigProvider.overrideWithValue(
            SyncConfig(httpClient: server.client, login: fakeLogin('u2'), autoSync: false),
          ),
        ],
      ),
    );
    addTearDown(d.c.dispose);
    expect(await d.sync.signIn(), 'otherUser');
  });

  test('tài khoản chờ xóa ⇒ chặn ghi; hủy xóa ⇒ đồng bộ lại', () async {
    final a = await device(server, 'u1');
    await a.sync.signIn();
    await a.sync.syncNow();
    await a.sync.requestDeletion();
    spend(a, cashOf(a), 3);
    await a.sync.syncNow();
    expect(a.state.block, SyncBlock.pendingDeletion);
    await a.sync.cancelDeletion();
    await a.sync.syncNow();
    expect(a.state.phase, SyncPhase.idle);
    expect(a.state.pending, 0);
  });

  test('máy chủ chưa có tài khoản ⇒ fetchRemoteAccount null; tạo mới rồi đẩy gói khóa', () async {
    final b = await device(server, 'u9', withAccount: false);
    expect(await b.sync.signIn(), isNull);
    expect(await b.sync.fetchRemoteAccount(), isNull);
    b.c.read(sessionProvider.notifier).createAccount(testPassword, DefaultCategoryLocale.vi);
    b.c.read(sessionProvider.notifier).finishOnboarding();
    await b.sync.syncNow();
    expect(server.user('u9').bundle, isNotNull);
    expect(server.user('u9').records, isNotEmpty);
  });

  test('kéo nhiều trang, lưu con trỏ sau mỗi trang', () async {
    final a = await device(server, 'u1');
    final w = cashOf(a);
    for (var i = 0; i < 7; i++) {
      spend(a, w, i + 1);
    }
    await a.sync.signIn();
    await a.sync.syncNow();
    final b = await device(server, 'u1', withAccount: false);
    await b.sync.signIn();
    final remote = (await b.sync.fetchRemoteAccount())!;
    b.services.vault.adoptRemoteAccount(
      bundleJson: remote.bundle,
      wrappedAccountKey: remote.wrappedAccountKey,
      walletKeys: remote.walletKeys,
      password: testPassword,
    );
    final engine = SyncEngine(
      api: b.sync.api,
      store: b.services.store,
      vault: b.services.vault,
      onApplied: () {},
      pageSize: 3,
    );
    final (n, skipped) = await engine.pull();
    expect(skipped, 0);
    expect(n, server.user('u1').records.length);
    expect(engine.cursor, server.user('u1').rev);
    expect(server.paths.where((p) => p.contains('/sync/pull')).length, greaterThan(3));
  });
}
