import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

/// Tùy chọn hiển thị (không phải dữ liệu tài chính - lưu thường được).
@immutable
final class AppSettings {
  const AppSettings({
    this.theme = ThemeChoice.system,
    this.localeCode,
    this.hideBalances = false,
    this.baseCurrency = 'VND',
    this.billReminders = false,
    this.carryOverBalance = true,
    this.taxReminders = false,
  });
  final ThemeChoice theme;

  /// null = theo hệ thống (ngôn ngữ chưa hỗ trợ ⇒ tiếng Anh, [resolveAppLocale]).
  final String? localeCode;
  final bool hideBalances;

  /// Mã tiền tệ quy đổi tổng số dư (ISO 4217).
  final String baseCurrency;

  /// Nhắc hóa đơn bằng thông báo hệ thống (người dùng tự bật, cần quyền).
  final bool billReminders;

  /// Tổng quan theo tháng: mang số dư cuối tháng trước sang làm số dư đầu tháng (tắt = chỉ xem thu/chi trong tháng).
  final bool carryOverBalance;

  /// Nhắc hạn quyết toán thuế TNCN và đợt thu quá hạn bằng thông báo hệ thống.
  final bool taxReminders;

  Locale? get locale => localeCode == null ? null : Locale(localeCode!);

  AppSettings copyWith({
    ThemeChoice? theme,
    String? localeCode,
    bool clearLocale = false,
    bool? hideBalances,
    String? baseCurrency,
    bool? billReminders,
    bool? carryOverBalance,
    bool? taxReminders,
  }) => AppSettings(
    theme: theme ?? this.theme,
    localeCode: clearLocale ? null : (localeCode ?? this.localeCode),
    hideBalances: hideBalances ?? this.hideBalances,
    baseCurrency: baseCurrency ?? this.baseCurrency,
    billReminders: billReminders ?? this.billReminders,
    carryOverBalance: carryOverBalance ?? this.carryOverBalance,
    taxReminders: taxReminders ?? this.taxReminders,
  );
}

/// Ngôn ngữ hiển thị khi chưa chọn: ngôn ngữ ưu tiên đầu của hệ thống nếu là vi/en, còn lại tiếng Anh
/// (PRODUCT_POLICY mục 1.1).
Locale resolveAppLocale(Locale? device) =>
    (device != null && (device.languageCode == 'vi' || device.languageCode == 'en'))
    ? Locale(device.languageCode)
    : const Locale('en');

const kDefaultsV2 = 'defaults.v2';

/// Di trú một lần cho máy đã cài trước khi đổi mặc định sang "theo hệ thống" (PRODUCT_POLICY mục 1.2):
/// máy cũ chưa từng lưu lựa chọn thì đang dùng ngầm Tối + (ngôn ngữ chưa hỗ trợ ⇒ vi) ⇒ ghi lại đúng như cũ
/// để giao diện không đổi đột ngột. Máy mới (chưa có CSDL/tùy chọn) dùng thẳng mặc định mới.
Future<void> migrateFirstRunDefaults(
  SharedPreferences prefs, {
  required bool installedBefore,
  required Locale device,
}) async {
  if (prefs.getBool(kDefaultsV2) ?? false) return;
  if (installedBefore) {
    if (!prefs.containsKey('theme')) await prefs.setString('theme', ThemeChoice.dark.name);
    if (!prefs.containsKey('locale') && device.languageCode != 'vi' && device.languageCode != 'en') {
      await prefs.setString('locale', 'vi');
    }
  }
  await prefs.setBool(kDefaultsV2, true);
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
  static const _kCarry = 'carryOverBalance';
  static const _kTaxReminders = 'taxReminders';

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
      carryOverBalance: prefs.getBool(_kCarry) ?? true,
      taxReminders: prefs.getBool(_kTaxReminders) ?? false,
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

  Future<void> setCarryOverBalance(bool v) async {
    state = state.copyWith(carryOverBalance: v);
    await _prefs.setBool(_kCarry, v);
  }

  Future<void> setTaxReminders(bool v) async {
    state = state.copyWith(taxReminders: v);
    await _prefs.setBool(_kTaxReminders, v);
  }

  Future<void> setHideBalances(bool v) async {
    state = state.copyWith(hideBalances: v);
    await _prefs.setBool(_kHide, v);
  }
}
