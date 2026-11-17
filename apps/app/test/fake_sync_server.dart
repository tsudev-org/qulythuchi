import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Máy chủ đồng bộ giả trong bộ nhớ, mô phỏng đúng hợp đồng của `services/sync-api` (ADR-0010):
/// token xoay vòng + phát hiện dùng lại, thu hồi thiết bị, gói khóa `if_absent`, rev tài khoản, push lũy đẳng,
/// kéo theo con trỏ. Có móc để giả lập máy chủ độc (tráo gói khóa, quay lui rev).
final class FakeSyncServer {
  final users = <String, FakeUser>{};
  final _access = <String, (String user, String device)>{};
  final _refresh = <String, ({String user, String device, bool used})>{};
  final revoked = <String>{};
  var _seq = 0;
  int requests = 0;
  final paths = <String>[];

  /// Từ chối mọi access token hiện có (giả lập hết hạn/đổi SESSION_SECRET).
  void expireAccessTokens() => _access.clear();

  FakeUser user(String id) => users.putIfAbsent(id, () => FakeUser(id));

  late final http.Client client = MockClient(_handle);

  Future<http.Response> _handle(http.Request req) async {
    requests++;
    paths.add('${req.method} ${req.url.path}');
    try {
      return await _route(req);
    } on _Err catch (e) {
      return _json({'code': e.code, 'message': 'x'}, e.status);
    }
  }

  http.Response _json(Object? body, [int status = 200]) =>
      http.Response.bytes(utf8.encode(jsonEncode(body)), status, headers: {'content-type': 'application/json'});

  Map<String, Object?> _body(http.Request r) => (jsonDecode(r.body) as Map).cast<String, Object?>();

  (String, String) _auth(http.Request r) {
    final h = r.headers['Authorization'];
    final a = h == null ? null : _access[h.substring(7)];
    if (a == null) throw const _Err(401, 'invalid_token');
    if (revoked.contains(a.$2)) throw const _Err(401, 'device_revoked');
    return a;
  }

  Map<String, Object?> _grant(String user, String device) {
    final acc = 'acc-${++_seq}';
    final ref = 'qtr_${++_seq}';
    _access[acc] = (user, device);
    _refresh[ref] = (user: user, device: device, used: false);
    return {
      'token_type': 'Bearer',
      'access_token': acc,
      'expires_in': 900,
      'refresh_token': ref,
      'device_id': device,
      'user': {'id': user, 'email': '$user@example.com', 'email_verified': true, 'display_name': 'Người dùng $user', 'avatar_url': null},
    };
  }

