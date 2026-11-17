import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Gốc máy chủ đồng bộ production (ADR-0010 mục 9).
final Uri defaultServer = Uri.parse('https://qulythuchi.tsudev.com');

/// Lỗi gọi API. [code] máy đọc được (khớp `{code, message}` của máy chủ); [message] là câu cố định của máy chủ
/// hoặc null - KHÔNG BAO GIỜ chứa dữ liệu người dùng, nhưng giao diện vẫn dịch theo [code] thay vì in [message].
final class ApiException implements Exception {
  const ApiException(this.status, this.code, [this.message]);
  final int status;
  final String code;
  final String? message;

  /// Mã nội bộ (không đến từ máy chủ).
  static const network = 'network';
  static const tlsPin = 'tls_pin';
  static const badResponse = 'bad_response';
  static const signedOut = 'signed_out';

  /// Phiên không còn dùng được ⇒ phải đăng nhập lại.
  bool get sessionEnded =>
      status == 401 && (code == 'invalid_grant' || code == 'device_revoked' || code == signedOut || code == 'unauthenticated');

  @override
  String toString() => 'ApiException($status, $code)';
}

/// Nơi giữ refresh token (kho bí mật của thiết bị) - access token chỉ ở trong bộ nhớ.
abstract interface class TokenStore {
  Future<String?> readRefresh();
  Future<void> writeRefresh(String token);
  Future<void> clear();
}

final class MemoryTokenStore implements TokenStore {
  String? refresh;
  @override
  Future<String?> readRefresh() async => refresh;
  @override
  Future<void> writeRefresh(String token) async => refresh = token;
  @override
  Future<void> clear() async => refresh = null;
}

/// Kết quả cấp token (`POST /api/v1/auth/token`).
final class TokenGrant {
  const TokenGrant({required this.accessToken, required this.expiresIn, required this.refreshToken, required this.deviceId, required this.user});
  final String accessToken;
  final int expiresIn;
  final String refreshToken;
  final String deviceId;
  final Map<String, Object?> user;

  static TokenGrant fromJson(Map<String, Object?> j) => TokenGrant(
    accessToken: j['access_token']! as String,
    expiresIn: (j['expires_in'] as num?)?.toInt() ?? 900,
    refreshToken: j['refresh_token']! as String,
    deviceId: j['device_id']! as String,
    user: (j['user']! as Map).cast<String, Object?>(),
  );
}

/// Ánh xạ lỗi tầng mạng (gồm lỗi ghim chứng chỉ) thành [ApiException]. Bộ phát hiện do nền tảng cung cấp
/// (`http_client_io.dart`) để tệp này giữ thuần Dart và chạy được cả trên web.
typedef TransportErrorMapper = ApiException? Function(Object error);

/// Khách API: bearer + tự làm mới token xoay vòng (một lượt làm mới tại một thời điểm), hoặc cookie trên web.
final class ApiClient {
  ApiClient({
    required http.Client client,
    required this.tokens,
    Uri? base,
    this.cookieMode = false,
    this.mapTransportError,
    DateTime Function()? now,
  }) : _http = client,
       base = base ?? defaultServer,
       _now = now ?? DateTime.now;

  final http.Client _http;
  final TokenStore tokens;
  final Uri base;

  /// Web: dùng cookie phiên `__Host-qt_session` của trình duyệt (cùng gốc), gửi `X-Qt-Csrf: 1` cho mọi lượt ghi.
  final bool cookieMode;
  final TransportErrorMapper? mapTransportError;
  final DateTime Function() _now;

  String? _access;
  DateTime _accessExpiry = DateTime.fromMillisecondsSinceEpoch(0);
  Future<void>? _refreshing;

  /// Gọi khi một lượt làm mới thất bại vĩnh viễn (phiên bị thu hồi/hết hạn).
  void Function()? onSessionEnded;

  Uri resolve(String path, [Map<String, String>? query]) =>
      base.replace(path: path, queryParameters: (query == null || query.isEmpty) ? null : query);

  /// Nhận token từ lượt đăng nhập (mã một lần + PKCE).
  Future<TokenGrant> exchangeCode({
    required String code,
    required String verifier,
    required String redirectUri,
    required String platform,
    required String deviceName,
  }) async {
    final grant = TokenGrant.fromJson(
      await _send('POST', '/api/v1/auth/token', body: {
        'grant_type': 'authorization_code',
        'code': code,
        'code_verifier': verifier,
        'redirect_uri': redirectUri,
        'platform': platform,
        'device_name': deviceName,
      }, auth: false) as Map<String, Object?>,
    );
    await _adopt(grant);
    return grant;
  }

  Future<void> _adopt(TokenGrant g) async {
    // Lưu refresh MỚI trước khi dùng access mới: mất điện giữa chừng không để lại token đã xoay.
    await tokens.writeRefresh(g.refreshToken);
    _access = g.accessToken;
    // Trừ hao 60 giây cho lệch giờ và thời gian truyền.
    _accessExpiry = _now().add(Duration(seconds: g.expiresIn - 60));
  }

