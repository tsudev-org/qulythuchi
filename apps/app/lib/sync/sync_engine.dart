import 'dart:convert';
import 'dart:typed_data';

import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../attachments/file_sync.dart';
import '../data/record_store.dart';
import '../pro/pro_block.dart';
import '../security/vault.dart';
import 'api_client.dart';
import 'shared_wallets.dart';

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

  /// Máy này đã đồng bộ với tài khoản TsuDEV khác.
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
  const SyncReport({
    this.pulled = 0,
    this.pushed = 0,
    this.rejected = 0,
    this.skipped = 0,
    this.quotaFull = false,
    this.shared,
    this.badInvites = 0,
    this.proBlock,
    this.files = const FileSyncReport(),
  });
  final int pulled;
  final int pushed;
  final int rejected;
  final int skipped;
  final bool quotaFull;

  /// Trạng thái ví chung sau lượt này (null khi máy chủ/bản này không bật ví chung).
  final SharedOverview? shared;

  /// Lời mời có bằng chứng sai (ai đó không cầm mã thật nhận lời mời) - đã hủy.
  final int badInvites;

  /// Máy chủ trả 402 ở lượt này (bản ghi/ảnh vẫn an toàn trên máy, chờ lượt sau).
  final ProBlock? proBlock;

  /// Ảnh đính kèm (P7b).
  final FileSyncReport files;
}

/// Một lượt đồng bộ: khóa ⇒ kéo (hợp nhất theo trường) ⇒ đẩy (ADR-0004, ADR-0010 mục 3, ADR-0011).
///
/// Máy chủ chỉ thấy bản mã. Mọi bước ghi xuống [RecordStore] của một trang kéo nằm trong MỘT giao tác đồng bộ (không
/// có `await` ở giữa) rồi gọi [onApplied] để repository nạp lại - sửa đổi của người dùng không xen vào giữa được.
final class SyncEngine {
  SyncEngine({
    required this.api,
    required this.store,
    required this.vault,
    required this.onApplied,
    this.book,
    this.pageSize = 200,
  });

  /// Bí mật cặp + danh mục chia sẻ (null ⇒ không đồng bộ ví chung, như bản P6).
  final SharingBook? book;

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

  /// Ràng buộc dữ liệu máy này với một tài khoản TsuDEV (id máy chủ). Khác ⇒ [SyncBlock.otherUser].
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

