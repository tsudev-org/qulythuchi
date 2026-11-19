import 'package:qulythuchi_core/qulythuchi_core.dart';
import 'package:test/test.dart';

CivilDate d(String s) => CivilDate.parse(s);
var _n = 0;
String newId() => '00000000-0000-4000-8000-${(_n++).toString().padLeft(12, '0')}';
const w1 = 'w1', w2 = 'w2', wUsd = 'w3';

Txn tx(
  TxnKind kind,
  int amount,
  String date, {
  String wallet = w1,
  String? cat,
  String? plan,
  int withheld = 0,
  int fee = 0,
  bool pending = false,
  String? payee,
}) => Txn(
  id: newId(),
  walletId: wallet,
  kind: kind,
  amount: amount,
  date: d(date),
  categoryId: cat,
  incomePlanId: plan,
  taxWithheld: withheld,
  fee: fee,
  pending: pending,
  payee: payee,
);

void main() {
  group('Tiền tệ ISO 4217', () {
    test('bảng đầy đủ, mã duy nhất, tra theo mã số', () {
      expect(Currency.all.length, greaterThan(150));
      expect(Currency.all.map((c) => c.code).toSet().length, Currency.all.length);
      expect(Currency.byNumeric(704), Currency.vnd);
      expect(Currency.byNumeric(840), Currency.usd);
      expect(Currency.of('KWD').minorDigits, 3);
      expect(Currency.of('IDR').numeric, 360);
      // Hằng hay dùng giữ nguyên danh tính trong bảng đầy đủ.
      expect(identical(Currency.all.firstWhere((c) => c.code == 'VND'), Currency.vnd), isTrue);
    });
    test('tìm theo tên vi/en, tiền tệ tự khai vẫn chạy', () {
      expect(Currency.search('rupiah').single.code, 'IDR');
      expect(Currency.search('Bảng Anh').single.code, 'GBP');
      expect(Currency.of('XBT', minorDigits: 4).numeric, 0);
      expect(Currency.of('ZAR').displayName('vi'), 'Rand Nam Phi');
    });
    test('bản ghi ví lưu tiền tệ ISO không kèm số chữ số', () {
      final w = Wallet(id: 'a', name: 'Ví', type: WalletType.cash, currency: Currency.of('INR'));
      expect(w.toValues().containsKey('currencyDigits'), isFalse);
    });
  });

  group('Tóm tắt kỳ (chuyển số dư)', () {
    final wallets = [
      Wallet(id: w1, name: 'Tiền mặt', type: WalletType.cash, currency: Currency.vnd, openingBalance: 1000000),
      Wallet(id: w2, name: 'Ngân hàng', type: WalletType.bank, currency: Currency.vnd),
      Wallet(id: wUsd, name: 'USD', type: WalletType.bank, currency: Currency.usd, openingBalance: 10000),
    ];
    final txns = [
      tx(TxnKind.income, 5000000, '2026-10-05'),
      tx(TxnKind.expense, 2000000, '2026-10-20'),
      tx(TxnKind.income, 9000000, '2026-11-01', withheld: 1000000),
      tx(TxnKind.expense, 500000, '2026-11-10'),
      tx(TxnKind.transferOut, 300000, '2026-11-11', fee: 3300),
      tx(TxnKind.transferIn, 300000, '2026-11-11', wallet: w2),
      tx(TxnKind.expense, 999, '2026-11-12', pending: true),
      tx(TxnKind.expense, 1000000, '2026-12-01'),
      tx(TxnKind.income, 2500, '2026-11-03', wallet: wUsd),
    ];
    test('đầu kỳ tháng 11 = cuối kỳ tháng 10', () {
      final oct = Ledger.periodSummary(wallets, txns, DateRange(d('2026-10-01'), d('2026-10-31')));
      final nov = Ledger.periodSummary(wallets, txns, DateRange(d('2026-11-01'), d('2026-11-30')));
      final octVnd = oct.firstWhere((s) => s.currency == Currency.vnd);
      final novVnd = nov.firstWhere((s) => s.currency == Currency.vnd);
      expect(octVnd.closing, novVnd.opening);
      expect(novVnd.opening.minor, 4000000);
      expect(novVnd.income.minor, 9000000);
      expect(novVnd.taxWithheld.minor, 1000000);
      expect(novVnd.transferNet.minor, 0, reason: 'chuyển giữa hai ví đang xem triệt tiêu');
      expect(novVnd.fees.minor, 3300);
      expect(novVnd.closing.minor, 4000000 + 9000000 - 500000 - 3300);
      expect(novVnd.savingRateBp, (8500000 * 10000) ~/ 9000000);
      final usd = nov.firstWhere((s) => s.currency == Currency.usd);
      expect(usd.closing.minor, 12500);
    });
    test('chỉ xem một ví: chuyển ra ngoài là chuyển ròng', () {
      final s = Ledger.periodSummary(wallets.take(1), txns, DateRange(d('2026-11-01'), d('2026-11-30'))).single;
      expect(s.transferNet.minor, -300000);
    });
  });

  group('Khoản thu nhiều đợt', () {
    final plan = IncomePlan(
      id: 'p1',
      name: 'Website quán cà phê',
      payer: 'Anh B',
      currency: Currency.vnd,
      total: 20000000,
      withholdingBp: 1000,
      installments: [
        PlannedInstallment(date: d('2026-10-01'), amount: 6000000, label: 'Đặt cọc 30%'),
        PlannedInstallment(date: d('2026-11-01'), amount: 8000000, label: 'Bản thử'),
        PlannedInstallment(date: d('2026-12-01'), amount: 6000000, label: 'Nghiệm thu'),
      ],
    );
    test('lưu/đọc lại bản ghi', () {
      final r = SyncRecord(
        id: '00000000-0000-4000-8000-0000000000aa',
        type: RecordTypes.incomePlan,
        walletId: null,
      ).setAll(plan.toValues(), HlcClock('node'));
      final back = IncomePlan.fromRecord(r);
      expect(back.installments.length, 3);
      expect(back.installments.first.label, 'Đặt cọc 30%');
      expect(back.total, 20000000);
    });
    test('tiến độ, đợt kế tiếp, quá hạn', () {
      final txns = [
        tx(TxnKind.income, 5400000, '2026-10-02', plan: 'p1', withheld: 600000),
        tx(TxnKind.income, 3000000, '2026-11-05', plan: 'p1'),
        tx(TxnKind.income, 1, '2026-11-06', plan: 'p1', pending: true),
        tx(TxnKind.expense, 100, '2026-11-06', plan: 'p1'),
      ];
      final p = Ledger.incomePlanProgress(plan, txns, d('2026-11-20'));
      expect(p.receipts.length, 2);
      expect(p.received.minor, 8400000);
      expect(p.withheld.minor, 600000);
      expect(p.gross.minor, 9000000);
      expect(p.remaining.minor, 11000000);
      expect(p.progressBp, 4500);
      expect(p.nextInstallment!.label, 'Bản thử');
      expect(p.overdue.minor, 5000000);
    });
    test('cộng thu theo người trả', () {
      final txns = [
        tx(TxnKind.income, 1000000, '2026-11-01', payee: 'A'),
        tx(TxnKind.income, 2000000, '2026-11-15', payee: 'A', withheld: 200000),
        tx(TxnKind.income, 1500000, '2026-11-20', payee: 'B'),
        tx(TxnKind.income, 9, '2026-10-20', payee: 'B'),
      ];
      final wallets = [Wallet(id: w1, name: 'x', type: WalletType.cash, currency: Currency.vnd)];
      final g = Ledger.incomeBy(wallets, txns, DateRange(d('2026-11-01'), d('2026-11-30')), (t) => t.payee);
      expect(g.first.key, 'A');
      expect(g.first.received.minor, 3000000);
      expect(g.first.withheld.minor, 200000);
      expect(g.first.count, 2);
      expect(g.first.lastDate, d('2026-11-15'));
      expect(g.last.received.minor, 1500000);
    });
  });

  group('Thuế TNCN Việt Nam', () {
    final r = VnPitRules.rules2026;
    test('chọn quy tắc theo năm', () {
      expect(VnPitRules.forYear(2025).personalDeduction, 11000000);
      expect(VnPitRules.forYear(2026).personalDeduction, 15500000);
      expect(VnPitRules.forYear(2030).brackets.length, 5);
    });
    test('biểu lũy tiến 5 bậc theo tháng', () {
      expect(r.progressiveMonthly(0), 0);
      expect(r.progressiveMonthly(10000000), 500000);
      expect(r.progressiveMonthly(30000000), 500000 + 2000000);
      expect(r.progressiveMonthly(50000000), 2500000 + 4000000);
      expect(r.progressiveMonthly(150000000), 500000 + 2000000 + 6000000 + 12000000 + 17500000);
      expect(r.progressiveYearly(120000000), 6000000);
    });
    test('biểu 7 bậc cũ', () {
      expect(VnPitRules.rules2020.progressiveMonthly(18000000), 250000 + 500000 + 1200000);
    });
    test('lương 30 triệu, 1 người phụ thuộc', () {
      final m = r.monthly(gross: 30000000, dependents: 1);
      expect(m.insurance, 3150000);
      expect(m.deduction, 21700000);
      expect(m.taxable, 5150000);
      expect(m.tax, 257500);
      expect(m.net, 30000000 - 3150000 - 257500);
      expect(r.monthly(gross: 15000000).tax, 0);
      expect(r.monthly(gross: 10000000, resident: false).tax, 2000000);
    });
    test('gross từ net', () {
      final g = r.grossForNet(26592500, dependents: 1);
      expect(r.monthly(gross: g, dependents: 1).net, greaterThanOrEqualTo(26592500));
      expect(r.monthly(gross: g - 1, dependents: 1).net, lessThan(26592500));
    });
    test('ước tính quyết toán từ sổ', () {
      final cats = [
        const Category(id: 'sal', name: 'Lương', kind: CategoryKind.income, taxType: IncomeTaxType.salary),
        const Category(id: 'fl', name: 'Freelance', kind: CategoryKind.income, taxType: IncomeTaxType.casual),
        const Category(id: 'fl2', name: 'Thiết kế', kind: CategoryKind.income, parentId: 'fl'),
        const Category(id: 'int', name: 'Lãi', kind: CategoryKind.income, taxType: IncomeTaxType.exempt),
      ];
      final wallets = [
        Wallet(id: w1, name: 'x', type: WalletType.bank, currency: Currency.vnd),
        Wallet(id: wUsd, name: 'y', type: WalletType.bank, currency: Currency.usd),
      ];
      final txns = [
        for (var m = 1; m <= 12; m++)
          tx(TxnKind.income, 30000000, '2026-${m.toString().padLeft(2, '0')}-05', cat: 'sal', withheld: 0),
        tx(TxnKind.income, 9000000, '2026-06-01', cat: 'fl2', withheld: 1000000),
        tx(TxnKind.income, 500000, '2026-06-01', cat: 'int'),
        tx(TxnKind.income, 777, '2026-06-01', cat: 'sal', wallet: wUsd),
        tx(TxnKind.income, 1, '2025-06-01', cat: 'sal'),
      ];
      final e = AnnualPitEstimate.fromLedger(
        year: 2026,
        txns: txns,
        categories: cats,
        wallets: wallets,
        profile: const TaxProfile(dependents: 1, monthlyInsurance: 3150000),
      );
      expect(e.salaryIncome, 360000000);
      expect(e.casualIncome, 10000000, reason: 'danh mục con theo loại thuế của cha, tính trước thuế');
      expect(e.exemptIncome, 500000);
      expect(e.withheld, 1000000);
      expect(e.insurance, 3150000 * 12);
      expect(e.deduction, 21700000 * 12);
      expect(e.taxable, 370000000 - 37800000 - 260400000);
      expect(e.tax, r.progressiveYearly(71800000));
      expect(e.balance, e.tax - 1000000);
    });
    test('lịch hạn: dời khỏi cuối tuần', () {
      // 30/4/2028 là Chủ nhật ⇒ thứ Hai 1/5/2028.
      expect(VnTaxCalendar.selfSettlementDeadline(2027), d('2028-05-01'));
      expect(VnTaxCalendar.selfSettlementDeadline(2026), d('2027-04-30'));
      expect(VnTaxCalendar.businessQuarterDeadline(2026, 4), d('2027-02-01'));
      final up = VnTaxCalendar.upcoming(d('2027-03-15'), days: 60);
      expect(up.map((x) => x.kind), [TaxDeadlineKind.selfSettlement]);
    });
  });

  group('QR thanh toán EMVCo', () {
    test('CRC-16/CCITT-FALSE chuẩn', () {
      expect(emvCrc16('123456789'), '29B1');
    });
    test('tạo rồi đọc lại VietQR', () {
      final s = VietQr.build(bin: '970436', account: '0011001234567', amount: 150000, message: 'Tiền điện tháng 11');
      final q = PaymentQr.parse(s);
      expect(q.scheme, PaymentQrScheme.vietQr);
      expect(q.isDynamic, isTrue);
      expect(q.bankBin, '970436');
      expect(q.bank!.shortName, 'Vietcombank');
      expect(q.accountNumber, '0011001234567');
      expect(q.amount, Money(150000, Currency.vnd));
      expect(q.message, 'Tien dien thang 11');
      expect(q.payeeLabel, 'Vietcombank 0011001234567');
      expect(VietQr.bankAppLink(q, 'vcb').toString(), contains('ba=0011001234567%40970436'));
    });
    test('mã tĩnh không có số tiền', () {
      final q = PaymentQr.parse(VietQr.build(bin: '970422', account: '123456789'));
      expect(q.isDynamic, isFalse);
      expect(q.amount, isNull);
      expect(q.currency, Currency.vnd);
    });
    test('từ chối CRC sai và chuỗi lạ', () {
      final s = VietQr.build(bin: '970436', account: '1', amount: 1);
      final bad = '${s.substring(0, s.length - 4)}0000';
      expect(() => PaymentQr.parse(bad), throwsA(isA<PaymentQrException>()));
      expect(() => PaymentQr.parse('https://example.com'), throwsA(isA<PaymentQrException>()));
      expect(() => PaymentQr.parse('000201010211'), throwsA(isA<PaymentQrException>()));
    });
    test('PromptPay THB có số tiền thập phân', () {
      String tlv(String t, String v) => '$t${v.length.toString().padLeft(2, '0')}$v';
      final body =
          '${tlv('00', '01')}${tlv('01', '12')}'
          '${tlv('29', tlv('00', 'A000000677010111') + tlv('01', '0066812345678'))}'
          '${tlv('53', '764')}${tlv('54', '120.50')}${tlv('58', 'TH')}${tlv('59', 'Somchai Shop')}6304';
      final q = PaymentQr.parse(body + emvCrc16(body));
      expect(q.scheme, PaymentQrScheme.promptPay);
      expect(q.currency!.code, 'THB');
      expect(q.amount!.minor, 12050);
      expect(q.merchantName, 'Somchai Shop');
      expect(q.payeeLabel, 'Somchai Shop');
    });
    test('số tiền có chữ số lẻ vượt tiền tệ bị bỏ (không làm tròn)', () {
      String tlv(String t, String v) => '$t${v.length.toString().padLeft(2, '0')}$v';
      final body = '${tlv('00', '01')}${tlv('01', '12')}${tlv('53', '704')}${tlv('54', '100.5')}6304';
      expect(PaymentQr.parse(body + emvCrc16(body)).amount, isNull);
    });
  });
}
