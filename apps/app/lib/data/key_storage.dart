import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Kho bí mật của thiết bị (Android Keystore, Keychain, libsecret, DPAPI). Web KHÔNG có kho an toàn ⇒ [supported] false.
abstract interface class KeyStorage {
  bool get supported;
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

final class SecureKeyStorage implements KeyStorage {
  SecureKeyStorage()
    : _s = const FlutterSecureStorage(
        aOptions: AndroidOptions(),
        // Không đồng bộ iCloud, chỉ đọc được sau lần mở khóa đầu tiên của máy.
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
        // macOS: keychain đăng nhập thường (không cần entitlement Keychain Sharing / provisioning profile).
        mOptions: MacOsOptions(usesDataProtectionKeychain: false),
      );
  final FlutterSecureStorage _s;

  @override
  bool get supported => !kIsWeb;

  @override
  Future<String?> read(String key) => _s.read(key: key);

  @override
  Future<void> write(String key, String value) => _s.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _s.delete(key: key);
}

/// Dùng cho test và cho web (không lưu gì bền vững).
final class MemoryKeyStorage implements KeyStorage {
  MemoryKeyStorage({this.supported = true});
  final Map<String, String> values = {};

  @override
  final bool supported;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}
