import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

/// Tùy chọn hiển thị (không phải dữ liệu tài chính - lưu thường được).
@immutable
final class AppSettings {
  const AppSettings({
    this.theme = ThemeChoice.dark,
    this.localeCode,
    this.hideBalances = false,
    this.baseCurrency = 'VND',
    this.billReminders = false,
  });
  final ThemeChoice theme;

  /// null = theo hệ thống (mặc định tiếng Việt nếu hệ thống không phải vi/en).
  final String? localeCode;
  final bool hideBalances;

  /// Mã tiền tệ quy đổi tổng số dư (ISO 4217).
  final String baseCurrency;

  /// Nhắc hóa đơn bằng thông báo hệ thống (người dùng tự bật, cần quyền).
  final bool billReminders;

  Locale? get locale => localeCode == null ? null : Locale(localeCode!);

  AppSettings copyWith({
    ThemeChoice? theme,
    String? localeCode,
    bool clearLocale = false,
    bool? hideBalances,
    String? baseCurrency,
    bool? billReminders,
  }) => AppSettings(
    theme: theme ?? this.theme,
    localeCode: clearLocale ? null : (localeCode ?? this.localeCode),
    hideBalances: hideBalances ?? this.hideBalances,
    baseCurrency: baseCurrency ?? this.baseCurrency,
    billReminders: billReminders ?? this.billReminders,
  );
}

/// Ghi đè trong `main()`/test bằng `sharedPreferencesProvider.overrideWithValue(...)`.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

final class SettingsNotifier extends Notifier<AppSettings> {
  static const _kTheme = 'theme';
  static const _kLocale = 'locale';
  static const _kHide = 'hideBalances';
  static const _kBase = 'baseCurrency';
  static const _kReminders = 'billReminders';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final loc = prefs.getString(_kLocale);
    return AppSettings(
      theme: ThemeChoice.parse(prefs.getString(_kTheme)),
      localeCode: (loc == 'vi' || loc == 'en') ? loc : null,
      hideBalances: prefs.getBool(_kHide) ?? false,
      baseCurrency: RegExp(r'^[A-Z]{3}$').hasMatch(prefs.getString(_kBase) ?? '') ? prefs.getString(_kBase)! : 'VND',
      billReminders: prefs.getBool(_kReminders) ?? false,
    );
  }

  Future<void> setTheme(ThemeChoice t) async {
    state = state.copyWith(theme: t);
    await _prefs.setString(_kTheme, t.name);
  }

  Future<void> setLocale(String? code) async {
    state = code == null ? state.copyWith(clearLocale: true) : state.copyWith(localeCode: code);
    if (code == null) {
      await _prefs.remove(_kLocale);
    } else {
      await _prefs.setString(_kLocale, code);
    }
  }

  Future<void> setBaseCurrency(String code) async {
    state = state.copyWith(baseCurrency: code);
    await _prefs.setString(_kBase, code);
  }

  Future<void> setBillReminders(bool v) async {
    state = state.copyWith(billReminders: v);
    await _prefs.setBool(_kReminders, v);
  }

  Future<void> setHideBalances(bool v) async {
    state = state.copyWith(hideBalances: v);
    await _prefs.setBool(_kHide, v);
  }
}
