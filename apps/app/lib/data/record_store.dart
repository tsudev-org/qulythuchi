import 'dart:typed_data';

import 'package:sqlite3/common.dart';

/// Một dòng bản ghi đã niêm phong. Máy chủ (P6) chỉ thấy đúng các cột này - không có bản rõ.
final class SealedRow {
  const SealedRow({required this.id, required this.type, required this.walletId, required this.sealed, this.rev = 0});
  final String id;
  final String type;
  final String? walletId;
  final Uint8List sealed;

  /// Phiên bản phía máy chủ đã biết (0 = chưa đồng bộ).
  final int rev;
}

/// Kho thô trên SQLite: chỉ lưu byte đã mã hóa và siêu dữ liệu tối thiểu (ADR-0001 mục 4).
final class RecordStore {
  RecordStore(this._db) {
    _migrate();
  }

  final CommonDatabase _db;
  static const schemaVersion = 1;

  void _migrate() {
    final v = _db.userVersion;
    if (v > schemaVersion) throw StateError('CSDL được tạo bởi phiên bản app mới hơn');
    if (v < 1) {
      _db.execute('''
        CREATE TABLE IF NOT EXISTS meta (k TEXT PRIMARY KEY, v BLOB NOT NULL) STRICT;
        CREATE TABLE IF NOT EXISTS wallet_keys (wallet_id TEXT PRIMARY KEY, wrapped BLOB NOT NULL, dirty INTEGER NOT NULL DEFAULT 1) STRICT;
        CREATE TABLE IF NOT EXISTS records (
          id TEXT PRIMARY KEY,
          type TEXT NOT NULL,
          wallet_id TEXT,
          sealed BLOB NOT NULL,
          rev INTEGER NOT NULL DEFAULT 0,
          dirty INTEGER NOT NULL DEFAULT 1
        ) STRICT;
        CREATE INDEX IF NOT EXISTS records_dirty ON records(dirty) WHERE dirty = 1;
      ''');
      _db.userVersion = 1;
    }
  }

  Uint8List? getMeta(String key) {
    final rs = _db.select('SELECT v FROM meta WHERE k = ?', [key]);
    return rs.isEmpty ? null : rs.first['v'] as Uint8List;
  }

  void putMeta(String key, Uint8List value) =>
      _db.execute('INSERT INTO meta(k, v) VALUES(?, ?) ON CONFLICT(k) DO UPDATE SET v = excluded.v', [key, value]);

  void deleteMeta(String key) => _db.execute('DELETE FROM meta WHERE k = ?', [key]);

  Map<String, Uint8List> walletKeys() => {
    for (final r in _db.select('SELECT wallet_id, wrapped FROM wallet_keys'))
      r['wallet_id'] as String: r['wrapped'] as Uint8List,
  };

  void putWalletKey(String walletId, Uint8List wrapped) => _db.execute(
    'INSERT INTO wallet_keys(wallet_id, wrapped) VALUES(?, ?) '
    'ON CONFLICT(wallet_id) DO UPDATE SET wrapped = excluded.wrapped, dirty = 1',
    [walletId, wrapped],
  );

  List<SealedRow> allRecords() => [
    for (final r in _db.select('SELECT id, type, wallet_id, sealed, rev FROM records'))
      SealedRow(
        id: r['id'] as String,
        type: r['type'] as String,
        walletId: r['wallet_id'] as String?,
        sealed: r['sealed'] as Uint8List,
        rev: r['rev'] as int,
      ),
  ];

  /// Ghi nhiều bản ghi trong một giao tác (chuyển ví = 2 bản ghi phải cùng thành công hoặc cùng thất bại).
  void putRecords(Iterable<SealedRow> rows) {
    transaction(() {
      final stmt = _db.prepare(
        'INSERT INTO records(id, type, wallet_id, sealed, dirty) VALUES(?, ?, ?, ?, 1) '
        'ON CONFLICT(id) DO UPDATE SET sealed = excluded.sealed, dirty = 1 '
        'WHERE records.type = excluded.type AND records.wallet_id IS excluded.wallet_id',
      );
      try {
        for (final row in rows) {
          stmt.execute([row.id, row.type, row.walletId, row.sealed]);
          if (_db.updatedRows != 1) throw StateError('Bản ghi đổi loại hoặc đổi ví - từ chối');
        }
      } finally {
        stmt.close();
      }
    });
  }

  T transaction<T>(T Function() body) {
    _db.execute('BEGIN IMMEDIATE');
    try {
      final result = body();
      _db.execute('COMMIT');
      return result;
    } on Object {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  /// Xóa sạch dữ liệu cục bộ (đặt lại app).
  void wipe() {
    transaction(() {
      _db.execute('DELETE FROM records');
      _db.execute('DELETE FROM wallet_keys');
      _db.execute('DELETE FROM meta');
    });
  }

  void close() => _db.close();
}
