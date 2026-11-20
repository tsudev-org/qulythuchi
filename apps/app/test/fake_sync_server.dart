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

  /// Ví chung (ADR-0015, `services/sync-api/src/wallets/routes.ts`).
  final wallets = <String, FakeWallet>{};
  final invites = <String, Map<String, Object?>>{};

  /// Tệp đính kèm (P7b): `u/<user>/<id>` và `w/<ví>/<id>` như R2. [proBlocked] ⇒ PUT trả 402 pro_required.
  final r2 = <String, List<int>>{};
  var proBlocked = false;

  /// Móc giả lập máy chủ độc: sửa lời mời đã nhận trước khi trả cho chủ ví.
  void Function(Map<String, Object?> invite)? tamperAccepted;

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
      'user': {
        'id': user,
        'email': '$user@example.com',
        'email_verified': true,
        'display_name': 'Người dùng $user',
        'avatar_url': null,
      },
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
        final challenge = base64Url
            .encode(sha256.convert(ascii.encode(b['code_verifier']! as String)).bytes)
            .replaceAll('=', '');
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
        return _json({
          'records': page,
          'cursor': page.isEmpty ? since : page.last['rev'],
          'has_more': rows.length > limit,
        });
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
                {
                  ...d,
                  'created_at': '2026-11-18T00:00:00.000Z',
                  'last_seen_at': '2026-11-18T01:00:00.000Z',
                  'current': d['id'] == device,
                },
          ],
        });
      case ('POST', '/api/v1/me/deletion'):
        u.deleting = true;
        return _json({'status': 'pending_deletion'}, 202);
      case ('DELETE', '/api/v1/me/deletion'):
        u.deleting = false;
        return _json({'status': 'active'});
    }
    if (path.startsWith('/api/v1/files/')) return _file(req, 'u/$uid/${path.split('/').last}', canWrite: true);
    if (path.startsWith('/api/v1/wallets/') && req.url.pathSegments.length == 6 && req.url.pathSegments[4] == 'files') {
      final wid = req.url.pathSegments[3];
      final w = _member(wid, uid);
      return _file(req, 'w/$wid/${req.url.pathSegments[5]}', canWrite: w.members[uid] != 'viewer');
    }
    if (path.startsWith('/api/v1/wallets') || path.startsWith('/api/v1/invites/')) return _wallets(req, uid, device);
    if (m == 'DELETE' && path.startsWith('/api/v1/me/devices/')) {
      final id = path.split('/').last;
      if (!u.devices.containsKey(id) || revoked.contains(id)) throw const _Err(404, 'not_found');
      revoked.add(id);
      return http.Response('', 204);
    }
    throw const _Err(404, 'not_found');
  }
}

extension on FakeSyncServer {
  http.Response _file(http.Request req, String key, {required bool canWrite}) {
    switch (req.method) {
      case 'PUT':
        if (!canWrite) throw const _Err(403, 'read_only');
        if (proBlocked) return _json({'code': 'pro_required', 'reason': 'no_pro'}, 402);
        final b = req.bodyBytes;
        if (b.length < 4 || b[0] != 0x51 || b[1] != 0x54) throw const _Err(400, 'bad_request');
        final qw = req.url.queryParameters['wallet_id'];
        if (key.startsWith('u/') && qw != null && wallets.containsKey(qw)) throw const _Err(409, 'shared_wallet');
        final existed = r2.containsKey(key);
        r2.putIfAbsent(key, () => List.of(b));
        return _json({'status': existed ? 'unchanged' : 'stored'}, existed ? 200 : 201);
      case 'GET':
        final b = r2[key];
        if (b == null) throw const _Err(404, 'not_found');
        return http.Response.bytes(b, 200, headers: {'content-type': 'application/octet-stream'});
      case 'DELETE':
        if (!canWrite) throw const _Err(403, 'read_only');
        r2.remove(key);
        return http.Response('', 204);
    }
    throw const _Err(404, 'not_found');
  }

  FakeWallet _member(String wid, String uid) {
    final w = wallets[wid];
    if (w == null || !w.members.containsKey(uid)) throw const _Err(404, 'not_found');
    return w;
  }

  FakeWallet _owner(String wid, String uid) {
    final w = _member(wid, uid);
    if (w.members[uid] != 'owner') throw const _Err(403, 'forbidden');
    return w;
  }

