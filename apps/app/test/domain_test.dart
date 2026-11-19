import 'package:flutter_test/flutter_test.dart';
import 'package:qulythuchi/domain/amount_expression.dart';
import 'package:qulythuchi/domain/default_categories.dart';
import 'package:qulythuchi/domain/vn_search.dart';
import 'package:qulythuchi/security/vault.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

void main() {
  group('máy tính số tiền', () {
    int vnd(String s) => evaluateAmount(s, Currency.vnd).minor;
    int usd(String s) => evaluateAmount(s, Currency.usd, locale: AppLocale.en).minor;

    test('cộng trừ nhân chia', () {
      expect(vnd('50.000'), 50000);
      expect(vnd('50.000 + 25.000'), 75000);
      expect(vnd('120.000x3'), 360000);
      expect(vnd('120.000*3-10.000'), 350000);
      expect(vnd('-5.000+2.000'), -3000);
      expect(vnd('100.000÷3'), 33333);
      expect(usd('10.50/4'), 262); // 2.625 → làm tròn chẵn 2.62
      expect(usd('10.70/4'), 268); // 2.675 → 2.68
    });

    test('từ chối biểu thức sai, chia 0, tràn', () {
      for (final bad in ['', '+', '5.000+', '5.000xx2', '5.000/0', '5.000x1,5', 'abc']) {
        expect(() => vnd(bad), throwsA(anything), reason: bad);
      }
      expect(() => vnd('9.007.199.254.740.991+1'), throwsA(isA<MoneyOverflowException>()));
      expect(() => usd('1.234'), throwsFormatException);
    });

    test('nhận ra phép tính', () {
      expect(hasOperator('50.000'), isFalse);
      expect(hasOperator('-50.000'), isFalse);
      expect(hasOperator('5+5'), isTrue);
    });
  });

  test('tìm kiếm không dấu', () {
    expect(normalizeVi('  Phở   BÒ Đà Nẵng '), 'pho bo da nang');
    expect(matchesVi('Cà phê sữa đá', 'ca phe'), isTrue);
    expect(matchesVi('Cà phê sữa đá', 'sua da ca'), isTrue);
    expect(matchesVi('Cà phê', 'tra'), isFalse);
    // Dạng tổ hợp (NFD) cũng chuẩn hóa được.
    expect(normalizeVi('Phở'), 'pho');
  });

  test('bộ danh mục mặc định: 36 mục, tên vi/en đầy đủ, thu/chi đúng', () {
    var count = 0;
    for (final g in defaultCategories) {
      count += 1 + g.children.length;
      for (final c in [g, ...g.children]) {
        expect(c.vi, isNotEmpty);
        expect(c.en, isNotEmpty);
        expect(c.kind, g.kind);
      }
    }
    expect(count, 36);
  });

  test('chính sách PIN', () {
    expect(PinPolicy.isValidPin('123456'), isTrue);
    expect(PinPolicy.isValidPin('12345'), isFalse);
    expect(PinPolicy.isValidPin('12345a'), isFalse);
    expect(PinPolicy.isValidPin('1' * 13), isFalse);
    expect(PinPolicy.delayAfter(4), Duration.zero);
    expect(PinPolicy.delayAfter(5), const Duration(seconds: 30));
    expect(PinPolicy.delayAfter(6), const Duration(seconds: 60));
    expect(PinPolicy.delayAfter(30), const Duration(hours: 1));
  });
}
