import 'dart:typed_data';

import 'package:sodium/sodium_sumo.dart';

import '../sync/sync_record.dart';
import 'envelope.dart';

/// Mã hóa/giải mã [SyncRecord] với AAD ràng buộc ví + loại + id (chống tráo bản ghi trên máy chủ).
final class RecordCipher {
  RecordCipher(this._envelope);
  final Envelope _envelope;

  Uint8List seal(SyncRecord record, SecureKey key) => _envelope.seal(
    Uint8List.fromList(record.toBytes()),
    key,
    EnvelopeContext.record(type: record.type, recordId: record.id, walletId: record.walletId),
  );

  /// [type], [recordId], [walletId] lấy từ siêu dữ liệu máy chủ; bản rõ phải khớp, nếu không ⇒ lỗi.
  SyncRecord open(Uint8List sealed, SecureKey key, {required String type, required String recordId, String? walletId}) {
    final plain = _envelope.open(
      sealed,
      key,
      EnvelopeContext.record(type: type, recordId: recordId, walletId: walletId),
    );
    final SyncRecord record;
    try {
      record = SyncRecord.fromBytes(plain);
    } on Object {
      throw const EnvelopeException();
    }
    if (record.type != type || record.id != recordId || record.walletId != walletId) {
      throw const EnvelopeException();
    }
    return record;
  }
}
