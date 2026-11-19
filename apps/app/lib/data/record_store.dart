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

/// Trạng thái cục bộ của một ví chung. [localVer]: phiên bản khóa đang niêm phong các bản ghi của ví trên máy này
/// (nhỏ hơn [keyVer] ⇒ cần mã hóa lại khi đã có khóa mới).
final class SharedWalletRow {
  const SharedWalletRow({
    required this.walletId,
    required this.role,
    required this.keyVer,
    required this.localVer,
    this.cursor = 0,
    this.maxRev = 0,
  });
  final String walletId;
  final String role;
  final int keyVer;
  final int localVer;
  final int cursor;
  final int maxRev;

  SharedWalletRow copyWith({String? role, int? keyVer, int? localVer, int? cursor, int? maxRev}) => SharedWalletRow(
    walletId: walletId,
    role: role ?? this.role,
    keyVer: keyVer ?? this.keyVer,
    localVer: localVer ?? this.localVer,
    cursor: cursor ?? this.cursor,
    maxRev: maxRev ?? this.maxRev,
  );
}

/// Kho thô trên SQLite: chỉ lưu byte đã mã hóa và siêu dữ liệu tối thiểu (ADR-0001 mục 4).
final class RecordStore {
  RecordStore(this._db) {
    _migrate();
  }

