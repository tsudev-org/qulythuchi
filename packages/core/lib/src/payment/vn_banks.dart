// Danh bạ ngân hàng Việt Nam theo mã BIN NAPAS (VietQR). Sinh từ dữ liệu công khai api.vietqr.io/v2/banks và
// /v2/android-app-deeplinks ngày 19/11/2026. Thêm/sửa: giữ nguyên định dạng, chạy lại test lõi.

/// Một ngân hàng/ví nhận chuyển khoản VietQR.
final class VnBank {
  const VnBank(this.bin, this.shortName, this.name, [this.appId]);

  /// Mã BIN 6 số của NAPAS.
  final String bin;
  final String shortName;
  final String name;

  /// Mã app cho liên kết mở app ngân hàng `https://dl.vietqr.io/pay?app=<appId>` (null = chưa hỗ trợ).
  final String? appId;

  /// Tra theo BIN.
  static VnBank? byBin(String bin) {
    for (final b in all) {
      if (b.bin == bin) return b;
    }
    return null;
  }

  /// Các ngân hàng có app mở được bằng liên kết.
  static Iterable<VnBank> get withApp => all.where((b) => b.appId != null);

  static const all = <VnBank>[
    VnBank('970415', 'VietinBank', 'Ngân hàng TMCP Công thương Việt Nam', 'icb'),
    VnBank('970436', 'Vietcombank', 'Ngân hàng TMCP Ngoại Thương Việt Nam', 'vcb'),
    VnBank('970418', 'BIDV', 'Ngân hàng TMCP Đầu tư và Phát triển Việt Nam', 'bidv'),
    VnBank('970405', 'Agribank', 'Ngân hàng Nông nghiệp và Phát triển Nông thôn Việt Nam', 'vba'),
    VnBank('970448', 'OCB', 'Ngân hàng TMCP Phương Đông', 'ocb'),
    VnBank('970422', 'MBBank', 'Ngân hàng TMCP Quân đội', 'mb'),
    VnBank('970407', 'Techcombank', 'Ngân hàng TMCP Kỹ thương Việt Nam', 'tcb'),
    VnBank('970416', 'ACB', 'Ngân hàng TMCP Á Châu', 'acb'),
    VnBank('970432', 'VPBank', 'Ngân hàng TMCP Việt Nam Thịnh Vượng', 'vpb'),
    VnBank('970423', 'TPBank', 'Ngân hàng TMCP Tiên Phong', 'tpb'),
    VnBank('970403', 'Sacombank', 'Ngân hàng TMCP Sài Gòn Tài Lộc'),
    VnBank('970437', 'HDBank', 'Ngân hàng TMCP Phát triển Thành phố Hồ Chí Minh', 'hdb'),
    VnBank('970454', 'VietCapitalBank', 'Ngân hàng TMCP Bản Việt'),
    VnBank('970429', 'SCB', 'Ngân hàng TMCP Sài Gòn', 'scb'),
    VnBank('970441', 'VIB', 'Ngân hàng TMCP Quốc tế Việt Nam', 'vib-2'),
    VnBank('970443', 'SHB', 'Ngân hàng TMCP Sài Gòn - Hà Nội', 'shb'),
    VnBank('970431', 'Eximbank', 'Ngân hàng TMCP Xuất Nhập khẩu Việt Nam', 'eib'),
    VnBank('970426', 'MSB', 'Ngân hàng TMCP Hàng Hải'),
    VnBank('546034', 'CAKE', 'TMCP Việt Nam Thịnh Vượng - Ngân hàng số CAKE by VPBank', 'cake'),
    VnBank('546035', 'Ubank', 'TMCP Việt Nam Thịnh Vượng - Ngân hàng số Ubank by VPBank'),
    VnBank('963388', 'Timo', 'Ngân hàng số Timo by Ban Viet Bank (Timo by Ban Viet Bank)', 'timo'),
    VnBank(
      '971005',
      'ViettelMoney',
      'Tổng Công ty Dịch vụ số Viettel - Chi nhánh tập đoàn công nghiệp viễn thông Quân Đội',
    ),
    VnBank(
      '971011',
      'VNPTMoney',
      'Trung tâm dịch vụ tài chính số VNPT- Chi nhánh Tổng công ty truyền thông (VNPT Fintech)',
    ),
    VnBank('970400', 'SaigonBank', 'Ngân hàng TMCP Sài Gòn Công Thương', 'sgicb'),
    VnBank('970409', 'BacABank', 'Ngân hàng TMCP Bắc Á'),
    VnBank('971133', 'PVcomBank Pay', 'Ngân hàng số PVcomBank'),
    VnBank('971025', 'MoMo', 'CTCP Dịch Vụ Di Động Trực Tuyến'),
    VnBank('970412', 'PVcomBank', 'Ngân hàng TMCP Đại Chúng Việt Nam', 'pvcb'),
    VnBank('970414', 'MBV', 'Ngân hàng TNHH MTV Việt Nam Hiện Đại', 'mbv'),
    VnBank('970419', 'NCB', 'Ngân hàng TMCP Quốc Dân', 'ncb'),
    VnBank('970424', 'ShinhanBank', 'Ngân hàng TNHH MTV Shinhan Việt Nam', 'shbvn'),
    VnBank('970425', 'ABBANK', 'Ngân hàng TMCP An Bình', 'abb'),
    VnBank('970427', 'VietABank', 'Ngân hàng TMCP Việt Á', 'vab'),
    VnBank('970428', 'NamABank', 'Ngân hàng TMCP Nam Á', 'nab'),
    VnBank('970430', 'PGBank', 'Ngân hàng TMCP Thịnh vượng và Phát triển'),
    VnBank('970433', 'VietBank', 'Ngân hàng TMCP Việt Nam Thương Tín'),
    VnBank('970438', 'BaoVietBank', 'Ngân hàng TMCP Bảo Việt', 'bvb'),
    VnBank('970440', 'SeABank', 'Ngân hàng TMCP Đông Nam Á', 'seab'),
    VnBank('970446', 'COOPBANK', 'Ngân hàng Hợp tác xã Việt Nam', 'coopbank'),
    VnBank('970449', 'LPBank', 'Ngân hàng TMCP Lộc Phát Việt Nam', 'lpb'),
    VnBank('970452', 'KienLongBank', 'Ngân hàng TMCP Kiên Long', 'klb'),
    VnBank('668888', 'KBank', 'Ngân hàng Đại chúng TNHH Kasikornbank'),
    VnBank('970466', 'KEBHanaHCM', 'Ngân hàng KEB Hana – Chi nhánh Thành phố Hồ Chí Minh'),
    VnBank('970467', 'KEBHANAHN', 'Ngân hàng KEB Hana – Chi nhánh Hà Nội'),
    VnBank('977777', 'MAFC', 'Công ty Tài chính TNHH MTV Mirae Asset (Việt Nam) '),
    VnBank('999888', 'VBSP', 'Ngân hàng Chính sách Xã hội'),
    VnBank('963668', 'BNP HN', 'Ngân hàng BNP Paribas – Chi nhánh Hà Nội'),
    VnBank('555666', 'BIDC', 'Ngân hàng Đầu Tư Và Phát Triển Campuchia - Chi nhánh Hà Nội'),
    VnBank('963666', 'BNP HCM', 'Ngân hàng BNP Paribas – Chi nhánh Thành phố Hồ Chí Minh'),
    VnBank('971101', 'ZaloPay', 'Ví điện tử ZaloPay'),
    VnBank('963688', 'BOCHK', 'Ngân hàng Bank of China (Hong Kong) Limited – Chi nhánh Hồ Chí Minh'),
    VnBank('970465', 'BSP', 'Ngân hàng SinoPac - Chi nhánh Thành phố Hồ Chí Minh'),
    VnBank('168999', 'CUBHCM', 'Ngân hàng Cathay United Bank – Chi nhánh Hồ Chí Minh'),
    VnBank('963686', 'ESUN', 'Ngân hàng Thương mại TNHH E.SUN – Chi nhánh Đồng Nai (ESUNBANK)'),
    VnBank('963669', 'ICBC', 'Ngân hàng Công thương Trung Quốc – Chi nhánh thành phố Hà Nội'),
    VnBank('971032', 'MVAS', 'Trung tâm Dịch vụ số Mobifone – Chi nhánh Tổng Công ty viễn thông Mobifone'),
    VnBank('963326', 'TNEX', 'TNEX by MSB'),
    VnBank('458761', 'HSBC', 'Ngân hàng TNHH MTV HSBC (Việt Nam)'),
    VnBank('970442', 'HongLeong', 'Ngân hàng TNHH MTV Hong Leong Việt Nam'),
    VnBank('970455', 'IBKHN', 'Ngân hàng Công nghiệp Hàn Quốc - Chi nhánh Hà Nội'),
    VnBank('970456', 'IBKHCM', 'Ngân hàng Công nghiệp Hàn Quốc - Chi nhánh TP. Hồ Chí Minh'),
    VnBank('970434', 'IndovinaBank', 'Ngân hàng TNHH Indovina'),
    VnBank('970406', 'Vikki', 'Ngân hàng TNHH Một thành viên số Vikki'),
    VnBank('801011', 'Nonghyup', 'Ngân hàng Nonghyup - Chi nhánh Hà Nội'),
    VnBank('796500', 'DBSBank', 'DBS Bank Ltd - Chi nhánh Thành phố Hồ Chí Minh'),
    VnBank('970439', 'PublicBank', 'Ngân hàng TNHH MTV Public Việt Nam', 'pbvn'),
    VnBank('970410', 'StandardChartered', 'Ngân hàng TNHH MTV Standard Chartered Bank Việt Nam'),
    VnBank('533948', 'Citibank', 'Ngân hàng Citibank, N.A. - Chi nhánh Hà Nội'),
    VnBank('422589', 'CIMB', 'Ngân hàng TNHH MTV CIMB Việt Nam', 'cimb'),
    VnBank('970458', 'UnitedOverseas', 'Ngân hàng United Overseas - Chi nhánh TP. Hồ Chí Minh'),
    VnBank(
      '970444',
      'CBBank',
      'Ngân hàng Thương mại trách nhiệm hữu hạn một thành viên Ngoại thương Công nghệ số (Vietcombank Neo Limited)',
    ),
    VnBank('970408', 'GPBank', 'Ngân hàng Thương mại TNHH MTV Dầu Khí Toàn Cầu'),
    VnBank('970421', 'VRB', 'Ngân hàng Liên doanh Việt - Nga'),
    VnBank('970457', 'Woori', 'Ngân hàng TNHH MTV Woori Việt Nam', 'wvn'),
    VnBank('970462', 'KookminHN', 'Ngân hàng Kookmin - Chi nhánh Hà Nội'),
    VnBank('970463', 'KookminHCM', 'Ngân hàng Kookmin - Chi nhánh Thành phố Hồ Chí Minh'),
  ];
}
