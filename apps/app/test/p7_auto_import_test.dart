import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulythuchi/data/key_storage.dart';
import 'package:qulythuchi/data/record_store.dart';
import 'package:qulythuchi/domain/default_categories.dart';
import 'package:qulythuchi/security/vault.dart';
import 'package:qulythuchi/services/auto_import.dart';
import 'package:qulythuchi/services/import_csv.dart';
import 'package:qulythuchi/services/xlsx_reader.dart';
import 'package:qulythuchi/state/ledger_repository.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';
import 'package:sodium/sodium_sumo.dart';
import 'package:sqlite3/sqlite3.dart';

import 'helpers.dart';

// Mọi sao kê/thông báo/thư dưới đây là dữ liệu GIẢ.
const _pw = 'mat-khau-thu-nghiem';

Uint8List _bytes(String s) => Uint8List.fromList(utf8.encode(s));

/// XLSX tối thiểu: chuỗi dùng chung + ô số + ô ngày (kiểu 1 = numFmt 14).
Uint8List _xlsx(List<List<Object>> rows) {
  final strings = <String>[];
  final sheet = StringBuffer('<worksheet><sheetData>');
  for (var r = 0; r < rows.length; r++) {
    sheet.write('<row r="${r + 1}">');
    for (var c = 0; c < rows[r].length; c++) {
      final ref = '${String.fromCharCode(65 + c)}${r + 1}';
      final v = rows[r][c];
      if (v is String) {
        strings.add(v);
        sheet.write('<c r="$ref" t="s"><v>${strings.length - 1}</v></c>');
      } else if (v is DateTime) {
        final serial = v.difference(DateTime.utc(1899, 12, 30)).inDays;
        sheet.write('<c r="$ref" s="1"><v>$serial</v></c>');
      } else {
        sheet.write('<c r="$ref"><v>$v</v></c>');
      }
    }
    sheet.write('</row>');
  }
  sheet.write('</sheetData></worksheet>');
  String esc(String s) => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;');
  final sst = '<sst>${strings.map((s) => '<si><t>${esc(s)}</t></si>').join()}</sst>';
  const styles = '<styleSheet><cellXfs count="2"><xf numFmtId="0"/><xf numFmtId="14"/></cellXfs></styleSheet>';
  final a = Archive()
    ..add(ArchiveFile.string('xl/worksheets/sheet1.xml', sheet.toString()))
    ..add(ArchiveFile.string('xl/sharedStrings.xml', sst))
    ..add(ArchiveFile.string('xl/styles.xml', styles));
  return Uint8List.fromList(ZipEncoder().encode(a));
}

