import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show immutable;
import 'package:qulythuchi_core/qulythuchi_core.dart';

/// Bí mật cặp của ví chung (ADR-0015 mục 2): nửa bí mật của mã mời, cả chủ ví lẫn thành viên đều giữ.
///
/// Lưu thành bản ghi E2EE cấp tài khoản (loại [recordType]) nên mọi thiết bị của cùng tài khoản đều có - thiết bị nào
/// của chủ ví cũng hoàn tất được lời mời và xoay khóa; thiết bị nào của thành viên cũng mở được khóa ví.
@immutable
final class ShareSecret {
  const ShareSecret({
    required this.id,
    required this.walletId,
    required this.inviteId,
    required this.secret,
    required this.side,
    this.userId,
    this.role,
  });

  static const recordType = 'wallet_share';

  final String id;
  final String walletId;
  final String inviteId;
  final Uint8List secret;

  /// `owner`: mình là chủ ví, bí mật dùng chia khóa cho [userId]. `member`: mình là người được mời.
  final String side;
  final String? userId;
  final WalletRole? role;

  bool get isOwnerSide => side == 'owner';

  ShareSecret copyWith({String? userId, WalletRole? role}) => ShareSecret(
    id: id,
    walletId: walletId,
    inviteId: inviteId,
    secret: secret,
    side: side,
    userId: userId ?? this.userId,
    role: role ?? this.role,
  );

  Map<String, Object?> toValues() => {
    'walletId': walletId,
    'inviteId': inviteId,
    'secret': base64.encode(secret),
    'side': side,
    'userId': userId,
    'role': role?.name,
  };

  static ShareSecret? fromRecord(SyncRecord r) {
    try {
      final secret = base64.decode(r['secret']! as String);
      if (secret.length != WalletSharing.secretBytes) return null;
      final side = r['side'];
      if (side != 'owner' && side != 'member') return null;
      return ShareSecret(
        id: r.id,
        walletId: r['walletId']! as String,
        inviteId: r['inviteId']! as String,
        secret: secret,
        side: side! as String,
        userId: r['userId'] as String?,
        role: WalletRole.fromName(r['role']),
      );
    } on Object {
      return null;
    }
  }
}

/// Nơi giữ bí mật cặp + danh mục chia sẻ trong ví chung (do `LedgerRepository` cài đặt).
abstract interface class SharingBook {
  List<ShareSecret> shareSecrets();
  void saveShareSecret(ShareSecret s);

  /// Bỏ mọi bí mật của một ví (bị thu hồi / tự rời).
  void forgetShareSecrets(String walletId);

  /// Ghi (khi đổi) bản ghi danh mục mình dùng trong ví chung để người khác hiện đúng tên danh mục.
  void publishWalletCategories(String walletId);
}

Uint8List? _b64(Object? v) {
  if (v is! String) return null;
  try {
    return base64.decode(v);
  } on FormatException {
    return null;
  }
}

@immutable
final class WalletMember {
  const WalletMember({
    required this.userId,
    required this.role,
    this.displayName,
    this.email,
    this.kemPublicKey,
    this.boxPublicKey,
    this.badge,
  });
  final String userId;
  final WalletRole role;

  /// Huy hiệu SAU `badge_display` (máy chủ đã lọc theo lựa chọn ẩn/hiện): `pro` | `donor` | `both` | `none`.
  final String? badge;
  final String? displayName;
  final String? email;
  final Uint8List? kemPublicKey;
  final Uint8List? boxPublicKey;
}

@immutable
final class AcceptedInvite {
  const AcceptedInvite({required this.userId, this.displayName, this.email, this.kemPublicKey, this.proof});
  final String userId;
  final String? displayName;
  final String? email;
  final Uint8List? kemPublicKey;
  final Uint8List? proof;
}

@immutable
final class WalletInvite {
  const WalletInvite({required this.inviteId, required this.role, required this.expiresAt, this.accepted});
  final String inviteId;
  final WalletRole role;
  final DateTime expiresAt;
  final AcceptedInvite? accepted;
}

@immutable
final class SharedWalletInfo {
  const SharedWalletInfo({
    required this.walletId,
    required this.role,
    required this.keyVer,
    required this.ownerId,
    required this.needsRotation,
    required this.shares,
    required this.members,
    required this.invites,
  });
  final String walletId;
  final WalletRole role;
  final int keyVer;
  final String ownerId;
  final bool needsRotation;
  final Map<int, Uint8List> shares;
  final List<WalletMember> members;
  final List<WalletInvite> invites;
}