  final CommonDatabase _db;
  static const schemaVersion = 2;

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
    if (v < 2) {
      // P9 ví chung (ADR-0015): trạng thái từng ví chung (quyền, phiên bản khóa, con trỏ kéo của không gian ví) và khóa
      // ví theo phiên bản, bọc bằng khóa chủ (ngữ cảnh swk|ví|phiên bản).
      _db.execute('''
        CREATE TABLE IF NOT EXISTS shared_wallets (
          wallet_id TEXT PRIMARY KEY,
          role TEXT NOT NULL,
          key_ver INTEGER NOT NULL,
          local_ver INTEGER NOT NULL,
          cursor INTEGER NOT NULL DEFAULT 0,
          max_rev INTEGER NOT NULL DEFAULT 0
        ) STRICT;
        CREATE TABLE IF NOT EXISTS shared_keys (
          wallet_id TEXT NOT NULL,
          key_ver INTEGER NOT NULL,
          wrapped BLOB NOT NULL,
          PRIMARY KEY (wallet_id, key_ver)
        ) STRICT;
      ''');
      _db.userVersion = 2;
    }
  }

  // ------------------------------------------------------------------ Ví chung (P9)

  List<SharedWalletRow> sharedWallets() => [
    for (final r in _db.select('SELECT wallet_id, role, key_ver, local_ver, cursor, max_rev FROM shared_wallets'))
      SharedWalletRow(
        walletId: r['wallet_id'] as String,
        role: r['role'] as String,
        keyVer: r['key_ver'] as int,
        localVer: r['local_ver'] as int,
        cursor: r['cursor'] as int,
        maxRev: r['max_rev'] as int,
      ),
  ];

  SharedWalletRow? sharedWallet(String walletId) => sharedWallets().where((w) => w.walletId == walletId).firstOrNull;

  void putSharedWallet(SharedWalletRow w) => _db.execute(
    'INSERT INTO shared_wallets(wallet_id, role, key_ver, local_ver, cursor, max_rev) VALUES(?, ?, ?, ?, ?, ?) '
    'ON CONFLICT(wallet_id) DO UPDATE SET role = excluded.role, key_ver = excluded.key_ver, '
    'local_ver = excluded.local_ver, cursor = excluded.cursor, max_rev = excluded.max_rev',
    [w.walletId, w.role, w.keyVer, w.localVer, w.cursor, w.maxRev],
  );

  Map<int, Uint8List> sharedKeys(String walletId) => {
    for (final r in _db.select('SELECT key_ver, wrapped FROM shared_keys WHERE wallet_id = ?', [walletId]))
      r['key_ver'] as int: r['wrapped'] as Uint8List,
  };

  void putSharedKey(String walletId, int keyVer, Uint8List wrapped) => _db.execute(
    'INSERT INTO shared_keys(wallet_id, key_ver, wrapped) VALUES(?, ?, ?) '
    'ON CONFLICT(wallet_id, key_ver) DO UPDATE SET wrapped = excluded.wrapped',
    [walletId, keyVer, wrapped],
  );

  /// Bản ghi của một ví (để mã hóa lại khi xoay khóa).
  List<SealedRow> walletRecords(String walletId) => [
    for (final r in _db.select(
      'SELECT id, type, wallet_id, sealed, rev, dirty FROM records WHERE wallet_id = ? ORDER BY rowid',
      [walletId],
    ))
      _row(r),
  ];

  /// Ghi đè bản niêm phong (mã hóa lại bằng khóa mới), giữ rev; [dirty] null = giữ cờ cũ.
  void resealRecord(String id, Uint8List sealed, {bool? dirty}) => _db.execute(
    dirty == null
        ? 'UPDATE records SET sealed = ? WHERE id = ?'
        : 'UPDATE records SET sealed = ?, dirty = ? WHERE id = ?',
    [sealed, if (dirty != null) dirty ? 1 : 0, id],
  );

  /// Ví vừa thành ví chung trên máy này: rev cũ thuộc không gian tài khoản, không so được với rev của ví ⇒ về 0 để lượt
  /// kéo đầu tiên của ví hợp nhất lại mọi bản ghi.
  void resetWalletRevs(String walletId) => _db.execute('UPDATE records SET rev = 0 WHERE wallet_id = ?', [walletId]);

  /// Bỏ hẳn một ví chung khỏi máy (bị thu hồi / tự rời): bản ghi, khóa, trạng thái.
  void dropSharedWallet(String walletId) => transaction(() {
    _db.execute('DELETE FROM records WHERE wallet_id = ?', [walletId]);
    _db.execute('DELETE FROM shared_keys WHERE wallet_id = ?', [walletId]);
    _db.execute('DELETE FROM shared_wallets WHERE wallet_id = ?', [walletId]);
  });

  /// Bản ghi chưa đẩy của không gian tài khoản (bỏ bản ghi của ví chung - chúng đi đường riêng).
  List<SealedRow> dirtyAccountRecords(int limit) => [
    for (final r in _db.select(
      'SELECT id, type, wallet_id, sealed, rev, dirty FROM records WHERE dirty = 1 '
      'AND (wallet_id IS NULL OR wallet_id NOT IN (SELECT wallet_id FROM shared_wallets)) ORDER BY rowid LIMIT ?',
      [limit],
    ))
      _row(r),
  ];

  /// Bản ghi chưa đẩy của một ví chung.
  List<SealedRow> dirtyWalletRecords(String walletId, int limit) => [
    for (final r in _db.select(
      'SELECT id, type, wallet_id, sealed, rev, dirty FROM records WHERE dirty = 1 AND wallet_id = ? ORDER BY rowid LIMIT ?',
      [walletId, limit],
    ))
      _row(r),
  ];

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

  /// Khóa ví đã bọc chưa đẩy lên máy chủ.
  Map<String, Uint8List> dirtyWalletKeys() => {
    for (final r in _db.select('SELECT wallet_id, wrapped FROM wallet_keys WHERE dirty = 1'))
      r['wallet_id'] as String: r['wrapped'] as Uint8List,
  };

  /// Đã đẩy xong ⇒ bỏ cờ (chỉ khi bản bọc chưa đổi trong lúc gửi).
  void markWalletKeySynced(String walletId, Uint8List wrapped) =>
      _db.execute('UPDATE wallet_keys SET dirty = 0 WHERE wallet_id = ? AND wrapped = ?', [walletId, wrapped]);

  /// Khóa ví nhận từ máy chủ (không đánh dirty). Không ghi đè khóa đã có.
  void putRemoteWalletKey(String walletId, Uint8List wrapped) => _db.execute(
    'INSERT INTO wallet_keys(wallet_id, wrapped, dirty) VALUES(?, ?, 0) ON CONFLICT(wallet_id) DO NOTHING',
    [walletId, wrapped],
  );

  SealedRow? record(String id) {
    final rs = _db.select('SELECT id, type, wallet_id, sealed, rev, dirty FROM records WHERE id = ?', [id]);
    return rs.isEmpty ? null : _row(rs.first);
  }

  bool isDirty(String id) => _db.select('SELECT 1 FROM records WHERE id = ? AND dirty = 1', [id]).isNotEmpty;

  int get dirtyCount => _db.select('SELECT count(*) AS n FROM records WHERE dirty = 1').first['n'] as int;

  /// Bản ghi chưa đẩy (cũ nhất trước theo rowid để lô ổn định).
  List<SealedRow> dirtyRecords(int limit) => [
    for (final r in _db.select(
      'SELECT id, type, wallet_id, sealed, rev, dirty FROM records WHERE dirty = 1 ORDER BY rowid LIMIT ?',
      [limit],
    ))
      _row(r),
  ];

  /// Máy chủ đã nhận ⇒ ghi rev; chỉ bỏ cờ dirty nếu bản niêm phong chưa đổi trong lúc gửi (người dùng sửa tiếp).
  void markSynced(String id, Uint8List sentSealed, int rev) {
    _db.execute('UPDATE records SET rev = ?, dirty = 0 WHERE id = ? AND sealed = ?', [rev, id, sentSealed]);
    if (_db.updatedRows == 0) _db.execute('UPDATE records SET rev = max(rev, ?) WHERE id = ?', [rev, id]);
  }

  /// Ghi bản ghi nhận/hợp nhất từ máy chủ với rev và cờ dirty tường minh. Danh tính (loại, ví) không đổi được.
  void putSynced(SealedRow row, {required bool dirty}) {
    _db.execute(
      'INSERT INTO records(id, type, wallet_id, sealed, rev, dirty) VALUES(?, ?, ?, ?, ?, ?) '
      'ON CONFLICT(id) DO UPDATE SET sealed = excluded.sealed, rev = excluded.rev, dirty = excluded.dirty '
      'WHERE records.type = excluded.type AND records.wallet_id IS excluded.wallet_id',
      [row.id, row.type, row.walletId, row.sealed, row.rev, dirty ? 1 : 0],
    );
    if (_db.updatedRows != 1) throw StateError('Bản ghi đổi loại hoặc đổi ví - từ chối');
  }

  static SealedRow _row(Row r) => SealedRow(
    id: r['id'] as String,
    type: r['type'] as String,
    walletId: r['wallet_id'] as String?,
    sealed: r['sealed'] as Uint8List,
    rev: r['rev'] as int,
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

  int _txDepth = 0;

  /// Giao tác; gọi lồng nhau thì chỉ lớp ngoài cùng BEGIN/COMMIT (lỗi ở bất kỳ lớp nào ⇒ hủy toàn bộ).
  T transaction<T>(T Function() body) {
    if (_txDepth > 0) {
      _txDepth++;
      try {
        return body();
      } finally {
        _txDepth--;
      }
    }
    _db.execute('BEGIN IMMEDIATE');
    _txDepth = 1;
    try {
      final result = body();
      _db.execute('COMMIT');
      return result;
    } on Object {
      _db.execute('ROLLBACK');
      rethrow;
    } finally {
      _txDepth = 0;
    }
  }

  /// Xóa sạch dữ liệu cục bộ (đặt lại app).
  void wipe() {
    transaction(() {
      _db.execute('DELETE FROM records');
      _db.execute('DELETE FROM wallet_keys');
      _db.execute('DELETE FROM shared_keys');
      _db.execute('DELETE FROM shared_wallets');
      _db.execute('DELETE FROM meta');
    });
  }

  void close() => _db.close();
}
