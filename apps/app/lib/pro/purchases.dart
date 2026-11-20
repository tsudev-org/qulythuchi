import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Mã sản phẩm Google Play của hợp đồng chung (PRODUCT_POLICY 7.4) - KHÔNG có gói tháng `thang`.
abstract final class PlayIds {
  static const pro = 'tsudev_pro';

  /// Gói cơ sở TRẢ TRƯỚC 1 năm (P1Y), không tự gia hạn; gia hạn = nạp thêm.
  static const proBasePlan = 'nam';
  static const donations = ['ung_ho_20k', 'ung_ho_50k', 'ung_ho_100k', 'ung_ho_200k'];
  static const all = {pro, ...donations};
}

/// Mức Ủng hộ (đồng, số nguyên) - chỉ để hiển thị ở bản ngoài cửa hàng; bản Play dùng giá cửa hàng trả về.
const donationVnd = {'ung_ho_20k': 20000, 'ung_ho_50k': 50000, 'ung_ho_100k': 100000, 'ung_ho_200k': 200000};

/// Giá Pro trên web (đồng, số nguyên, đã gồm thuế - PRODUCT_POLICY 7.2).
const proWebPriceVnd = 490000;

/// `obfuscatedAccountId` = base64url(SHA-256(`tsudev-pro|` + `sub`)), 43 ký tự (PRODUCT_POLICY 7.4) - tsudev.com so khớp
/// để biên nhận không dùng lại được cho tài khoản khác.
String obfuscatedAccountId(String sub) =>
    base64Url.encode(sha256.convert(utf8.encode('tsudev-pro|$sub')).bytes).replaceAll('=', '');

enum PurchaseOutcome {
  /// tsudev.com đã xác minh ⇒ giao dịch đã hoàn tất.
  verified,

  /// Chờ thanh toán (tiền mặt/chuyển khoản ở Play) hoặc chưa xác minh được - giữ lại, tự thử lại lần mở sau.
  pending,
  cancelled,

  /// Cửa hàng không sẵn sàng / sản phẩm chưa có.
  unavailable,

  /// tsudev.com từ chối biên nhận.
  invalid,
  error,
}

/// Gửi biên nhận lên máy chủ (`POST /api/v1/me/purchases/play`). Trả kết quả để quyết có hoàn tất giao dịch không.
typedef ReceiptVerifier = Future<PurchaseOutcome> Function(String productId, String purchaseToken);

/// Cửa hàng trong app. Chỉ có ở bản cửa hàng; bản ngoài cửa hàng dùng trang tsudev.com.
abstract interface class StorePurchases {
  /// Giá cửa hàng đã định dạng theo id (Play tự quy đổi tiền tệ). Thiếu id ⇒ sản phẩm chưa có.
  Future<Map<String, String>> prices();

  /// Mở luồng mua. [accountId] = [obfuscatedAccountId] của người đang đăng nhập.
  Future<PurchaseOutcome> buy(String productId, {required String accountId});

  /// Nhận giao dịch còn dở (Play giao lại khi mở app) và xác minh bằng [verify]. Gọi một lần.
  void start(ReceiptVerifier verify);
}
