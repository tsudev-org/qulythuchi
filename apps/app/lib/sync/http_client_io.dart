import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import 'api_client.dart';
import 'pinned_roots.g.dart';

/// SecurityContext CHỈ tin tập CA gốc được ghim (ADR-0011): CA khác (kể cả CA hợp lệ do hệ điều hành tin, CA do
/// phần mềm diệt virus/proxy công ty cài) ⇒ bắt tay TLS thất bại ⇒ chặn đồng bộ, app ngoại tuyến vẫn dùng bình thường.
SecurityContext pinnedSecurityContext() =>
    SecurityContext(withTrustedRoots: false)..setTrustedCertificatesBytes(utf8.encode(pinnedRootsPem));

http.Client createSyncHttpClient() {
  final client = HttpClient(context: pinnedSecurityContext())
    ..connectionTimeout = const Duration(seconds: 20)
    ..idleTimeout = const Duration(seconds: 15)
    // Không bao giờ chấp nhận chứng chỉ lỗi (mặc định đã từ chối; ghi rõ để không ai "sửa cho chạy").
    ..badCertificateCallback = ((_, _, _) => false);
  return IOClient(client);
}

ApiException? mapSyncTransportError(Object error) =>
    error is HandshakeException || error is TlsException ? const ApiException(0, ApiException.tlsPin) : null;

const bool syncUsesCookies = false;
