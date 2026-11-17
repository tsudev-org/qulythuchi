import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:sodium/sodium_sumo.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

import 'envelope.dart';
import 'recovery_phrase.dart';

/// Mật khẩu mã hóa không đạt yêu cầu tối thiểu.
final class WeakPasswordException implements Exception {
  const WeakPasswordException();
  @override
  String toString() => 'WeakPasswordException: mật khẩu mã hóa cần ít nhất ${KeyHierarchy.minPasswordLength} ký tự';
}

/// Tham số Argon2id lưu kèm gói khóa.
@immutable
final class KdfParams {
  const KdfParams({required this.salt, required this.opsLimit, required this.memLimit});

  /// Mặc định: 3 lượt, 64 MiB - chạy được trên điện thoại tầm trung và web, vượt mức tối thiểu OWASP.
  static const defaultOps = 3;
  static const defaultMem = 64 * 1024 * 1024;

  /// Sàn chấp nhận khi mở khóa (OWASP: m=19 MiB, t=2). Máy chủ không thể ép tham số yếu hơn.
  static const minOps = 2;
  static const minMem = 19 * 1024 * 1024;

  final Uint8List salt;
  final int opsLimit;
  final int memLimit;

  Map<String, Object?> toJson() => {'alg': 'argon2id13', 'salt': base64.encode(salt), 'ops': opsLimit, 'mem': memLimit};

  static KdfParams fromJson(Map<String, Object?> json) {
    if (json['alg'] != 'argon2id13') throw const FormatException('Thuật toán KDF không hỗ trợ');
    return KdfParams(
      salt: base64.decode(json['salt']! as String),
      opsLimit: json['ops']! as int,
      memLimit: json['mem']! as int,
    );
  }
}

/// Gói khóa của tài khoản - lưu trên máy chủ, mọi phần bí mật đều đã bọc (ADR-0002).
@immutable
final class AccountKeyBundle {
  const AccountKeyBundle({
    required this.kdf,
    required this.masterByPassword,
    required this.masterByRecovery,
    required this.kemPublicKey,
    required this.kemSecretWrapped,
    required this.boxPublicKey,
    required this.boxSecretWrapped,
  });

  static const version = 1;

  final KdfParams kdf;
  final Uint8List masterByPassword;
  final Uint8List masterByRecovery;

  /// Khóa công khai X-Wing (ML-KEM-768 + X25519) để người khác chia sẻ khóa ví (P9).
  final Uint8List kemPublicKey;
  final Uint8List kemSecretWrapped;

  /// Khóa công khai X25519 để Email Worker niêm phong email chuyển tiếp (ADR-0006).
  final Uint8List boxPublicKey;
  final Uint8List boxSecretWrapped;

  AccountKeyBundle copyWith({KdfParams? kdf, Uint8List? masterByPassword, Uint8List? masterByRecovery}) =>
      AccountKeyBundle(
        kdf: kdf ?? this.kdf,
        masterByPassword: masterByPassword ?? this.masterByPassword,
        masterByRecovery: masterByRecovery ?? this.masterByRecovery,
        kemPublicKey: kemPublicKey,
        kemSecretWrapped: kemSecretWrapped,
        boxPublicKey: boxPublicKey,
        boxSecretWrapped: boxSecretWrapped,
      );

  Map<String, Object?> toJson() => {
    'v': version,
    'kdf': kdf.toJson(),
    'mkPw': base64.encode(masterByPassword),
    'mkRc': base64.encode(masterByRecovery),
    'kemPk': base64.encode(kemPublicKey),
    'kemSk': base64.encode(kemSecretWrapped),
    'boxPk': base64.encode(boxPublicKey),
    'boxSk': base64.encode(boxSecretWrapped),
  };

