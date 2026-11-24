// tsudev-standards PRODUCT_POLICY mục 1.4: lần chạy đầu theo ngôn ngữ + giao diện của hệ thống.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulythuchi/state/settings.dart';
import 'package:qulythuchi/theme/app_theme.dart';
import 'package:qulythuchi/theme/tokens.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  test('ngôn ngữ hệ thống vi / en / ja ⇒ vi / en / en', () {
    expect(resolveAppLocale(const Locale('vi', 'VN')), const Locale('vi'));
    expect(resolveAppLocale(const Locale('en', 'US')), const Locale('en'));
    expect(resolveAppLocale(const Locale('ja', 'JP')), const Locale('en'));
    expect(resolveAppLocale(null), const Locale('en'));
  });

  test('chưa lưu lựa chọn ⇒ giao diện Hệ thống, lựa chọn đã lưu thắng', () {
    expect(ThemeChoice.parse(null), ThemeChoice.system);
    expect(ThemeChoice.parse('dark'), ThemeChoice.dark);
    expect(ThemeChoice.parse('warm'), ThemeChoice.light);
    expect(const AppSettings().theme, ThemeChoice.system);
    expect(const AppSettings().localeCode, isNull);
  });

  group('di trú máy đã cài (mục 1.2)', () {
    test('máy mới: không ghi gì ngoài dấu đã di trú', () async {
      SharedPreferences.setMockInitialValues({});
      final p = await SharedPreferences.getInstance();
      await migrateFirstRunDefaults(p, installedBefore: false, device: const Locale('ja'));
      expect(p.getString('theme'), isNull);
      expect(p.getString('locale'), isNull);
      expect(p.getBool(kDefaultsV2), isTrue);
    });

    test('máy cũ chưa từng chọn: giữ Tối + vi (máy ja), giữ theo hệ thống (máy en)', () async {
      SharedPreferences.setMockInitialValues({});
      final p = await SharedPreferences.getInstance();
      await migrateFirstRunDefaults(p, installedBefore: true, device: const Locale('ja'));
      expect(p.getString('theme'), 'dark');
      expect(p.getString('locale'), 'vi');

      SharedPreferences.setMockInitialValues({});
      final q = await SharedPreferences.getInstance();
      await migrateFirstRunDefaults(q, installedBefore: true, device: const Locale('en'));
      expect(q.getString('locale'), isNull);
    });

    test('lựa chọn đã lưu không bị ghi đè; chỉ chạy một lần', () async {
      SharedPreferences.setMockInitialValues({'theme': 'light', 'locale': 'en'});
      final p = await SharedPreferences.getInstance();
      await migrateFirstRunDefaults(p, installedBefore: true, device: const Locale('ja'));
      expect(p.getString('theme'), 'light');
      expect(p.getString('locale'), 'en');
      await p.remove('theme');
      await migrateFirstRunDefaults(p, installedBefore: true, device: const Locale('ja'));
      expect(p.getString('theme'), isNull);
    });
  });

  for (final brightness in Brightness.values) {
    testWidgets('máy mới + hệ thống ${brightness.name} ⇒ đúng bảng màu', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final services = makeServices(await testSodium());
      await pumpApp(tester, services, prefs: const {});
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byType(Scaffold).first);
      expect(Theme.of(ctx).brightness, brightness);
      final expected = brightness == Brightness.dark ? QtPalette.dark : QtPalette.light;
      expect(Theme.of(ctx).scaffoldBackgroundColor, expected.bgBase);
    });
  }
}
