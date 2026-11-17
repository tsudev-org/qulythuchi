import 'package:sqlite3/wasm.dart';

const bool databaseEncryptedAtRest = false;

/// Web: sqlite3.wasm tự phục vụ (không CDN) + IndexedDB. Không có SQLCipher, nên bảng chỉ chứa bản ghi đã
/// niêm phong bằng libsodium và khóa ví đã bọc (ADR-0001 mục 4).
Future<CommonDatabase> openAppDatabase({required String name, String? hexKey}) async {
  final sqlite = await WasmSqlite3.loadFromUrl(Uri.parse('sqlite3.wasm'));
  final fs = await IndexedDbFileSystem.open(dbName: name);
  sqlite.registerVirtualFileSystem(fs, makeDefault: true);
  return sqlite.open('/$name.db');
}
