import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulythuchi/app.dart';
import 'package:qulythuchi/data/key_storage.dart';
import 'package:qulythuchi/data/record_store.dart';
import 'package:qulythuchi/security/vault.dart';
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
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [servicesProvider.overrideWithValue(services), sharedPreferencesProvider.overrideWithValue(sp)],
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
