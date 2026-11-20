/// Lý do máy chủ trả `402 pro_required` (ADR-0016 mục 4, ADR-0019 mục 5).
enum ProBlock {
  /// Tài khoản không có Pro còn hạn ⇒ mời xem màn Pro.
  noPro,

  /// tsudev.com không còn nhận tài khoản cho client này (grant OIDC quá 30 ngày) ⇒ mời ĐĂNG NHẬP LẠI, không hiện màn Pro.
  reauth,

  /// Ví chung của người khác: chủ ví hết Pro ⇒ báo, không bán Pro cho thành viên.
  ownerNoPro;

  /// `reason` lạ/thiếu ⇒ [noPro] (hợp đồng chung: 402 ⇒ màn Pro).
  static ProBlock parse(String? reason) => switch (reason) {
    'reauth' => reauth,
    'owner_no_pro' => ownerNoPro,
    _ => noPro,
  };

  /// Gộp nhiều lý do trong một lượt: đăng nhập lại > tự mua Pro > chủ ví.
  static ProBlock? worst(ProBlock? a, ProBlock? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.index <= b.index ? a : b;
  }
}
