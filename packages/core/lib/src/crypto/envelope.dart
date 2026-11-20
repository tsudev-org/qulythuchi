import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:sodium/sodium_sumo.dart';

/// Giải mã thất bại. Thông điệp cố ý chung chung - không tiết lộ khóa sai hay dữ liệu bị sửa.
final class EnvelopeException implements Exception {
  const EnvelopeException();
  @override
  String toString() => 'EnvelopeException: không mở được dữ liệu mã hóa';
}

/// Ngữ cảnh ràng buộc vào AAD: bản mã chỉ mở được đúng chỗ nó được tạo ra (chống tráo bản ghi).
@immutable
final class EnvelopeContext {
  const EnvelopeContext._(this.value, this.padBlock);

  final String value;
  final int padBlock;

  static final _safe = RegExp(r'^[a-z0-9_-]{1,64}$');

  static String _part(String s) {
    if (!_safe.hasMatch(s)) throw ArgumentError.value(s, 'context part');
    return s;
  }

  /// Bản ghi đồng bộ trong một ví (hoặc cấp tài khoản khi [walletId] null).
  factory EnvelopeContext.record({required String type, required String recordId, String? walletId}) =>
      EnvelopeContext._('rec|${walletId == null ? 'acct' : _part(walletId)}|${_part(type)}|${_part(recordId)}', 256);

  /// Khóa chủ được bọc bởi KEK loại [kind] (`password`, `recovery`).
  factory EnvelopeContext.masterKey(String kind) => EnvelopeContext._('mk|${_part(kind)}', 16);

  /// Khóa ví được bọc bởi khóa chủ.
  factory EnvelopeContext.walletKey(String walletId) => EnvelopeContext._('wk|${_part(walletId)}', 16);

  /// Khóa ví chung phiên bản [version] (P9, ADR-0015): bọc bởi khóa chủ hoặc bởi KEK chia sẻ X-Wing + bí mật cặp.
  /// Phiên bản nằm trong AAD ⇒ máy chủ không đổi số phiên bản của một bản bọc được.
  factory EnvelopeContext.sharedWalletKey(String walletId, int version) {
    if (version < 1 || version > 0x7fffffff) throw ArgumentError.value(version, 'version');
    return EnvelopeContext._('swk|${_part(walletId)}|$version', 16);
  }

  /// Khóa bí mật danh tính được bọc bởi khóa chủ.
  factory EnvelopeContext.identityKey(String kind) => EnvelopeContext._('ik|${_part(kind)}', 16);

  /// Tệp đính kèm (ảnh hóa đơn) - ngữ cảnh `attf` (ADR-0017): gắn ví (hoặc `acct`) + giao dịch + tệp, khối đệm 64 KiB
  /// để giấu cỡ ảnh. Khóa là khóa tệp riêng (không phải khóa ví). Thay ngữ cảnh `att` cũ của ADR-0007 (chưa từng dùng).
  factory EnvelopeContext.attachmentFile({String? walletId, required String txnId, required String attachmentId}) =>
      EnvelopeContext._(
        'attf|${walletId == null ? 'acct' : _part(walletId)}|${_part(txnId)}|${_part(attachmentId)}',
        attachmentPadBlock,
      );

  static const attachmentPadBlock = 64 * 1024;

  /// Tệp sao lưu toàn bộ dữ liệu.
  factory EnvelopeContext.backup(String backupId) => EnvelopeContext._('bak|${_part(backupId)}', 4096);
}

/// Phong bì v1: `'Q' 'T' 0x01 0x01 ‖ nonce(24) ‖ XChaCha20-Poly1305-IETF(pad(bản rõ))`,
/// AAD = 4 byte đầu ‖ utf8(ngữ cảnh). Xem ADR-0002.
final class Envelope {
  Envelope(this._sodium);

  final SodiumSumo _sodium;

  static const version = 1;
  static const algXChaCha20Poly1305 = 1;
  static final Uint8List header = Uint8List.fromList([0x51, 0x54, version, algXChaCha20Poly1305]);
  static const nonceBytes = 24;
  static const tagBytes = 16;
  static const overhead = 4 + nonceBytes + tagBytes;

  Aead get _aead => _sodium.crypto.aeadXChaCha20Poly1305IETF;

  Uint8List _aad(EnvelopeContext context) {
    final ctx = utf8.encode(context.value);
    return Uint8List(header.length + ctx.length)
      ..setAll(0, header)
      ..setAll(header.length, ctx);
  }

  /// Mã hóa. [nonce] chỉ dùng cho vector đối chiếu - mã thật luôn để nonce ngẫu nhiên.
  Uint8List seal(Uint8List plaintext, SecureKey key, EnvelopeContext context, {@visibleForTesting Uint8List? nonce}) {
    final n = nonce ?? _sodium.randombytes.buf(nonceBytes);
    if (n.length != nonceBytes) throw ArgumentError('nonce phải 24 byte');
    final padded = _sodium.pad(plaintext, context.padBlock);
    final cipher = _aead.encrypt(message: padded, nonce: n, key: key, additionalData: _aad(context));
    return Uint8List(header.length + nonceBytes + cipher.length)
      ..setAll(0, header)
      ..setAll(header.length, n)
      ..setAll(header.length + nonceBytes, cipher);
  }

  /// Giải mã và kiểm toàn vẹn. Sai khóa, sai ngữ cảnh, bị sửa ⇒ [EnvelopeException].
  Uint8List open(Uint8List sealed, SecureKey key, EnvelopeContext context) {
    if (sealed.length < overhead) throw const EnvelopeException();
    for (var i = 0; i < header.length; i++) {
      if (sealed[i] != header[i]) throw const EnvelopeException();
    }
    final n = Uint8List.sublistView(sealed, header.length, header.length + nonceBytes);
    final cipher = Uint8List.sublistView(sealed, header.length + nonceBytes);
    try {
      final padded = _aead.decrypt(cipherText: cipher, nonce: n, key: key, additionalData: _aad(context));
      return _sodium.unpad(padded, context.padBlock);
    } on SodiumException {
      throw const EnvelopeException();
    }
  }
}
