import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';

import 'auto_import.dart';

/// Một app cài trên máy (để người dùng chọn app ngân hàng được nghe).
final class InstalledApp {
  const InstalledApp(this.packageName, this.label);
  final String packageName;
  final String label;
}

/// Cầu nối tới bộ nghe thông báo ngân hàng phía Android (ADR-0006, ADR-0012). Thông báo của app được chọn được
/// `BankNotificationListener` mã hóa bằng khóa Android Keystore và xếp hàng trong bộ nhớ riêng của app; Dart chỉ
/// lấy ra (và xóa) khi kho khóa đang mở. Không gì rời thiết bị.
abstract interface class NotificationBridge {
  bool get supported;
  Future<bool> isEnabled();
  Future<void> openSettings();
  Future<List<InstalledApp>> installedApps();
  Future<void> setWatched(Set<String> packages);

  /// Lấy và XÓA toàn bộ thông báo đang chờ.
  Future<List<RawNotification>> drain();
}

final class NoopNotificationBridge implements NotificationBridge {
  const NoopNotificationBridge();
  @override
  bool get supported => false;
  @override
  Future<bool> isEnabled() async => false;
  @override
  Future<void> openSettings() async {}
  @override
  Future<List<InstalledApp>> installedApps() async => const [];
  @override
  Future<void> setWatched(Set<String> packages) async {}
  @override
  Future<List<RawNotification>> drain() async => const [];
}

final class AndroidNotificationBridge implements NotificationBridge {
  const AndroidNotificationBridge();
  static const _ch = MethodChannel('com.tsudev.qulythuchi/notifications');

  static bool get platformSupported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  bool get supported => true;

  @override
  Future<bool> isEnabled() async => await _ch.invokeMethod<bool>('isEnabled') ?? false;

  @override
  Future<void> openSettings() => _ch.invokeMethod<void>('openSettings');

  @override
  Future<List<InstalledApp>> installedApps() async {
    final raw = await _ch.invokeListMethod<Map<Object?, Object?>>('installedApps') ?? const [];
    return [
      for (final m in raw)
        if (m['package'] is String) InstalledApp(m['package']! as String, (m['label'] as String?) ?? ''),
    ]..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
  }

  @override
  Future<void> setWatched(Set<String> packages) => _ch.invokeMethod<void>('setWatched', packages.toList());

  @override
  Future<List<RawNotification>> drain() async {
    final raw = await _ch.invokeListMethod<Map<Object?, Object?>>('drain') ?? const [];
    return [
      for (final m in raw)
        if (m['package'] is String)
          RawNotification(
            packageName: m['package']! as String,
            title: (m['title'] as String?) ?? '',
            text: (m['text'] as String?) ?? '',
            postedAt: DateTime.fromMillisecondsSinceEpoch((m['postedAt'] as int?) ?? 0),
          ),
    ];
  }
}
