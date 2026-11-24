import 'dart:io';

import 'package:flutter/widgets.dart';

/// Chỉ desktop, chỉ khi biến môi trường `QT_DO_KHOI_DONG=<đường dẫn tệp>` được đặt (script đo của CI): khi khung hình
/// đầu tiên đã raster ⇒ ghi tệp mốc (không chứa dữ liệu) rồi thoát. Không đặt biến ⇒ không làm gì.
void armStartupProbe() {
  if (!(Platform.isLinux || Platform.isWindows || Platform.isMacOS)) return;
  final path = Platform.environment['QT_DO_KHOI_DONG'];
  if (path == null || path.isEmpty) return;
  WidgetsBinding.instance.waitUntilFirstFrameRasterized.then((_) {
    File(path).writeAsStringSync('first-frame');
    exit(0);
  });
}
