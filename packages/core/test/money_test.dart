import 'package:qulythuchi_core/qulythuchi_core.dart';
import 'package:test/test.dart';

void main() {
  group('Money', () {
    test('cộng trừ cùng tiền tệ, chặn khác tiền tệ', () {
      final a = Money(1000, Currency.vnd);
      expect(a + Money(500, Currency.vnd), Money(1500, Currency.vnd));
      expect(a - Money(1500, Currency.vnd), Money(-500, Currency.vnd));
      expect(() => a + Money(1, Currency.usd), throwsA(isA<CurrencyMismatchException>()));
    });

    test('chặn tràn vượt phạm vi an toàn của web', () {
      expect(() => Money(Money.maxSafe + 1, Currency.vnd), throwsA(isA<MoneyOverflowException>()));
      expect(() => Money(Money.maxSafe, Currency.vnd) + Money(1, Currency.vnd), throwsA(isA<MoneyOverflowException>()));
      expect(() => Money(Money.maxSafe, Currency.vnd).times(2), throwsA(isA<MoneyOverflowException>()));
    });

    test('allocate không mất đồng nào, chia dư tất định', () {
      final parts = Money(100, Currency.vnd).allocate([1, 1, 1]);
      expect(parts.map((m) => m.minor), [34, 33, 33]);
      final neg = Money(-100, Currency.vnd).allocate([1, 1, 1]);
      expect(neg.fold<int>(0, (a, m) => a + m.minor), -100);
      for (var amount = 0; amount < 2000; amount += 37) {
        final p = Money(amount, Currency.vnd).allocate([5500, 1000, 1000, 1000, 1000, 500]);
        expect(p.fold<int>(0, (a, m) => a + m.minor), amount);
      }
      expect(() => Money(1, Currency.vnd).allocate([]), throwsArgumentError);
      expect(() => Money(1, Currency.vnd).allocate([0, 0]), throwsArgumentError);
      expect(() => Money(1, Currency.vnd).allocate([-1, 2]), throwsArgumentError);
    });

    test('basisPointsOf và so sánh', () {
      expect(Money(800, Currency.vnd).basisPointsOf(Money(1000, Currency.vnd)), 8000);
      expect(Money(1, Currency.vnd).basisPointsOf(Money(0, Currency.vnd)), 0);
      expect(Money(1, Currency.vnd) < Money(2, Currency.vnd), isTrue);
      expect(Money(2, Currency.vnd) >= Money(2, Currency.vnd), isTrue);
      expect(-Money(5, Currency.vnd), Money(-5, Currency.vnd));
      expect(Money(-5, Currency.vnd).abs(), Money(5, Currency.vnd));
    });

    test('quy đổi: các trường hợp làm tròn', () {
      // 1 USD = 25450.5 VND: 25450.5 -> nửa, 25450 chẵn
      expect(Money(100, Currency.usd).convert(Currency.vnd, '25450.5').minor, 25450);
      // 3 USD -> 76351.5 -> 76352 (chẵn)
      expect(Money(300, Currency.usd).convert(Currency.vnd, '25450.5').minor, 76352);
      // VND -> USD: 100000 đ với 1 VND = 0.0000393 USD -> 3.93 USD
      expect(Money(100000, Currency.vnd).convert(Currency.usd, '0.0000393').minor, 393);
      expect(Money(-300, Currency.usd).convert(Currency.vnd, '25450.5').minor, -76352);
      expect(() => Money(1, Currency.usd).convert(Currency.vnd, '1e5'), throwsFormatException);
      expect(() => Money(1, Currency.usd).convert(Currency.vnd, '-1'), throwsFormatException);
    });
  });

  group('Currency', () {
    test('tra mã và tiền tệ lạ', () {
      expect(Currency.of('VND'), Currency.vnd);
      expect(Currency.of('XYZ', minorDigits: 3).minorDigits, 3);
      expect(() => Currency.of('vnd'), throwsArgumentError);
      expect(() => Currency.of('XYZ'), throwsArgumentError);
    });
  });

  group('định dạng', () {
    test('vi và en', () {
      expect(formatMoney(Money(1234567, Currency.vnd)), '1.234.567 ₫');
      expect(formatMoney(Money(-50000, Currency.vnd)), '-50.000 ₫');
      expect(formatMoney(Money(123456, Currency.usd), locale: AppLocale.en), r'$1,234.56');
      expect(formatMoney(Money(5, Currency.usd), locale: AppLocale.vi), '0,05 \$');
      expect(formatMoney(Money(0, Currency.vnd), withSymbol: false), '0');
      expect(formatMoney(Money(100, Currency.vnd), plusSign: true), '+100 ₫');
      expect(formatMoney(Money(999, Currency.vnd), withSymbol: false), '999');
      expect(formatMoney(Money(1000, Currency.vnd), withSymbol: false), '1.000');
    });

    test('đọc số theo ngôn ngữ, từ chối mơ hồ', () {
      expect(parseMoney('1.234.567', Currency.vnd).minor, 1234567);
      expect(parseMoney('1.234.567 ₫', Currency.vnd).minor, 1234567);
      expect(parseMoney('-50000', Currency.vnd).minor, -50000);
      expect(parseMoney('1.234,56', Currency.usd).minor, 123456);
      expect(parseMoney(r'$1,234.5', Currency.usd, locale: AppLocale.en).minor, 123450);
      expect(() => parseMoney('1,5', Currency.vnd), throwsFormatException);
      expect(() => parseMoney('12.34', Currency.vnd), throwsFormatException);
      expect(() => parseMoney('abc', Currency.vnd), throwsFormatException);
      expect(() => parseMoney('99999999999999999', Currency.vnd), throwsA(isA<MoneyOverflowException>()));
    });
  });
}
