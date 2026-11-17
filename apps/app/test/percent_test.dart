import 'package:flutter_test/flutter_test.dart';
import 'package:qulythuchi/ui/widgets/common.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

void main() {
  test('percentText: số nguyên không thập phân, tiếng Việt dùng dấu phẩy, tiếng Anh dấu chấm', () {
    expect(percentText(8000), '80');
    expect(percentText(8000, locale: AppLocale.vi), '80');
    expect(percentText(9790), '97.9');
    expect(percentText(9790, locale: AppLocale.vi), '97,9');
    expect(percentText(1250, locale: AppLocale.vi), '12,5');
    expect(percentText(0), '0');
  });

  test('percentText: làm tròn nửa lên bằng số nguyên, giữ dấu âm', () {
    expect(percentText(9794), '97.9');
    expect(percentText(9795), '98');
    expect(percentText(9999), '100');
    expect(percentText(-1250, locale: AppLocale.vi), '-12,5');
    expect(percentText(-300), '-3');
  });

  test('dạng mặc định (dấu chấm) đọc lại được bởi ô nhập hũ', () {
    final m = RegExp(r'^(\d{1,3})(?:[.,](\d{1,2}))?$');
    for (final bp in [5500, 1250, 1000, 9790]) {
      expect(m.hasMatch(percentText(bp)), isTrue);
      expect(m.hasMatch(percentText(bp, locale: AppLocale.vi)), isTrue);
    }
  });
}
