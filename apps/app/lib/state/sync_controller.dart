import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:qulythuchi_core/qulythuchi_core.dart' show Attachment, InviteCode, WalletRole;

import '../attachments/file_sync.dart';
import '../data/key_storage.dart';
import '../security/vault.dart';
import '../sync/api_client.dart';
import '../sync/http_client.dart';
import '../sync/login_launcher.dart';
import '../sync/shared_wallets.dart';
import '../sync/sync_engine.dart';
import 'providers.dart';

/// Refresh token lưu trong kho bí mật của thiết bị - KHÔNG trong CSDL thường (phiếu P6 mục 2).
final class KeyStorageTokenStore implements TokenStore {
  KeyStorageTokenStore(this._keys);
  final KeyStorage _keys;
  static const _k = 'qt.sync.refresh';
  @override
  Future<String?> readRefresh() => _keys.read(_k);
  @override
  Future<void> writeRefresh(String token) => _keys.write(_k, token);
  @override
  Future<void> clear() => _keys.delete(_k);
}

/// Cách mở trình duyệt đăng nhập (ghi đè trong test).
typedef LoginRunner = Future<LoginOutcome> Function(Uri server);

/// Cấu hình tầng mạng - ghi đè trong test bằng `MockClient` + bộ đăng nhập giả.
final class SyncConfig {
  const SyncConfig({
    required this.httpClient,
    required this.login,
    this.server,
    this.cookieMode = false,
    this.autoSync = true,
  });
  final http.Client httpClient;
  final LoginRunner login;
  final Uri? server;
  final bool cookieMode;

  /// Tự đồng bộ khi mở khóa/sửa dữ liệu/định kỳ (test tắt để điều khiển từng bước).
  final bool autoSync;
}

final syncConfigProvider = Provider<SyncConfig>(
  (ref) => SyncConfig(
    httpClient: createSyncHttpClient(),
    cookieMode: syncUsesCookies,
    login: (server) => runSystemBrowserLogin(server, doneHtml: _doneHtml),
  ),
);

const _doneHtml =
    '<!doctype html><meta charset="utf-8"><title>Quly Thu Chi</title>'
    '<body style="font-family:sans-serif;text-align:center;padding:48px">'
    '<p>Đã đăng nhập. Hãy quay lại ứng dụng Quly Thu Chi.</p><p>Signed in. Return to the app.</p></body>';

enum SyncPhase { signedOut, idle, syncing, blocked, error }

/// Hồ sơ tài khoản TsuDEV đang đăng nhập (D2 - lưu trong CSDL đã mã hóa, không ra log).
@immutable
final class SyncProfile {
  const SyncProfile({required this.userId, required this.displayName, this.email});
  final String userId;
  final String displayName;
  final String? email;

  Map<String, Object?> toJson() => {'id': userId, 'name': displayName, 'email': email};
  static SyncProfile fromJson(Map<String, Object?> j) => SyncProfile(
    userId: j['id']! as String,
    displayName: (j['display_name'] ?? j['name'] ?? '') as String,
    email: j['email'] as String?,
  );
}

@immutable
final class SyncState {
  const SyncState({
    this.phase = SyncPhase.signedOut,
    this.profile,
    this.lastSyncAt,
    this.pending = 0,
    this.error,
    this.block,
    this.quotaFull = false,
    this.rejected = 0,
    this.filesPending = 0,
    this.filesBlocked = false,
  });
  final SyncPhase phase;
  final SyncProfile? profile;
  final DateTime? lastSyncAt;

  /// Số bản ghi chờ đẩy.
  final int pending;

  /// Mã lỗi gần nhất ([ApiException.code]) - giao diện dịch theo mã.
  final String? error;
  final SyncBlock? block;
  final bool quotaFull;
  final int rejected;

  /// Ảnh đính kèm chờ tải lên (đang an toàn trên máy); [filesBlocked]: máy chủ trả 402 cần TsuDEV Pro.
  final int filesPending;
  final bool filesBlocked;

  bool get signedIn => phase != SyncPhase.signedOut;

