import 'dart:convert';
import 'dart:typed_data';

import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../data/record_store.dart';
import '../security/vault.dart';
import 'api_client.dart';

/// Lý do đồng bộ bị chặn - cần người dùng quyết định, không tự thử lại.
enum SyncBlock {
  /// Máy chủ đã có tài khoản mã hóa với khóa chủ KHÁC tài khoản trên máy này (ADR-0011 mục 3).
  differentAccount,

  /// Đã từng đồng bộ, nay máy chủ trả gói khóa có danh tính khác vân tay đã ghim (THREAT_MODEL T4).
  identityChanged,

  /// Máy chủ cấp rev không lớn hơn rev đã thấy ⇒ dữ liệu máy chủ bị quay lui (THREAT_MODEL T2).
  rollback,

  /// Tài khoản đang chờ xóa: máy chủ chỉ cho đọc.
  pendingDeletion,

  /// Máy này đã đồng bộ với tài khoản tsudev khác.
  otherUser,
}

final class SyncBlockedException implements Exception {
  const SyncBlockedException(this.block);
  final SyncBlock block;
  @override
  String toString() => 'SyncBlockedException(${block.name})';
}

/// Kết quả một lượt đồng bộ - chỉ đếm, không có nội dung.
final class SyncReport {
  const SyncReport({this.pulled = 0, this.pushed = 0, this.rejected = 0, this.skipped = 0, this.quotaFull = false});
  final int pulled;
  final int pushed;
  final int rejected;
  final int skipped;
  final bool quotaFull;
}

/// Một lượt đồng bộ: khóa ⇒ kéo (hợp nhất theo trường) ⇒ đẩy (ADR-0004, ADR-0010 mục 3, ADR-0011).
///
/// Máy chủ chỉ thấy bản mã. Mọi bước ghi xuống [RecordStore] của một trang kéo nằm trong MỘT giao tác đồng bộ (không
/// có `await` ở giữa) rồi gọi [onApplied] để repository nạp lại - sửa đổi của người dùng không xen vào giữa được.
final class SyncEngine {
  SyncEngine({required this.api, required this.store, required this.vault, required this.onApplied, this.pageSize = 200});

  final ApiClient api;
  final RecordStore store;
  final Vault vault;

  /// Gọi đồng bộ (không await) sau khi một trang kéo đã ghi xong.
  final void Function() onApplied;
  final int pageSize;

  static const pushBatch = 200;
  static const _mCursor = 'sync.cursor';
  static const _mMaxRev = 'sync.maxRev';
  static const _mUser = 'sync.user';
  static const _mIdPin = 'sync.idPin';

  int _metaInt(String k) => int.tryParse(utf8.decode(store.getMeta(k) ?? const [])) ?? 0;
  void _putInt(String k, int v) => store.putMeta(k, utf8.encode('$v'));

  int get cursor => _metaInt(_mCursor);

  /// Ràng buộc dữ liệu máy này với một tài khoản tsudev (id máy chủ). Khác ⇒ [SyncBlock.otherUser].
  void bindUser(String userId) {
    final bound = store.getMeta(_mUser);
    if (bound == null) {
      store.putMeta(_mUser, utf8.encode(userId));
    } else if (utf8.decode(bound) != userId) {
      throw const SyncBlockedException(SyncBlock.otherUser);
    }
  }

  /// Bỏ ràng buộc tài khoản và trạng thái đồng bộ (đăng xuất CÓ chủ ý: lần đăng nhập sau đẩy lại toàn bộ).
  void forgetSyncState() {
    store.transaction(() {
      for (final k in [_mCursor, _mMaxRev, _mUser, _mIdPin]) {
        store.deleteMeta(k);
      }
    });
  }

  Future<SyncReport> run() async {
    if (!vault.isUnlocked) throw StateError('Kho khóa đang khóa');
    try {
      await syncKeys();
      final pulled = await pull();
      final pushed = await push();
      return SyncReport(
        pulled: pulled.$1,
        skipped: pulled.$2,
        pushed: pushed.$1,
        rejected: pushed.$2,
        quotaFull: pushed.$3,
      );
    } on ApiException catch (e) {
      if (e.status == 403 && e.code == 'pending_deletion') throw const SyncBlockedException(SyncBlock.pendingDeletion);
      rethrow;
    }
  }

  // ------------------------------------------------------------------ Khóa

