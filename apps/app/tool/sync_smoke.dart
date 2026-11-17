// Kiểm thử khói ĐẦU-CUỐI với máy chủ thật (P6), dùng đúng mã của app (ApiClient, ghim CA, PKCE, vòng lặp 127.0.0.1).
//   dart run tool/sync_smoke.dart health   - chỉ kiểm TLS ghim + /api/v1/health
//   dart run tool/sync_smoke.dart login    - đăng nhập tsudev.com trong trình duyệt, gọi /me, /keys, /me/devices, /me/usage
//                                            rồi đăng xuất (thu hồi thiết bị kiểm thử). Không in dữ liệu D3 hay token.
// Đặt QT_SERVER=https://... để trỏ máy chủ khác.
import 'dart:io';

import 'package:qulythuchi/sync/api_client.dart';
import 'package:qulythuchi/sync/http_client_io.dart';
import 'package:qulythuchi/sync/loopback_login.dart';

Future<void> main(List<String> args) async {
  final server = Uri.parse(Platform.environment['QT_SERVER'] ?? defaultServer.toString());
  final api = ApiClient(
    client: createSyncHttpClient(),
    tokens: MemoryTokenStore(),
    base: server,
    mapTransportError: mapSyncTransportError,
  );
  final health = await api.getJsonPublic('/api/v1/health');
  stdout.writeln('health: $health (TLS ghim CA: đạt)');
  if (args.firstOrNull != 'login') return;

  final login = await LoopbackLogin.start();
  final url = login.request.startUrl(server).toString();
  stdout.writeln('Mở trang sau trong trình duyệt để đăng nhập tsudev.com:\n$url');
  for (final opener in ['wslview', 'xdg-open', 'open']) {
    try {
      final r = await Process.run(opener, [url]);
      if (r.exitCode == 0) break;
    } on ProcessException {
      // thử lệnh kế
    }
  }
  final cb = await login.wait(doneHtml: '<p>Đã đăng nhập. Quay lại cửa sổ dòng lệnh.</p>');
  if (cb.code == null) {
    stderr.writeln('Đăng nhập thất bại: ${cb.error}');
    exitCode = 1;
    return;
  }
  final grant = await api.exchangeCode(
    code: cb.code!,
    verifier: login.request.verifier,
    redirectUri: login.request.redirectUri,
    platform: 'linux',
    deviceName: 'Kiểm thử khói P6 (CLI)',
  );
  stdout.writeln('token: đạt (device ${grant.deviceId.substring(0, 8)}...)');
  final me = (await api.getJson('/api/v1/me'))! as Map;
  stdout.writeln('me: status=${me['status']} email_verified=${me['email_verified']}');
  final keys = (await api.getJson('/api/v1/keys'))! as Map;
  stdout.writeln(
    'keys: gói khóa ${keys['account'] == null ? 'CHƯA có' : 'đã có'}, ${(keys['wallets']! as List).length} khóa ví',
  );
  final devices = ((await api.getJson('/api/v1/me/devices'))! as Map)['devices']! as List;
  stdout.writeln('devices: ${devices.length} thiết bị còn hiệu lực');
  final usage = (await api.getJson('/api/v1/me/usage'))! as Map;
  stdout.writeln('usage: ${(usage['records']! as Map)['count']} bản ghi');
  final pull = (await api.getJson('/api/v1/sync/pull', {'since': '0', 'limit': '1'}))! as Map;
  stdout.writeln('pull: đạt (has_more=${pull['has_more']})');
  // Làm mới xoay vòng thật một lần.
  await api.forceRefreshForTest();
  await api.getJson('/api/v1/me');
  stdout.writeln('refresh xoay vòng: đạt');
  await api.logout();
  stdout.writeln('logout: đã thu hồi thiết bị kiểm thử');
}