  Future<http.Response> _wallets(http.Request req, String uid, String device) async {
    final m = req.method;
    final seg = req.url.pathSegments.skip(2).toList(); // [wallets|invites, ...]
    if (seg[0] == 'invites') {
      final inv = invites[seg[1]];
      if (inv == null) throw const _Err(404, 'invite_gone');
      final w = wallets[inv['wallet_id']]!;
      if (m == 'GET') {
        return _json({
          'invite_id': seg[1],
          'wallet_id': w.id,
          'role': inv['role'],
          'expires_at': 1900000000000,
          'owner_name': 'Người dùng ${w.owner}',
          'state': w.owner == uid
              ? 'own'
              : inv['accepted_by'] == null
              ? 'open'
              : inv['accepted_by'] == uid
              ? 'accepted'
              : 'taken',
        });
      }
      if (w.members.containsKey(uid)) throw const _Err(409, 'already_member');
      if (inv['accepted_by'] != null && inv['accepted_by'] != uid) throw const _Err(409, 'invite_taken');
      inv['accepted_by'] = uid;
      inv['kem_pk'] = user(uid).bundle!['kemPk'];
      inv['proof'] = _body(req)['proof'];
      return _json({'wallet_id': w.id, 'state': 'accepted'});
    }
    if (seg.length == 1 && m == 'POST') {
      final b = _body(req);
      final wid = b['wallet_id']! as String;
      if (wallets.containsKey(wid)) throw const _Err(409, 'wallet_exists');
      final w = wallets[wid] = FakeWallet(wid, uid);
      w.members[uid] = 'owner';
      w.shares[uid] = {1: b['wrapped']! as String};
      final u = user(uid);
      final moved = u.records.values.where((r) => r['wallet_id'] == wid).toList()
        ..sort((a, b) => (a['rev']! as int).compareTo(b['rev']! as int));
      for (final r in moved) {
        w.records[r['id']! as String] = {...r, 'key_ver': 1, 'rev': ++w.rev};
        u.records.remove(r['id']);
      }
      return _json({'wallet_id': wid, 'key_ver': 1, 'rev': w.rev});
    }
    if (seg.length == 1 && m == 'GET') {
      return _json({
        'wallets': [
          for (final w in wallets.values)
            if (w.members.containsKey(uid))
              {
                'wallet_id': w.id,
                'role': w.members[uid],
                'key_ver': w.keyVer,
                'rev': w.rev,
                'owner_id': w.owner,
                'needs_rotation': w.members[uid] == 'owner' && w.needsRotation,
                'shares': [
                  for (final e in (w.shares[uid] ?? const <int, String>{}).entries)
                    {'key_ver': e.key, 'wrapped': e.value},
                ],
                'members': [
                  for (final e in w.members.entries)
                    {
                      'user_id': e.key,
                      'role': e.value,
                      'joined_at': 1,
                      'display_name': 'Người dùng ${e.key}',
                      'email': '${e.key}@example.com',
                      'kem_pk': user(e.key).bundle?['kemPk'],
                      'box_pk': user(e.key).bundle?['boxPk'],
                    },
                ],
                'invites': w.members[uid] != 'owner'
                    ? const <Object?>[]
                    : [
                        for (final e in invites.entries)
                          if (e.value['wallet_id'] == w.id)
                            {
                              'invite_id': e.key,
                              'role': e.value['role'],
                              'expires_at': 1900000000000,
                              'accepted': e.value['accepted_by'] == null
                                  ? null
                                  : () {
                                      final a = <String, Object?>{
                                        'user_id': e.value['accepted_by'],
                                        'display_name': 'Người dùng ${e.value['accepted_by']}',
                                        'email': null,
                                        'kem_pk': e.value['kem_pk'],
                                        'proof': e.value['proof'],
                                      };
                                      tamperAccepted?.call(a);
                                      return a;
                                    }(),
                            },
                      ],
              },
        ],
        'pending': [
          for (final e in invites.entries)
            if (e.value['accepted_by'] == uid)
              {'invite_id': e.key, 'wallet_id': e.value['wallet_id'], 'role': e.value['role'], 'owner_name': 'x'},
        ],
      });
    }
    final wid = seg[1];
    final tail = seg.skip(2).join('/');
    switch ((m, tail)) {
      case ('POST', 'invites'):
        _owner(wid, uid);
        final b = _body(req);
        invites[b['invite_id']! as String] = {'wallet_id': wid, 'role': b['role']};
        return _json({'invite_id': b['invite_id'], 'expires_at': 1900000000000});
      case ('POST', 'members'):
        final w = _owner(wid, uid);
        final b = _body(req);
        if (b['key_ver'] != w.keyVer) throw const _Err(409, 'stale_key');
        final inv = invites[b['invite_id']];
        final who = inv?['accepted_by'] as String?;
        if (who == null) throw const _Err(404, 'invite_gone');
        w.members[who] = inv!['role']! as String;
        (w.shares[who] ??= {})[w.keyVer] = b['wrapped']! as String;
        invites.remove(b['invite_id']);
        return _json({'user_id': who, 'role': w.members[who]});
      case ('POST', 'rotate'):
        final w = _owner(wid, uid);
        final b = _body(req);
        if (b['key_ver'] != w.keyVer + 1) throw const _Err(409, 'stale_key');
        final remove = (b['remove'] as List? ?? const []).cast<String>();
        final shares = (b['shares']! as List).cast<Map<Object?, Object?>>();
        final remaining = w.members.keys.where((u) => !remove.contains(u)).toSet();
        if (shares.length != remaining.length || !shares.every((x) => remaining.contains(x['user_id']))) {
          throw const _Err(409, 'members_changed');
        }
        for (final r in remove) {
          w.members.remove(r);
          w.shares.remove(r);
        }
        w.keyVer++;
        for (final x in shares) {
          (w.shares[x['user_id']! as String] ??= {})[w.keyVer] = x['wrapped']! as String;
        }
        w.needsRotation = false;
        return _json({'key_ver': w.keyVer});
      case ('DELETE', 'members/me'):
        final w = _member(wid, uid);
        if (w.members[uid] == 'owner') throw const _Err(409, 'owner_cannot_leave');
        w.members.remove(uid);
        w.shares.remove(uid);
        w.needsRotation = true;
        return _json({'ok': true});
      case ('POST', 'push'):
        final w = _member(wid, uid);
        final role = w.members[uid];
        if (role == 'viewer') throw const _Err(403, 'read_only');
        final b = _body(req);
        if (b['key_ver'] != w.keyVer) throw const _Err(409, 'stale_key');
        final results = <Object?>[];
        for (final r in (b['records']! as List).cast<Map<Object?, Object?>>()) {
          final id = r['id']! as String;
          if (r['type'] == 'wallet' && role != 'owner') {
            results.add({'id': id, 'status': 'rejected', 'reason': 'forbidden'});
            continue;
          }
          final prev = w.records[id];
          if (prev != null && prev['sealed'] == r['sealed']) {
            results.add({'id': id, 'status': 'unchanged', 'rev': prev['rev']});
            continue;
          }
          final rev = ++w.rev;
          w.records[id] = {...r.cast<String, Object?>(), 'wallet_id': wid, 'key_ver': w.keyVer, 'rev': rev};
          results.add({'id': id, 'status': 'applied', 'rev': rev});
        }
        return _json({'results': results});
      case ('GET', 'pull'):
        final w = _member(wid, uid);
        final since = int.parse(req.url.queryParameters['since'] ?? '0');
        final rows = w.records.values.where((r) => (r['rev']! as int) > since).toList()
          ..sort((a, b) => (a['rev']! as int).compareTo(b['rev']! as int));
        return _json({
          'key_ver': w.keyVer,
          'records': rows,
          'cursor': rows.isEmpty ? since : rows.last['rev'],
          'has_more': false,
        });
    }
    if (m == 'PUT' && tail.startsWith('members/')) {
      final w = _owner(wid, uid);
      w.members[tail.split('/').last] = _body(req)['role']! as String;
      return _json({'role': w.members[tail.split('/').last]});
    }
    if (m == 'DELETE' && tail.startsWith('invites/')) {
      _owner(wid, uid);
      invites.remove(tail.split('/').last);
      return _json({'ok': true});
    }
    throw const _Err(404, 'not_found');
  }
}

final class FakeWallet {
  FakeWallet(this.id, this.owner);
  final String id;
  final String owner;
  int keyVer = 1;
  int rev = 0;
  bool needsRotation = false;
  final members = <String, String>{};
  final shares = <String, Map<int, String>>{};
  final records = <String, Map<String, Object?>>{};
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