  static AccountKeyBundle fromJson(Map<String, Object?> json) {
    try {
      if (json['v'] != version) throw const FormatException('Phiên bản gói khóa không hỗ trợ');
      Uint8List b(String k) => base64.decode(json[k]! as String);
      return AccountKeyBundle(
        kdf: KdfParams.fromJson((json['kdf']! as Map).cast<String, Object?>()),
        masterByPassword: b('mkPw'),
        masterByRecovery: b('mkRc'),
        kemPublicKey: b('kemPk'),
        kemSecretWrapped: b('kemSk'),
        boxPublicKey: b('boxPk'),
        boxSecretWrapped: b('boxSk'),
      );
    } on FormatException {
      rethrow;
    } on Object {
      throw const FormatException('Gói khóa hỏng');
    }
  }
}

/// Kết quả tạo tài khoản mã hóa. Người gọi PHẢI hiển thị [recoveryWords] một lần rồi bỏ đi,
/// và gọi `masterKey.dispose()` khi khóa app.
final class AccountSetup {
  AccountSetup(this.bundle, this.masterKey, this.recoveryWords);
  final AccountKeyBundle bundle;
  final SecureKey masterKey;
  final List<String> recoveryWords;
}

/// Khóa danh tính đã mở.
final class IdentityKeys {
  IdentityKeys(this.kem, this.box);
  final KeyPair kem;
  final KeyPair box;

  void dispose() {
    kem.secretKey.dispose();
    box.secretKey.dispose();
  }
}

/// Phân cấp khóa E2EE (ADR-0002).
final class KeyHierarchy {
  KeyHierarchy(this._sodium, {@visibleForTesting this.allowWeakKdf = false}) : _envelope = Envelope(_sodium);

  final SodiumSumo _sodium;
  final Envelope _envelope;

  /// Chỉ cho test: cho phép tham số Argon2id nhỏ để test chạy nhanh.
  final bool allowWeakKdf;

  static const keyBytes = 32;
  static const minPasswordLength = 10;
  static const _recoveryContext = 'QTRECOV1';
  static const _shareContext = 'QTSHARE1';

  Envelope get envelope => _envelope;

  SecureKey _passwordKek(String password, KdfParams params) {
    if (!allowWeakKdf && (params.opsLimit < KdfParams.minOps || params.memLimit < KdfParams.minMem)) {
      throw const FormatException('Tham số KDF yếu hơn mức sàn - từ chối');
    }
    if (params.salt.length != _sodium.crypto.pwhash.saltBytes) throw const FormatException('Salt sai độ dài');
    // NFKC: cùng mật khẩu tiếng Việt gõ trên iOS/Windows/Linux phải ra cùng byte.
    final bytes = Int8List.fromList(utf8.encode(normalizePassword(password)));
    return _sodium.crypto.pwhash.callRaw(
      outLen: keyBytes,
      password: bytes,
      salt: params.salt,
      opsLimit: params.opsLimit,
      memLimit: params.memLimit,
      alg: CryptoPwhashAlgorithm.argon2id13,
    );
  }

  SecureKey _recoveryKek(Uint8List entropy) {
    final ikm = _sodium.secureCopy(entropy);
    try {
      return _sodium.crypto.kdf.deriveFromKey(
        masterKey: ikm,
        context: _recoveryContext,
        subkeyId: BigInt.one,
        subkeyLen: keyBytes,
      );
    } finally {
      ikm.dispose();
    }
  }

  Uint8List _wrap(SecureKey kek, SecureKey payload, EnvelopeContext ctx) {
    final bytes = payload.extractBytes();
    try {
      return _envelope.seal(bytes, kek, ctx);
    } finally {
      bytes.fillRange(0, bytes.length, 0);
    }
  }

  SecureKey _unwrap(SecureKey kek, Uint8List wrapped, EnvelopeContext ctx) {
    final bytes = _envelope.open(wrapped, kek, ctx);
    try {
      return _sodium.secureCopy(bytes);
    } finally {
      bytes.fillRange(0, bytes.length, 0);
    }
  }

