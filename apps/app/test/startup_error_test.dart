import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulythuchi/ui/startup_error.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Màn lỗi khởi động (kho bí mật không mở được): Linux có hướng dẫn cài Secret Service, nền tảng khác chỉ câu lỗi chung.
void main() {
  Future<void> dung(WidgetTester tester, TargetPlatform nenTang) async {
    SharedPreferences.setMockInitialValues({'locale': 'vi'});
    final prefs = await SharedPreferences.getInstance();
    debugDefaultTargetPlatformOverride = nenTang;
    await tester.pumpWidget(StartupErrorApp(prefs: prefs));
    await tester.pumpAndSettle();
  }

  testWidgets('Linux: có hướng dẫn GNOME Keyring / KeePassXC', (tester) async {
    await dung(tester, TargetPlatform.linux);
    expect(find.text('Không mở được kho dữ liệu an toàn của thiết bị.'), findsOneWidget);
    expect(find.textContaining('gnome-keyring'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Windows: chỉ câu lỗi chung', (tester) async {
    await dung(tester, TargetPlatform.windows);
    expect(find.text('Không mở được kho dữ liệu an toàn của thiết bị.'), findsOneWidget);
    expect(find.textContaining('gnome-keyring'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });
}
