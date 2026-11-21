import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sodium/sodium_sumo.dart';

import 'app.dart';
import 'data/db_open.dart';
import 'data/key_storage.dart';
import 'data/record_store.dart';
import 'security/vault.dart';
import 'state/providers.dart';
import 'state/settings.dart';
import 'theme/font_licenses.dart';
import 'ui/startup_error.dart';

const _dbName = 'qulythuchi';
const _kDbKey = 'qt.dbKey';

/// Khóa CSDL đã có trước lần chạy này ⇒ máy đã cài (dùng cho di trú mặc định giao diện/ngôn ngữ).
bool _dbExisted = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();
  final prefs = await SharedPreferences.getInstance();
  final hadPrefs = prefs.getKeys().isNotEmpty;
  try {
    final services = await bootstrap();
    await migrateFirstRunDefaults(
      prefs,
      installedBefore: hadPrefs || _dbExisted,
      device: PlatformDispatcher.instance.locale,
    );
    runApp(
      ProviderScope(
        overrides: [servicesProvider.overrideWithValue(services), sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const QulyApp(),
      ),
    );
  } on Object catch (e) {
    // Chỉ in loại lỗi - không in thông điệp (có thể chứa đường dẫn/khóa).
    debugPrint('Khởi động thất bại: ${e.runtimeType}');
    runApp(StartupErrorApp(prefs: prefs));
  }
}

/// Dựng sodium, kho khóa thiết bị, CSDL (mã hóa cả tệp trên máy) và kho khóa ứng dụng.
Future<AppServices> bootstrap() async {
  final sodium = await SodiumSumoInit.init();
  final KeyStorage keyStorage = kIsWeb ? MemoryKeyStorage(supported: false) : SecureKeyStorage();
  String? hexKey;
  if (databaseEncryptedAtRest) {
    hexKey = await keyStorage.read(_kDbKey);
    _dbExisted = hexKey != null;
    if (hexKey == null) {
      final bytes = sodium.randombytes.buf(32);
      hexKey = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      bytes.fillRange(0, bytes.length, 0);
      await keyStorage.write(_kDbKey, hexKey);
      // Kiểm tra đọc lại được trước khi tạo CSDL, tránh tạo CSDL với khóa không lưu bền.
      if (await keyStorage.read(_kDbKey) != hexKey) throw StateError('Kho bí mật không lưu được');
    }
  }
  final db = await openAppDatabase(name: _dbName, hexKey: hexKey);
  final store = RecordStore(db);
  return AppServices(
    sodium: sodium,
    store: store,
    keyStorage: keyStorage,
    vault: Vault(sodium: sodium, store: store, keyStorage: keyStorage),
  );
}
