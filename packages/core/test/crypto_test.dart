import 'dart:convert';
import 'dart:typed_data';

import 'package:qulythuchi_core/qulythuchi_core.dart';
import 'package:sodium/sodium_sumo.dart';
import 'package:test/test.dart';

const id1 = '0f8fad5b-d9cb-469f-a165-70867728950e';
const w1 = '7c9e6679-7425-40de-944b-e07fc1f90ae7';
const w2 = '16fd2706-8baf-433b-82eb-8c7fada847da';

void main() {
  late SodiumSumo sodium;
  late KeyHierarchy keys;
  late KdfParams fastKdf;

  setUpAll(() async {
    sodium = await SodiumSumoInit.init();
    keys = KeyHierarchy(sodium, allowWeakKdf: true);
    fastKdf = keys.newKdfParams(opsLimit: 1, memLimit: 8192);
  });

  group('Envelope', () {
    test('mở đúng ngữ cảnh, đệm giấu độ dài', () {
      final env = Envelope(sodium);
      final key = sodium.secureRandom(32);
      final ctx = EnvelopeContext.record(type: 'txn', recordId: id1, walletId: w1);
      final short = env.seal(Uint8List.fromList([1]), key, ctx);
      final longer = env.seal(Uint8List.fromList(List.filled(200, 7)), key, ctx);
      expect(short.length, longer.length); // cùng khối 256
      expect(env.open(short, key, ctx), [1]);
      expect(short.sublist(0, 4), [0x51, 0x54, 1, 1]);
    });

    test('sai khóa / sai ngữ cảnh / bị sửa / cắt ngắn ⇒ EnvelopeException', () {
      final env = Envelope(sodium);
      final key = sodium.secureRandom(32);
      final ctx = EnvelopeContext.record(type: 'txn', recordId: id1, walletId: w1);
      final sealed = env.seal(Uint8List.fromList(utf8.encode('bí mật')), key, ctx);
      final ex = throwsA(isA<EnvelopeException>());
      expect(() => env.open(sealed, sodium.secureRandom(32), ctx), ex);
      expect(() => env.open(sealed, key, EnvelopeContext.record(type: 'txn', recordId: id1, walletId: w2)), ex);
      expect(() => env.open(sealed, key, EnvelopeContext.record(type: 'wallet', recordId: id1, walletId: w1)), ex);
      final tampered = Uint8List.fromList(sealed)..[40] ^= 1;
      expect(() => env.open(tampered, key, ctx), ex);
      final badHeader = Uint8List.fromList(sealed)..[2] = 9;
      expect(() => env.open(badHeader, key, ctx), ex);
      expect(() => env.open(Uint8List(10), key, ctx), ex);
      expect(() => EnvelopeContext.record(type: 'TXN|x', recordId: id1), throwsArgumentError);
    });

    test('nonce khác nhau mỗi lần mã hóa', () {
      final env = Envelope(sodium);
      final key = sodium.secureRandom(32);
      final ctx = EnvelopeContext.backup('b1');
      final a = env.seal(Uint8List(5), key, ctx);
      final b = env.seal(Uint8List(5), key, ctx);
      expect(a.sublist(4, 28), isNot(equals(b.sublist(4, 28))));
    });
  });

  group('RecoveryPhrase', () {
    test('vector BIP39 chuẩn (entropy toàn 0x00 và 0xff)', () {
      final zeros = RecoveryPhrase.fromEntropy(Uint8List(32));
      expect(zeros.first, 'abandon');
      expect(zeros.last, 'art');
      final ff = RecoveryPhrase.fromEntropy(Uint8List.fromList(List.filled(32, 0xff)));
      expect(ff.join(' '), '${List.filled(23, 'zoo').join(' ')} vote');
      expect(RecoveryPhrase.toEntropy(ff), List.filled(32, 0xff));
    });

    test('từ chối sai số từ, từ lạ, sai tổng kiểm; chuẩn hóa đầu vào', () {
      final words = RecoveryPhrase.fromEntropy(sodium.randombytes.buf(32));
      expect(RecoveryPhrase.normalize('  ${words.join('   ').toUpperCase()}\n'), words);
      expect(() => RecoveryPhrase.toEntropy(words.sublist(1)), throwsA(isA<RecoveryPhraseException>()));
      expect(() => RecoveryPhrase.toEntropy([...words.sublist(1), 'xxxx']), throwsA(isA<RecoveryPhraseException>()));
      final swapped = [...words]..[0] = words[0] == 'abandon' ? 'ability' : 'abandon';
      expect(() => RecoveryPhrase.toEntropy(swapped), throwsA(isA<RecoveryPhraseException>()));
    });
  });

  group('KeyHierarchy', () {
    test('tạo tài khoản, mở bằng mật khẩu và bằng 24 từ ra cùng khóa chủ', () {
      final setup = keys.createAccount('mật khẩu rất dài 123', kdf: fastKdf);
      final json = jsonDecode(jsonEncode(setup.bundle.toJson())) as Map<String, Object?>;
      final bundle = AccountKeyBundle.fromJson(json);
      final byPw = keys.unlockWithPassword(bundle, 'mật khẩu rất dài 123');
      final byRc = keys.unlockWithRecovery(bundle, setup.recoveryWords);
      expect(byPw.extractBytes(), setup.masterKey.extractBytes());
      expect(byRc.extractBytes(), setup.masterKey.extractBytes());
      expect(() => keys.unlockWithPassword(bundle, 'sai mật khẩu 12345'), throwsA(isA<EnvelopeException>()));
    });

    test('mật khẩu tiếng Việt NFC và NFD mở như nhau', () {
      const nfc = 'Tiền bạc Việt Nam';
      const nfd = 'Tiền bạc Việt Nam';
      expect(nfc == nfd, isFalse);
      final setup = keys.createAccount(nfc, kdf: fastKdf);
      expect(keys.unlockWithPassword(setup.bundle, nfd).extractBytes(), setup.masterKey.extractBytes());
    });

    test('mật khẩu ngắn bị từ chối; máy chủ không ép được tham số KDF yếu', () {
      expect(() => keys.createAccount('ngan', kdf: fastKdf), throwsA(isA<WeakPasswordException>()));
      final strict = KeyHierarchy(sodium);
      final setup = keys.createAccount('mật khẩu rất dài 123', kdf: fastKdf);
      expect(() => strict.unlockWithPassword(setup.bundle, 'mật khẩu rất dài 123'), throwsFormatException);
      expect(() => AccountKeyBundle.fromJson({'v': 9}), throwsFormatException);
      expect(() => AccountKeyBundle.fromJson({'v': 1, 'kdf': 5}), throwsFormatException);
    });

    test('đổi mật khẩu và xoay 24 từ giữ nguyên khóa chủ, vô hiệu bản cũ', () {
      final setup = keys.createAccount('mật khẩu cũ 1234567', kdf: fastKdf);
      final changed = keys.changePassword(setup.bundle, setup.masterKey, 'mật khẩu mới 7654321');
      expect(changed.kdf.salt, isNot(equals(setup.bundle.kdf.salt)));
      expect(keys.unlockWithPassword(changed, 'mật khẩu mới 7654321').extractBytes(), setup.masterKey.extractBytes());
      expect(() => keys.unlockWithPassword(changed, 'mật khẩu cũ 1234567'), throwsA(isA<EnvelopeException>()));
      final (rotated, newWords) = keys.rotateRecovery(changed, setup.masterKey);
      expect(keys.unlockWithRecovery(rotated, newWords).extractBytes(), setup.masterKey.extractBytes());
      expect(() => keys.unlockWithRecovery(rotated, setup.recoveryWords), throwsA(isA<EnvelopeException>()));
    });

    test('khóa ví ràng buộc id ví; chia sẻ qua X-Wing; mở email niêm phong', () {
      final alice = keys.createAccount('alice password 123', kdf: fastKdf);
      final bob = keys.createAccount('bob password 12345', kdf: fastKdf);
      final (walletKey, wrapped) = keys.createWalletKey(alice.masterKey, w1);
      expect(keys.openWalletKey(alice.masterKey, w1, wrapped).extractBytes(), walletKey.extractBytes());
      expect(() => keys.openWalletKey(alice.masterKey, w2, wrapped), throwsA(isA<EnvelopeException>()));

      final shared = keys.shareWalletKey(walletKey, w1, bob.bundle.kemPublicKey);
      final bobId = keys.openIdentity(bob.bundle, bob.masterKey);
      expect(keys.receiveWalletKey(shared, w1, bobId).extractBytes(), walletKey.extractBytes());
      expect(() => keys.receiveWalletKey(shared, w2, bobId), throwsA(isA<EnvelopeException>()));
      final aliceId = keys.openIdentity(alice.bundle, alice.masterKey);
      expect(() => keys.receiveWalletKey(shared, w1, aliceId), throwsA(isA<EnvelopeException>()));
      expect(() => keys.receiveWalletKey(Uint8List(10), w1, bobId), throwsA(isA<EnvelopeException>()));

      final sealed = sodium.crypto.box.seal(
        message: Uint8List.fromList(utf8.encode('VCB: -50,000VND')),
        publicKey: bob.bundle.boxPublicKey,
      );
      expect(utf8.decode(keys.openSealedEmail(sealed, bobId)), 'VCB: -50,000VND');
      expect(() => keys.openSealedEmail(sealed, aliceId), throwsA(isA<EnvelopeException>()));
      bobId.dispose();
      aliceId.dispose();
    });
  });

  group('RecordCipher', () {
    test('khứ hồi và chặn tráo bản ghi giữa id/ví/loại', () {
      final cipher = RecordCipher(Envelope(sodium));
      final key = sodium.secureRandom(32);
      final rec = SyncRecord(id: id1, type: 'txn', walletId: w1).set('amount', 50000, HlcClock('a'));
      final sealed = cipher.seal(rec, key);
      expect(cipher.open(sealed, key, type: 'txn', recordId: id1, walletId: w1).toBytes(), rec.toBytes());
      final ex = throwsA(isA<EnvelopeException>());
      expect(() => cipher.open(sealed, key, type: 'txn', recordId: id1, walletId: w2), ex);
      expect(
        () => cipher.open(sealed, key, type: 'txn', recordId: '16fd2706-8baf-433b-82eb-8c7fada847da', walletId: w1),
        ex,
      );
    });
  });
}