  /// [pushAllowed] = false: quyền lợi đã cho biết không đồng bộ được (`can_sync = false`) ⇒ chỉ kéo, không gọi đẩy
  /// (PRODUCT_POLICY 7.4: gặp 402 thì không thử lại).
  Future<SyncReport> run({bool pushAllowed = true}) async {
    if (!vault.isUnlocked) throw StateError('Kho khóa đang khóa');
    try {
      await syncKeys();
      final shared = book == null ? null : await refreshShared();
      var pulled = await pull();
      ProBlock? proBlock;
      // 402 `pro_required` (ADR-0019 mục 5): giữ bản ghi chờ đẩy trên máy, KHÔNG thử lại trong lượt này, vẫn kéo tiếp.
      Future<(int, int, bool)> gated(Future<(int, int, bool)> Function() run) async {
        if (!pushAllowed) return (0, 0, false);
        try {
          return await run();
        } on ApiException catch (e) {
          if (!e.proRequired) rethrow;
          proBlock = ProBlock.worst(proBlock, ProBlock.parse(e.reason));
          return (0, 0, false);
        }
      }

      var pushed = await gated(push);
      if (!pushAllowed) proBlock = ProBlock.noPro;
      if (shared != null) {
        for (final w in store.sharedWallets()) {
          final p = await pullWallet(w.walletId);
          pulled = (pulled.$1 + p.$1, pulled.$2 + p.$2);
          if (WalletRole.fromName(w.role)?.canWrite ?? false) book!.publishWalletCategories(w.walletId);
          // Ví chung chạy bằng Pro của CHỦ ví: thành viên miễn phí vẫn đẩy được (ADR-0016 Q5).
          ProBlock? walletBlock;
          (int, int, bool) q;
          try {
            q = await pushWallet(w.walletId);
          } on ApiException catch (e) {
            if (!e.proRequired) rethrow;
            walletBlock = ProBlock.parse(e.reason);
            q = (0, 0, false);
          }
          proBlock = ProBlock.worst(proBlock, walletBlock);
          pushed = (pushed.$1 + q.$1, pushed.$2 + q.$2, pushed.$3 || q.$3);
        }
      }
      final files = pushAllowed ? await FileSync(api: api, store: store).run() : const FileSyncReport(blocked: true);
      if (files.blocked) proBlock = ProBlock.worst(proBlock, files.proBlock ?? ProBlock.noPro);
      return SyncReport(
        proBlock: proBlock,
        files: files,
        pulled: pulled.$1,
        skipped: pulled.$2,
        pushed: pushed.$1,
        rejected: pushed.$2,
        quotaFull: pushed.$3,
        shared: shared?.$1,
        badInvites: shared?.$2 ?? 0,
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
        throw SyncBlockedException(
          store.getMeta(_mIdPin) == null ? SyncBlock.differentAccount : SyncBlock.identityChanged,
        );
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
  Future<(int, int)> pull() => _pullPages(
    since: cursor,
    fetch: (since) async => (await api.getJson('/api/v1/sync/pull', {'since': '$since', 'limit': '$pageSize'}))! as Map,
    save: (next) {
      _putInt(_mCursor, next);
      if (next > _metaInt(_mMaxRev)) _putInt(_mMaxRev, next);
    },
  );

  /// Kéo theo trang, kiểm rev tăng chặt (T2), áp mỗi trang trong MỘT giao tác cùng con trỏ.
  Future<(int, int)> _pullPages({
    required int since,
    required Future<Map<Object?, Object?>> Function(int since) fetch,
    required void Function(int next) save,
    _Apply? apply,
  }) async {
    final applyOne = apply ?? (r) => _applyRemote(r);
    var applied = 0;
    var skipped = 0;
    while (true) {
      final j = await fetch(since);
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
          switch (applyOne(r)) {
            case _Applied.changed:
              applied++;
              changed = true;
            case _Applied.same:
              break;
            case _Applied.skipped:
              skipped++;
          }
        }
        save(next);
      });
      if (changed) onApplied();
      since = next;
      if (!hasMore || records.isEmpty) break;
    }
    return (applied, skipped);
  }