/// Lời mời mình đã nhận, chờ chủ ví mở app để hoàn tất.
@immutable
final class PendingJoin {
  const PendingJoin({required this.inviteId, required this.walletId, required this.role, this.ownerName});
  final String inviteId;
  final String walletId;
  final WalletRole role;
  final String? ownerName;
}

/// Ảnh chụp `GET /api/v1/wallets`. Chỉ có id, quyền, tên/email thành viên (D2) và khóa đã bọc - không có dữ liệu D3.
@immutable
final class SharedOverview {
  const SharedOverview({this.wallets = const [], this.pending = const []});
  final List<SharedWalletInfo> wallets;
  final List<PendingJoin> pending;

  SharedWalletInfo? wallet(String id) => wallets.where((w) => w.walletId == id).firstOrNull;

  static SharedOverview parse(Object? json) {
    if (json is! Map) throw const FormatException('wallets');
    final wallets = <SharedWalletInfo>[];
    for (final w in (json['wallets'] as List? ?? const []).cast<Map<Object?, Object?>>()) {
      final role = WalletRole.fromName(w['role']);
      if (role == null) continue;
      wallets.add(
        SharedWalletInfo(
          walletId: w['wallet_id']! as String,
          role: role,
          keyVer: (w['key_ver']! as num).toInt(),
          ownerId: w['owner_id']! as String,
          needsRotation: w['needs_rotation'] == true,
          shares: {
            for (final s in (w['shares'] as List? ?? const []).cast<Map<Object?, Object?>>())
              (s['key_ver']! as num).toInt(): ?_b64(s['wrapped']),
          },
          members: [
            for (final m in (w['members'] as List? ?? const []).cast<Map<Object?, Object?>>())
              if (WalletRole.fromName(m['role']) case final r?)
                WalletMember(
                  userId: m['user_id']! as String,
                  role: r,
                  displayName: m['display_name'] as String?,
                  email: m['email'] as String?,
                  kemPublicKey: _b64(m['kem_pk']),
                  boxPublicKey: _b64(m['box_pk']),
                  badge: m['badge'] as String?,
                ),
          ],
          invites: [
            for (final i in (w['invites'] as List? ?? const []).cast<Map<Object?, Object?>>())
              if (WalletRole.fromName(i['role']) case final r?)
                WalletInvite(
                  inviteId: i['invite_id']! as String,
                  role: r,
                  expiresAt: DateTime.fromMillisecondsSinceEpoch((i['expires_at']! as num).toInt()),
                  accepted: switch (i['accepted']) {
                    final Map<Object?, Object?> a => AcceptedInvite(
                      userId: a['user_id']! as String,
                      displayName: a['display_name'] as String?,
                      email: a['email'] as String?,
                      kemPublicKey: _b64(a['kem_pk']),
                      proof: _b64(a['proof']),
                    ),
                    _ => null,
                  },
                ),
          ],
        ),
      );
    }
    return SharedOverview(
      wallets: wallets,
      pending: [
        for (final p in (json['pending'] as List? ?? const []).cast<Map<Object?, Object?>>())
          if (WalletRole.fromName(p['role']) case final r?)
            PendingJoin(
              inviteId: p['invite_id']! as String,
              walletId: p['wallet_id']! as String,
              role: r,
              ownerName: p['owner_name'] as String?,
            ),
      ],
    );
  }
}

/// Thông tin lời mời trước khi nhận.
@immutable
final class InvitePreview {
  const InvitePreview({
    required this.code,
    required this.walletId,
    required this.role,
    required this.state,
    required this.expiresAt,
    this.ownerName,
  });
  final InviteCode code;
  final String walletId;
  final WalletRole role;

  /// `open`, `accepted` (mình đã nhận), `taken` (người khác đã dùng), `own` (ví của mình).
  final String state;
  final DateTime expiresAt;
  final String? ownerName;
}

/// Lỗi nghiệp vụ ví chung (mã để dịch ở giao diện).
final class SharingException implements Exception {
  const SharingException(this.code);

  /// `missingSecret`: thiết bị này chưa có bí mật cặp của một thành viên (chờ đồng bộ); `missingKey`: chưa có khóa ví;
  /// `notSignedIn`, `invalidCode`, `inviteTaken`, `inviteOwn`.
  final String code;
  @override
  String toString() => 'SharingException($code)';
}
