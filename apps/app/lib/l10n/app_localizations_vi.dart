// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Quly Thu Chi';

  @override
  String get navOverview => 'Tổng quan';

  @override
  String get navTransactions => 'Giao dịch';

  @override
  String get navWallets => 'Ví';

  @override
  String get navCategories => 'Danh mục';

  @override
  String get navSettings => 'Cài đặt';

  @override
  String get actionSave => 'Lưu';

  @override
  String get actionCancel => 'Hủy';

  @override
  String get actionDelete => 'Xóa';

  @override
  String get actionEdit => 'Sửa';

  @override
  String get actionAdd => 'Thêm';

  @override
  String get actionContinue => 'Tiếp tục';

  @override
  String get actionBack => 'Quay lại';

  @override
  String get actionDone => 'Xong';

  @override
  String get actionCopy => 'Sao chép';

  @override
  String get actionRetry => 'Thử lại';

  @override
  String get loading => 'Đang tải…';

  @override
  String get working => 'Đang xử lý, vui lòng chờ…';

  @override
  String get welcomeTitle => 'Chào mừng tới Quly Thu Chi';

  @override
  String get welcomeBody =>
      'Dữ liệu thu chi của bạn được mã hóa ngay trên thiết bị. Không ai khác, kể cả chúng tôi, đọc được.';

  @override
  String get welcomeStart => 'Bắt đầu';

  @override
  String get welcomeRestore => 'Tôi đã có 24 từ khôi phục';

  @override
  String get setupPasswordTitle => 'Tạo mật khẩu mã hóa';

  @override
  String get setupPasswordBody =>
      'Mật khẩu này mở khóa dữ liệu của bạn. Chúng tôi không thể khôi phục nếu bạn quên - khi đó chỉ 24 từ khôi phục giúp được.';

  @override
  String get passwordLabel => 'Mật khẩu mã hóa';

  @override
  String get passwordConfirmLabel => 'Nhập lại mật khẩu';

  @override
  String passwordTooShort(int min) {
    return 'Cần ít nhất $min ký tự';
  }

  @override
  String get passwordMismatch => 'Hai mật khẩu không khớp';

  @override
  String get passwordWrong => 'Mật khẩu không đúng';

  @override
  String get showPassword => 'Hiện mật khẩu';

  @override
  String get hidePassword => 'Ẩn mật khẩu';

  @override
  String get recoveryTitle => '24 từ khôi phục';

  @override
  String get recoveryBody =>
      'Chép tay 24 từ theo đúng thứ tự và cất nơi an toàn. Ai có 24 từ này sẽ đọc được toàn bộ dữ liệu. App sẽ không hiển thị lại.';

  @override
  String get recoveryConfirmCheck => 'Tôi đã chép lại đủ 24 từ';

  @override
  String get recoveryVerifyTitle => 'Xác nhận từ khôi phục';

  @override
  String get recoveryVerifyBody => 'Chọn đúng từ ở các vị trí được hỏi.';

  @override
  String recoveryWordN(int n) {
    return 'Từ thứ $n';
  }

  @override
  String get recoveryVerifyWrong => 'Chưa đúng. Kiểm tra lại bản chép tay.';

  @override
  String get restoreTitle => 'Khôi phục bằng 24 từ';

  @override
  String get restoreBody => 'Nhập 24 từ cách nhau bằng dấu cách.';

  @override
  String get restoreNeedsSync =>
      'Khôi phục dữ liệu từ máy chủ có ở bản đồng bộ (sắp ra mắt). Hiện tại chỉ mở khóa được dữ liệu trên chính thiết bị này.';

  @override
  String get restoreInvalid => '24 từ không hợp lệ';

  @override
  String get pinSetupTitle => 'Đặt PIN mở nhanh';

  @override
  String get pinSetupBody =>
      'PIN 6-12 chữ số để mở app nhanh trên thiết bị này. Sai 10 lần, PIN bị vô hiệu và cần mật khẩu.';

  @override
  String get pinLabel => 'PIN';

  @override
  String get pinConfirmLabel => 'Nhập lại PIN';

  @override
  String get pinInvalid => 'PIN gồm 6-12 chữ số';

  @override
  String get pinMismatch => 'Hai PIN không khớp';

  @override
  String get pinSkip => 'Để sau';

  @override
  String get lockTitle => 'Đã khóa';

  @override
  String get lockBody => 'Nhập PIN hoặc mật khẩu mã hóa để mở.';

  @override
  String get unlock => 'Mở khóa';

  @override
  String get unlockWithPassword => 'Dùng mật khẩu';

  @override
  String get unlockWithPin => 'Dùng PIN';

  @override
  String get unlockWithBiometric => 'Mở bằng sinh trắc';

  @override
  String get unlockWithRecovery => 'Quên mật khẩu? Dùng 24 từ';

  @override
  String get biometricReason => 'Xác thực để mở Quly Thu Chi';

  @override
  String pinWrong(int n) {
    return 'PIN sai. Còn $n lần thử.';
  }

  @override
  String pinLockedOut(String time) {
    return 'Sai nhiều lần. Thử lại sau $time.';
  }

  @override
  String get pinDisabledMsg => 'PIN đã bị vô hiệu. Hãy mở bằng mật khẩu mã hóa.';

  @override
  String get overviewTotal => 'Tổng số dư';

  @override
  String get overviewWallets => 'Các ví';

  @override
  String get overviewRecent => 'Giao dịch gần đây';

  @override
  String get overviewMonthIncome => 'Thu tháng này';

  @override
  String get overviewMonthExpense => 'Chi tháng này';

  @override
  String get seeAll => 'Xem tất cả';

  @override
  String get emptyWalletsTitle => 'Chưa có ví nào';

  @override
  String get emptyWalletsBody => 'Tạo ví đầu tiên (tiền mặt, tài khoản ngân hàng…) để bắt đầu ghi chép.';

  @override
  String get emptyTxnsTitle => 'Chưa có giao dịch';

  @override
  String get emptyTxnsBody => 'Bấm nút + để ghi khoản thu hoặc chi đầu tiên.';

  @override
  String get noResults => 'Không tìm thấy kết quả';

  @override
  String get hiddenAmount => 'Đã ẩn số tiền';

  @override
  String skippedRecords(int n) {
    return '$n bản ghi không mở được (có thể đã hỏng) và đã được bỏ qua.';
  }

  @override
  String get walletNew => 'Ví mới';

  @override
  String get walletEdit => 'Sửa ví';

  @override
  String get walletName => 'Tên ví';

  @override
  String get walletType => 'Loại ví';

  @override
  String get walletCurrency => 'Tiền tệ';

  @override
  String get walletOpening => 'Số dư ban đầu';

  @override
  String get walletCreditLimit => 'Hạn mức tín dụng';

  @override
  String get walletArchived => 'Lưu trữ (ẩn khỏi danh sách)';

  @override
  String get walletExcludeTotal => 'Không tính vào tổng số dư';

  @override
  String get walletBalance => 'Số dư';

  @override
  String walletDeleteConfirm(String name) {
    return 'Xóa ví \"$name\"?';
  }

  @override
  String get walletTypeCash => 'Tiền mặt';

  @override
  String get walletTypeBank => 'Tài khoản ngân hàng';

  @override
  String get walletTypeCredit => 'Thẻ tín dụng';

  @override
  String get walletTypeEwallet => 'Ví điện tử';

  @override
  String get walletTypeSaving => 'Tiết kiệm';

  @override
  String get walletTypeInvestment => 'Đầu tư';

  @override
  String get walletTypeOther => 'Khác';

  @override
  String get showArchived => 'Hiện ví đã lưu trữ';

  @override
  String get categoryNew => 'Danh mục mới';

  @override
  String get categoryEdit => 'Sửa danh mục';

  @override
  String get categoryName => 'Tên danh mục';

  @override
  String get categoryParent => 'Thuộc nhóm';

  @override
  String get categoryNoParent => '(Nhóm chính)';

  @override
  String get categoryExpense => 'Chi';

  @override
  String get categoryIncome => 'Thu';

  @override
  String categoryDeleteConfirm(String name) {
    return 'Xóa danh mục \"$name\"? Danh mục con cũng bị xóa; giao dịch cũ chuyển thành \"Chưa phân loại\".';
  }

  @override
  String get uncategorized => 'Chưa phân loại';

  @override
  String get txnNew => 'Giao dịch mới';

  @override
  String get txnEdit => 'Sửa giao dịch';

  @override
  String get txnExpense => 'Chi';

  @override
  String get txnIncome => 'Thu';

  @override
  String get txnTransfer => 'Chuyển ví';

  @override
  String get txnAdjustment => 'Điều chỉnh số dư';

  @override
  String get txnAmount => 'Số tiền';

  @override
  String get txnAmountHint => 'Có thể nhập phép tính, ví dụ 50.000+25.000';

  @override
  String txnAmountResult(String value) {
    return '= $value';
  }

  @override
  String get txnAmountInvalid => 'Số tiền không hợp lệ';

  @override
  String get txnAmountPositive => 'Số tiền phải lớn hơn 0';

  @override
  String txnReceived(String currency) {
    return 'Số tiền nhận ($currency)';
  }

  @override
  String get txnFee => 'Phí chuyển';

  @override
  String get txnWallet => 'Ví';

  @override
  String get txnFromWallet => 'Từ ví';

  @override
  String get txnToWallet => 'Tới ví';

  @override
  String get txnCategory => 'Danh mục';

  @override
  String get txnDate => 'Ngày';

  @override
  String get txnNote => 'Ghi chú';

  @override
  String get txnPayee => 'Người nhận / nơi chi';

  @override
  String txnTransferTo(String wallet) {
    return 'Chuyển tới $wallet';
  }

  @override
  String txnTransferFrom(String wallet) {
    return 'Nhận từ $wallet';
  }

  @override
  String get txnDeleteConfirm => 'Xóa giao dịch này?';

  @override
  String get txnDeleteTransferConfirm => 'Xóa cả hai vế của lần chuyển ví này?';

  @override
  String get selectWallet => 'Chọn ví';

  @override
  String get searchHint => 'Tìm ghi chú, danh mục, ví…';

  @override
  String get searchLabel => 'Tìm giao dịch';

  @override
  String get today => 'Hôm nay';

  @override
  String get yesterday => 'Hôm qua';

  @override
  String get settingsAppearance => 'Giao diện';

  @override
  String get themeLight => 'Sáng';

  @override
  String get themeDark => 'Tối';

  @override
  String get themeSystem => 'Hệ thống';

  @override
  String get settingsLanguage => 'Ngôn ngữ';

  @override
  String get settingsPrivacy => 'Riêng tư và bảo mật';

  @override
  String get settingsHideBalance => 'Ẩn số dư';

  @override
  String get settingsHideBalanceSub => 'Che mọi số tiền cho tới khi bạn bật lại';

  @override
  String get settingsPin => 'PIN mở nhanh';

  @override
  String get settingsPinOn => 'Đang bật';

  @override
  String get settingsPinOff => 'Đang tắt';

  @override
  String get settingsPinChange => 'Đổi PIN';

  @override
  String get settingsPinDisable => 'Tắt PIN';

  @override
  String get settingsBiometric => 'Mở khóa bằng sinh trắc';

  @override
  String get settingsBiometricSub => 'Cần bật PIN trước';

  @override
  String get settingsBiometricUnavailable => 'Thiết bị không hỗ trợ sinh trắc';

  @override
  String get settingsQuickUnlockWeb => 'Bản web không có PIN/sinh trắc vì trình duyệt không có kho bí mật an toàn.';

  @override
  String get settingsAutoLock => 'Tự khóa khi rời app hơn 60 giây';

  @override
  String get settingsLockNow => 'Khóa ngay';

  @override
  String get settingsChangePassword => 'Đổi mật khẩu mã hóa';

  @override
  String get settingsOldPassword => 'Mật khẩu hiện tại';

  @override
  String get settingsNewPassword => 'Mật khẩu mới';

  @override
  String get settingsPasswordChanged => 'Đã đổi mật khẩu mã hóa';

  @override
  String get settingsAbout => 'Giới thiệu';

  @override
  String settingsVersion(String version) {
    return 'Phiên bản $version';
  }

  @override
  String get settingsLicense => 'Mã nguồn mở AGPL-3.0';

  @override
  String get settingsReset => 'Xóa toàn bộ dữ liệu trên thiết bị';

  @override
  String get settingsResetConfirm =>
      'Xóa vĩnh viễn mọi ví, danh mục, giao dịch và khóa trên thiết bị này? Không hoàn tác được.';

  @override
  String get settingsResetTypeHint => 'Gõ XOA để xác nhận';

  @override
  String get settingsResetWord => 'XOA';

  @override
  String get saved => 'Đã lưu';

  @override
  String get deleted => 'Đã xóa';

  @override
  String get errNameRequired => 'Vui lòng nhập tên';

  @override
  String get errCurrencyLocked => 'Ví đã có giao dịch, không đổi được tiền tệ';

  @override
  String get errWalletHasTxns => 'Ví còn giao dịch. Hãy lưu trữ ví thay vì xóa.';

  @override
  String get errParentMissing => 'Nhóm cha không còn tồn tại';

  @override
  String get errTwoLevelsOnly => 'Danh mục chỉ có 2 tầng';

  @override
  String get errKindMismatch => 'Danh mục không cùng loại thu/chi';

  @override
  String get errWalletMissing => 'Hãy chọn ví';

  @override
  String get errSameWallet => 'Ví nguồn và ví đích phải khác nhau';

  @override
  String get errReceivedRequired => 'Hai ví khác tiền tệ: nhập số tiền nhận';

  @override
  String get errGeneric => 'Đã có lỗi xảy ra. Vui lòng thử lại.';

  @override
  String get errStorage => 'Không mở được kho dữ liệu an toàn của thiết bị.';

  @override
  String get walletArchivedBadge => 'Đã lưu trữ';

  @override
  String get settingsNewRecovery => 'Cấp 24 từ khôi phục mới';

  @override
  String get settingsNewRecoveryConfirm => 'Bộ 24 từ cũ sẽ hết hiệu lực. Tiếp tục?';

  @override
  String get settingsLanguageSystem => 'Theo hệ thống';

  @override
  String get settingsSecurityNote =>
      'Dữ liệu được mã hóa đầu-cuối bằng libsodium. Mật khẩu và 24 từ không bao giờ rời thiết bị.';

  @override
  String get iconLabel => 'Biểu tượng';
}