  SyncState copyWith({
    SyncPhase? phase,
    SyncProfile? profile,
    DateTime? lastSyncAt,
    int? pending,
    String? error,
    bool clearError = false,
    SyncBlock? block,
    bool clearBlock = false,
    bool? quotaFull,
    int? rejected,
    int? filesPending,
    bool? filesBlocked,
  }) => SyncState(
    phase: phase ?? this.phase,
    profile: profile ?? this.profile,
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    pending: pending ?? this.pending,
    error: clearError ? null : (error ?? this.error),
    block: clearBlock ? null : (block ?? this.block),
    quotaFull: quotaFull ?? this.quotaFull,
    rejected: rejected ?? this.rejected,
    filesPending: filesPending ?? this.filesPending,
    filesBlocked: filesBlocked ?? this.filesBlocked,
  );
}

/// Tài khoản mã hóa đang có trên máy chủ (cho thiết bị mới nhận về).
final class RemoteAccount {
  const RemoteAccount(this.bundle, this.wrappedAccountKey, this.walletKeys);
  final Map<String, Object?> bundle;
  final Uint8List wrappedAccountKey;
  final Map<String, Uint8List> walletKeys;
}

final syncProvider = NotifierProvider<SyncController, SyncState>(SyncController.new);

/// Điều phối đăng nhập + đồng bộ nền (P6, ADR-0011). Chỉ đồng bộ khi kho khóa đang mở.
final class SyncController extends Notifier<SyncState> {
  late ApiClient _api;
  Timer? _debounce;
  Timer? _periodic;
  Future<void>? _running;
  Future<void>? _queued;

  static const _mProfile = 'sync.profile';
  static const debounceDelay = Duration(seconds: 4);
  static const periodicEvery = Duration(minutes: 10);

  ApiClient get api => _api;

  @override
  SyncState build() {
    final services = ref.watch(servicesProvider);
    final config = ref.watch(syncConfigProvider);
    _api = ApiClient(
      client: config.httpClient,
      tokens: KeyStorageTokenStore(services.keyStorage),
      base: config.server,
      cookieMode: config.cookieMode,
      mapTransportError: mapSyncTransportError,
    )..onSessionEnded = _onSessionEnded;
    ref.onDispose(() {
      _debounce?.cancel();
      _periodic?.cancel();
    });
    if (config.autoSync) {
      ref.listen(sessionProvider, (_, s) => _onSession(s));
      ref.listen(ledgerProvider, (_, _) => _onLocalChange());
    }
    final raw = services.store.getMeta(_mProfile);
    final profile = raw == null ? null : SyncProfile.fromJson((jsonDecode(utf8.decode(raw)) as Map).cast());
    if (profile == null) return const SyncState();
    // Hồ sơ còn nhưng token đã mất (kho bí mật bị xóa): kiểm ở lượt đồng bộ đầu - lỗi 401 ⇒ về signedOut.
    if (config.autoSync) Future.microtask(() => _onSession(ref.read(sessionProvider)));
    return SyncState(phase: SyncPhase.idle, profile: profile, pending: services.store.dirtyCount);
  }

  void _onSession(SessionStatus s) {
    _periodic?.cancel();
    if (s != SessionStatus.unlocked || !state.signedIn) return;
    unawaited(syncNow());
    _periodic = Timer.periodic(periodicEvery, (_) => unawaited(syncNow()));
  }

  void _onLocalChange() {
    if (!state.signedIn || state.phase == SyncPhase.syncing) return;
    final pending = ref.read(servicesProvider).store.dirtyCount;
    if (pending != state.pending) state = state.copyWith(pending: pending);
    if (pending == 0) return;
    _debounce?.cancel();
    _debounce = Timer(debounceDelay, () => unawaited(syncNow()));
  }

  /// App quay lại tiền cảnh.
  void onResume() {
    final last = state.lastSyncAt;
    if (last == null || DateTime.now().difference(last) > const Duration(minutes: 1)) unawaited(syncNow());
  }

  void _onSessionEnded() {
    final services = ref.read(servicesProvider);
    services.store.deleteMeta(_mProfile);
    _periodic?.cancel();
    state = SyncState(error: 'device_revoked', pending: services.store.dirtyCount);
  }

