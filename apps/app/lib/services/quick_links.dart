import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Đường dẫn ghi nhanh từ widget màn hình chính / lối tắt: `com.tsudev.qulythuchi:/quick?mode=type|voice|scan`.
/// Chỉ mang chế độ mở, không mang dữ liệu.
const quickLinkPath = '/quick';

typedef QuickLinksListener = StreamSubscription<void>? Function(void Function(String mode) onQuick);

/// Nghe liên kết ghi nhanh (Android/iOS), gồm cả liên kết đã mở app lúc khởi động. Nền tảng khác ⇒ null.
StreamSubscription<void>? listenQuickLinks(void Function(String mode) onQuick) {
  if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) {
    return null;
  }
  void handle(Uri? uri) {
    if (uri == null || uri.scheme != 'com.tsudev.qulythuchi' || uri.path != quickLinkPath) return;
    onQuick(uri.queryParameters['mode'] ?? 'type');
  }

  final links = AppLinks();
  unawaited(links.getInitialLink().then(handle, onError: (_) {}));
  return links.uriLinkStream.listen(handle, onError: (_) {});
}
