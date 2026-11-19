import 'dart:typed_data';

import 'package:qulythuchi_core/qulythuchi_core.dart';
import 'package:sodium/sodium_sumo.dart';
import 'package:test/test.dart';

const w1 = '7c9e6679-7425-40de-944b-e07fc1f90ae7';
const w2 = '16fd2706-8baf-433b-82eb-8c7fada847da';

void main() {
  late SodiumSumo sodium;
  late KeyHierarchy keys;
  late WalletSharing sharing;
  late AccountSetup alice;
  late AccountSetup bob;
  late IdentityKeys aliceId;
  late IdentityKeys bobId;
  final ex = throwsA(isA<EnvelopeException>());

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
    keys = KeyHierarchy(sodium, allowWeakKdf: true);
    sharing = WalletSharing(sodium);
    final kdf = keys.newKdfParams(opsLimit: 1, memLimit: 8192);
    alice = keys.createAccount('mật khẩu của An 2026', kdf: kdf);
    bob = keys.createAccount('mật khẩu của Bình 2026', kdf: kdf);
    aliceId = keys.openIdentity(alice.bundle, alice.masterKey);
    bobId = keys.openIdentity(bob.bundle, bob.masterKey);
  });

  group('InviteCode', () {
    test('mã và liên kết đọc lại được; bí mật nằm sau #', () {
      final code = sharing.newInvite();
      expect(code.inviteId, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4')));
      final again = InviteCode.parse(code.encode())!;
      expect(again.inviteId, code.inviteId);
      expect(again.secret, code.secret);
      final link = code.link('https://qulythuchi.tsudev.com');
      expect(link.split('#').first, isNot(contains(code.encode().split('.').last)));
      expect(InviteCode.parse('Mời bạn vào ví: $link nhé')!.secret, code.secret);
    });

    test('mã sai định dạng ⇒ null', () {
      final code = sharing.newInvite().encode();
      expect(InviteCode.parse(''), isNull);
      expect(InviteCode.parse(code.substring(0, code.length - 1)), isNull);
      expect(InviteCode.parse('${code}x'), isNull);
      expect(InviteCode.parse(code.toUpperCase()), isNull);
    });
  });

  group('Bằng chứng nhận lời mời', () {
    test('chỉ người có bí mật làm được; ràng buộc ví, lời mời, khóa công khai', () {
      final code = sharing.newInvite();
      final proof = sharing.acceptProof(
        secret: code.secret,
        walletId: w1,
        inviteId: code.inviteId,
        kemPublicKey: bob.bundle.kemPublicKey,
      );
      bool ok({Uint8List? p, Uint8List? secret, String wallet = w1, String? invite, Uint8List? pk}) =>
          sharing.verifyAcceptProof(
            proof: p ?? proof,
            secret: secret ?? code.secret,
            walletId: wallet,
            inviteId: invite ?? code.inviteId,
            kemPublicKey: pk ?? bob.bundle.kemPublicKey,
          );
      expect(ok(), isTrue);
      // Máy chủ độc thay khóa công khai của mình vào ⇒ chủ ví phát hiện.
      expect(ok(pk: alice.bundle.kemPublicKey), isFalse);
      expect(ok(wallet: w2), isFalse);
      expect(ok(invite: sharing.newInvite().inviteId), isFalse);
      expect(ok(secret: sharing.newInvite().secret), isFalse);
      expect(ok(p: Uint8List(32)), isFalse);
      expect(ok(p: Uint8List(31)), isFalse);
    });
  });

  group('Chia sẻ khóa ví', () {
    test('người nhận mở được bằng khóa danh tính + bí mật cặp', () {
      final vk = sharing.newWalletKey();
      final secret = sharing.newInvite().secret;
      final blob = sharing.shareKey(
        walletKey: vk,
        walletId: w1,
        version: 3,
        recipientKemPublicKey: bob.bundle.kemPublicKey,
        pairSecret: secret,
      );
      expect(WalletSharing.isShareBlob(blob), isTrue);
      final got = sharing.openShare(blob, walletId: w1, version: 3, identity: bobId, pairSecret: secret);
      expect(got.extractBytes(), vk.extractBytes());
    });

    test('thiếu một trong hai, sai ví/phiên bản, bị sửa ⇒ không mở được', () {
      final vk = sharing.newWalletKey();
      final secret = sharing.newInvite().secret;
      final blob = sharing.shareKey(
        walletKey: vk,
        walletId: w1,
        version: 1,
        recipientKemPublicKey: bob.bundle.kemPublicKey,
        pairSecret: secret,
      );
      // Kẻ chỉ có mã mời (lộ qua tin nhắn) nhưng không có khóa riêng danh tính.
      expect(() => sharing.openShare(blob, walletId: w1, version: 1, identity: aliceId, pairSecret: secret), ex);
      // Máy chủ độc không có bí mật cặp.
      expect(() => sharing.openShare(blob, walletId: w1, version: 1, identity: bobId, pairSecret: Uint8List(32)), ex);
      expect(() => sharing.openShare(blob, walletId: w2, version: 1, identity: bobId, pairSecret: secret), ex);
      expect(() => sharing.openShare(blob, walletId: w1, version: 2, identity: bobId, pairSecret: secret), ex);
      final bad = Uint8List.fromList(blob)..[blob.length - 1] ^= 1;
      expect(() => sharing.openShare(bad, walletId: w1, version: 1, identity: bobId, pairSecret: secret), ex);
      expect(() => sharing.openShare(Uint8List(10), walletId: w1, version: 1, identity: bobId, pairSecret: secret), ex);
      expect(
        () => sharing.openShare(blob.sublist(0, 1200), walletId: w1, version: 1, identity: bobId, pairSecret: secret),
        ex,
      );
    });

    test('máy chủ độc tự tạo khối bằng khóa của nó ⇒ người nhận từ chối', () {
      // Kẻ tấn công biết khóa công khai của Bình nhưng không có bí mật cặp: tự sinh khóa ví của mình.
      final evilKey = sharing.newWalletKey();
      final forged = sharing.shareKey(
        walletKey: evilKey,
        walletId: w1,
        version: 1,
        recipientKemPublicKey: bob.bundle.kemPublicKey,
        pairSecret: sharing.newInvite().secret,
      );
      final secret = sharing.newInvite().secret;
      expect(() => sharing.openShare(forged, walletId: w1, version: 1, identity: bobId, pairSecret: secret), ex);
    });

    test('bản bọc cho chính mình: theo ví + phiên bản, chỉ khóa chủ mở được', () {
      final vk = sharing.newWalletKey();
      final wrapped = sharing.wrapForSelf(alice.masterKey, vk, w1, 2);
      expect(sharing.openForSelf(alice.masterKey, wrapped, w1, 2).extractBytes(), vk.extractBytes());
      expect(() => sharing.openForSelf(bob.masterKey, wrapped, w1, 2), ex);
      expect(() => sharing.openForSelf(alice.masterKey, wrapped, w1, 1), ex);
      expect(() => EnvelopeContext.sharedWalletKey(w1, 0), throwsArgumentError);
      // Khóa ví riêng (ngữ cảnh wk|) không bị nhầm thành khóa ví chung.
      final (_, privateWrapped) = keys.createWalletKey(alice.masterKey, w1);
      expect(() => sharing.openForSelf(alice.masterKey, privateWrapped, w1, 1), ex);
    });

    test('xoay khóa: khóa mới không mở được bản ghi cũ và ngược lại', () {
      final cipher = RecordCipher(sharing.envelope);
      final clock = HlcClock('t', now: () => 1763337600000);
      final r = SyncRecord(id: w2, type: 'txn', walletId: w1).set('amount', 120000, clock);
      final v1 = sharing.newWalletKey();
      final v2 = sharing.newWalletKey();
      final old = cipher.seal(r, v1);
      expect(() => cipher.open(old, v2, type: 'txn', recordId: w2, walletId: w1), ex);
      final resealed = cipher.seal(cipher.open(old, v1, type: 'txn', recordId: w2, walletId: w1), v2);
      expect(cipher.open(resealed, v2, type: 'txn', recordId: w2, walletId: w1)['amount'], 120000);
    });
  });

  group('Mã an toàn', () {
    test('12 chữ số, ổn định, khác nhau giữa hai danh tính', () {
      final a = sharing.safetyCode(alice.bundle.kemPublicKey, alice.bundle.boxPublicKey);
      expect(a, matches(RegExp(r'^\d{4} \d{4} \d{4}$')));
      expect(sharing.safetyCode(alice.bundle.kemPublicKey, alice.bundle.boxPublicKey), a);
      expect(sharing.safetyCode(bob.bundle.kemPublicKey, bob.bundle.boxPublicKey), isNot(a));
    });
  });

  test('WalletRole', () {
    expect(WalletRole.fromName('editor'), WalletRole.editor);
    expect(WalletRole.fromName('admin'), isNull);
    expect(WalletRole.viewer.canWrite, isFalse);
    expect(WalletRole.editor.canManage, isFalse);
    expect(WalletRole.owner.canManage, isTrue);
  });
}