  /// Tải bản mã ảnh [a] từ máy chủ, kiểm mở được rồi mới đệm lại. null = chưa đăng nhập hoặc máy chủ không có.
  Future<Uint8List?> fetchAttachment(Attachment a) async {
    if (!state.signedIn) return null;
    final got = await FileSync(api: _api, store: ref.read(servicesProvider).store).download(a);
    if (got == null) return null;
    return ref.read(repositoryProvider).cacheDownloaded(a, got.$1, got.$2);
  }

  SyncEngine _engine() {
    final s = ref.read(servicesProvider);
    return SyncEngine(
      api: _api,
      store: s.store,
      vault: s.vault,
      book: ref.read(repositoryProvider),
      onApplied: () => ref.read(ledgerProvider.notifier).reload(),
    );
  }

  // ------------------------------------------------------------------ Đăng nhập / đăng xuất

  /// Đăng nhập bằng trình duyệt hệ thống. Trả null nếu thành công, ngược lại mã lỗi để dịch.
  /// [provider]: `google`/`github` ⇒ gợi ý tsudev.com mở thẳng lối đó; null ⇒ tài khoản tsudev (email).
  Future<String?> signIn({String? provider}) async {
    final config = ref.read(syncConfigProvider);
    final base = config.server ?? defaultServer;
    final server = provider == null ? base : base.replace(queryParameters: {'provider': provider});
    if (config.cookieMode) {
      await startWebLogin(server);
      return null;
    }
    try {
      final out = await config.login(server);
      final code = out.callback.code;
      if (code == null) return out.callback.error ?? 'login_failed';
      final grant = await _api.exchangeCode(
        code: code,
        verifier: out.request.verifier,
        redirectUri: out.request.redirectUri,
        platform: out.platform,
        deviceName: 'Quly Thu Chi - ${_platformLabel(out.platform)}',
      );
      final profile = SyncProfile.fromJson(grant.user);
      final services = ref.read(servicesProvider);
      if (services.vault.hasAccount) {
        try {
          _engine().bindUser(profile.userId);
        } on SyncBlockedException catch (e) {
          await _api.logout();
          return e.block.name;
        }
      }
      services.store.putMeta(_mProfile, utf8.encode(jsonEncode(profile.toJson())));
      state = SyncState(phase: SyncPhase.idle, profile: profile, pending: services.store.dirtyCount);
      if (ref.read(sessionProvider) == SessionStatus.unlocked) {
        if (config.autoSync) _onSession(SessionStatus.unlocked);
      }
      return null;
    } on ApiException catch (e) {
      return e.code;
    }
  }

  static String _platformLabel(String p) => switch (p) {
    'android' => 'Android',
    'ios' => 'iOS',
    'macos' => 'macOS',
    'windows' => 'Windows',
    _ => 'Linux',
  };

  /// Web: hỏi máy chủ cookie phiên còn không (gọi lúc mở trang).
  Future<void> refreshWebStatus() async {
    if (!_api.cookieMode) return;
    try {
      final j = (await _api.getJsonPublic('/api/v1/auth/status'))! as Map;
      if (j['signed_in'] != true) return;
      final me = (await _api.getJson('/api/v1/me'))! as Map;
      final profile = SyncProfile.fromJson(me.cast());
      ref.read(servicesProvider).store.putMeta(_mProfile, utf8.encode(jsonEncode(profile.toJson())));
      state = state.copyWith(phase: SyncPhase.idle, profile: profile);
    } on ApiException {
      // Ngoại tuyến: giữ trạng thái.
    }
  }

  /// Đăng xuất: thu hồi thiết bị này trên máy chủ, xóa token và trạng thái đồng bộ. Dữ liệu trên máy GIỮ NGUYÊN.
  Future<void> signOut() async {
    _debounce?.cancel();
    _periodic?.cancel();
    await _api.logout();
    final services = ref.read(servicesProvider);
    services.store.deleteMeta(_mProfile);
    _engine().forgetSyncState();
    // Lần đăng nhập sau phải đẩy lại toàn bộ (tài khoản có thể đã bị xóa trên máy chủ).
    state = SyncState(pending: services.store.dirtyCount);
  }

