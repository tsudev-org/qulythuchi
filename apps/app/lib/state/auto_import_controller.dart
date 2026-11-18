import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auto_import.dart';
import '../services/notification_bridge.dart';
import '../sync/api_client.dart';
import 'providers.dart';
import 'settings.dart';
import 'sync_controller.dart';

/// Cầu nối thông báo (ghi đè trong test).
final notificationBridgeProvider = Provider<NotificationBridge>(
  (ref) =>
      AndroidNotificationBridge.platformSupported ? const AndroidNotificationBridge() : const NoopNotificationBridge(),
);

/// Cài đặt tự nhập. Chỉ chứa tên gói app và id ví ngẫu nhiên (không phải dữ liệu tài chính) nên lưu
/// SharedPreferences được.
@immutable
final class AutoImportSettings {
  const AutoImportSettings({
    this.notifications = false,
    this.apps = const {},
    this.autoConfirm = false,
    this.email = false,
    this.emailWalletId,
  });

  /// Bật đọc thông báo ngân hàng (Android).
  final bool notifications;

  /// Gói app ngân hàng được nghe ⇒ id ví nhận giao dịch.
  final Map<String, String> apps;

  /// Ghi thẳng vào số dư, không qua hàng chờ (ADR-0006: tắt mặc định).
  final bool autoConfirm;

  /// Đã bật email chuyển tiếp (máy chủ có địa chỉ) ⇒ tải hộp thư khi mở khóa.
  final bool email;
  final String? emailWalletId;

  AutoImportSettings copyWith({
    bool? notifications,
    Map<String, String>? apps,
    bool? autoConfirm,
    bool? email,
    String? emailWalletId,
  }) => AutoImportSettings(
    notifications: notifications ?? this.notifications,
    apps: apps ?? this.apps,
    autoConfirm: autoConfirm ?? this.autoConfirm,
    email: email ?? this.email,
    emailWalletId: emailWalletId ?? this.emailWalletId,
  );
}

/// Kết quả lượt nhập thông báo gần nhất (hiển thị trên màn Tự nhập).
@immutable
final class AutoImportState {
  const AutoImportState({required this.settings, this.lastAdded = 0, this.lastIgnored = 0, this.lastRun});
  final AutoImportSettings settings;
  final int lastAdded;
  final int lastIgnored;
  final DateTime? lastRun;
}

final autoImportProvider = NotifierProvider<AutoImportController, AutoImportState>(AutoImportController.new);

final class AutoImportController extends Notifier<AutoImportState> {
  static const _kNotif = 'autoImport.notifications';
  static const _kApps = 'autoImport.apps';
  static const _kAutoConfirm = 'autoImport.autoConfirm';
  static const _kEmail = 'autoImport.email';
  static const _kEmailWallet = 'autoImport.emailWallet';
  Future<void>? _running;

  @override
  AutoImportState build() {
    final p = ref.watch(sharedPreferencesProvider);
    var apps = <String, String>{};
    try {
      final raw = p.getString(_kApps);
      if (raw != null) apps = (jsonDecode(raw) as Map).map((k, v) => MapEntry(k as String, v as String));
    } on Object {
      apps = {};
    }
    ref.listen(sessionProvider, (_, s) {
      if (s == SessionStatus.unlocked) unawaited(pull());
    });
    final s = AutoImportSettings(
      notifications: p.getBool(_kNotif) ?? false,
      apps: apps,
      autoConfirm: p.getBool(_kAutoConfirm) ?? false,
      email: p.getBool(_kEmail) ?? false,
      emailWalletId: p.getString(_kEmailWallet),
    );
    if (ref.read(sessionProvider) == SessionStatus.unlocked) Future.microtask(pull);
    return AutoImportState(settings: s);
  }

  Future<void> _save(AutoImportSettings s) async {
    state = AutoImportState(
      settings: s,
      lastAdded: state.lastAdded,
      lastIgnored: state.lastIgnored,
      lastRun: state.lastRun,
    );
    final p = ref.read(sharedPreferencesProvider);
    await p.setBool(_kNotif, s.notifications);
    await p.setString(_kApps, jsonEncode(s.apps));
    await p.setBool(_kAutoConfirm, s.autoConfirm);
    await p.setBool(_kEmail, s.email);
    if (s.emailWalletId != null) await p.setString(_kEmailWallet, s.emailWalletId!);
    final bridge = ref.read(notificationBridgeProvider);
    if (bridge.supported) await bridge.setWatched(s.notifications ? s.apps.keys.toSet() : const {});
  }

  Future<void> setNotifications(bool v) => _save(state.settings.copyWith(notifications: v));
  Future<void> setAutoConfirm(bool v) => _save(state.settings.copyWith(autoConfirm: v));

