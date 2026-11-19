import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:sodium/sodium_sumo.dart';

import '../crypto/envelope.dart';
import '../crypto/key_hierarchy.dart';

/// Quyền của một thành viên trong ví chung (ADR-0015 mục 3).
enum WalletRole {
  /// Chủ ví: mời, đổi quyền, thu hồi, xoay khóa, sửa thông tin ví.
  owner,

  /// Thêm/sửa/xóa giao dịch trong ví. Không sửa thông tin ví, không quản lý thành viên.
  editor,

  /// Chỉ xem.
  viewer;

  bool get canWrite => this != viewer;
  bool get canManage => this == owner;

  static WalletRole? fromName(Object? name) => values.where((r) => r.name == name).firstOrNull;
}

/// Mã mời: id lời mời (UUID v4, máy chủ biết) + bí mật 32 byte (máy chủ KHÔNG biết).
///
/// Mã đi qua kênh ngoài (Zalo, tin nhắn, QR gặp mặt). Bí mật làm hai việc: chứng minh người nhận lời mời đúng là người
/// cầm mã (máy chủ không giả được khóa công khai của người nhận) và trộn vào KEK chia sẻ khóa ví (máy chủ không giả
/// được khóa ví gửi cho người nhận). Xem ADR-0015 mục 2.
@immutable
final class InviteCode {
  InviteCode(this.inviteId, Uint8List secret) : secret = Uint8List.fromList(secret) {
    if (!_uuid.hasMatch(inviteId)) throw ArgumentError.value(inviteId, 'inviteId');
    if (secret.length != WalletSharing.secretBytes) throw ArgumentError('Bí mật lời mời phải 32 byte');
  }

  final String inviteId;
  final Uint8List secret;

  static final _uuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
  static final _pattern = RegExp(
    r'([0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12})\.([A-Za-z0-9_-]{43})(?![A-Za-z0-9_-])',
  );

  /// Dạng gõ/dán được: `<id>.<bí mật base64url không đệm>`.
  String encode() => '$inviteId.${base64Url.encode(secret).replaceAll('=', '')}';

  /// Liên kết mở web app. Bí mật nằm sau `#` nên KHÔNG được gửi tới máy chủ khi mở liên kết.
  String link(String origin) => '$origin/app/#/moi/${encode()}';

  /// Đọc mã từ chuỗi người dùng dán (mã trần hoặc cả liên kết). Sai định dạng ⇒ null.
  static InviteCode? parse(String input) {
    final m = _pattern.firstMatch(input.trim());
    if (m == null) return null;
    try {
      final secret = base64Url.decode('${m.group(2)!}=');
      if (secret.length != WalletSharing.secretBytes) return null;
      return InviteCode(m.group(1)!, secret);
    } on FormatException {
      return null;
    }
  }
}

/// Mật mã của ví chung (P9, ADR-0015). Chỉ ghép các hàm libsodium: X-Wing (`crypto_kem`), BLAKE2b có khóa
/// (`crypto_generichash`), phong bì v1 (XChaCha20-Poly1305). Không tự chế nguyên thủy mật mã.
final class WalletSharing {
  WalletSharing(this._sodium) : _envelope = Envelope(_sodium);

  final SodiumSumo _sodium;
  final Envelope _envelope;

  static const secretBytes = 32;
  static const keyBytes = KeyHierarchy.keyBytes;

  /// Đầu khối chia sẻ khóa: 'Q' 'S' phiên bản 1. Khối = đầu ‖ bản mã X-Wing ‖ phong bì v1 (ngữ cảnh `swk`).
  static final Uint8List shareHeader = Uint8List.fromList([0x51, 0x53, 0x01]);
  static const _proofLabel = 'QTINV1';
  static const _kekLabel = 'QTSHARE2';

  Envelope get envelope => _envelope;

  /// Khóa ví mới (256 bit ngẫu nhiên).
  SecureKey newWalletKey() => _sodium.secureRandom(keyBytes);

