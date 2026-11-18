import 'package:qulythuchi_core/qulythuchi_core.dart';
import 'package:test/test.dart';

// Mọi thông báo/hóa đơn dưới đây là dữ liệu GIẢ dựng theo định dạng phổ biến, không phải dữ liệu thật.
void main() {
  group('số tiền nói/viết tiếng Việt', () {
    int? amt(String s) => findSpokenAmount(s)?.amount;

    test('chữ số + đơn vị', () {
      expect(amt('ăn trưa 50 nghìn'), 50000);
      expect(amt('ăn trưa 50k'), 50000);
      expect(amt('cafe 35 ngàn'), 35000);
      expect(amt('tiền nhà 3tr'), 3000000);
      expect(amt('mua điện thoại 1tr2'), 1200000);
      expect(amt('1tr25 tiền học'), 1250000);
      expect(amt('2k5 gửi xe'), 2500);
      expect(amt('lương 15 triệu'), 15000000);
      expect(amt('1,5 triệu'), 1500000);
      expect(amt('2 triệu 500'), 2500000);
      expect(amt('1 triệu 2'), 1200000);
      expect(amt('120.000đ'), 120000);
      expect(amt('120.000 đồng'), 120000);
      expect(amt('mua xe 1 tỷ 2'), 1200000000);
      expect(amt('2 củ'), 2000000);
    });

    test('chữ viết bằng lời', () {
      expect(amt('năm mươi nghìn'), 50000);
      expect(amt('một trăm hai mươi lăm nghìn'), 125000);
      expect(amt('hai trăm rưỡi'), 250000);
      expect(amt('một triệu rưỡi'), 1500000);
      expect(amt('mười lăm triệu'), 15000000);
      expect(amt('ba trăm nghìn'), 300000);
      expect(amt('một triệu hai'), 1200000);
      expect(amt('một triệu hai trăm'), 1200000);
      expect(amt('năm nghìn hai'), 5200);
      expect(amt('hai trăm lẻ năm nghìn'), 205000);
      expect(amt('một trăm hai nghìn'), 120000);
      expect(amt('hai tỷ ba trăm triệu'), 2300000000);
    });

    test('số trần nhỏ hiểu là nghìn; số chữ không đơn vị bị bỏ qua', () {
      expect(amt('ăn trưa 50'), 50000);
      expect(amt('ăn trưa 45000'), 45000);
      expect(amt('mua quà cho ba'), isNull);
      expect(amt('năm nay vui'), isNull);
      expect(amt('không có gì'), isNull);
    });

    test('ưu tiên khoảng có đơn vị hơn số trần', () {
      expect(amt('năm 2026 ăn tết hết 2 triệu'), 2000000);
      expect(amt('ăn trưa 2 người 100k'), 100000);
    });

    test('vị trí token để cắt ghi chú', () {
      final f = findSpokenAmount('ăn trưa 1 triệu rưỡi với bạn')!;
      expect((f.startToken, f.endToken), (2, 5));
    });

    test('tràn số bị từ chối', () {
      expect(amt('999999999 tỷ'), isNull);
    });
  });

  group('câu ghi nhanh (giọng nói/gõ)', () {
    final today = CivilDate(2026, 11, 18);

    test('chi tiêu mặc định, ghi chú bỏ số tiền và từ đệm', () {
      final e = parseQuickEntry('ăn trưa hết 50 nghìn', today)!;
      expect(e.kind, TxnKind.expense);
      expect(e.amount, 50000);
      expect(e.date, today);
      expect(e.note, 'ăn trưa');
    });

    test('thu nhập theo từ khóa', () {
      expect(parseQuickEntry('nhận lương 15 triệu', today)!.kind, TxnKind.income);
      expect(parseQuickEntry('thu 200k tiền bán đồ', today)!.kind, TxnKind.income);
      expect(parseQuickEntry('+500k', today)!.kind, TxnKind.income);
      expect(parseQuickEntry('ăn với bạn 100k', today)!.kind, TxnKind.expense);
      expect(parseQuickEntry('trả lãi vay 2 triệu', today)!.kind, TxnKind.expense);
    });

    test('ngày tương đối và ngày cụ thể', () {
      final y = parseQuickEntry('hôm qua đổ xăng 80k', today)!;
      expect(y.date, CivilDate(2026, 11, 17));
      expect(y.note, 'đổ xăng');
      expect(parseQuickEntry('hôm kia cafe 30k', today)!.date, CivilDate(2026, 11, 16));
      final d = parseQuickEntry('ngày 15/11 tiền điện 450 nghìn', today)!;
      expect(d.date, CivilDate(2026, 11, 15));
      expect(d.note, 'tiền điện');
      // Ngày trong tương lai không ghi năm ⇒ năm trước.
      expect(parseQuickEntry('20/12 quà 300k', today)!.date, CivilDate(2025, 12, 20));
    });

    test('không có số tiền ⇒ null', () {
      expect(parseQuickEntry('ăn trưa', today), isNull);
    });
  });

  group('thông báo ngân hàng', () {
    test('dạng "+số VND ... Số dư ... ND:"', () {
      final n = parseBankNotification(
        packageName: 'com.VCB',
        title: 'Thông báo biến động số dư',
        text:
            'Số dư TK VCB 0011001234567 +500,000 VND lúc 18-11-2026 10:20:15. Số dư 12,345,678 VND. '
            'Ref 123456.ND: NGUYEN VAN A chuyển tiền ăn trưa',
      )!;
      expect(n.incoming, isTrue);
      expect(n.amount, 500000);
      expect(n.balanceAfter, 12345678);
      expect(n.accountTail, '4567');
      expect(n.date, CivilDate(2026, 11, 18));
      expect(n.description, 'NGUYEN VAN A chuyển tiền ăn trưa');
      expect(n.currency, Currency.vnd);
    });

    test('dạng nhãn "So tien GD: -" nhiều dòng', () {
      final n = parseBankNotification(
        packageName: 'vn.com.techcombank.bb.app',
        title: 'Techcombank',
        text: 'TK 19031234567890\nSo tien GD: -150,000\nSo du: 2,000,000\nND: Thanh toan Grab',
      )!;
      expect(n.incoming, isFalse);
      expect(n.amount, 150000);
      expect(n.balanceAfter, 2000000);
      expect(n.accountTail, '7890');
      expect(n.description, 'Thanh toan Grab');
    });

    test('dạng một dòng có "|" và "SD:"', () {
      final n = parseBankNotification(
        packageName: 'com.mbmobile',
        title: 'MB',
        text: 'TK 0123xxx456|GD: +2,000,000VND 18/11/26 09:01 |SD: 5,000,000VND|ND: LUONG THANG 11',
      )!;
      expect(n.incoming, isTrue);
      expect(n.amount, 2000000);
      expect(n.balanceAfter, 5000000);
      expect(n.accountTail, '3456');
      expect(n.description, 'LUONG THANG 11');
    });

    test('ví điện tử: số không dấu + từ khóa chiều tiền', () {
      final n = parseBankNotification(
        packageName: 'com.mservice.momo',
        title: 'Nhận tiền thành công',
        text: 'Bạn vừa nhận 100.000đ từ NGUYEN VAN B',
      )!;
      expect(n.incoming, isTrue);
      expect(n.amount, 100000);
    });

    test('số dư không bị nhầm là số tiền giao dịch', () {
      final n = parseBankNotification(
        packageName: 'x',
        title: 'Biến động',
        text: 'SD: +9,000,000VND. GD: -45,000VND. ND: cafe',
      )!;
      expect(n.amount, 45000);
      expect(n.incoming, isFalse);
    });

    test('đuôi ".00" và ngoại tệ', () {
      expect(parseBankNotification(packageName: 'x', title: '', text: 'GD: -50,000.00 VND')!.amount, 50000);
      final usd = parseBankNotification(packageName: 'x', title: '', text: 'Card 1234 -12.50 USD at SHOP')!;
      expect(usd.currency.code, 'USD');
      expect(usd.amount, 1250);
    });

    test('OTP, khuyến mãi, không rõ chiều tiền ⇒ null', () {
      expect(parseBankNotification(packageName: 'x', title: 'OTP', text: 'Ma OTP cua quy khach la 123456'), isNull);
      expect(parseBankNotification(packageName: 'x', title: 'Ưu đãi', text: 'Giảm ngay 50% cho đơn đầu tiên'), isNull);
      expect(parseBankNotification(packageName: 'x', title: 'Tin', text: 'Lãi suất 5% từ 01/12'), isNull);
    });

    test('dấu vân tay ổn định, khác khi nội dung khác', () {
      BankNotice p(String t) => parseBankNotification(packageName: 'p', title: '', text: t)!;
      expect(p('GD: -1,000VND ND: a').fingerprint, p('GD: -1,000VND ND: a').fingerprint);
      expect(p('GD: -1,000VND ND: a').fingerprint, isNot(p('GD: -1,000VND ND: b').fingerprint));
    });
  });

  group('hóa đơn OCR', () {
    test('lấy dòng "Tổng thanh toán", bỏ tiền khách đưa/tiền thừa', () {
      const text = '''
CỬA HÀNG TIỆN LỢI ABC
123 Đường Số 1, Q.1
HÓA ĐƠN BÁN LẺ
Ngày: 18/11/2026 12:30
Bánh mì            2 x 15.000     30.000
Nước suối                         10.000
Tổng tiền hàng                    40.000
Giảm giá                           5.000
Tổng thanh toán                   35.000
Tiền khách đưa                   100.000
Tiền thừa                         65.000
''';
      final r = parseReceiptText(text);
      expect(r.total, 35000);
      expect(r.date, CivilDate(2026, 11, 18));
      expect(r.merchant, 'CỬA HÀNG TIỆN LỢI ABC');
    });

    test('số tổng ở dòng kế tiếp; không có nhãn ⇒ số lớn nhất', () {
      expect(parseReceiptText('Shop\nTOTAL\n125,000 VND').total, 125000);
      expect(parseReceiptText('Quán X\nCơm 45.000\nTrà 5.000').total, 45000);
    });

    test('bỏ mã số thuế/số điện thoại dài', () {
      expect(parseReceiptText('Quán Y\nMST 0312345678\nPhở 55.000').total, 55000);
    });
  });

  group('thông minh', () {
    test('dấu vân tay sao kê bỏ dấu và ký tự đặc biệt', () {
      final d = CivilDate(2026, 11, 18);
      expect(txnFingerprint(d, -50000, 'Thanh toán GRAB*123'), txnFingerprint(d, -50000, 'thanh toan grab 123'));
      expect(txnFingerprint(d, -50000, 'a'), isNot(txnFingerprint(d, 50000, 'a')));
    });

    test('gợi ý danh mục: trùng hệt > học theo từ > luật', () {
      final s = CategorySuggester(
        history: const [
          CategorySample('Phở Hà Nội', CategoryKind.expense, 'eat'),
          CategorySample('Phở bò', CategoryKind.expense, 'eat'),
          CategorySample('Grab đi làm', CategoryKind.expense, 'taxi'),
          CategorySample('Grab về nhà', CategoryKind.expense, 'taxi'),
          CategorySample('Highlands', CategoryKind.expense, 'coffee'),
        ],
        rules: const {
          'fuel': ['xăng', 'petrolimex'],
          'salary': ['lương'],
        },
      );
      expect(s.suggest('highlands', CategoryKind.expense), 'coffee');
      expect(s.suggest('phở gà', CategoryKind.expense), 'eat');
      expect(s.suggest('grab', CategoryKind.expense), 'taxi');
      expect(s.suggest('đổ XĂNG', CategoryKind.expense), 'fuel');
      expect(
        s.suggest('lương tháng 11', CategoryKind.income, ruleKinds: const {'salary': CategoryKind.income}),
        'salary',
      );
      expect(s.suggest('lương', CategoryKind.expense, ruleKinds: const {'salary': CategoryKind.income}), isNull);
      expect(s.suggest('xăngdầu', CategoryKind.expense), isNull, reason: 'luật khớp trọn từ');
      expect(s.suggest('', CategoryKind.expense), isNull);
    });

    Txn tx(String id, int amount, CivilDate d, {String? note, TxnSource src = TxnSource.manual, String? cat}) => Txn(
      id: id,
      walletId: 'w',
      kind: TxnKind.expense,
      amount: amount,
      date: d,
      note: note,
      source: src,
      categoryId: cat,
    );

    test('phát hiện trùng', () {
      final d = CivilDate(2026, 11, 18);
      final c = tx('n', 45000, d, note: 'Thanh toan Grab', src: TxnSource.notification);
      final dup = possibleDuplicates(c, [
        tx('a', 45000, d.addDays(-1), note: 'grab đi làm'),
        tx('b', 45000, d.addDays(-3)),
        tx('c', 46000, d),
        c,
      ]);
      expect(dup.map((t) => t.id), ['a']);
    });

    test('khoản chi bất thường', () {
      final d = CivilDate(2026, 11, 18);
      final hist = [for (var i = 1; i <= 6; i++) tx('h$i', 50000, d.addDays(-i * 5), cat: 'eat')];
      expect(isUnusualExpense(tx('x', 200000, d, cat: 'eat'), hist), isTrue);
      expect(isUnusualExpense(tx('x', 120000, d, cat: 'eat'), hist), isFalse);
      expect(isUnusualExpense(tx('x', 900000, d, cat: 'eat'), hist.take(4)), isFalse);
    });
  });
}
