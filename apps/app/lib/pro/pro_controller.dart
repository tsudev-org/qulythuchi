import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:tsudev_ui/tsudev_ui.dart';

import '../state/providers.dart';
import '../state/settings.dart';
import '../state/sync_controller.dart';
import '../sync/api_client.dart';
import 'channel.dart';
import 'play_purchases.dart';
import 'prefs_store.dart';
import 'purchases.dart';

/// Kho khoá-giá trị của `tsudev_ui` (mã cài đặt, JWS đệm, JWKS, mốc nhắc) - nằm trong cài đặt của app.
final tsuStoreProvider = Provider<TsuKeyValueStore>((ref) => PrefsKeyValueStore(ref.watch(sharedPreferencesProvider)));

/// Đồng hồ của phần Pro (test ghi đè để kiểm 7.6 theo ngày).
final proClockProvider = Provider<DateTime Function()>((_) => DateTime.now);

/// Kênh phát hành của bản build (ADR-0019 mục 3).
final distChannelProvider = Provider<DistChannel>((_) => DistChannel.resolve());

/// Cửa hàng trong app: chỉ bản Play (App Store chưa làm - 2027); bản ngoài cửa hàng ⇒ null (dùng trang tsudev.com).
final storePurchasesProvider = Provider<StorePurchases?>(
  (ref) => ref.watch(distChannelProvider) == DistChannel.play ? PlayPurchases() : null,
);

/// Kiểm JWS quyền lợi: ES256 + JWKS của tsudev.com (discovery), `aud` = `qulythuchi` (JWS do tsudev.com cấp cho máy
/// chủ RP của sản phẩm, máy chủ chuyển nguyên văn xuống app - ADR-0019 mục 1).
final entitlementVerifierProvider = Provider<EntitlementVerifier>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return EntitlementVerifier(
    clientId: tsudevClientId,
    jwks: DiscoveryJwks(client: client, store: ref.watch(tsuStoreProvider)),
  );
});

/// MỘT bộ điều khiển nhắc gia hạn cho cả tiến trình, nối vòng đời app (PRODUCT_POLICY 7.6, README `tsudev_ui`).
final proRenewalControllerProvider = Provider<ProRenewalController>((ref) {
  final c = ProRenewalController(store: ref.watch(tsuStoreProvider), clock: ref.watch(proClockProvider));
  final lifecycle = AppLifecycleListener(onStateChange: c.handleAppLifecycleState);
  ref.onDispose(lifecycle.dispose);
  return c;
});

final proNoticeControllerProvider = Provider<ProNoticeController>(
  (ref) => ProNoticeController(store: ref.watch(tsuStoreProvider), clock: ref.watch(proClockProvider)),
);

/// Phần KHÔNG ký của `GET /api/v1/me/entitlements` - chỉ để chọn lời nhắn/ẩn hiện nút, không cấp quyền gì (N4).
@immutable
final class ServerPro {
  const ServerPro({required this.enforce, required this.status, required this.canSync, this.serverDataUntil});

  /// Máy chủ đang bật gate Pro.
  final bool enforce;

  /// `ok` | `reauth` (cần đăng nhập lại để tsudev.com trả quyền lợi) | `unknown`.
  final String status;

  /// `false` ⇒ app KHÔNG gọi đẩy (bản miễn phí không gửi dữ liệu lên mạng, PRODUCT_POLICY 7.1 N2).
  final bool canSync;

  /// Pro đã hết: bản sao trên máy chủ còn kéo/xuất tới mốc này rồi bị xoá (PRODUCT_POLICY 7.2).
  final DateTime? serverDataUntil;

  bool get needsReauth => status == 'reauth';

  static ServerPro fromJson(Map<String, Object?> j) => ServerPro(
    enforce: j['enforce'] == true,
    status: j['status'] is String ? j['status']! as String : 'unknown',
    canSync: j['can_sync'] != false,
    serverDataUntil: j['server_data_until'] is String ? DateTime.tryParse(j['server_data_until']! as String) : null,
  );
}

@immutable
final class ProState {
  const ProState({this.ent = const EntitlementState.free(), this.server, this.checks = 0});

  /// JWS đã kiểm (mạng hoặc đệm ≤ 7 ngày); không có ⇒ miễn phí.
  final EntitlementState ent;
  final ServerPro? server;

  /// Tăng mỗi lần làm mới xong - mốc để màn chính hỏi nhắc gia hạn/thông báo (một lần mỗi lần mở app).
  final int checks;

  bool isPro(DateTime now) => ent.isPro(now);
  TsuBadgeKind get badge => ent.badge;

  /// Đẩy lên máy chủ được không. Chưa biết ⇒ cứ thử (máy chủ tự kiểm, trả 402 nếu không).
  bool get canSync => server?.canSync ?? true;
}