  /// Lời mời mới: UUID v4 + 32 byte bí mật, đều từ `randombytes`.
  InviteCode newInvite() {
    final b = _sodium.randombytes.buf(16);
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    final id =
        '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
    return InviteCode(id, _sodium.randombytes.buf(secretBytes));
  }

  /// Bằng chứng nhận lời mời: BLAKE2b-256 có khóa = bí mật lời mời, trên ví + lời mời + khóa công khai X-Wing của
  /// người nhận. Máy chủ chuyển nguyên cho chủ ví; không có bí mật thì không làm giả được.
  Uint8List acceptProof({
    required Uint8List secret,
    required String walletId,
    required String inviteId,
    required Uint8List kemPublicKey,
  }) {
    final key = _sodium.secureCopy(secret);
    try {
      final label = utf8.encode('$_proofLabel|$walletId|$inviteId|');
      final msg = Uint8List(label.length + kemPublicKey.length)
        ..setAll(0, label)
        ..setAll(label.length, kemPublicKey);
      return _sodium.crypto.genericHash(message: msg, outLen: 32, key: key);
    } finally {
      key.dispose();
    }
  }

  /// So bằng chứng theo thời gian hằng (`sodium_memcmp`).
  bool verifyAcceptProof({
    required Uint8List proof,
    required Uint8List secret,
    required String walletId,
    required String inviteId,
    required Uint8List kemPublicKey,
  }) {
    if (proof.length != 32) return false;
    final want = acceptProof(secret: secret, walletId: walletId, inviteId: inviteId, kemPublicKey: kemPublicKey);
    return _sodium.memcmp(proof, want);
  }

  /// KEK = BLAKE2b-256(khóa = bí mật cặp, "QTSHARE2" ‖ bí mật chung X-Wing ‖ bản mã X-Wing) - giống chế độ PSK của
  /// HPKE: phải có CẢ khóa riêng danh tính của người nhận LẪN bí mật cặp mới mở được.
  SecureKey _kek(Uint8List pairSecret, Uint8List sharedSecret, Uint8List kemCiphertext) {
    if (pairSecret.length != secretBytes) throw ArgumentError('Bí mật cặp phải 32 byte');
    final key = _sodium.secureCopy(pairSecret);
    final label = utf8.encode(_kekLabel);
    final msg = Uint8List(label.length + sharedSecret.length + kemCiphertext.length)
      ..setAll(0, label)
      ..setAll(label.length, sharedSecret)
      ..setAll(label.length + sharedSecret.length, kemCiphertext);
    try {
      final out = _sodium.crypto.genericHash(message: msg, outLen: keyBytes, key: key);
      try {
        return _sodium.secureCopy(out);
      } finally {
        out.fillRange(0, out.length, 0);
      }
    } finally {
      key.dispose();
      msg.fillRange(0, msg.length, 0);
    }
  }

  /// Chia sẻ khóa ví phiên bản [version] tới thành viên có khóa công khai X-Wing [recipientKemPublicKey].
  Uint8List shareKey({
    required SecureKey walletKey,
    required String walletId,
    required int version,
    required Uint8List recipientKemPublicKey,
    required Uint8List pairSecret,
  }) {
    final enc = _sodium.crypto.kem.enc(publicKey: recipientKemPublicKey);
    final ss = enc.sharedSecret.extractBytes();
    try {
      return sealShare(
        walletKey: walletKey,
        walletId: walletId,
        version: version,
        sharedSecret: ss,
        kemCiphertext: enc.ciphertext,
        pairSecret: pairSecret,
      );
    } finally {
      ss.fillRange(0, ss.length, 0);
      enc.sharedSecret.dispose();
    }
  }