  KdfParams newKdfParams({int? opsLimit, int? memLimit}) => KdfParams(
    salt: _sodium.randombytes.buf(_sodium.crypto.pwhash.saltBytes),
    opsLimit: opsLimit ?? KdfParams.defaultOps,
    memLimit: memLimit ?? KdfParams.defaultMem,
  );

  /// Chuẩn hóa Unicode NFKC cho mật khẩu mã hóa.
  static String normalizePassword(String password) => unorm.nfkc(password);

  static void checkPassword(String password) {
    if (normalizePassword(password).runes.length < minPasswordLength) throw const WeakPasswordException();
  }

  /// Tạo tài khoản mã hóa mới: khóa chủ, khóa danh tính, 24 từ khôi phục.
  AccountSetup createAccount(String password, {KdfParams? kdf}) {
    checkPassword(password);
    final params = kdf ?? newKdfParams();
    final master = _sodium.secureRandom(keyBytes);
    final entropy = _sodium.randombytes.buf(RecoveryPhrase.entropyBytes);
    final words = RecoveryPhrase.fromEntropy(entropy);
    final pwKek = _passwordKek(password, params);
    final rcKek = _recoveryKek(entropy);
    entropy.fillRange(0, entropy.length, 0);
    final kem = _sodium.crypto.kem.keyPair();
    final box = _sodium.crypto.box.keyPair();
    try {
      final bundle = AccountKeyBundle(
        kdf: params,
        masterByPassword: _wrap(pwKek, master, EnvelopeContext.masterKey('password')),
        masterByRecovery: _wrap(rcKek, master, EnvelopeContext.masterKey('recovery')),
        kemPublicKey: kem.publicKey,
        kemSecretWrapped: _wrap(master, kem.secretKey, EnvelopeContext.identityKey('kem')),
        boxPublicKey: box.publicKey,
        boxSecretWrapped: _wrap(master, box.secretKey, EnvelopeContext.identityKey('box')),
      );
      return AccountSetup(bundle, master, words);
    } finally {
      pwKek.dispose();
      rcKek.dispose();
      kem.secretKey.dispose();
      box.secretKey.dispose();
    }
  }

  /// Mở khóa chủ bằng mật khẩu. Sai mật khẩu ⇒ [EnvelopeException].
  SecureKey unlockWithPassword(AccountKeyBundle bundle, String password) {
    final kek = _passwordKek(password, bundle.kdf);
    try {
      return _unwrap(kek, bundle.masterByPassword, EnvelopeContext.masterKey('password'));
    } finally {
      kek.dispose();
    }
  }

  /// Mở khóa chủ bằng 24 từ. Sai từ/tổng kiểm ⇒ [RecoveryPhraseException]; sai khóa ⇒ [EnvelopeException].
  SecureKey unlockWithRecovery(AccountKeyBundle bundle, List<String> words) {
    final entropy = RecoveryPhrase.toEntropy(words);
    final kek = _recoveryKek(entropy);
    entropy.fillRange(0, entropy.length, 0);
    try {
      return _unwrap(kek, bundle.masterByRecovery, EnvelopeContext.masterKey('recovery'));
    } finally {
      kek.dispose();
    }
  }

  /// Đổi mật khẩu mã hóa: chỉ bọc lại khóa chủ, dữ liệu giữ nguyên. Salt mới mỗi lần.
  AccountKeyBundle changePassword(AccountKeyBundle bundle, SecureKey master, String newPassword, {KdfParams? kdf}) {
    checkPassword(newPassword);
    final params = kdf ?? newKdfParams(opsLimit: bundle.kdf.opsLimit, memLimit: bundle.kdf.memLimit);
    final kek = _passwordKek(newPassword, params);
    try {
      return bundle.copyWith(kdf: params, masterByPassword: _wrap(kek, master, EnvelopeContext.masterKey('password')));
    } finally {
      kek.dispose();
    }
  }

