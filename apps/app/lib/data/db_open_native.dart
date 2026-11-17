import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart';

const bool databaseEncryptedAtRest = true;

final _hex = RegExp(r'^[0-9a-f]{64}$');

Future<CommonDatabase> openAppDatabase({required String name, String? hexKey}) async {
  if (hexKey == null || !_hex.hasMatch(hexKey)) throw ArgumentError('Thiếu khóa CSDL');
  final dir = await getApplicationSupportDirectory();
  await dir.create(recursive: true);
  final db = sqlite3.open('${dir.path}${Platform.pathSeparator}$name.db');
  try {
    keyDatabase(db, hexKey);
  } on Object {
    db.close();
    rethrow;
  }
  return db;
}

/// Đặt khóa SQLite3MultipleCiphers (mặc định ChaCha20-Poly1305) và kiểm tra khóa đúng bằng một lần đọc.
void keyDatabase(CommonDatabase db, String hexKey) {
  final cipher = db.select('PRAGMA cipher');
  if (cipher.isEmpty) throw StateError('SQLite không có hỗ trợ mã hóa (sqlite3mc)');
  db.execute("PRAGMA hexkey = '$hexKey'");
  db.select('SELECT count(*) FROM sqlite_master');
}
