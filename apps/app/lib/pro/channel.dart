import 'package:flutter/foundation.dart';

/// Kênh phát hành của bản build (ADR-0019 mục 3) - quyết định nút mua/gia hạn/ủng hộ đi đâu (PRODUCT_POLICY 3.3, 4.3).
///
/// - [play]: bản Google Play ⇒ CHỈ Google Play Billing, `MUST NOT` có liên kết thanh toán/ủng hộ ra web.
/// - [appStore]: bản App Store (2027) ⇒ chỉ IAP; IAP chưa làm ⇒ ẩn nút mua, không có liên kết ra web.
/// - [direct]: web, desktop tải trực tiếp, APK ngoài Play ⇒ mở `tsudev.com/pro` / `tsudev.com/ung-ho`.
enum DistChannel {
  play,
  appStore,
  direct;

  /// Bản cửa hàng: không bao giờ dẫn ra thanh toán web.
  bool get isStore => this != direct;

  /// `--dart-define=TSU_CHANNEL=play|appstore|direct`. Không đặt ⇒ Android = [play], iOS = [appStore] (mặc định AN TOÀN
  /// theo luật cửa hàng: quên cờ thì bản cửa hàng không có liên kết web); nền khác = [direct]. APK ngoài Play
  /// `MUST` build với `TSU_CHANNEL=direct`.
  static DistChannel resolve({String raw = _raw, bool web = kIsWeb, TargetPlatform? platform}) {
    switch (raw) {
      case 'play':
        return play;
      case 'appstore':
        return appStore;
      case 'direct':
        return direct;
    }
    if (web) return direct;
    return switch (platform ?? defaultTargetPlatform) {
      TargetPlatform.android => play,
      TargetPlatform.iOS => appStore,
      _ => direct,
    };
  }

  static const _raw = String.fromEnvironment('TSU_CHANNEL');
}

/// `client_id` của sản phẩm ở tsudev.com (`?app=` của trang Pro/Ủng hộ, `aud` của JWS quyền lợi).
const tsudevClientId = 'qulythuchi';

/// Trang Ủng hộ cho bản ngoài cửa hàng (PRODUCT_POLICY 7.4).
Uri donateWebUrl(String clientId) => Uri.https('tsudev.com', '/ung-ho', {'app': clientId});

/// `X-Tsu-Platform` (AUTH_AND_ACCOUNT 14.3).
String tsuPlatform({bool web = kIsWeb, TargetPlatform? platform}) {
  if (web) return 'web';
  return switch (platform ?? defaultTargetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    TargetPlatform.macOS => 'macos',
    TargetPlatform.windows => 'windows',
    _ => 'linux',
  };
}