  // ------------------------------------------------------------------ Thiết bị mới: nhận tài khoản từ máy chủ

  /// null = máy chủ chưa có tài khoản mã hóa (thiết bị này tạo mới rồi đẩy lên).
  Future<RemoteAccount?> fetchRemoteAccount() async {
    final j = (await _api.getJson('/api/v1/keys'))! as Map;
    final account = j['account'] as Map?;
    if (account == null) return null;
    final wallets = <String, Uint8List>{
      for (final w in (j['wallets']! as List).cast<Map<Object?, Object?>>())
        w['wallet_id']! as String: base64.decode(w['wrapped']! as String),
    };
    final acct = wallets.remove(Vault.accountKeyServerId);
    if (acct == null) throw const ApiException(0, ApiException.badResponse);
    return RemoteAccount((account['bundle']! as Map).cast<String, Object?>(), acct, wallets);
  }

  /// Mở tài khoản máy chủ trên thiết bị chưa có tài khoản (sai mật khẩu ⇒ ném lỗi của Vault), rồi đồng bộ.
  Future<void> adoptRemote(RemoteAccount remote, {String? password, List<String>? words}) async {
    final services = ref.read(servicesProvider);
    services.vault.adoptRemoteAccount(
      bundleJson: remote.bundle,
      wrappedAccountKey: remote.wrappedAccountKey,
      walletKeys: remote.walletKeys,
      password: password,
      words: words,
    );
    final profile = state.profile;
    if (profile != null) _engine().bindUser(profile.userId);
    ref.read(sessionProvider.notifier).markUnlocked();
    await syncNow();
  }

  // ------------------------------------------------------------------ Đồng bộ

  /// Chạy một lượt. Gọi khi đang chạy ⇒ xếp ĐÚNG MỘT lượt nữa sau lượt hiện tại và chờ lượt đó (thay đổi mới nhất
  /// chắc chắn được gửi). Lỗi được ghi vào [state], không ném ra.
  Future<void> syncNow() {
    final running = _running;
    if (running != null) {
      return _queued ??= running.then((_) {
        _queued = null;
        return syncNow();
      });
    }
    return _running = _run().whenComplete(() => _running = null);
  }

  Future<void> _run() async {
    final services = ref.read(servicesProvider);
    if (!state.signedIn || !services.vault.isUnlocked) return;
    _debounce?.cancel();
    state = state.copyWith(phase: SyncPhase.syncing, clearError: true);
    try {
      final engine = _engine();
      final profile = state.profile;
      if (profile != null) engine.bindUser(profile.userId);
      final report = await engine.run();
      if (!state.signedIn) return;
      state = state.copyWith(
        phase: SyncPhase.idle,
        lastSyncAt: DateTime.now(),
        pending: services.store.dirtyCount,
        clearBlock: true,
        quotaFull: report.quotaFull || report.files.quotaFull,
        rejected: report.rejected,
        filesPending: report.files.pending,
        filesBlocked: report.files.blocked,
      );
      ref.read(ledgerProvider.notifier).pruneAttachmentCache();
      if (report.shared != null) ref.read(sharedWalletsProvider.notifier).set(report.shared!, report.badInvites);
    } on SyncBlockedException catch (e) {
      _periodic?.cancel();
      state = state.copyWith(phase: SyncPhase.blocked, block: e.block, pending: services.store.dirtyCount);
    } on ApiException catch (e) {
      if (!state.signedIn) return; // phiên đã kết thúc trong lúc chạy (_onSessionEnded đã đặt trạng thái)
      state = state.copyWith(phase: SyncPhase.error, error: e.code, pending: services.store.dirtyCount);
    } on StateError {
      // Khóa app giữa chừng: thôi, lượt mở khóa sau chạy lại.
      if (state.signedIn) state = state.copyWith(phase: SyncPhase.idle);
    }
  }

