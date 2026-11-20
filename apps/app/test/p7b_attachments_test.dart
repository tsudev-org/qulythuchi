import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:qulythuchi/data/record_store.dart';
import 'package:qulythuchi/state/ledger_repository.dart';
import 'package:qulythuchi/state/providers.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import 'fake_sync_server.dart';
import 'helpers.dart' show testPassword;
import 'p9_shared_test.dart' show Device, device, family, spend;

/// P7b ảnh đính kèm E2EE (ADR-0017): engine + mật mã THẬT, máy chủ giả theo hợp đồng `services/sync-api`.
SanitizedImage photo(String marker) => SanitizedImage(
  bytes: Uint8List.fromList([0xff, 0xd8, ...utf8.encode('hoa-don-$marker'), 0xff, 0xd9]),
  width: 4,
  height: 3,
);

Wallet cash(Device d, [String name = 'Tiền mặt']) =>
    d.ledger.saveWallet(Wallet(id: d.ledger.newId(), name: name, type: WalletType.cash, currency: Currency.vnd));

String r2Dump(FakeSyncServer s) => latin1.decode([for (final b in s.r2.values) ...b]);

void main() {
  late FakeSyncServer server;
  setUp(() => server = FakeSyncServer());

  test(
    '402 pro_required: ảnh GIỮ trên máy chờ tải; có Pro ⇒ lên máy chủ (chỉ bản mã), máy thứ hai tải về xem được',
    () async {
      final a = await device(server, 'an');
      final w = cash(a);
      final t = spend(a, w.id, 50000, note: 'Siêu thị');
      final att = a.ledger.addAttachment(t.id, photo('sieu-thi'));
      expect(a.ledger.attachmentsOf(t.id).map((x) => x.id), [att.id]);
      expect(a.ledger.attachmentState(att.id), BlobState.pending);

      server.proBlocked = true;
      await a.sync.syncNow();
      expect(a.state.filesBlocked, isTrue);
      expect(a.state.filesPending, 1);
      expect(a.ledger.attachmentState(att.id), BlobState.pending, reason: 'không mất ảnh khi hết Pro');
      expect(server.r2, isEmpty);

      server.proBlocked = false;
      await a.sync.syncNow();
      expect(a.state.filesBlocked, isFalse);
      expect(a.state.filesPending, 0);
      expect(a.ledger.attachmentState(att.id), BlobState.synced);
      expect(server.r2.keys, ['u/an/${att.id}']);
      expect(r2Dump(server).contains('hoa-don'), isFalse, reason: 'máy chủ chỉ có bản mã');
      expect(server.r2.values.single.length % 65536, 44, reason: 'đệm 64 KiB + 44 byte phong bì');

      final b = await device(server, 'an', withAccount: false);
      final remote = await b.sync.fetchRemoteAccount();
      await b.sync.adoptRemote(remote!, password: testPassword);
      await b.sync.syncNow();
      final seen = b.ledger.attachmentsOf(b.data.txns.single.id).single;
      expect(b.c.read(repositoryProvider).openAttachment(seen), isNull, reason: 'chưa tải về');
      final bytes = await b.sync.fetchAttachment(seen);
      expect(utf8.decode(bytes!.sublist(2, bytes.length - 2)), 'hoa-don-sieu-thi');
      expect(b.ledger.attachmentState(seen.id), BlobState.synced);

      // Xóa ở máy A ⇒ máy chủ xóa; máy B kéo bia mộ ⇒ bỏ đệm.
      a.ledger.deleteAttachment(att.id);
      expect(a.ledger.attachmentsOf(t.id), isEmpty);
      await a.sync.syncNow();
      expect(server.r2, isEmpty);
      await b.sync.syncNow();
      expect(b.ledger.attachmentsOf(b.data.txns.single.id), isEmpty);
      expect(b.ledger.attachmentState(seen.id), isNull);
    },
  );

  test('máy chủ độc tráo tệp giữa hai ảnh ⇒ không mở được, không đệm', () async {
    final a = await device(server, 'an');
    final w = cash(a);
    final t = spend(a, w.id, 1000);
    final x = a.ledger.addAttachment(t.id, photo('x'));
    final y = a.ledger.addAttachment(t.id, photo('y'));
    await a.sync.syncNow();
    final kx = 'u/an/${x.id}';
    final ky = 'u/an/${y.id}';
    final tmp = server.r2[kx]!;
    server.r2[kx] = server.r2[ky]!;
    server.r2[ky] = tmp;
    // Máy thứ hai chưa có bản mã cục bộ ⇒ phải tải.
    final b = await device(server, 'an', withAccount: false);
    await b.sync.adoptRemote((await b.sync.fetchRemoteAccount())!, password: testPassword);
    await b.sync.syncNow();
    final bx = b.c.read(repositoryProvider).attachment(x.id)!;
    await expectLater(b.sync.fetchAttachment(bx), throwsA(isA<EnvelopeException>()));
    expect(b.ledger.attachmentState(x.id), isNull);
  });

  test('tối đa 5 ảnh; xóa giao dịch xóa luôn ảnh; đổi ví mã hóa lại ảnh sang ví/giao dịch mới', () async {
    final a = await device(server, 'an');
    final w1 = cash(a);
    final w2 = cash(a, 'Ngân hàng');
    final t = spend(a, w1.id, 1000);
    for (var i = 0; i < Attachment.maxPerTxn; i++) {
      a.ledger.addAttachment(t.id, photo('$i'));
    }
    expect(
      () => a.ledger.addAttachment(t.id, photo('6')),
      throwsA(isA<LedgerException>().having((e) => e.code, 'code', 'tooManyAttachments')),
    );

    final moved = a.ledger.saveTxn(a.data.txn(t.id)!.copyWithWallet(w2.id));
    expect(moved.id, isNot(t.id));
    expect(a.ledger.attachmentsOf(t.id), isEmpty);
    final now = a.ledger.attachmentsOf(moved.id);
    expect(now, hasLength(5));
    expect(now.every((x) => x.walletId == w2.id), isTrue);
    final repo = a.c.read(repositoryProvider);
    expect(now.map((x) => utf8.decode(repo.openAttachment(x)!.sublist(2, 11))).toSet(), hasLength(5));

    a.ledger.deleteTxn(moved.id);
    expect(a.ledger.attachmentsOf(moved.id), isEmpty);
    expect(now.every((x) => a.ledger.attachmentState(x.id) == BlobState.deleting), isTrue);
    await a.sync.syncNow();
    expect(server.r2, isEmpty);
  });

  test('ví chung: người ghi gắn ảnh ⇒ lên không gian ví, chủ ví tải về xem; người xem không gắn được', () async {
    final (an, binh, w) = await family(server);
    final t = binh.data.txns.single;
    final att = binh.ledger.addAttachment(t.id, photo('cho'));
    await binh.sync.syncNow();
    expect(server.r2.keys, ['w/${w.id}/${att.id}']);
    await an.sync.syncNow();
    final seen = an.c.read(repositoryProvider).attachment(att.id)!;
    final bytes = await an.sync.fetchAttachment(seen);
    expect(utf8.decode(bytes!.sublist(2, bytes.length - 2)), 'hoa-don-cho');
  });

  test('ví chung: người xem gắn ảnh ⇒ readOnly, không sót bản mã mồ côi', () async {
    final (_, binh, _) = await family(server, role: WalletRole.viewer);
    final t = binh.data.txns.single;
    expect(
      () => binh.ledger.addAttachment(t.id, photo('x')),
      throwsA(isA<LedgerException>().having((e) => e.code, 'code', 'readOnly')),
    );
    expect(binh.services.store.blobsIn(BlobState.pending, withBytes: false), isEmpty);
  });

  test('ảnh tải lên trước khi ví được chia sẻ ⇒ chuyển sang không gian ví để thành viên đọc được', () async {
    final an = await device(server, 'an');
    final w = cash(an, 'Chi tiêu nhà');
    final t = spend(an, w.id, 7000);
    final att = an.ledger.addAttachment(t.id, photo('truoc'));
    await an.sync.syncNow();
    expect(server.r2.keys, ['u/an/${att.id}']);
    await an.sync.shareWallet(w.id);
    await an.sync.syncNow();
    expect(server.r2.keys, ['w/${w.id}/${att.id}']);
  });
}

extension on Txn {
  Txn copyWithWallet(String walletId) =>
      Txn(id: id, walletId: walletId, kind: kind, amount: amount, date: date, note: note);
}
