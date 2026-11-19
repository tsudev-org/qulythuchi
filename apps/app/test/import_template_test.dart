import 'package:flutter_test/flutter_test.dart';
import 'package:qulythuchi/services/import_csv.dart';
import 'package:qulythuchi/services/import_template.dart';
import 'package:qulythuchi/services/xlsx_reader.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

void main() {
  var n = 0;
  String id() => '00000000-0000-4000-8000-${(n++).toString().padLeft(12, '0')}';

  test('tệp mẫu CSV tiếng Việt: nhận ra, tạo ví/danh mục, chuyển ví, thuế khấu trừ, điều chỉnh', () {
    final rows = parseCsv(templateCsv(vi: true));
    final cols = detectTemplate(rows.first);
    expect(cols, isNotNull);
    final cash = Wallet(id: id(), name: 'Tiền mặt', type: WalletType.cash, currency: Currency.vnd);
    final food = Category(id: id(), name: 'Ăn uống', kind: CategoryKind.expense);
    final plan = planTemplateImport(
      rows,
      cols!,
      wallets: [cash],
      categories: [food],
      existing: const [],
      newId: id,
      defaultCurrency: Currency.vnd,
    );
    expect(plan.skippedRows, isEmpty);
    expect(plan.rowCount, 6);
    expect(plan.newWallets.map((w) => '${w.name}/${w.currency.code}'), ['Ngân hàng/VND', 'Thẻ USD/USD']);
    // "Ăn ngoài" tạo mới dưới cha "Ăn uống" đã có; Lương, Freelance, Giải trí tạo mới.
    final eatOut = plan.newCategories.firstWhere((c) => c.name == 'Ăn ngoài');
    expect(eatOut.parentId, food.id);
    final freelance = plan.txns.firstWhere((t) => t.note == 'Đợt 1 dự án web');
    expect(freelance.amount, 4500000);
    expect(freelance.taxWithheld, 500000);
    expect(freelance.payee, 'Khách B');
    final usd = plan.txns.firstWhere((t) => t.note == 'Đăng ký phần mềm');
    expect(usd.amount, 1250);
    final transfer = plan.txns.where((t) => t.transferId != null).toList();
    expect(transfer.map((t) => t.kind).toSet(), {TxnKind.transferOut, TxnKind.transferIn});
    expect(transfer.first.transferId, transfer.last.transferId);
    final adj = plan.txns.firstWhere((t) => t.kind == TxnKind.adjustment);
    expect(adj.amount, -20000);
    expect(plan.txns.firstWhere((t) => t.note == 'Phở').tags, ['gia đình']);
  });

  test('tệp mẫu XLSX tiếng Anh đọc lại được; nhập lại không nhân đôi', () {
    final rows = parseXlsx(templateXlsx(vi: false));
    final cols = detectTemplate(rows.first)!;
    final first = planTemplateImport(
      rows,
      cols,
      wallets: const [],
      categories: const [],
      existing: const [],
      newId: id,
      defaultCurrency: Currency.usd,
    );
    expect(first.rowCount, 3);
    expect(first.newWallets.every((w) => w.currency == Currency.usd), isTrue);
    expect(first.txns.firstWhere((t) => t.kind == TxnKind.income).amount, 300000);
    final again = planTemplateImport(
      rows,
      cols,
      wallets: first.newWallets,
      categories: first.newCategories,
      existing: first.txns,
      newId: id,
      defaultCurrency: Currency.usd,
    );
    expect(again.rowCount, 0);
    expect(again.duplicates, 3);
    expect(again.newWallets, isEmpty);
  });

  test('sao kê thường không bị nhận nhầm là tệp mẫu; dòng sai bị đếm', () {
    expect(detectTemplate(['Ngày giao dịch', 'Số tiền', 'Nội dung']), isNull);
    final cols = detectTemplate(['Ngày', 'Loại', 'Số tiền', 'Ví'])!;
    final plan = planTemplateImport(
      [
        ['Ngày', 'Loại', 'Số tiền', 'Ví'],
        ['31/02/2026', 'Chi', '10.000', 'A'],
        ['01/03/2026', 'Mua', '10.000', 'A'],
        ['01/03/2026', 'Chi', 'abc', 'A'],
        ['01/03/2026', 'Chi', '10.000', ''],
        ['01/03/2026', 'chi', '10.000', 'A'],
      ],
      cols,
      wallets: const [],
      categories: const [],
      existing: const [],
      newId: id,
      defaultCurrency: Currency.vnd,
    );
    expect(plan.skippedRows, [2, 3, 4, 5]);
    expect(plan.rowCount, 1);
  });
}