void main() {
  late SodiumSumo sodium;
  setUpAll(() async => sodium = await testSodium());

  late RecordStore store;
  late Vault vault;
  late LedgerRepository repo;
  late Wallet bank;

  setUp(() {
    store = RecordStore(sqlite3.openInMemory());
    vault = Vault(
      sodium: sodium,
      store: store,
      keyStorage: MemoryKeyStorage(),
      config: testVaultConfig,
      allowWeakKdf: true,
    )..createAccount(_pw);
    repo = LedgerRepository(store, vault)..seedDefaultCategories(DefaultCategoryLocale.vi);
    bank = repo.saveWallet(Wallet(id: repo.newId(), name: 'VCB', type: WalletType.bank, currency: Currency.vnd));
  });

  group('sao kê ngân hàng', () {
    const csv =
        'NGÂN HÀNG X - SAO KÊ TÀI KHOẢN\n'
        'Số tài khoản: 0011xxx\n'
        'Từ ngày 01/11/2026 đến 18/11/2026\n'
        'STT,Ngày giao dịch,Số tiền ghi nợ,Số tiền ghi có,Số dư,Nội dung\n'
        '1,15/11/2026,"45.000",,"9.955.000",Thanh toan GRAB\n'
        '2,16/11/2026,,"15.000.000","24.955.000",LUONG THANG 11\n'
        '3,17/11/2026,"80.000",,"24.875.000",PETROLIMEX CH 12\n';

    test('tìm dòng tiêu đề, cột ghi nợ/có, bỏ cột số dư, gợi ý danh mục, vào hàng chờ', () {
      final rows = parseCsv(_bytes(csv));
      final h = findHeaderRow(rows);
      expect(h, 3);
      final g = guessColumns(rows[h]);
      expect((g.date, g.debit, g.credit, g.note), (1, 2, 3, 5));
      expect(g.amount, isNull, reason: 'cột số dư không được nhận là số tiền');
      final data = repo.snapshot();
      final r = buildImportTxns(
        rows,
        ImportMapping(date: g.date!, debit: g.debit, credit: g.credit, note: g.note, headerRow: h, pending: true),
        bank,
        data.categories,
        repo.newId,
        existing: data.txns,
        suggester: LedgerCategorySuggester(data),
        source: TxnSource.statement,
      );
      expect(r.skipped, 0);
      expect(r.txns.map((t) => (t.kind, t.amount, t.pending)), [
        (TxnKind.expense, 45000, true),
        (TxnKind.income, 15000000, true),
        (TxnKind.expense, 80000, true),
      ]);
      final names = [for (final t in r.txns) data.category(t.categoryId)?.name];
      expect(names, ['Taxi, xe công nghệ', 'Lương', 'Xăng xe']);
      repo.importTxns(r.txns);
      final after = repo.load();
      expect(after.pendingTxns, hasLength(3));
      expect(after.balance(after.wallet(bank.id)!).minor, 0, reason: 'chờ xác nhận không tính vào số dư');
    });

    test('nhập lại cùng sao kê không nhân đôi (đếm theo số lần)', () {
      final rows = parseCsv(_bytes('${csv}4,17/11/2026,"80.000",,"24.795.000",PETROLIMEX CH 12\n'));
      final h = findHeaderRow(rows);
      final g = guessColumns(rows[h]);
      ImportResult run() {
        final data = repo.load();
        return buildImportTxns(
          rows,
          ImportMapping(date: g.date!, debit: g.debit, credit: g.credit, note: g.note, headerRow: h),
          bank,
          data.categories,
          repo.newId,
          existing: data.txns,
        );
      }

      final first = run();
      expect(first.txns, hasLength(4));
      repo.importTxns(first.txns);
      final again = run();
      expect(again.txns, isEmpty);
      expect(again.duplicates, 4);
    });

    test('XLSX: chuỗi dùng chung, ô ngày kiểu số sê-ri, ô số', () {
      final rows = parseXlsx(
        _xlsx([
          ['Sao kê'],
          ['Ngày', 'Diễn giải', 'Ghi nợ', 'Ghi có'],
          [DateTime.utc(2026, 11, 15), 'Cafe <Highlands> & bạn', 35000, ''],
          [DateTime.utc(2026, 11, 16), 'Hoàn tiền', '', 12000],
        ]),
      );
      expect(rows[2], ['2026-11-15', 'Cafe <Highlands> & bạn', '35000', '']);
      final h = findHeaderRow(rows);
      final g = guessColumns(rows[h]);
      final data = repo.snapshot();
      final r = buildImportTxns(
        rows,
        ImportMapping(date: g.date!, debit: g.debit, credit: g.credit, note: g.note, headerRow: h),
        bank,
        data.categories,
        repo.newId,
        suggester: LedgerCategorySuggester(data),
      );
      expect(r.txns.map((t) => (t.date, t.kind, t.amount)), [
        (CivilDate(2026, 11, 15), TxnKind.expense, 35000),
        (CivilDate(2026, 11, 16), TxnKind.income, 12000),
      ]);
      expect(data.category(r.txns.first.categoryId)?.name, 'Cà phê, đồ uống');
    });

    test('XLSX hỏng ⇒ FormatException', () {
      expect(() => parseXlsx(_bytes('khong phai zip')), throwsFormatException);
    });
  });

  group('thông báo ngân hàng', () {
    RawNotification n(String text, {String pkg = 'com.VCB'}) =>
        RawNotification(packageName: pkg, title: 'VCB', text: text, postedAt: DateTime(2026, 11, 18, 9));

    test('chỉ app đã gán ví; trùng bị bỏ; OTP bỏ; khác tiền tệ bỏ; mặc định chờ xác nhận', () {
      final data = repo.snapshot();
      final r = txnsFromNotifications(
        [
          n('TK 0011 GD: -45,000VND 18/11/26 ND: Thanh toan GRAB'),
          n('TK 0011 GD: -45,000VND 18/11/26 ND: Thanh toan GRAB'),
          n('Ma OTP la 123456'),
          n('TK 0011 GD: -45,000VND ND: x', pkg: 'com.other'),
          n('Card 1234 -12.50 USD at SHOP'),
        ],
        data,
        (pkg) => pkg == 'com.VCB' ? bank.id : null,
        repo.newId,
      );
      expect(r.txns, hasLength(1));
      expect(r.duplicates, 1);
      expect(r.ignored, 3);
      final t = r.txns.single;
      expect(
        (t.kind, t.amount, t.pending, t.source, t.note),
        (TxnKind.expense, 45000, true, TxnSource.notification, 'Thanh toan GRAB'),
      );
      expect(data.category(t.categoryId)?.name, 'Taxi, xe công nghệ');
      expect(t.date, CivilDate(2026, 11, 18));

      repo.importTxns(r.txns);
      final again = txnsFromNotifications(
        [n('TK 0011 GD: -45,000VND 18/11/26 ND: Thanh toan GRAB')],
        repo.load(),
        (_) => bank.id,
        repo.newId,
      );
      expect(again.txns, isEmpty, reason: 'ngân hàng đăng lại cùng thông báo');
    });

    test('tự xác nhận ⇒ tính vào số dư ngay', () {
      final r = txnsFromNotifications(
        [n('GD: +2,000,000VND ND: LUONG')],
        repo.snapshot(),
        (_) => bank.id,
        repo.newId,
        autoConfirm: true,
      );
      repo.importTxns(r.txns);
      final after = repo.load();
      expect(after.balance(after.wallet(bank.id)!).minor, 2000000);
    });
  });

  group('email niêm phong', () {
    test('mở bằng khóa danh tính, nhập vào hàng chờ, trả id để xóa kể cả thư hỏng', () {
      final bundle = AccountKeyBundle.fromJson(
        (jsonDecode(utf8.decode(store.getMeta('account.bundle') ?? store.getMeta('bundle')!)) as Map)
            .cast<String, Object?>(),
      );
      Uint8List seal(Map<String, Object?> m) => sodium.crypto.box.seal(
        message: Uint8List.fromList(utf8.encode(jsonEncode(m))),
        publicKey: bundle.boxPublicKey,
      );
      final items = [
        {
          'id': 'a',
          'sealed': base64.encode(
            seal({'v': 1, 'from': 'alert@bank.example', 'subject': 'Bien dong', 'text': 'GD: -50,000VND ND: cafe'}),
          ),
          'received_at': DateTime(2026, 11, 18).millisecondsSinceEpoch,
        },
        {'id': 'b', 'sealed': base64.encode(Uint8List(80)), 'received_at': 0},
        {
          'id': 'c',
          'sealed': base64.encode(seal({'v': 1, 'from': 'x', 'subject': 'Khuyen mai', 'text': 'Giam 50%'})),
          'received_at': 0,
        },
      ];
      final (res, done) = txnsFromInbox(items, vault.openSealedEmail, repo.snapshot(), bank.id, repo.newId);
      expect(done, ['a', 'b', 'c']);
      expect(res.ignored, 2);
      final t = res.txns.single;
      expect((t.amount, t.kind, t.source, t.pending, t.note), (50000, TxnKind.expense, TxnSource.email, true, 'cafe'));
    });
  });

  group('ghi nhanh', () {
    test('câu ⇒ giao dịch có gợi ý danh mục học từ lịch sử', () {
      final data0 = repo.snapshot();
      final eat = data0.categories.firstWhere((c) => c.name == 'Ăn ngoài');
      repo.saveTxn(
        Txn(
          id: repo.newId(),
          walletId: bank.id,
          kind: TxnKind.expense,
          amount: 40000,
          date: CivilDate(2026, 11, 1),
          note: 'bún chả Hàng Mành',
          categoryId: eat.id,
        ),
      );
      final data = repo.load();
      final e = parseQuickEntry('bún chả 45k', CivilDate(2026, 11, 18))!;
      final t = txnFromQuickEntry(e, bank, LedgerCategorySuggester(data), 'id', source: TxnSource.voice);
      expect((t.amount, t.categoryId, t.source, t.pending), (45000, eat.id, TxnSource.voice, false));
    });
  });
}
