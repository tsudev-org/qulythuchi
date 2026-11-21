import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Giấy phép SIL OFL 1.1 của font đóng gói kèm app (Inter thân bài, Be Vietnam Pro tiêu đề) - OFL bắt buộc kèm giấy
/// phép khi phân phối; hiện ở trang "Giấy phép" của Flutter.
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(['Inter'], await rootBundle.loadString('assets/fonts/Inter-LICENSE.txt'));
    yield LicenseEntryWithLineBreaks([
      'Be Vietnam Pro',
    ], await rootBundle.loadString('assets/fonts/OFL-BeVietnamPro.txt'));
  });
}
