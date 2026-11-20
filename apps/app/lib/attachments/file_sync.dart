import 'dart:typed_data';

import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../data/record_store.dart';
import '../sync/api_client.dart';

/// Kết quả một lượt đồng bộ tệp.
final class FileSyncReport {
  const FileSyncReport({this.uploaded = 0, this.pending = 0, this.blocked = false, this.quotaFull = false});
  final int uploaded;

  /// Ảnh còn chờ tải lên (vẫn nằm an toàn trên máy).
  final int pending;

  /// Máy chủ trả 402 `pro_required` - ảnh được GIỮ cục bộ, thử lại lượt sau.
  final bool blocked;
  final bool quotaFull;
}

/// Đồng bộ bản mã ảnh đính kèm (ADR-0017 mục 7). Chỉ chuyển byte đã mã hóa; không bao giờ ghi id/cỡ/tên ra log.
final class FileSync {
  FileSync({required this.api, required this.store});

  final ApiClient api;
  final RecordStore store;

  static String accountPath(String id) => '/api/v1/files/$id';
  static String walletPath(String walletId, String id) => '/api/v1/wallets/$walletId/files/$id';

  SharedWalletRow? _shared(String? walletId) => walletId == null ? null : store.sharedWallet(walletId);

  Future<FileSyncReport> run() async {
    var uploaded = 0;
    var blocked = false;
    var quotaFull = false;

    // 1. Xóa trên máy chủ (không cần Pro).
    for (final b in store.blobsIn(BlobState.deleting, withBytes: false)) {
      final shared = _shared(b.walletId);
      final paths = switch (b.remote) {
        BlobRemote.account => [accountPath(b.id)],
        BlobRemote.wallet => [if (b.walletId != null) walletPath(b.walletId!, b.id)],
        // Tệp thiết bị khác tạo: có thể ở cả hai chỗ.
        BlobRemote.unknown => [accountPath(b.id), if (shared != null) walletPath(b.walletId!, b.id)],
      };
      var done = true;
      for (final p in paths) {
        try {
          await api.delete(p);
        } on ApiException catch (e) {
          if (e.status == 0) rethrow;
          // 404 (không có/không là thành viên) và 403 (người xem) ⇒ không làm gì thêm được ở máy này.
          if (e.status != 404 && e.status != 403) done = false;
        }
      }
      if (done) store.deleteBlob(b.id);
    }

    // 2. Tải lên ảnh mới; 3. chuyển ảnh của ví vừa thành ví chung sang không gian ví (thành viên mới đọc được).
    // Chỉ đọc siêu dữ liệu trước; bản mã nạp từng tệp một (đệm ảnh đã xem có thể lớn).
    final pending = store.blobsIn(BlobState.pending, withBytes: false);
    final moving = [
      for (final b in store.blobsIn(BlobState.synced, withBytes: false))
        if (b.remote == BlobRemote.account && (_shared(b.walletId)?.role ?? 'viewer') != 'viewer') b,
    ];
    for (final meta in [...pending, ...moving]) {
      if (blocked || quotaFull) break;
      final b = store.blob(meta.id);
      final sealed = b?.sealed;
      if (b == null || sealed == null) continue;
      final shared = _shared(b.walletId);
      if (shared != null && shared.role == 'viewer') continue;
      try {
        if (shared != null) {
          await api.putBytes(walletPath(b.walletId!, b.id), sealed);
        } else {
          await api.putBytes(accountPath(b.id), sealed, {if (b.walletId != null) 'wallet_id': b.walletId!});
        }
      } on ApiException catch (e) {
        if (e.status == 402 && e.code == 'pro_required') {
          blocked = true;
          continue;
        }
        if (e.status == 507) {
          quotaFull = true;
          continue;
        }
        if (e.status == 0) rethrow;
        // 409 shared_wallet (máy chưa biết ví đã chia sẻ), 403, 413... ⇒ giữ chờ, lượt sau thử lại.
        continue;
      }
      if (b.state == BlobState.synced) {
        // Đã có bản ở không gian ví ⇒ bỏ bản ở không gian tài khoản.
        try {
          await api.delete(accountPath(b.id));
        } on ApiException catch (e) {
          if (e.status == 0) rethrow;
        }
      } else {
        uploaded++;
      }
      store.setBlobState(b.id, BlobState.synced, shared != null ? BlobRemote.wallet : BlobRemote.account);
    }
    final left = store.blobsIn(BlobState.pending, withBytes: false).length;
    return FileSyncReport(uploaded: uploaded, pending: left, blocked: blocked, quotaFull: quotaFull);
  }

  /// Tải bản mã của [a] từ máy chủ: thử không gian đúng loại ví trước, rồi chỗ còn lại (ảnh tải lên trước khi ví được
  /// chia sẻ). Trả (bản mã, nơi tìm thấy); null nếu không có ở đâu.
  Future<(Uint8List, BlobRemote)?> download(Attachment a) async {
    final shared = _shared(a.walletId) != null;
    final order = [
      if (shared) (walletPath(a.walletId!, a.id), BlobRemote.wallet),
      (accountPath(a.id), BlobRemote.account),
    ];
    for (final (path, where) in order) {
      try {
        return (await api.getFile(path), where);
      } on ApiException catch (e) {
        if (e.status != 404) rethrow;
      }
    }
    return null;
  }
}

/// Quyền ghi ảnh theo vai trò ví chung (null = ví cá nhân).
bool canEditAttachments(WalletRole? role) => role == null || role.canWrite;
