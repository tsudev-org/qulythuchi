import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

/// Tùy chọn hiển thị (không phải dữ liệu tài chính - lưu thường được).
@immutable
final class AppSettings {
  const AppSettings({this.theme = ThemeChoice.dark, this.localeCode, this.hideBalances = false});
  final ThemeChoice theme;

  /// null = theo hệ thống (mặc định tiếng Việt nếu hệ thống không phải vi/en).
  final String? localeCode;
  final bool hideBalances;

  Locale? get locale => localeCode == null ? null : Locale(localeCode!);

  AppSettings copyWith({ThemeChoice? theme, String? localeCode, bool clearLocale = false, bool? hideBalances}) =>
      AppSettings(
        theme: theme ?? this.theme,
        localeCode: clearLocale ? null : (localeCode ?? this.localeCode),
        hideBalances: hideBalances ?? this.hideBalances,
      );
}

/// Ghi đè trong `main()`/test bằng `sharedPreferencesProvider.overrideWithValue(...)`.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

final class SettingsNotifier extends Notifier<AppSettings> {
  static const _kTheme = 'theme';
  static const _kLocale = 'locale';
  static const _kHide = 'hideBalances';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final loc = prefs.getString(_kLocale);
    return AppSettings(
      theme: ThemeChoice.parse(prefs.getString(_kTheme)),
      localeCode: (loc == 'vi' || loc == 'en') ? loc : null,
      hideBalances: prefs.getBool(_kHide) ?? false,
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

  Future<void> setHideBalances(bool v) async {
    state = state.copyWith(hideBalances: v);
    await _prefs.setBool(_kHide, v);
  }
}
