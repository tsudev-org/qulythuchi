import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:sodium/sodium_sumo.dart';

import '../crypto/envelope.dart';
import '../domain/models.dart';
import '../sync/sync_record.dart';

/// Ảnh đính kèm của một giao dịch (ADR-0017). Bản ghi loại [RecordTypes.attachment], cùng ví với giao dịch; id bản ghi
/// = id tệp. [fileKey] là khóa tệp riêng - nằm trong bản ghi đã niêm phong bằng khóa ví, KHÔNG bao giờ rời máy dạng rõ.
/// Không lưu tên tệp gốc.
@immutable
final class Attachment {
  const Attachment({
    required this.id,
    required this.walletId,
    required this.txnId,
    required this.fileKey,
    required this.mime,
    required this.size,
    required this.width,
    required this.height,
  });

  /// Phiên bản định dạng tệp (ngữ cảnh `attf`).
  static const format = 1;

  /// Tối đa ảnh mỗi giao dịch.
  static const maxPerTxn = 5;

  final String id;
  final String? walletId;
  final String txnId;
  final Uint8List fileKey;
  final String mime;

  /// Byte bản rõ (JPEG đã làm sạch), trước khi đệm.
  final int size;
  final int width;
  final int height;

  Map<String, Object?> toValues() => {
    'txnId': txnId,
    'key': base64.encode(fileKey),
    'mime': mime,
    'size': size,
    'w': width,
    'h': height,
    'fmt': format,
  };

  /// null nếu bản ghi hỏng/thiếu trường hoặc định dạng mới hơn app này hiểu.
  static Attachment? fromRecord(SyncRecord r) {
    if (r.type != RecordTypes.attachment) return null;
    final txnId = r['txnId'];
    final key = r['key'];
    final mime = r['mime'];
    final size = r['size'];
    final w = r['w'];
    final h = r['h'];
    final fmt = r['fmt'];
    if (txnId is! String || key is! String || mime is! String || size is! int || w is! int || h is! int) return null;
    if (fmt != format) return null;
    final Uint8List k;
    try {
      k = base64.decode(key);
    } on FormatException {
      return null;
    }
    if (k.length != AttachmentCipher.keyBytes) return null;
    return Attachment(
      id: r.id,
      walletId: r.walletId,
      txnId: txnId,
      fileKey: k,
      mime: mime,
      size: size,
      width: w,
      height: h,
    );
  }
}

/// Mã hóa/giải mã nội dung tệp bằng khóa tệp riêng, ngữ cảnh `attf|ví|giao dịch|tệp`, phong bì v1.
final class AttachmentCipher {
  AttachmentCipher(this._sodium) : _envelope = Envelope(_sodium);

  final SodiumSumo _sodium;
  final Envelope _envelope;

  static const keyBytes = 32;

  /// Khóa tệp mới, ngẫu nhiên, không dùng lại.
  Uint8List newFileKey() => _sodium.randombytes.buf(keyBytes);

  EnvelopeContext _ctx(Attachment a) =>
      EnvelopeContext.attachmentFile(walletId: a.walletId, txnId: a.txnId, attachmentId: a.id);

  Uint8List seal(Uint8List plain, Attachment a) {
    final key = SecureKey.fromList(_sodium, a.fileKey);
    try {
      return _envelope.seal(plain, key, _ctx(a));
    } finally {
      key.dispose();
    }
  }

  /// Sai khóa/ngữ cảnh/bị sửa ⇒ [EnvelopeException]; cỡ bản rõ không khớp bản ghi ⇒ cũng [EnvelopeException].
  Uint8List open(Uint8List sealed, Attachment a) {
    final key = SecureKey.fromList(_sodium, a.fileKey);
    try {
      final plain = _envelope.open(sealed, key, _ctx(a));
      if (plain.length != a.size) throw const EnvelopeException();
      return plain;
    } finally {
      key.dispose();
    }
  }
}
