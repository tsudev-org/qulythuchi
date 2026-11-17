import 'dart:async';
import 'dart:io';

import 'pkce.dart';

/// Máy tính: nhận mã qua vòng lặp `http://127.0.0.1:<cổng>/callback` (RFC 8252 mục 7.3). Chỉ nghe trên 127.0.0.1,
/// cổng do hệ điều hành cấp, đóng ngay sau lượt gọi hợp lệ đầu tiên hoặc khi hết giờ.
final class LoopbackLogin {
  LoopbackLogin._(this._server, this.request);

  static Future<LoopbackLogin> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    return LoopbackLogin._(server, LoginRequest.create('http://127.0.0.1:${server.port}/callback'));
  }

  final HttpServer _server;
  final LoginRequest request;

  /// Chờ trình duyệt quay về. Yêu cầu khác đường dẫn/sai state bị trả 404 và bỏ qua.
  Future<LoginCallback> wait({Duration timeout = const Duration(minutes: 5), required String doneHtml}) async {
    try {
      await for (final req in _server.timeout(timeout)) {
        final result = req.uri.path == '/callback' ? request.parseCallback(req.uri) : null;
        req.response.headers
          ..contentType = ContentType.html
          ..set('Cache-Control', 'no-store')
          ..set('Referrer-Policy', 'no-referrer');
        if (result == null) {
          req.response.statusCode = HttpStatus.notFound;
          await req.response.close();
          continue;
        }
        req.response.write(doneHtml);
        await req.response.close();
        return result;
      }
    } on TimeoutException {
      return const LoginCallback.failed('timeout');
    } finally {
      await close();
    }
    return const LoginCallback.failed('cancelled');
  }

  Future<void> close() => _server.close(force: true);
}