  Future<void> syncKeys() async {
    var j = (await api.getJson('/api/v1/keys'))! as Map;
    if (j['account'] == null) {
      try {
        await api.putJson('/api/v1/keys/account', {'bundle': vault.bundleJson, 'if_absent': true});
        vault.clearBundleDirty();
      } on ApiException catch (e) {
        if (e.status != 409) rethrow;
        // Máy khác vừa tạo gói khóa: đọc lại và so như thường.
        j = (await api.getJson('/api/v1/keys'))! as Map;
      }
    }
    final account = j['account'] as Map?;
    if (account != null) {
      final bundle = (account['bundle']! as Map).cast<String, Object?>();
      if (!vault.remoteBundleMatches(bundle)) {
        throw SyncBlockedException(store.getMeta(_mIdPin) == null ? SyncBlock.differentAccount : SyncBlock.identityChanged);
      }
      if (vault.bundleDirty) {
        await api.putJson('/api/v1/keys/account', {'bundle': vault.bundleJson});
        vault.clearBundleDirty();
      } else {
        vault.offerRemoteBundle(bundle);
      }
    }
    final pin = vault.localFingerprint;
    final pinned = store.getMeta(_mIdPin);
    if (pinned != null && utf8.decode(pinned) != pin) throw const SyncBlockedException(SyncBlock.identityChanged);
    store.putMeta(_mIdPin, utf8.encode(pin));

    final remote = <String, Uint8List>{
      for (final w in (j['wallets']! as List).cast<Map<Object?, Object?>>())
        w['wallet_id']! as String: base64.decode(w['wrapped']! as String),
    };
    final upload = <String, Uint8List>{
      for (final e in store.walletKeys().entries)
        if (!remote.containsKey(e.key)) e.key: e.value,
      ...store.dirtyWalletKeys(),
      if (!remote.containsKey(Vault.accountKeyServerId)) Vault.accountKeyServerId: vault.wrappedAccountKey,
    };
    final entries = upload.entries.toList();
    for (var i = 0; i < entries.length; i += 200) {
      final chunk = entries.sublist(i, (i + 200).clamp(0, entries.length));
      await api.putJson('/api/v1/keys/wallets', {
        'keys': [
          for (final e in chunk) {'wallet_id': e.key, 'wrapped': base64.encode(e.value)},
        ],
      });
      for (final e in chunk) {
        if (e.key != Vault.accountKeyServerId) store.markWalletKeySynced(e.key, e.value);
      }
    }
    if (vault.importWalletKeys(remote) > 0) onApplied();
  }

  // ------------------------------------------------------------------ Kéo

  /// Trả (số bản ghi nhận, số bản ghi bỏ qua vì không mở được).
  Future<(int, int)> pull() async {
    var since = cursor;
    var applied = 0;
    var skipped = 0;
    while (true) {
      final j = (await api.getJson('/api/v1/sync/pull', {'since': '$since', 'limit': '$pageSize'}))! as Map;
      final records = (j['records']! as List).cast<Map<Object?, Object?>>();
      final next = (j['cursor']! as num).toInt();
      final hasMore = j['has_more'] == true;
      // Máy chủ phải trả rev tăng dần, lớn hơn `since`, và con trỏ không lùi.
      var last = since;
      for (final r in records) {
        final rev = (r['rev']! as num).toInt();
        if (rev <= last) throw const ApiException(0, ApiException.badResponse);
        last = rev;
      }
      if (next < since || (records.isNotEmpty && next != last)) throw const ApiException(0, ApiException.badResponse);
      var changed = false;
      store.transaction(() {
        for (final r in records) {
          switch (_applyRemote(r)) {
            case _Applied.changed:
              applied++;
              changed = true;
            case _Applied.same:
              break;
            case _Applied.skipped:
              skipped++;
          }
        }
        _putInt(_mCursor, next);
        if (next > _metaInt(_mMaxRev)) _putInt(_mMaxRev, next);
      });
      if (changed) onApplied();
      since = next;
      if (!hasMore || records.isEmpty) break;
    }
    return (applied, skipped);
  }