  /// [keyVer]: phiên bản khóa niêm phong bản ghi của ví chung (null = không gian tài khoản). Bản ghi mang phiên bản cũ
  /// được mã hóa lại bằng khóa hiện tại trước khi lưu; [repushStale] (chủ ví) ⇒ đánh dirty để đẩy bản mới lên.
  _Applied _applyRemote(Map<Object?, Object?> r, {int? keyVer, bool repushStale = false}) {
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

    final openKey = walletId == null
        ? vault.keyFor(null)
        : keyVer == null
        ? (vault.hasWalletKey(walletId) ? vault.keyFor(walletId) : null)
        : vault.keyForVersion(walletId, keyVer);
    if (openKey == null || (walletId != null && !vault.hasWalletKey(walletId))) {
      // Chưa có khóa ví (sẽ đến sau): giữ bản mã để mở khi có khóa.
      if (!localDirty && keyVer == null) store.putSynced(row, dirty: false);
      return _Applied.skipped;
    }
    final SyncRecord remote;
    try {
      remote = vault.cipher.open(sealed, openKey, type: type, recordId: id, walletId: walletId);
    } on Object {
      // Hỏng hoặc bị tráo (AAD sai): KHÔNG lưu, không ghi đè bản cục bộ.
      return _Applied.skipped;
    }
    // Bản ghi ví chung niêm phong bằng phiên bản khóa khác phiên bản máy này đang dùng ⇒ niêm phong lại.
    final stale = walletId != null && keyVer != null && !identical(openKey, vault.keyFor(walletId));
    SyncRecord? mine;
    if (local != null) {
      try {
        mine = vault.cipher.open(local.sealed, vault.keyFor(walletId), type: type, recordId: id, walletId: walletId);
      } on Object {
        mine = null;
      }
    }
    if (mine == null || _sameBytes(mine.merge(remote).toBytes(), remote.toBytes())) {
      store.putSynced(
        stale
            ? SealedRow(
                id: id,
                type: type,
                walletId: walletId,
                sealed: vault.cipher.seal(remote, vault.keyFor(walletId)),
                rev: rev,
              )
            : row,
        dirty: stale && repushStale,
      );
      return _Applied.changed;
    }
    final merged = mine.merge(remote);
    // Hai phía đều có trường mới hơn: lưu bản hợp nhất và đẩy lại (ADR-0010 mục 3).
    store.putSynced(
      SealedRow(
        id: id,
        type: type,
        walletId: walletId,
        sealed: vault.cipher.seal(merged, vault.keyFor(walletId)),
        rev: rev,
      ),
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
  Future<(int, int, bool)> push() => _pushRows(
    rows: store.dirtyAccountRecords,
    send: (records) async => (await api.postJson('/api/v1/sync/push', {'records': records}))! as Map,
    maxSeen: () => _metaInt(_mMaxRev),
    saveMax: (v) => _putInt(_mMaxRev, v),
    json: _pushJson,
  );

  Future<(int, int, bool)> _pushRows({
    required List<SealedRow> Function(int limit) rows,
    required Future<Map<Object?, Object?>> Function(List<Map<String, Object?>> records) send,
    required int Function() maxSeen,
    required void Function(int) saveMax,
    required Map<String, Object?> Function(SealedRow) json,
  }) async {
    var pushed = 0;
    var quota = false;
    final rejected = <String>{};
    while (true) {
      final batch = [
        for (final r in rows(pushBatch + rejected.length))
          if (!rejected.contains(r.id)) r,
      ].take(pushBatch).toList();
      if (batch.isEmpty) break;
      final seen = maxSeen();
      final res = await send([for (final r in batch) json(r)]);
      final results = (res['results']! as List).cast<Map<Object?, Object?>>();
      final sent = {for (final r in batch) r.id: r};
      var maxRev = seen;
      var rollback = false;
      store.transaction(() {
        for (final x in results) {
          final id = x['id'] as String?;
          final row = sent[id];
          if (row == null) continue;
          switch (x['status']) {
            case 'applied':
              final rev = (x['rev']! as num).toInt();
              if (rev <= seen) rollback = true;
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
        if (maxRev > seen) saveMax(maxRev);
      });
      if (rollback) throw const SyncBlockedException(SyncBlock.rollback);
      if (results.length != batch.length) throw const ApiException(0, ApiException.badResponse);
    }
    return (pushed, rejected.length, quota);
  }

  // ------------------------------------------------------------------ Ví chung (P9, ADR-0015)

  SharingBook get _book => book ?? (throw StateError('Ví chung chưa bật'));

  static String _b64(Uint8List b) => base64.encode(b);

  /// Lấy danh sách ví chung, cài khóa mới nhận, mã hóa lại bản ghi khi khóa đã xoay, (chủ ví) hoàn tất lời mời đã kiểm
  /// bằng chứng và xoay khóa khi có người rời; bỏ ví mình không còn là thành viên. Trả (ảnh chụp, số lời mời bị hủy).
  Future<(SharedOverview, int)> refreshShared() async {
    var overview = SharedOverview.parse(await api.getJson('/api/v1/wallets'));
    var badInvites = 0;
    var again = false;
    for (final w in overview.wallets) {
      _adoptWallet(w);
      if (w.role != WalletRole.owner) continue;
      final secrets = _book.shareSecrets();
      for (final inv in w.invites) {
        final a = inv.accepted;
        if (a == null) continue;
        final secret = secrets.where((s) => s.isOwnerSide && s.inviteId == inv.inviteId).lastOrNull;
        // Bí mật chưa đồng bộ tới thiết bị này: để thiết bị đã tạo lời mời (hoặc lượt sau) hoàn tất.
        if (secret == null) continue;
        final proofOk =
            a.kemPublicKey != null &&
            a.proof != null &&
            vault.sharing.verifyAcceptProof(
              proof: a.proof!,
              secret: secret.secret,
              walletId: w.walletId,
              inviteId: inv.inviteId,
              kemPublicKey: a.kemPublicKey!,
            );
        if (!proofOk) {
          // Người nhận không cầm mã thật, hoặc máy chủ tráo khóa công khai (THREAT_MODEL T21) ⇒ hủy lời mời.
          await api.delete('/api/v1/wallets/${w.walletId}/invites/${inv.inviteId}');
          badInvites++;
          again = true;
          continue;
        }
        if (vault.keyForVersion(w.walletId, w.keyVer) == null) continue;
        await api.postJson('/api/v1/wallets/${w.walletId}/members', {
          'invite_id': inv.inviteId,
          'key_ver': w.keyVer,
          'wrapped': _b64(vault.shareKeyTo(w.walletId, w.keyVer, a.kemPublicKey!, secret.secret)),
        });
        _book.saveShareSecret(secret.copyWith(userId: a.userId, role: inv.role));
        again = true;
      }
      if (w.needsRotation) {
        try {
          await rotateWalletKey(w);
          again = true;
        } on SharingException {
          // Thiếu bí mật cặp của ai đó trên thiết bị này: lượt sau (sau khi kéo bản ghi tài khoản) thử lại.
        }
      }
    }
    final listed = {for (final w in overview.wallets) w.walletId};
    for (final row in store.sharedWallets()) {
      if (listed.contains(row.walletId) || row.role == WalletRole.owner.name) continue;
      // Bị thu hồi hoặc đã rời ví: bỏ hẳn dữ liệu và khóa của ví trên máy này.
      store.dropSharedWallet(row.walletId);
      vault.forgetSharedWallet(row.walletId);
      _book.forgetShareSecrets(row.walletId);
      onApplied();
    }
    if (again) overview = SharedOverview.parse(await api.getJson('/api/v1/wallets'));
    return (overview, badInvites);
  }

  /// Đồng bộ trạng thái cục bộ của một ví chung với máy chủ: quyền, khóa, mã hóa lại.
  void _adoptWallet(SharedWalletInfo w) {
    var row = store.sharedWallet(w.walletId);
    if (row == null) {
      final hasLocal = store.walletRecords(w.walletId).isNotEmpty;
      row = SharedWalletRow(
        walletId: w.walletId,
        role: w.role.name,
        keyVer: w.keyVer,
        // Bản ghi có sẵn trên máy (thiết bị khác của chủ ví) đang niêm phong bằng khóa ví riêng = phiên bản 1.
        localVer: hasLocal ? 1 : w.keyVer,
      );
      store.transaction(() {
        store.resetWalletRevs(w.walletId);
        store.putSharedWallet(row!);
      });
    }
    final secrets = [
      for (final s in _book.shareSecrets())
        if (!s.isOwnerSide && s.walletId == w.walletId) s.secret,
    ];
    // Quyền đổi (nâng/hạ) ⇒ giao diện phải nạp lại để ẩn/hiện nút ghi.
    var installed = row.role != w.role.name;
    w.shares.forEach((ver, wrapped) {
      if (vault.keyForVersion(w.walletId, ver) != null) return;
      final key = vault.openSharedKey(w.walletId, ver, wrapped, secrets);
      if (key == null) return;
      vault.installSharedKey(w.walletId, ver, key);
      installed = true;
    });
    vault.setLocalKeyVersion(w.walletId, row.localVer);
    row = row.copyWith(role: w.role.name, keyVer: w.keyVer);
    if (row.localVer != w.keyVer && vault.keyForVersion(w.walletId, w.keyVer) != null) {
      _reseal(w.walletId, row.localVer, w.keyVer, markDirty: w.role == WalletRole.owner);
      row = row.copyWith(localVer: w.keyVer);
      installed = true;
    }
    store.putSharedWallet(row);
    if (installed) onApplied();
  }

  /// Mã hóa lại mọi bản ghi của ví từ phiên bản [from] sang [to] trong một giao tác. [markDirty] (chủ ví) ⇒ đẩy lại.
  void _reseal(String walletId, int from, int to, {required bool markDirty}) {
    final oldKey = vault.keyForVersion(walletId, from);
    final newKey = vault.keyForVersion(walletId, to)!;
    store.transaction(() {
      for (final r in store.walletRecords(walletId)) {
        if (oldKey == null) break;
        try {
          final rec = vault.cipher.open(r.sealed, oldKey, type: r.type, recordId: r.id, walletId: walletId);
          store.resealRecord(r.id, vault.cipher.seal(rec, newKey), dirty: markDirty ? true : null);
        } on Object {
          // Không mở được bằng phiên bản cũ (hỏng): bỏ qua, lượt kéo sau thay bằng bản máy chủ.
        }
      }
    });
    vault.setLocalKeyVersion(walletId, to);
  }

  Future<(int, int)> pullWallet(String walletId) async {
    final row = store.sharedWallet(walletId);
    // Chưa mở được khóa hiện tại (bí mật cặp chưa đồng bộ tới): KHÔNG kéo, kẻo con trỏ vượt qua bản ghi chưa mở.
    if (row == null || row.localVer != row.keyVer || !vault.hasWalletKey(walletId)) return (0, 0);
    final repush = row.role == WalletRole.owner.name;
    var cur = row;
    return _pullPages(
      since: row.cursor,
      fetch: (since) async =>
          (await api.getJson('/api/v1/wallets/$walletId/pull', {'since': '$since', 'limit': '$pageSize'}))! as Map,
      save: (next) {
        cur = cur.copyWith(cursor: next, maxRev: next > cur.maxRev ? next : cur.maxRev);
        store.putSharedWallet(cur);
      },
      apply: (r) {
        // Không gian ví: mọi bản ghi phải thuộc đúng ví này (máy chủ không chèn được bản ghi ví khác).
        if (r['wallet_id'] != walletId) return _Applied.skipped;
        return _applyRemote(r, keyVer: (r['key_ver'] as num?)?.toInt() ?? 0, repushStale: repush);
      },
    );
  }

  Future<(int, int, bool)> pushWallet(String walletId) async {
    final row = store.sharedWallet(walletId);
    if (row == null || !(WalletRole.fromName(row.role)?.canWrite ?? false) || row.localVer != row.keyVer) {
      return (0, 0, false);
    }
    try {
      return await _pushRows(
        rows: (limit) => store.dirtyWalletRecords(walletId, limit),
        send: (records) async =>
            (await api.postJson('/api/v1/wallets/$walletId/push', {'key_ver': row.keyVer, 'records': records}))! as Map,
        maxSeen: () => store.sharedWallet(walletId)?.maxRev ?? 0,
        saveMax: (v) {
          final r = store.sharedWallet(walletId);
          if (r != null) store.putSharedWallet(r.copyWith(maxRev: v));
        },
        json: (r) {
          final j = _pushJson(r)..remove('wallet_id');
          return j;
        },
      );
    } on ApiException catch (e) {
      // Khóa vừa xoay hoặc vừa bị hạ quyền: lượt sau làm mới trạng thái rồi đẩy lại.
      if (e.code == 'stale_key' || e.code == 'read_only' || e.status == 404) return (0, 0, false);
      rethrow;
    }
  }

  /// Chủ ví: biến ví riêng thành ví chung. Khóa ví hiện tại thành phiên bản 1; máy chủ chuyển bản ghi sang không gian ví.
  Future<void> shareWallet(String walletId) async {
    await syncKeys();
    if (store.sharedWallet(walletId) == null) {
      final wrapped = vault.wrapSharedForSelf(walletId, 1);
      try {
        await api.postJson('/api/v1/wallets', {'wallet_id': walletId, 'wrapped': _b64(wrapped)});
      } on ApiException catch (e) {
        if (e.code != 'wallet_exists') rethrow;
      }
      store.putSharedKey(walletId, 1, wrapped);
    }
    await refreshShared();
  }

  /// Chủ ví: tạo lời mời. Bí mật được LƯU (bản ghi E2EE) TRƯỚC khi báo máy chủ - không bao giờ có lời mời mà mình mất
  /// bí mật. Trả mã để gửi qua kênh ngoài.
  Future<InviteCode> createInvite(String walletId, WalletRole role) async {
    if (role == WalletRole.owner) throw ArgumentError.value(role, 'role');
    final code = vault.sharing.newInvite();
    _book.saveShareSecret(
      ShareSecret(
        id: _uuid(),
        walletId: walletId,
        inviteId: code.inviteId,
        secret: code.secret,
        side: 'owner',
        role: role,
      ),
    );
    await api.postJson('/api/v1/wallets/$walletId/invites', {'invite_id': code.inviteId, 'role': role.name});
    // Đẩy ngay bản ghi bí mật để thiết bị khác của chủ ví cũng hoàn tất được.
    await push();
    return code;
  }

  Future<void> cancelInvite(String walletId, String inviteId) =>
      api.delete('/api/v1/wallets/$walletId/invites/$inviteId');

  Future<void> changeRole(String walletId, String userId, WalletRole role) =>
      api.putJson('/api/v1/wallets/$walletId/members/$userId', {'role': role.name});

  /// Chủ ví: xoay khóa ví (thu hồi [remove]). Khóa mới chỉ được cài SAU khi máy chủ nhận; bản ghi của ví trên máy này
  /// được mã hóa lại và đánh dirty để đẩy lên bằng phiên bản mới.
  Future<void> rotateWalletKey(SharedWalletInfo w, {Set<String> remove = const {}}) async {
    final next = w.keyVer + 1;
    final secrets = _book.shareSecrets();
    final key = vault.sharing.newWalletKey();
    try {
      final shares = <Map<String, Object?>>[];
      for (final m in w.members) {
        if (remove.contains(m.userId)) continue;
        if (m.role == WalletRole.owner) {
          shares.add({'user_id': m.userId, 'wrapped': _b64(vault.wrapSharedForSelf(w.walletId, next, key: key))});
          continue;
        }
        final secret = secrets
            .where((s) => s.isOwnerSide && s.walletId == w.walletId && s.userId == m.userId)
            .lastOrNull;
        final pk = m.kemPublicKey;
        if (secret == null || pk == null) throw const SharingException('missingSecret');
        shares.add({
          'user_id': m.userId,
          'wrapped': _b64(vault.shareKeyTo(w.walletId, next, pk, secret.secret, key: key)),
        });
      }
      await api.postJson('/api/v1/wallets/${w.walletId}/rotate', {
        'key_ver': next,
        'remove': remove.toList(),
        'shares': shares,
      });
    } on Object {
      key.dispose();
      rethrow;
    }
    vault.installSharedKey(w.walletId, next, key);
    final row = store.sharedWallet(w.walletId);
    if (row != null) {
      _reseal(w.walletId, row.localVer, next, markDirty: true);
      store.putSharedWallet(row.copyWith(keyVer: next, localVer: next));
    }
    onApplied();
  }

  /// Người được mời: xem lời mời trước khi nhận.
  Future<InvitePreview> previewInvite(InviteCode code) async {
    final j = (await api.getJson('/api/v1/invites/${code.inviteId}'))! as Map;
    final role = WalletRole.fromName(j['role']);
    final walletId = j['wallet_id'];
    if (role == null || walletId is! String) throw const ApiException(0, ApiException.badResponse);
    return InvitePreview(
      code: code,
      walletId: walletId,
      role: role,
      state: j['state'] as String? ?? 'open',
      expiresAt: DateTime.fromMillisecondsSinceEpoch((j['expires_at']! as num).toInt()),
      ownerName: j['owner_name'] as String?,
    );
  }

  /// Người được mời: nhận lời mời. Bằng chứng ràng buộc khóa công khai X-Wing CỦA MÌNH với bí mật lời mời; bí mật được
  /// lưu thành bản ghi E2EE để mọi thiết bị của mình mở được khóa ví khi chủ ví hoàn tất.
  Future<void> acceptInvite(InvitePreview p) async {
    if (p.state == 'own') throw const SharingException('inviteOwn');
    if (p.state == 'taken') throw const SharingException('inviteTaken');
    await syncKeys();
    final proof = vault.sharing.acceptProof(
      secret: p.code.secret,
      walletId: p.walletId,
      inviteId: p.code.inviteId,
      kemPublicKey: vault.kemPublicKey,
    );
    final known = _book.shareSecrets().any((s) => !s.isOwnerSide && s.inviteId == p.code.inviteId);
    if (!known) {
      _book.saveShareSecret(
        ShareSecret(
          id: _uuid(),
          walletId: p.walletId,
          inviteId: p.code.inviteId,
          secret: p.code.secret,
          side: 'member',
          role: p.role,
        ),
      );
    }
    await api.postJson('/api/v1/invites/${p.code.inviteId}/accept', {'proof': _b64(proof)});
    await push();
  }

  /// Thành viên tự rời ví: mất quyền ngay, dữ liệu ví bị xóa khỏi máy này.
  Future<void> leaveWallet(String walletId) async {
    await api.delete('/api/v1/wallets/$walletId/members/me');
    store.dropSharedWallet(walletId);
    vault.forgetSharedWallet(walletId);
    _book.forgetShareSecrets(walletId);
    onApplied();
  }

  /// UUID v4 từ `randombytes` (id bản ghi bí mật cặp).
  String _uuid() => vault.sharing.newInvite().inviteId;

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

typedef _Apply = _Applied Function(Map<Object?, Object?> r);
