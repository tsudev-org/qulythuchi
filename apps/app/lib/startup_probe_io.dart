import 'dart:io';

import 'package:flutter/widgets.dart';

/// Mã thoát báo "khung hình đầu tiên đã raster" cho `tool/do_khoi_dong.py`.
const startupProbeExitCode = 37;

/// Chỉ desktop, chỉ khi biến môi trường `QT_DO_KHOI_DONG=1` (script đo của CI): khi khung hình đầu tiên đã raster thì
/// thoát với mã [startupProbeExitCode]. Không dùng tệp/stdout vì app macOS chạy trong sandbox và app Windows là GUI.
void armStartupProbe() {
  if (!(Platform.isLinux || Platform.isWindows || Platform.isMacOS)) return;
  if (Platform.environment['QT_DO_KHOI_DONG'] != '1') return;
  WidgetsBinding.instance.waitUntilFirstFrameRasterized.then((_) => exit(startupProbeExitCode));
}
