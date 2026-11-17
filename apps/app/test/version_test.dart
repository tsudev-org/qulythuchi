import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qulythuchi/ui/settings/settings_page.dart';

/// Phiếu 20261117-V1: phiên bản `YY.M.DDNN`, Android versionCode `YYMDDNN`, hiển thị trong app trùng pubspec.
void main() {
  test('phiên bản theo khuôn thống nhất và khớp pubspec', () {
    final m = RegExp(
      r'^version: (\d{2})\.(\d{1,2})\.(\d{4})\+(\d+)$',
      multiLine: true,
    ).firstMatch(File('pubspec.yaml').readAsStringSync());
    expect(m, isNotNull, reason: 'pubspec version phải là YY.M.DDNN+YYMDDNN');
    final (yy, month, ddnn, code) = (m!.group(1)!, m.group(2)!, m.group(3)!, m.group(4)!);
    expect(month.startsWith('0'), isFalse, reason: 'tháng không có số 0 đầu');
    expect(int.parse(month), inInclusiveRange(1, 12));
    expect(code, '$yy$month$ddnn', reason: 'versionCode = YYMDDNN');
    expect(appVersion, '$yy.$month.$ddnn');
  });
}