  _Applied _applyRemote(Map<Object?, Object?> r) {
    final id = r['id']! as String;
    final type = r['type']! as String;
    final walletId = r['wallet_id'] as String?;
    final rev = (r['rev']! as num).toInt();
    final sealed = base64.decode(r['sealed']! as String);
    final local = store.record(id);
    if (local != null && (local.type != type || local.walletId != walletId)) return _Applied.skipped;
    final localDirty = local != null && store.isDirty(id);
    if (local != null && local.rev == rev && !localDirty) return _Applied.same;
    final row = SealedRow(id: id, type: type, walletId: walletId, sealed: sealed, rev: rev);

    final canOpen = walletId == null || vault.hasWalletKey(walletId);
    if (!canOpen) {
      // Chưa có khóa ví (sẽ đến sau): giữ bản mã để mở khi có khóa.
      if (!localDirty) store.putSynced(row, dirty: false);
      return _Applied.skipped;
    }
    final SyncRecord remote;
    try {
      remote = vault.cipher.open(sealed, vault.keyFor(walletId), type: type, recordId: id, walletId: walletId);
    } on Object {
      // Hỏng hoặc bị tráo (AAD sai): KHÔNG lưu, không ghi đè bản cục bộ.
      return _Applied.skipped;
    }
    SyncRecord? mine;
    if (local != null) {
      try {
        mine = vault.cipher.open(local.sealed, vault.keyFor(walletId), type: type, recordId: id, walletId: walletId);
      } on Object {
        mine = null;
      }
    }
    if (mine == null) {
      store.putSynced(row, dirty: false);
      return _Applied.changed;
    }
    final merged = mine.merge(remote);
    if (_sameBytes(merged.toBytes(), remote.toBytes())) {
      store.putSynced(row, dirty: false);
      return _Applied.changed;
    }
    // Hai phía đều có trường mới hơn: lưu bản hợp nhất và đẩy lại (ADR-0010 mục 3).
    store.putSynced(
      SealedRow(id: id, type: type, walletId: walletId, sealed: vault.cipher.seal(merged, vault.keyFor(walletId)), rev: rev),
      dirty: true,
    );
    return _Applied.changed;
  }

  static bool _sameBytes(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // ------------------------------------------------------------------ Đẩy

  /// Trả (số bản ghi máy chủ nhận, số bị từ chối, hết hạn mức?).
  Future<(int, int, bool)> push() async {
    var pushed = 0;
    var quota = false;
    final rejected = <String>{};
    while (true) {
      final rows = [
        for (final r in store.dirtyRecords(pushBatch + rejected.length))
          if (!rejected.contains(r.id)) r,
      ].take(pushBatch).toList();
      if (rows.isEmpty) break;
      final maxSeen = _metaInt(_mMaxRev);
      final body = {
        'records': [for (final r in rows) _pushJson(r)],
      };
      final res = (await api.postJson('/api/v1/sync/push', body))! as Map;
      final results = (res['results']! as List).cast<Map<Object?, Object?>>();
      final sent = {for (final r in rows) r.id: r};
      var maxRev = maxSeen;
      var rollback = false;
      store.transaction(() {
        for (final x in results) {
          final id = x['id'] as String?;
          final row = sent[id];
          if (row == null) continue;
          switch (x['status']) {
            case 'applied':
              final rev = (x['rev']! as num).toInt();
              if (rev <= maxSeen) rollback = true;
              if (rev > maxRev) maxRev = rev;
              store.markSynced(row.id, row.sealed, rev);
              pushed++;
            case 'unchanged':
              store.markSynced(row.id, row.sealed, (x['rev']! as num).toInt());
            default:
              rejected.add(row.id);
              if (x['reason'] == 'quota') quota = true;
          }
        }
        if (maxRev > maxSeen) _putInt(_mMaxRev, maxRev);
      });
      if (rollback) throw const SyncBlockedException(SyncBlock.rollback);
      if (results.length != rows.length) throw const ApiException(0, ApiException.badResponse);
    }
    return (pushed, rejected.length, quota);
  }

  Map<String, Object?> _pushJson(SealedRow r) {
    var deleted = false;
    try {
      deleted = vault.cipher
          .open(r.sealed, vault.keyFor(r.walletId), type: r.type, recordId: r.id, walletId: r.walletId)
          .isDeleted;
    } on Object {
      // Bản ghi của chính máy này luôn mở được; nếu không, gửi như bản ghi thường.
    }
    return {'id': r.id, 'type': r.type, 'wallet_id': r.walletId, 'sealed': base64.encode(r.sealed), 'deleted': deleted};
  }
}

enum _Applied { changed, same, skipped }
