import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qulythuchi/sync/loopback_login.dart';

void main() {
  test('vòng lặp 127.0.0.1: bỏ qua đường dẫn/state lạ, nhận đúng mã rồi đóng cổng', () async {
    final login = await LoopbackLogin.start();
    final uri = Uri.parse(login.request.redirectUri);
    expect(uri.host, '127.0.0.1');
    expect(uri.path, '/callback');
    final result = login.wait(doneHtml: 'ok', timeout: const Duration(seconds: 10));
    final http = HttpClient();
    Future<int> hit(String q) async {
      final r = await (await http.getUrl(uri.replace(query: q))).close();
      await r.drain<void>();
      return r.statusCode;
    }

    expect(await hit('state=gia-mao&code=x'), 404);
    expect((await (await http.getUrl(uri.replace(path: '/khac'))).close()).statusCode, 404);
    expect(await hit('state=${login.request.state}&code=ma-that'), 200);
    expect((await result).code, 'ma-that');
    await expectLater(hit('state=${login.request.state}&code=lan-hai'), throwsA(isA<IOException>()));
    http.close(force: true);
  });

  test('hết giờ ⇒ lỗi timeout', () async {
    final login = await LoopbackLogin.start();
    final r = await login.wait(doneHtml: 'ok', timeout: const Duration(milliseconds: 200));
    expect(r.error, 'timeout');
  });
}