  Future<bool> get hasSession async => cookieMode || await tokens.readRefresh() != null;

  Future<void> _refresh() => _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<void> _doRefresh() async {
    final refresh = await tokens.readRefresh();
    if (refresh == null) throw const ApiException(401, ApiException.signedOut);
    try {
      final j = await _send('POST', '/api/v1/auth/token', body: {'grant_type': 'refresh_token', 'refresh_token': refresh}, auth: false);
      await _adopt(TokenGrant.fromJson(j as Map<String, Object?>));
    } on ApiException catch (e) {
      if (e.sessionEnded) await _endSession();
      rethrow;
    }
  }

  Future<void> _endSession() async {
    _access = null;
    await tokens.clear();
    onSessionEnded?.call();
  }

  /// Đăng xuất: thu hồi thiết bị phía máy chủ (nếu được) rồi xóa token cục bộ. Không ném lỗi mạng.
  Future<void> logout() async {
    final refresh = await tokens.readRefresh();
    try {
      if (cookieMode) {
        await _send('POST', '/api/v1/auth/web-logout', auth: false);
      } else if (refresh != null) {
        await _send('POST', '/api/v1/auth/logout', body: {'refresh_token': refresh}, auth: false);
      }
    } on ApiException {
      // Máy chủ không với tới: vẫn xóa token cục bộ; thiết bị thu hồi được từ máy khác.
    }
    _access = null;
    await tokens.clear();
  }

  /// Gọi không cần đăng nhập (kiểm sức khỏe).
  Future<Object?> getJsonPublic(String path) => _send('GET', path, auth: false);

  /// Ép làm mới token ngay (kiểm thử khói xoay vòng refresh).
  Future<void> forceRefreshForTest() async {
    _access = null;
    await _refresh();
  }

  Future<Object?> getJson(String path, [Map<String, String>? query]) => _authed('GET', path, query: query);
  Future<Object?> postJson(String path, [Object? body]) => _authed('POST', path, body: body);
  Future<Object?> putJson(String path, Object? body) => _authed('PUT', path, body: body);
  Future<Object?> delete(String path) => _authed('DELETE', path);

  /// Tải thô (xuất dữ liệu máy chủ).
  Future<Uint8List> getBytes(String path) async => (await _authedRaw('GET', path)).bodyBytes;

  Future<Object?> _authed(String method, String path, {Map<String, String>? query, Object? body}) async =>
      _decode(await _authedRaw(method, path, query: query, body: body));

  Future<http.Response> _authedRaw(String method, String path, {Map<String, String>? query, Object? body}) async {
    if (cookieMode) return _raw(method, path, query: query, body: body, auth: false);
    if (_access == null || !_now().isBefore(_accessExpiry)) await _refresh();
    var res = await _raw(method, path, query: query, body: body, auth: true);
    if (res.statusCode == 401) {
      final err = _error(res);
      if (err.code == 'device_revoked') {
        await _endSession();
        throw err;
      }
      // Access hết hạn sớm (máy chủ đổi SESSION_SECRET, giờ máy sai): làm mới một lần rồi thử lại.
      await _refresh();
      res = await _raw(method, path, query: query, body: body, auth: true);
    }
    return res;
  }

  Future<Object?> _send(String method, String path, {Object? body, required bool auth}) async =>
      _decode(await _raw(method, path, body: body, auth: auth));

  Future<http.Response> _raw(String method, String path, {Map<String, String>? query, Object? body, required bool auth}) async {
    final req = http.Request(method, resolve(path, query));
    req.headers['Accept'] = 'application/json';
    if (auth && _access != null) req.headers['Authorization'] = 'Bearer $_access';
    if (cookieMode && method != 'GET') req.headers['X-Qt-Csrf'] = '1';
    if (body != null) {
      req.headers['Content-Type'] = 'application/json';
      req.bodyBytes = utf8.encode(jsonEncode(body));
    }
    try {
      return await http.Response.fromStream(await _http.send(req)).timeout(const Duration(seconds: 60));
    } on ApiException {
      rethrow;
    } on Object catch (e) {
      throw mapTransportError?.call(e) ?? const ApiException(0, ApiException.network);
    }
  }

  Object? _decode(http.Response res) {
    if (res.statusCode == 204 || res.bodyBytes.isEmpty) {
      if (res.statusCode >= 400) throw ApiException(res.statusCode, ApiException.badResponse);
      return null;
    }
    if (res.statusCode >= 400) throw _error(res);
    try {
      return jsonDecode(utf8.decode(res.bodyBytes));
    } on FormatException {
      throw ApiException(res.statusCode, ApiException.badResponse);
    }
  }

  static ApiException _error(http.Response res) {
    try {
      final j = jsonDecode(utf8.decode(res.bodyBytes));
      if (j is Map && j['code'] is String) {
        return ApiException(res.statusCode, j['code'] as String, j['message'] is String ? j['message'] as String : null);
      }
    } on Object {
      // Trang lỗi HTML của CDN... - rơi xuống mã chung.
    }
    return ApiException(res.statusCode, ApiException.badResponse);
  }
}
