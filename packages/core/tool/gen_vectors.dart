// Sinh vector đối chiếu phong bì v1 cho các bản cài khác (Worker TypeScript, kiểm độc lập).
// Khóa và nonce CỐ ĐỊNH chỉ dùng ở đây. Chạy: dart run tool/gen_vectors.dart > ../../conformance/envelope-v1.json
// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:typed_data';

import 'package:qulythuchi_core/qulythuchi_core.dart';
import 'package:sodium/sodium_sumo.dart';

String hex(List<int> b) => b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
Uint8List seq(int n, int start) => Uint8List.fromList(List.generate(n, (i) => (start + i) & 0xff));

Future<void> main() async {
  final sodium = await SodiumSumoInit.init();
  final env = Envelope(sodium);
  final key = sodium.secureCopy(seq(32, 0x00));
  final nonce = seq(24, 0xa0);
  const id = '0f8fad5b-d9cb-469f-a165-70867728950e';
  const wallet = '7c9e6679-7425-40de-944b-e07fc1f90ae7';
  final clock = HlcClock('vec', now: () => 1763337600000);
  final rec = SyncRecord(
    id: id,
    type: 'txn',
    walletId: wallet,
  ).setAll({'amount': 50000, 'kind': 'expense', 'note': 'Phở bò', 'date': '2026-11-17'}, clock);
  final cases = <Map<String, Object?>>[];
  void add(String name, EnvelopeContext ctx, List<int> plain) {
    // ignore: invalid_use_of_visible_for_testing_member
    final sealed = env.seal(Uint8List.fromList(plain), key, ctx, nonce: nonce);
    cases.add({
      'name': name,
      'context': ctx.value,
      'padBlock': ctx.padBlock,
      'plaintextHex': hex(plain),
      'sealedHex': hex(sealed),
    });
  }

  add('record', EnvelopeContext.record(type: 'txn', recordId: id, walletId: wallet), rec.toBytes());
  add('record-account', EnvelopeContext.record(type: 'category', recordId: id), utf8.encode('{}'));
  add('master-key', EnvelopeContext.masterKey('password'), seq(32, 0x40));
  add('empty', EnvelopeContext.backup('b1'), const []);

  final pwKdf = KdfParams(salt: seq(16, 0x10), opsLimit: 1, memLimit: 8192);
  final kek = sodium.crypto.pwhash.callRaw(
    outLen: 32,
    password: Int8List.fromList(utf8.encode(KeyHierarchy.normalizePassword('Mật khẩu Việt 2026'))),
    salt: pwKdf.salt,
    opsLimit: 1,
    memLimit: 8192,
    alg: CryptoPwhashAlgorithm.argon2id13,
  );
  final rcKek = sodium.crypto.kdf.deriveFromKey(
    masterKey: sodium.secureCopy(seq(32, 0x80)),
    context: 'QTRECOV1',
    subkeyId: BigInt.one,
    subkeyLen: 32,
  );

  print(
    const JsonEncoder.withIndent('  ').convert({
      'description': 'Vector đối chiếu phong bì Quly Thu Chi v1 (ADR-0002). SINH TỰ ĐỘNG - không sửa tay.',
      'generator': 'packages/core/tool/gen_vectors.dart',
      'libsodium': sodium.version.toString(),
      'format': 'Q T 0x01 0x01 | nonce(24) | xchacha20poly1305_ietf(sodium_pad(plain, padBlock), aad = header(4) | utf8(context))',
      'keyHex': hex(key.extractBytes()),
      'nonceHex': hex(nonce),
      'envelopes': cases,
      'argon2id': {
        'passwordNfkc': 'Mật khẩu Việt 2026',
        'saltHex': hex(pwKdf.salt),
        'ops': 1,
        'mem': 8192,
        'keyHex': hex(kek.extractBytes()),
      },
      'recoveryKdf': {
        'entropyHex': hex(seq(32, 0x80)),
        'context': 'QTRECOV1',
        'subkeyId': 1,
        'keyHex': hex(rcKek.extractBytes()),
        'words': RecoveryPhrase.fromEntropy(seq(32, 0x80)),
      },
      'hlc': Hlc(1763337600000, 10, 'vec').toString(),
      'canonicalJson': canonicalJson({
        'b': [1, 'Việt'],
        'a': null,
      }),
    }),
  );
}
