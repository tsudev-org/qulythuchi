import 'package:sqlite3/common.dart';

/// Mở CSDL của app. [hexKey] (64 hex) chỉ dùng trên máy: mã hóa cả tệp bằng SQLite3MultipleCiphers.
Future<CommonDatabase> openAppDatabase({required String name, String? hexKey}) =>
    throw UnsupportedError('Nền tảng không hỗ trợ');

/// Nền tảng có CSDL mã hóa cả tệp hay không (web: không - chỉ lưu bản ghi đã niêm phong, ADR-0008).
const bool databaseEncryptedAtRest = false;