  Future<http.Response> _route(http.Request req) async {
    final path = req.url.path;
    final m = req.method;
    if (m == 'POST' && path == '/api/v1/auth/token') {
      final b = _body(req);
      if (b['grant_type'] == 'authorization_code') {
        // Mã giả: "code:<user>:<challenge>" - kiểm PKCE như máy chủ thật.
        final parts = (b['code']! as String).split(':');
        final challenge = base64Url.encode(sha256.convert(ascii.encode(b['code_verifier']! as String)).bytes).replaceAll('=', '');
        if (parts.length != 3 || parts[2] != challenge) throw const _Err(400, 'invalid_grant');
        final device = 'dev-${++_seq}';
        user(parts[1]).devices[device] = {'id': device, 'name': b['device_name'], 'platform': b['platform']};
        return _json(_grant(parts[1], device));
      }
      final r = _refresh[b['refresh_token']];
      if (r == null || revoked.contains(r.device)) throw const _Err(401, 'invalid_grant');
      if (r.used) {
        revoked.add(r.device);
        throw const _Err(401, 'invalid_grant');
      }
      _refresh[b['refresh_token']! as String] = (user: r.user, device: r.device, used: true);
      return _json(_grant(r.user, r.device));
    }
    if (m == 'POST' && path == '/api/v1/auth/logout') {
      final r = _refresh[_body(req)['refresh_token']];
      if (r != null) revoked.add(r.device);
      return http.Response('', 204);
    }
    final (uid, device) = _auth(req);
    final u = user(uid);
    if (m != 'GET' && u.deleting && (path.startsWith('/api/v1/sync/') || path.startsWith('/api/v1/keys'))) {
      throw const _Err(403, 'pending_deletion');
    }
    switch ((m, path)) {
      case ('GET', '/api/v1/keys'):
        return _json({
          'account': u.bundle == null ? null : {'bundle': u.bundle, 'updated_at': 1},
          'wallets': [
            for (final e in u.walletKeys.entries) {'wallet_id': e.key, 'wrapped': e.value, 'updated_at': 1},
          ],
        });
      case ('PUT', '/api/v1/keys/account'):
        final b = _body(req);
        if (b['if_absent'] == true && u.bundle != null) {
          return _json({'code': 'bundle_exists', 'message': 'x'}, 409);
        }
        u.bundle = (b['bundle']! as Map).cast();
        return _json({'updated_at': 1});
      case ('PUT', '/api/v1/keys/wallets'):
        for (final k in (_body(req)['keys']! as List).cast<Map<Object?, Object?>>()) {
          u.walletKeys[k['wallet_id']! as String] = k['wrapped']! as String;
        }
        return _json({'updated_at': 1});
      case ('POST', '/api/v1/sync/push'):
        final results = <Object?>[];
        for (final r in (_body(req)['records']! as List).cast<Map<Object?, Object?>>()) {
          final id = r['id']! as String;
          final prev = u.records[id];
          if (prev != null && (prev['type'] != r['type'] || prev['wallet_id'] != r['wallet_id'])) {
            results.add({'id': id, 'status': 'rejected', 'reason': 'identity_mismatch'});
            continue;
          }
          if (prev != null && prev['sealed'] == r['sealed']) {
            results.add({'id': id, 'status': 'unchanged', 'rev': prev['rev']});
            continue;
          }
          final rev = ++u.rev;
          u.records[id] = {...r.cast<String, Object?>(), 'rev': rev};
          results.add({'id': id, 'status': 'applied', 'rev': rev});
        }
        return _json({'results': results});
      case ('GET', '/api/v1/sync/pull'):
        final since = int.parse(req.url.queryParameters['since'] ?? '0');
        final limit = int.parse(req.url.queryParameters['limit'] ?? '200');
        final rows = u.records.values.where((r) => (r['rev']! as int) > since).toList()
          ..sort((a, b) => (a['rev']! as int).compareTo(b['rev']! as int));
        final page = rows.take(limit).toList();
        return _json({'records': page, 'cursor': page.isEmpty ? since : page.last['rev'], 'has_more': rows.length > limit});
      case ('GET', '/api/v1/me'):
        return _json({
          'id': uid,
          'email': '$uid@example.com',
          'display_name': 'Người dùng $uid',
          'email_verified': true,
          'status': u.deleting ? 'pending_deletion' : 'active',
          'deletion': u.deleting ? {'scheduled_at': '2026-12-18T00:00:00.000Z', 'days_remaining': 30} : null,
          'device_id': device,
        });
      case ('GET', '/api/v1/me/usage'):
        return _json({
          'records': {'count': u.records.length, 'bytes': 1024, 'quota_bytes': 52428800},
          'files': {'count': 0, 'bytes': 0, 'quota_bytes': 209715200},
        });
      case ('GET', '/api/v1/me/devices'):
        return _json({
          'devices': [
            for (final d in u.devices.values)
              if (!revoked.contains(d['id']))
                {...d, 'created_at': '2026-11-18T00:00:00.000Z', 'last_seen_at': '2026-11-18T01:00:00.000Z', 'current': d['id'] == device},
          ],
        });
      case ('POST', '/api/v1/me/deletion'):
        u.deleting = true;
        return _json({'status': 'pending_deletion'}, 202);
      case ('DELETE', '/api/v1/me/deletion'):
        u.deleting = false;
        return _json({'status': 'active'});
    }
    if (m == 'DELETE' && path.startsWith('/api/v1/me/devices/')) {
      final id = path.split('/').last;
      if (!u.devices.containsKey(id) || revoked.contains(id)) throw const _Err(404, 'not_found');
      revoked.add(id);
      return http.Response('', 204);
    }
    throw const _Err(404, 'not_found');
  }
}

final class FakeUser {
  FakeUser(this.id);
  final String id;
  Map<String, Object?>? bundle;
  final walletKeys = <String, String>{};
  final records = <String, Map<String, Object?>>{};
  final devices = <String, Map<String, Object?>>{};
  int rev = 0;
  bool deleting = false;
}

final class _Err implements Exception {
  const _Err(this.status, this.code);
  final int status;
  final String code;
}
