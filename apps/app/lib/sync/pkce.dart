import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Tham số một lượt đăng nhập app (ADR-0003): `state` chống CSRF, PKCE S256 ràng buộc mã một lần với app này.
final class LoginRequest {
  LoginRequest._(this.state, this.verifier, this.redirectUri);

  factory LoginRequest.create(String redirectUri, {Random? random}) {
    final rnd = random ?? Random.secure();
    return LoginRequest._(_token(rnd, 24), _token(rnd, 48), redirectUri);
  }

  static String _token(Random rnd, int bytes) =>
      base64Url.encode(List<int>.generate(bytes, (_) => rnd.nextInt(256))).replaceAll('=', '');

  final String state;
  final String verifier;
  final String redirectUri;

  String get challenge => base64Url.encode(sha256.convert(ascii.encode(verifier)).bytes).replaceAll('=', '');

  /// [server] có thể mang `provider` (google|github) - gợi ý lối đăng nhập ở tsudev.com (AUTH_AND_ACCOUNT mục 3).
  Uri startUrl(Uri server) => server.replace(
    path: '/auth/app/start',
    queryParameters: {
      if (server.queryParameters['provider'] case final p? when loginProviders.contains(p)) 'provider': p,
      'redirect_uri': redirectUri,
      'state': state,
      'code_challenge': challenge,
      'code_challenge_method': 'S256',
    },
  );

  /// Đọc kết quả máy chủ trả về đích quay lại. Sai `state` ⇒ coi như không phải của lượt này (bỏ qua, không lỗi).
  LoginCallback? parseCallback(Uri uri) {
    if (uri.queryParameters['state'] != state) return null;
    final error = uri.queryParameters['error'];
    final code = uri.queryParameters['code'];
    if (error != null || code == null) {
      return LoginCallback.failed(error == 'access_denied' ? 'access_denied' : 'login_failed');
    }
    return LoginCallback.ok(code);
  }
}

final class LoginCallback {
  const LoginCallback.ok(String this.code) : error = null;
  const LoginCallback.failed(String this.error) : code = null;
  final String? code;
  final String? error;
}

/// Đích quay lại của di động - khớp `APP_SCHEME_REDIRECT` ở `services/sync-api/src/auth/redirects.ts`.
const mobileRedirectUri = 'com.tsudev.qulythuchi:/auth/callback';

/// Lối vào đăng nhập liên kết qua IdP tsudev.com, đúng thứ tự bắt buộc (AUTH_AND_ACCOUNT mục 3).
const loginProviders = ['google', 'github'];