/// Màn chính đang mở khoá ⇒ được hiện lời nhắc Pro.
final proPromptsEnabledProvider = Provider<bool>((ref) => ref.watch(sessionProvider) == SessionStatus.unlocked);

final proProvider = NotifierProvider<ProController, ProState>(ProController.new);

/// Quyền lợi TsuDEV Pro của app (ADR-0019): lấy JWS qua máy chủ sản phẩm, kiểm + đệm bằng `tsudev_ui`.
class ProController extends Notifier<ProState> {
  late EntitlementsRepository _repo;
  ServerPro? _lastServer;
  bool _force = false;
  Future<void>? _running;

  @override
  ProState build() {
    final store = ref.watch(tsuStoreProvider);
    _repo = EntitlementsRepository(
      verifier: ref.watch(entitlementVerifierProvider),
      store: store,
      fetchJws: _fetchJws,
      clock: ref.watch(proClockProvider),
    );
    // Mở app: đọc đệm ngay (ngoại tuyến vẫn biết Pro), rồi làm mới khi đã đăng nhập và mở khoá.
    Future.microtask(_loadCached);
    ref.listen(sessionProvider, (prev, s) {
      if (s == SessionStatus.unlocked && prev != SessionStatus.unlocked) unawaited(refresh());
    });
    ref.listen(syncProvider.select((s) => s.signedIn), (was, now) {
      if (now && was != true) unawaited(refresh());
      if (!now && was == true) unawaited(_signedOut());
    });
    return const ProState();
  }

  Future<void> _loadCached() async {
    final ent = await _repo.current();
    if (state.checks == 0 && state.server == null) state = ProState(ent: ent);
  }

  ApiClient get _api => ref.read(syncProvider.notifier).api;

  Future<String> _fetchJws() async {
    final j = ((await _api.getJson('/api/v1/me/entitlements', _force ? const {'refresh': '1'} : null))! as Map)
        .cast<String, Object?>();
    _lastServer = ServerPro.fromJson(j);
    final jws = j['jws'];
    if (jws is! String) throw const ApiException(200, 'no_jws');
    return jws;
  }

  /// Làm mới quyền lợi (mở app, mở khoá, quay lại app, sau khi mua: [force] ⇒ máy chủ hỏi lại tsudev.com).
  /// Chưa đăng nhập ⇒ chỉ đọc đệm. Không bao giờ ném lỗi.
  Future<void> refresh({bool force = false}) {
    final running = _running;
    if (running != null && !force) return running;
    return _running = _refresh(force).whenComplete(() => _running = null);
  }

  Future<void> _refresh(bool force) async {
    try {
      _lastServer = null;
      _force = force;
      final signedIn = ref.read(syncProvider).signedIn;
      final ent = signedIn ? await _repo.refresh() : await _repo.current();
      state = ProState(ent: ent, server: _lastServer ?? (signedIn ? state.server : null), checks: state.checks + 1);
      ref.read(syncProvider.notifier).setCanSync(state.canSync);
      // Giao dịch Play còn dở (mua lúc mất mạng...) được giao lại khi đã đăng nhập.
      if (signedIn && ent.entitlement != null) _startStore();
    } on Object {
      // Kho cài đặt lỗi... ⇒ giữ trạng thái cũ.
    } finally {
      _force = false;
    }
  }

  bool _storeStarted = false;

  void _startStore() {
    if (_storeStarted) return;
    final store = ref.read(storePurchasesProvider);
    if (store == null) return;
    _storeStarted = true;
    store.start(verifyPlayReceipt);
  }

  /// `sub` tsudev của người đang đăng nhập - lấy từ JWS ĐÃ KIỂM (không tin hồ sơ cục bộ).
  String? get accountSubject => state.ent.entitlement?.subject;

  /// Mua trong app (bản Play). Cần đăng nhập + JWS hợp lệ (để gắn `obfuscatedAccountId`).
  Future<PurchaseOutcome> buy(String productId) async {
    final store = ref.read(storePurchasesProvider);
    final sub = accountSubject;
    if (store == null || sub == null) return PurchaseOutcome.unavailable;
    _startStore();
    return store.buy(productId, accountId: obfuscatedAccountId(sub));
  }

  /// Biên nhận Play ⇒ máy chủ ⇒ tsudev.com (ADR-0019 mục 4). Xác minh xong ⇒ làm mới quyền lợi.
  Future<PurchaseOutcome> verifyPlayReceipt(String productId, String token) async {
    try {
      await _api.postJson('/api/v1/me/purchases/play', {'product_id': productId, 'purchase_token': token});
    } on ApiException catch (e) {
      return e.code == 'purchase_invalid' ? PurchaseOutcome.invalid : PurchaseOutcome.pending;
    }
    await refresh();
    return PurchaseOutcome.verified;
  }

  Future<void> _signedOut() async {
    ref.read(syncProvider.notifier).setCanSync(true);
    await _repo.clear();
    state = ProState(checks: state.checks);
  }
}