  Future<void> setApp(String packageName, String? walletId) {
    final apps = {...state.settings.apps};
    if (walletId == null) {
      apps.remove(packageName);
    } else {
      apps[packageName] = walletId;
    }
    return _save(state.settings.copyWith(apps: apps));
  }

  Future<void> setEmailWallet(String id) => _save(state.settings.copyWith(emailWalletId: id));

  /// Địa chỉ email chuyển tiếp hiện tại trên máy chủ (null = đang tắt). Cần đăng nhập đồng bộ.
  Future<String?> emailAddress() async {
    final r = await ref.read(syncProvider.notifier).api.getJson('/api/v1/inbox');
    final addr = (r is Map ? r['address'] : null) as String?;
    if ((addr != null) != state.settings.email) await _save(state.settings.copyWith(email: addr != null));
    return addr;
  }

  /// Bật hoặc đổi địa chỉ (địa chỉ cũ hết hiệu lực).
  Future<String> rotateEmailAddress() async {
    final r = await ref.read(syncProvider.notifier).api.postJson('/api/v1/inbox/address', const <String, Object?>{});
    final addr = (r is Map ? r['address'] : null);
    if (addr is! String) throw const ApiException(0, ApiException.badResponse);
    await _save(state.settings.copyWith(email: true));
    return addr;
  }

  /// Tắt: máy chủ xóa địa chỉ và thư đang chờ.
  Future<void> disableEmail() async {
    await ref.read(syncProvider.notifier).api.delete('/api/v1/inbox/address');
    await _save(state.settings.copyWith(email: false));
  }

  /// Lấy thông báo đang chờ ⇒ giao dịch chờ xác nhận. Chỉ chạy khi đã mở khóa; gọi chồng ⇒ dùng chung một lượt.
  Future<void> pull() => _running ??= _pull().whenComplete(() => _running = null);

  Future<void> _pull() async {
    if (ref.read(sessionProvider) != SessionStatus.unlocked) return;
    await _pullEmail();
    final bridge = ref.read(notificationBridgeProvider);
    if (!bridge.supported) return;
    final settings = state.settings;
    if (!settings.notifications) return;
    final raws = await bridge.drain();
    if (raws.isEmpty || ref.read(sessionProvider) != SessionStatus.unlocked) return;
    final ledger = ref.read(ledgerProvider.notifier);
    final r = txnsFromNotifications(
      raws,
      ref.read(ledgerProvider),
      (pkg) => settings.apps[pkg],
      ledger.newId,
      autoConfirm: settings.autoConfirm,
    );
    // Một lần ghi cho cả lô ⇒ một lượt đồng bộ.
    if (r.txns.isNotEmpty) ledger.importTxns(r.txns);
    state = AutoImportState(
      settings: state.settings,
      lastAdded: r.txns.length,
      lastIgnored: r.ignored + r.duplicates,
      lastRun: DateTime.now(),
    );
  }

  /// Hộp thư email niêm phong: mở trên máy bằng khóa danh tính, nhập vào hàng chờ, rồi xóa thư khỏi máy chủ.
  /// Lỗi mạng ⇒ bỏ qua lượt này (thư còn trên máy chủ tới 30 ngày).
  Future<void> _pullEmail() async {
    final settings = state.settings;
    final sync = ref.read(syncProvider);
    if (!settings.email || !sync.signedIn) return;
    final api = ref.read(syncProvider.notifier).api;
    final vault = ref.read(servicesProvider).vault;
    final data = ref.read(ledgerProvider);
    final walletId = data.wallet(settings.emailWalletId) != null
        ? settings.emailWalletId
        : data.wallets.where((w) => !w.archived && w.currency.code == 'VND').firstOrNull?.id;
    try {
      final r = await api.getJson('/api/v1/inbox');
      if (r is! Map) return;
      if (r['address'] == null) {
        await _save(settings.copyWith(email: false));
        return;
      }
      final items = [
        for (final it in (r['items'] as List? ?? const []))
          if (it is Map) it.cast<String, Object?>(),
      ];
      if (items.isEmpty || ref.read(sessionProvider) != SessionStatus.unlocked) return;
      final ledger = ref.read(ledgerProvider.notifier);
      final (res, done) = txnsFromInbox(
        items,
        vault.openSealedEmail,
        ref.read(ledgerProvider),
        walletId,
        ledger.newId,
        autoConfirm: settings.autoConfirm,
      );
      if (res.txns.isNotEmpty) ledger.importTxns(res.txns);
      for (final id in done) {
        await api.delete('/api/v1/inbox/$id');
      }
    } on ApiException {
      return;
    }
  }
}