  /// Phần đối xứng của [shareKey] (tách riêng để sinh vector đối chiếu với bí mật chung cố định).
  @visibleForTesting
  Uint8List sealShare({
    required SecureKey walletKey,
    required String walletId,
    required int version,
    required Uint8List sharedSecret,
    required Uint8List kemCiphertext,
    required Uint8List pairSecret,
    Uint8List? nonce,
  }) {
    final kek = _kek(pairSecret, sharedSecret, kemCiphertext);
    final raw = walletKey.extractBytes();
    try {
      // ignore: invalid_use_of_visible_for_testing_member
      final sealed = _envelope.seal(raw, kek, EnvelopeContext.sharedWalletKey(walletId, version), nonce: nonce);
      return Uint8List(shareHeader.length + kemCiphertext.length + sealed.length)
        ..setAll(0, shareHeader)
        ..setAll(shareHeader.length, kemCiphertext)
        ..setAll(shareHeader.length + kemCiphertext.length, sealed);
    } finally {
      raw.fillRange(0, raw.length, 0);
      kek.dispose();
    }
  }

  static bool isShareBlob(Uint8List blob) =>
      blob.length > shareHeader.length &&
      blob[0] == shareHeader[0] &&
      blob[1] == shareHeader[1] &&
      blob[2] == shareHeader[2];

  /// Mở khối chia sẻ. Sai khóa danh tính, sai bí mật cặp, sai ví/phiên bản, bị sửa ⇒ [EnvelopeException].
  SecureKey openShare(
    Uint8List blob, {
    required String walletId,
    required int version,
    required IdentityKeys identity,
    required Uint8List pairSecret,
  }) {
    final ctBytes = _sodium.crypto.kem.ciphertextBytes;
    if (!isShareBlob(blob) || blob.length <= shareHeader.length + ctBytes + Envelope.overhead) {
      throw const EnvelopeException();
    }
    final ct = Uint8List.sublistView(blob, shareHeader.length, shareHeader.length + ctBytes);
    final SecureKey ss;
    try {
      ss = _sodium.crypto.kem.dec(ciphertext: ct, secretKey: identity.kem.secretKey);
    } on SodiumException {
      throw const EnvelopeException();
    }
    final ssBytes = ss.extractBytes();
    final kek = _kek(pairSecret, ssBytes, ct);
    ssBytes.fillRange(0, ssBytes.length, 0);
    ss.dispose();
    try {
      return _openKey(kek, Uint8List.sublistView(blob, shareHeader.length + ctBytes), walletId, version);
    } finally {
      kek.dispose();
    }
  }

  /// Bọc khóa ví phiên bản [version] bằng khóa chủ - bản của chính tài khoản mình (mọi thiết bị của mình mở được).
  Uint8List wrapForSelf(SecureKey master, SecureKey walletKey, String walletId, int version) {
    final raw = walletKey.extractBytes();
    try {
      return _envelope.seal(raw, master, EnvelopeContext.sharedWalletKey(walletId, version));
    } finally {
      raw.fillRange(0, raw.length, 0);
    }
  }

  SecureKey openForSelf(SecureKey master, Uint8List wrapped, String walletId, int version) =>
      _openKey(master, wrapped, walletId, version);

  SecureKey _openKey(SecureKey kek, Uint8List sealed, String walletId, int version) {
    final raw = _envelope.open(sealed, kek, EnvelopeContext.sharedWalletKey(walletId, version));
    try {
      if (raw.length != keyBytes) throw const EnvelopeException();
      return _sodium.secureCopy(raw);
    } finally {
      raw.fillRange(0, raw.length, 0);
    }
  }

  /// Mã an toàn 12 chữ số của một danh tính (BLAKE2b của hai khóa công khai) để hai người so qua kênh ngoài.
  String safetyCode(Uint8List kemPublicKey, Uint8List boxPublicKey) {
    final label = utf8.encode('QTSAFE1');
    final msg = Uint8List(label.length + kemPublicKey.length + boxPublicKey.length)
      ..setAll(0, label)
      ..setAll(label.length, kemPublicKey)
      ..setAll(label.length + kemPublicKey.length, boxPublicKey);
    final h = _sodium.crypto.genericHash(message: msg, outLen: 16);
    var n = BigInt.zero;
    for (var i = 0; i < 8; i++) {
      n = (n << 8) | BigInt.from(h[i]);
    }
    final digits = (n % BigInt.from(10).pow(12)).toString().padLeft(12, '0');
    return '${digits.substring(0, 4)} ${digits.substring(4, 8)} ${digits.substring(8)}';
  }
}
