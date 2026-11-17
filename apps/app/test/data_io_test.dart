import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulythuchi/data/key_storage.dart';
import 'package:qulythuchi/data/record_store.dart';
import 'package:qulythuchi/domain/default_categories.dart';
import 'package:qulythuchi/security/vault.dart';
import 'package:qulythuchi/services/export.dart';
import 'package:qulythuchi/services/import_csv.dart';
import 'package:qulythuchi/state/ledger_repository.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';
import 'package:sodium/sodium_sumo.dart';
import 'package:sqlite3/sqlite3.dart';

import 'helpers.dart';

const _pw = 'mat-khau-thu-nghiem';
const _wrong = 'sai-mat-khau-roi';

Uint8List _bytes(String s) => Uint8List.fromList(utf8.encode(s));

void main() {
  late SodiumSumo sodium;
  setUpAll(() async => sodium = await testSodium());

  Vault newVault(RecordStore store) =>
      Vault(sodium: sodium, store: store, keyStorage: MemoryKeyStorage(), config: testVaultConfig, allowWeakKdf: true);

  group('sao lưu mã hóa', () {
    late Uint8List file;
    late List<String> words;
    late String walletId;

    setUp(() {
      final store = RecordStore(sqlite3.openInMemory());
      final vault = newVault(store);
      words = vault.createAccount(_pw);
      final repo = LedgerRepository(store, vault)..seedDefaultCategories(DefaultCategoryLocale.vi);
      walletId = repo
          .saveWallet(Wallet(id: repo.newId(), name: 'Ví', type: WalletType.cash, currency: Currency.vnd))
          .id;
      repo.saveTxn(
        Txn(
          id: repo.newId(),
          walletId: walletId,
          kind: TxnKind.expense,
          amount: 45000,
          date: CivilDate(2026, 11, 17),
          note: 'Phở bò bí mật',
        ),
      );
      file = vault.createBackup(repo.newId());
    });

    test('không chứa bản rõ; khôi phục bằng mật khẩu và 24 từ', () async {
      expect(utf8.decode(file).contains('Phở'), isFalse);
      for (final useWords in [false, true]) {
        final store = RecordStore(sqlite3.openInMemory());
        final vault = newVault(store);
        final n = await vault.restoreBackup(file, password: useWords ? null : _pw, words: useWords ? words : null);
        expect(n, greaterThan(28));
        final data = LedgerRepository(store, vault).load();
        expect(data.skipped, 0);
        expect(data.txns.single.note, 'Phở bò bí mật');
        expect(data.balance(data.wallet(walletId)!).minor, -45000);
        // Sau khi khôi phục, khóa rồi mở lại bằng mật khẩu gốc vẫn được.
        vault.lock();
        await vault.unlockWithPassword(_pw);
      }
    });

    test('sai mật khẩu, tệp hỏng, bị sửa hoặc thiết bị đã có tài khoản ⇒ từ chối', () async {
      final store = RecordStore(sqlite3.openInMemory());
      final vault = newVault(store);
      await expectLater(vault.restoreBackup(file, password: _wrong), throwsA(isA<EnvelopeException>()));
      expect(vault.hasAccount, isFalse);
      await expectLater(vault.restoreBackup(_bytes('{"x":1}'), password: _pw), throwsFormatException);
      final doc = jsonDecode(utf8.decode(file)) as Map<String, Object?>;
      final payload = base64.decode(doc['payload']! as String);
      payload[payload.length - 1] ^= 1;
      final tampered = _bytes(jsonEncode({...doc, 'payload': base64.encode(payload)}));
      await expectLater(vault.restoreBackup(tampered, password: _pw), throwsFormatException);
      // Đổi id ⇒ AAD khác ⇒ không mở được.
      final swapped = _bytes(jsonEncode({...doc, 'id': 'khac'}));
      await expectLater(vault.restoreBackup(swapped, password: _pw), throwsFormatException);
      expect(vault.hasAccount, isFalse);

      final other = newVault(RecordStore(sqlite3.openInMemory()))..createAccount(_pw);
      await expectLater(other.restoreBackup(file, password: _pw), throwsStateError);
    });
  });

  test('giao tác lồng nhau: lỗi ở lớp trong hủy cả lớp ngoài', () {
    final store = RecordStore(sqlite3.openInMemory());
    expect(
      () => store.transaction(() {
        store.putMeta('a', Uint8List.fromList([1]));
        store.transaction(() => throw StateError('x'));
      }),
      throwsStateError,
    );
    expect(store.getMeta('a'), isNull);
    store.transaction(() => store.transaction(() => store.putMeta('b', Uint8List.fromList([2]))));
    expect(store.getMeta('b'), [2]);
  });

  group('nhập CSV', () {
    test('đọc ngoặc kép, dấu ;, BOM; số tiền và ngày nhiều kiểu', () {
      final rows = parseCsv(_bytes('\uFEFFNgày;Số tiền;Ghi chú\r\n17/11/2026;"-50.000";"cà phê; bánh"\n'));
      expect(rows, [
        ['Ngày', 'Số tiền', 'Ghi chú'],
        ['17/11/2026', '-50.000', 'cà phê; bánh'],
      ]);
      expect(parseAmount('1.234.567 ₫', Currency.vnd), 1234567);
      expect(parseAmount('(1.200)', Currency.vnd), -1200);
      expect(parseAmount('1,234.5', Currency.usd), 123450);
      expect(parseAmount('1.234,56', Currency.usd), 123456);
      expect(parseAmount('abc', Currency.vnd), isNull);
      expect(parseDate('2026-11-17', DateOrder.dmy), CivilDate(2026, 11, 17));
      expect(parseDate('11/17/26', DateOrder.mdy), CivilDate(2026, 11, 17));
      expect(parseDate('31/02/2026', DateOrder.dmy), isNull);
    });

    test('ghép cột, đoán danh mục theo tên không dấu, đếm dòng lỗi, ghi một lần', () {
      final store = RecordStore(sqlite3.openInMemory());
      final vault = newVault(store)..createAccount(_pw);
      final repo = LedgerRepository(store, vault)..seedDefaultCategories(DefaultCategoryLocale.vi);
      final w = repo.saveWallet(Wallet(id: repo.newId(), name: 'Ví', type: WalletType.bank, currency: Currency.vnd));
      final rows = parseCsv(
        _bytes(
          'Date,Amount,Description,Category,Type\n'
          '17/11/2026,"50.000",Phở,an uong,chi\n'
          '18/11/2026,10000000,Lương,,thu\n'
          '19/11/2026,-20000,Taxi,,\n'
          'ngay-hong,1000,x,,\n'
          '20/11/2026,0,x,,\n',
        ),
      );
      final g = guessColumns(rows.first);
      expect((g.date, g.amount, g.note, g.category, g.type), (0, 1, 2, 3, 4));
      final data = repo.snapshot();
      final r = buildImportTxns(
        rows,
        ImportMapping(date: g.date!, amount: g.amount!, note: g.note, category: g.category, type: g.type),
        w,
        data.categories,
        repo.newId,
      );
      expect(r.skipped, 2);
      expect(r.txns.map((t) => (t.kind, t.amount)), [
        (TxnKind.expense, 50000),
        (TxnKind.income, 10000000),
        (TxnKind.expense, 20000),
      ]);
      expect(data.category(r.txns.first.categoryId)?.name, 'Ăn uống');
      expect(r.txns.every((t) => t.source == TxnSource.import), isTrue);
      expect(repo.importTxns(r.txns), 3);
      final after = repo.load();
      expect(after.balance(after.wallet(w.id)!).minor, 10000000 - 50000 - 20000);
    });
  });

  group('xuất', () {
    final table = ExportTable(
      ['Ngày', 'Ghi chú', 'Số tiền'],
      [
        ['2026-11-17', '=HYPERLINK("x")', exportNumber('-50000')],
        ['2026-11-18', 'a,"b"', exportNumber('12.50')],
      ],
    );

    test('CSV có BOM, chống công thức, số không bị thêm dấu nháy', () {
      final bytes = toCsv(table);
      expect(bytes.take(3), [0xEF, 0xBB, 0xBF]);
      final s = utf8.decode(bytes);
      expect(s, contains("'=HYPERLINK"));
      expect(s, contains(',-50000\r\n'));
      expect(s, contains('"a,""b"""'));
      expect(decimalString(-123450, 2), '-1234.50');
      expect(decimalString(5, 2), '0.05');
      expect(decimalString(45000, 0), '45000');
    });

    test('XLSX là zip hợp lệ có trang tính với ô số thật', () {
      final zip = ZipDecoder().decodeBytes(toXlsx(table));
      final sheet = utf8.decode(zip.findFile('xl/worksheets/sheet1.xml')!.content as List<int>);
      expect(zip.findFile('[Content_Types].xml'), isNotNull);
      expect(sheet, contains('<c r="C2"><v>-50000</v></c>'));
      expect(sheet, contains('&quot;'));
    });
  });
}