  // ------------------------------------------------------------------ Màn Tài khoản

  Future<Map<String, Object?>> me() async => ((await _api.getJson('/api/v1/me'))! as Map).cast();
  Future<Map<String, Object?>> usage() async => ((await _api.getJson('/api/v1/me/usage'))! as Map).cast();
  Future<List<Map<String, Object?>>> devices() async => [
    for (final d in ((await _api.getJson('/api/v1/me/devices'))! as Map)['devices']! as List)
      (d as Map).cast<String, Object?>(),
  ];
  Future<void> revokeDevice(String id) => _api.delete('/api/v1/me/devices/$id');
  Future<Uint8List> exportServerData() => _api.getBytes('/api/v1/me/export');
  Future<void> requestDeletion() => _api.postJson('/api/v1/me/deletion');
  Future<void> cancelDeletion() async {
    await _api.delete('/api/v1/me/deletion');
    if (state.block == SyncBlock.pendingDeletion) unawaited(syncNow());
  }

  // ------------------------------------------------------------------ Ví chung (P9, ADR-0015)

  /// Chạy một thao tác ví chung khi đã đăng nhập + mở khóa, sau lượt đồng bộ đang chạy (không ghi chồng CSDL).
  Future<T> _shared<T>(Future<T> Function(SyncEngine e) body) async {
    if (!state.signedIn) throw const SharingException('notSignedIn');
    final running = _running;
    if (running != null) await running;
    final engine = _engine();
    final profile = state.profile;
    if (profile != null) engine.bindUser(profile.userId);
    final out = await body(engine);
    return out;
  }

  Future<void> _afterShared(SyncEngine e) async {
    final (overview, bad) = await e.refreshShared();
    ref.read(sharedWalletsProvider.notifier).set(overview, bad);
    unawaited(syncNow());
  }

  Future<void> refreshShared() => _shared(_afterShared);

  Future<void> shareWallet(String walletId) => _shared((e) async {
    await e.shareWallet(walletId);
    await _afterShared(e);
  });

  Future<InviteCode> createInvite(String walletId, WalletRole role) => _shared((e) async {
    final code = await e.createInvite(walletId, role);
    await _afterShared(e);
    return code;
  });

  Future<void> cancelInvite(String walletId, String inviteId) => _shared((e) async {
    await e.cancelInvite(walletId, inviteId);
    await _afterShared(e);
  });

  Future<void> changeRole(String walletId, String userId, WalletRole role) => _shared((e) async {
    await e.changeRole(walletId, userId, role);
    await _afterShared(e);
  });

  /// Thu hồi thành viên = xoay khóa ví (ADR-0015 mục 5).
  Future<void> removeMember(String walletId, String userId) => _shared((e) async {
    final (overview, _) = await e.refreshShared();
    final w = overview.wallet(walletId);
    if (w == null) throw const SharingException('missingKey');
    await e.rotateWalletKey(w, remove: {userId});
    await _afterShared(e);
  });

  Future<InvitePreview> previewInvite(InviteCode code) => _shared((e) => e.previewInvite(code));

  Future<void> acceptInvite(InvitePreview p) => _shared((e) async {
    await e.acceptInvite(p);
    await _afterShared(e);
  });

  Future<void> leaveWallet(String walletId) => _shared((e) async {
    await e.leaveWallet(walletId);
    await _afterShared(e);
  });
}

/// Ảnh chụp ví chung gần nhất (từ lượt đồng bộ hoặc thao tác ví chung) - chỉ trong bộ nhớ.
final class SharedWalletsState {
  const SharedWalletsState({this.overview, this.badInvites = 0});
  final SharedOverview? overview;
  final int badInvites;
}

final sharedWalletsProvider = NotifierProvider<SharedWalletsNotifier, SharedWalletsState>(SharedWalletsNotifier.new);

final class SharedWalletsNotifier extends Notifier<SharedWalletsState> {
  @override
  SharedWalletsState build() => const SharedWalletsState();

  void set(SharedOverview overview, int badInvites) =>
      state = SharedWalletsState(overview: overview, badInvites: badInvites);
}
