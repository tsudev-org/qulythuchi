// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:qulythuchi/app.dart';
import 'package:qulythuchi/data/key_storage.dart';
import 'package:qulythuchi/data/record_store.dart';
import 'package:qulythuchi/security/vault.dart';
import 'package:qulythuchi/services/notification_bridge.dart';
import 'package:qulythuchi/services/reminders.dart';
import 'package:qulythuchi/state/auto_import_controller.dart';
import 'package:qulythuchi/state/capture_providers.dart';
import 'package:qulythuchi/state/providers.dart';
import 'package:qulythuchi/state/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sodium/sodium_sumo.dart';
import 'package:sqlite3/sqlite3.dart';

const testPassword = 'mat-khau-thu-nghiem';
const testVaultConfig = VaultConfig(kdfOps: 1, kdfMem: 8192, pinOps: 1, pinMem: 8192);

SodiumSumo? _sodium;
Future<SodiumSumo> testSodium() async => _sodium ??= await SodiumSumoInit.init();

AppServices makeServices(SodiumSumo sodium, {bool keyStorageSupported = true}) {
  final store = RecordStore(sqlite3.openInMemory());
  final keys = MemoryKeyStorage(supported: keyStorageSupported);
  return AppServices(
    sodium: sodium,
    store: store,
    keyStorage: keys,
    vault: Vault(sodium: sodium, store: store, keyStorage: keys, config: testVaultConfig, allowWeakKdf: true),
  );
}

Future<void> setSurface(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> pumpApp(
  WidgetTester tester,
  AppServices services, {
  Map<String, Object> prefs = const {'locale': 'vi'},
  List<Override> extra = const [],
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        servicesProvider.overrideWithValue(services),
        sharedPreferencesProvider.overrideWithValue(sp),
        reminderSchedulerProvider.overrideWithValue(NoopReminderScheduler()),
        // flutter test giả lập Android nhưng không có plugin/kênh gốc: dùng bản không-làm-gì.
        notificationBridgeProvider.overrideWithValue(const NoopNotificationBridge()),
        quickLinksListenerProvider.overrideWithValue((_) => null),
        ...extra,
      ],
      child: const QulyApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Chờ các Future.delayed (yieldFrame) và khung hình.
Future<void> settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pumpAndSettle();
}

Finder textField(String label) => find.widgetWithText(TextFormField, label);

/// Cuộn danh sách đang hiển thị tới khi [finder] dựng xong (ListView dựng lười trên màn nhỏ). Thử lên rồi xuống.
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    final scrollable = find.byType(Scrollable).hitTestable().first;
    for (final delta in [-300.0, 300.0]) {
      try {
        await tester.scrollUntilVisible(finder, delta, scrollable: scrollable, maxScrolls: 30);
        break;
      } on StateError {
        // Không thấy theo chiều này - thử chiều kia.
      }
    }
  }
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
}

/// Cuộn tới rồi bấm.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await scrollTo(tester, finder);
  await tester.tap(finder.first);
  await settle(tester);
}