  /// Cấp 24 từ mới (vô hiệu bộ cũ).
  (AccountKeyBundle, List<String>) rotateRecovery(AccountKeyBundle bundle, SecureKey master) {
    final entropy = _sodium.randombytes.buf(RecoveryPhrase.entropyBytes);
    final words = RecoveryPhrase.fromEntropy(entropy);
    final kek = _recoveryKek(entropy);
    entropy.fillRange(0, entropy.length, 0);
    try {
      return (bundle.copyWith(masterByRecovery: _wrap(kek, master, EnvelopeContext.masterKey('recovery'))), words);
    } finally {
      kek.dispose();
    }
  }

  /// Tạo khóa ví mới, trả về khóa và bản bọc bởi khóa chủ.
  (SecureKey, Uint8List) createWalletKey(SecureKey master, String walletId) {
    final key = _sodium.secureRandom(keyBytes);
    return (key, _wrap(master, key, EnvelopeContext.walletKey(walletId)));
  }

  SecureKey openWalletKey(SecureKey master, String walletId, Uint8List wrapped) =>
      _unwrap(master, wrapped, EnvelopeContext.walletKey(walletId));

  IdentityKeys openIdentity(AccountKeyBundle bundle, SecureKey master) {
    final kemSk = _unwrap(master, bundle.kemSecretWrapped, EnvelopeContext.identityKey('kem'));
    final boxSk = _unwrap(master, bundle.boxSecretWrapped, EnvelopeContext.identityKey('box'));
    return IdentityKeys(
      KeyPair(publicKey: bundle.kemPublicKey, secretKey: kemSk),
      KeyPair(publicKey: bundle.boxPublicKey, secretKey: boxSk),
    );
  }

  /// Chia sẻ khóa ví tới thành viên qua X-Wing (lai hậu lượng tử). Đầu ra: bản mã KEM ‖ phong bì.
  Uint8List shareWalletKey(SecureKey walletKey, String walletId, Uint8List recipientKemPublicKey) {
    final enc = _sodium.crypto.kem.enc(publicKey: recipientKemPublicKey);
    final kek = _sodium.crypto.kdf.deriveFromKey(
      masterKey: enc.sharedSecret,
      context: _shareContext,
      subkeyId: BigInt.one,
      subkeyLen: keyBytes,
    );
    try {
      final sealed = _wrap(kek, walletKey, EnvelopeContext.walletKey(walletId));
      return Uint8List(enc.ciphertext.length + sealed.length)
        ..setAll(0, enc.ciphertext)
        ..setAll(enc.ciphertext.length, sealed);
    } finally {
      kek.dispose();
      enc.sharedSecret.dispose();
    }
  }

  SecureKey receiveWalletKey(Uint8List shared, String walletId, IdentityKeys identity) {
    final ctBytes = _sodium.crypto.kem.ciphertextBytes;
    if (shared.length <= ctBytes) throw const EnvelopeException();
    final SecureKey secret;
    try {
      secret = _sodium.crypto.kem.dec(
        ciphertext: Uint8List.sublistView(shared, 0, ctBytes),
        secretKey: identity.kem.secretKey,
      );
    } on SodiumException {
      throw const EnvelopeException();
    }
    final kek = _sodium.crypto.kdf.deriveFromKey(
      masterKey: secret,
      context: _shareContext,
      subkeyId: BigInt.one,
      subkeyLen: keyBytes,
    );
    try {
      return _unwrap(kek, Uint8List.sublistView(shared, ctBytes), EnvelopeContext.walletKey(walletId));
    } finally {
      kek.dispose();
      secret.dispose();
    }
  }

  /// Mở email đã được Email Worker niêm phong (crypto_box_seal, ADR-0006).
  Uint8List openSealedEmail(Uint8List sealed, IdentityKeys identity) {
    try {
      return _sodium.crypto.box.sealOpen(
        cipherText: sealed,
        publicKey: identity.box.publicKey,
        secretKey: identity.box.secretKey,
      );
    } on SodiumException {
      throw const EnvelopeException();
    }
  }
}
