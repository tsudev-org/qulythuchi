import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:qulythuchi/data/db_open_native.dart' show keyDatabase;
import 'package:qulythuchi/data/key_storage.dart';
import 'package:qulythuchi/data/record_store.dart';
import 'package:qulythuchi/domain/default_categories.dart';
import 'package:qulythuchi/security/vault.dart';
import 'package:qulythuchi/state/ledger_repository.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';
import 'package:sodium/sodium_sumo.dart';
import 'package:sqlite3/sqlite3.dart';

const _pw = 'mat-khau-thu-nghiem';
const _cfg = VaultConfig(kdfOps: 1, kdfMem: 8192, pinOps: 1, pinMem: 8192);

void main() {
  late SodiumSumo sodium;
  setUpAll(() async => sodium = await SodiumSumoInit.init());

  test('CSDL sqlite3mc: sai khóa không đọc được', () {
    final dir = Directory.systemTemp.createTempSync('qt');
    final path = '${dir.path}/a.db';
    final key = 'ab' * 32;
    final db = sqlite3.open(path);
    keyDatabase(db, key);
    RecordStore(db).putMeta('x', Uint8List.fromList([1, 2, 3]));
    db.close();
    final raw = File(path).readAsBytesSync();
    expect(String.fromCharCodes(raw.take(15)), isNot('SQLite format 3'));
    final wrong = sqlite3.open(path);
    expect(() => keyDatabase(wrong, 'cd' * 32), throwsA(isA<SqliteException>()));
    wrong.close();
    final ok = sqlite3.open(path);
    keyDatabase(ok, key);
    expect(RecordStore(ok).getMeta('x'), [1, 2, 3]);
    ok.close();
    dir.deleteSync(recursive: true);
  });

  test('CSDL sqlite3mc: mặc định ChaCha20 và đọc được CSDL tạo bởi bản cũ (sqlite3 3.9.1)', () {
    // Tệp mẫu do libsqlite3mc của gói sqlite3 3.9.1 tạo (khóa thử 'ab' * 32). Nâng sqlite3/sqlite3mc mà đổi cipher
    // mặc định hoặc định dạng trang ⇒ test này đỏ ⇒ người dùng cũ không mở được CSDL. KHÔNG sinh lại tệp mẫu.
    final dir = Directory.systemTemp.createTempSync('qt');
    final path = '${dir.path}/cu.db';
    File('test/fixtures/sqlite3mc-chacha20-tu-3.9.1.mau').copySync(path);
    final db = sqlite3.open(path);
    expect(db.select('PRAGMA cipher').single.values.single, 'chacha20');
    keyDatabase(db, 'ab' * 32);
    expect(db.select('SELECT x FROM mau').single['x'], 'tao-boi-sqlite3-3.9.1');
    db.close();
    dir.deleteSync(recursive: true);
  });

  test('tạo tài khoản → ghi → khóa → mở bằng mật khẩu/24 từ/PIN đọc lại đúng', () async {
    final store = RecordStore(sqlite3.openInMemory());
    final keys = MemoryKeyStorage();
    final vault = Vault(sodium: sodium, store: store, keyStorage: keys, config: _cfg, allowWeakKdf: true);
    final words = vault.createAccount(_pw);
    expect(words, hasLength(24));
    var repo = LedgerRepository(store, vault);
    repo.seedDefaultCategories(DefaultCategoryLocale.vi);
    final a = repo.saveWallet(
      Wallet(id: repo.newId(), name: 'Tiền mặt', type: WalletType.cash, currency: Currency.vnd, openingBalance: 500000),
    );
    final b = repo.saveWallet(
      Wallet(id: repo.newId(), name: 'Ngân hàng', type: WalletType.bank, currency: Currency.vnd),
    );
    final food = repo.snapshot().categories.firstWhere((c) => c.name == 'Ăn uống');
    repo.saveTxn(
      Txn(
        id: repo.newId(),
        walletId: a.id,
        kind: TxnKind.expense,
        amount: 45000,
        date: CivilDate(2026, 11, 17),
        categoryId: food.id,
        note: 'Phở',
      ),
    );
    repo.saveTransfer(fromWalletId: a.id, toWalletId: b.id, amount: 100000, fee: 1000, date: CivilDate(2026, 11, 17));
    await vault.setPin('123456');

    // Không có bản rõ nào trong CSDL.
    for (final row in store.allRecords()) {
      expect(String.fromCharCodes(row.sealed).contains('Phở'), isFalse);
    }

    vault.lock();
    expect(() => vault.keyFor(null), throwsStateError);
    await expectLater(vault.unlockWithPassword('sai-mat-khau-roi'), throwsA(isA<EnvelopeException>()));

    for (final unlock in <Future<void> Function()>[
      () => vault.unlockWithPassword(_pw),
      () => vault.unlockWithRecovery(words),
      () async => expect(await vault.unlockWithPin('123456'), isA<PinOk>()),
    ]) {
      vault.lock();
      await unlock();
      repo = LedgerRepository(store, vault);
      final data = repo.load();
      expect(data.skipped, 0);
      expect(data.categories, hasLength(36));
      expect(data.balance(data.wallet(a.id)!).minor, 500000 - 45000 - 101000);
      expect(data.balance(data.wallet(b.id)!).minor, 100000);
      expect(data.txns.where((t) => t.transferId != null), hasLength(2));
    }
  });

  test('PIN sai: chờ tăng dần, quá 10 lần thì vô hiệu', () async {
    final store = RecordStore(sqlite3.openInMemory());
    final keys = MemoryKeyStorage();
    final vault = Vault(sodium: sodium, store: store, keyStorage: keys, config: _cfg, allowWeakKdf: true);
    vault.createAccount(_pw);
    await vault.setPin('246810');
    vault.lock();
    for (var i = 1; i <= 4; i++) {
      final r = await vault.unlockWithPin('000000');
      expect(r, isA<PinWrong>());
      expect((r as PinWrong).waitUntil, isNull);
    }
    final fifth = await vault.unlockWithPin('000000') as PinWrong;
    expect(fifth.waitUntil, isNotNull);
    expect(await vault.unlockWithPin('246810'), isA<PinLockedOut>());
    for (var i = 6; i <= 10; i++) {
      keys.values.remove('qt.pinUntil'); // giả lập đã chờ đủ
      final r = await vault.unlockWithPin('000000');
      expect(r, i == 10 ? isA<PinDisabled>() : isA<PinWrong>());
    }
    expect(vault.pinEnabled, isFalse);
    expect(vault.isUnlocked, isFalse);
  });

  test('bản ghi bị tráo sang id khác ⇒ bỏ qua, không lộ', () {
    final store = RecordStore(sqlite3.openInMemory());
    final vault = Vault(sodium: sodium, store: store, keyStorage: MemoryKeyStorage(), config: _cfg, allowWeakKdf: true);
    vault.createAccount(_pw);
    final repo = LedgerRepository(store, vault);
    final w = repo.saveWallet(Wallet(id: repo.newId(), name: 'Ví', type: WalletType.cash, currency: Currency.vnd));
    final t1 = repo.saveTxn(
      Txn(id: repo.newId(), walletId: w.id, kind: TxnKind.expense, amount: 1, date: CivilDate(2026, 1, 1)),
    );
    final rows = store.allRecords();
    final sealed = rows.firstWhere((r) => r.id == t1.id).sealed;
    store.putRecords([SealedRow(id: repo.newId(), type: 'txn', walletId: w.id, sealed: sealed)]);
    expect(LedgerRepository(store, vault).load().skipped, 1);
  });
}
