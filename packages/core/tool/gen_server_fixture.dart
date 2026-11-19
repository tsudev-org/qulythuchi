// Sinh dữ liệu mẫu THẬT (gói khóa, khóa ví đã bọc, phong bì bản ghi) cho test máy chủ `services/sync-api`, để máy chủ
// kiểm khung đúng định dạng lõi đang sinh ra. Mật khẩu và nội dung là GIẢ, khóa ngẫu nhiên mỗi lần chạy.
// Chạy: dart run tool/gen_server_fixture.dart > ../../services/sync-api/test/fixtures/core-v1.json
// ignore_for_file: avoid_print
import 'dart:convert';

import 'package:qulythuchi_core/qulythuchi_core.dart';
import 'package:sodium/sodium_sumo.dart';

Future<void> main() async {
  final sodium = await SodiumSumoInit.init();
  final kh = KeyHierarchy(sodium);
  // Tham số sàn (2 lượt / 19 MiB) cho nhanh - vẫn hợp lệ theo ADR-0007.
  final setup = kh.createAccount(
    'mat-khau-gia-cho-test',
    kdf: kh.newKdfParams(opsLimit: 2, memLimit: 19 * 1024 * 1024),
  );
  const walletId = '7c9e6679-7425-40de-944b-e07fc1f90ae7';
  final (walletKey, wrapped) = kh.createWalletKey(setup.masterKey, walletId);
  final cipher = RecordCipher(Envelope(sodium));
  final clock = HlcClock('fixture', now: () => 1763337600000);
  final records = <Map<String, Object?>>[];
  for (final (id, note) in [
    ('0f8fad5b-d9cb-469f-a165-70867728950e', 'Phở bò'),
    ('1b4e28ba-2fa1-41d2-883f-0016d3cca427', 'Tiền điện tháng 11'),
  ]) {
    final rec = SyncRecord(id: id, type: 'txn', walletId: walletId).setAll({'amount': 50000, 'note': note}, clock);
    records.add({'id': id, 'type': 'txn', 'wallet_id': walletId, 'sealed': base64.encode(cipher.seal(rec, walletKey))});
  }
  // Ví chung (ADR-0015): tài khoản thứ hai làm thành viên, khối chia sẻ X-Wing + bí mật cặp, bản bọc cho chủ ví.
  final member = kh.createAccount(
    'mat-khau-thanh-vien-gia',
    kdf: kh.newKdfParams(opsLimit: 2, memLimit: 19 * 1024 * 1024),
  );
  final sharing = WalletSharing(sodium);
  final invite = sharing.newInvite();
  final share = sharing.shareKey(
    walletKey: walletKey,
    walletId: walletId,
    version: 1,
    recipientKemPublicKey: member.bundle.kemPublicKey,
    pairSecret: invite.secret,
  );
  final proof = sharing.acceptProof(
    secret: invite.secret,
    walletId: walletId,
    inviteId: invite.inviteId,
    kemPublicKey: member.bundle.kemPublicKey,
  );
  print(
    const JsonEncoder.withIndent('  ').convert({
      'description': 'SINH TỰ ĐỘNG bởi packages/core/tool/gen_server_fixture.dart - không sửa tay. Dữ liệu giả.',
      'bundle': setup.bundle.toJson(),
      'wallet_key': {'wallet_id': walletId, 'wrapped': base64.encode(wrapped)},
      'records': records,
      'shared': {
        'member_bundle': member.bundle.toJson(),
        'invite_id': invite.inviteId,
        'owner_wrapped': base64.encode(sharing.wrapForSelf(setup.masterKey, walletKey, walletId, 1)),
        'member_share': base64.encode(share),
        'proof': base64.encode(proof),
      },
    }),
  );
  walletKey.dispose();
  setup.masterKey.dispose();
  member.masterKey.dispose();
}
