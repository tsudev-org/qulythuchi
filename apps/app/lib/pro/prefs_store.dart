import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsudev_ui/tsudev_ui.dart';

/// Nối `tsudev_ui` vào kho cài đặt của app (AUTH_AND_ACCOUNT 14.3: mã cài đặt nằm cùng chỗ với cài đặt). Chỉ chứa dữ
/// liệu không bí mật: mã cài đặt, JWS quyền lợi (đã ký, không chứa D3), JWKS công khai, mốc nhắc.
final class PrefsKeyValueStore implements TsuKeyValueStore {
  PrefsKeyValueStore(this._prefs);
  final SharedPreferences _prefs;

  @override
  Future<String?> read(String key) async => _prefs.getString(key);
  @override
  Future<void> write(String key, String value) => _prefs.setString(key, value);
  @override
  Future<void> delete(String key) => _prefs.remove(key);
}
