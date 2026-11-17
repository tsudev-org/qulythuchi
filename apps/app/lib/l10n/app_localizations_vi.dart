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

  @override
  String get navPlan => 'Kế hoạch';

  @override
  String get navMore => 'Thêm';

  @override
  String get planBudgets => 'Ngân sách';

  @override
  String get planJars => '6 hũ';

  @override
  String get planGoals => 'Mục tiêu';

  @override
  String get budgetNew => 'Ngân sách mới';

  @override
  String get budgetEdit => 'Sửa ngân sách';

  @override
  String get budgetName => 'Tên ngân sách';

  @override
  String get budgetAmount => 'Hạn mức mỗi kỳ';

  @override
  String get budgetPeriod => 'Chu kỳ';

  @override
  String get periodWeekly => 'Hằng tuần';

  @override
  String get periodMonthly => 'Hằng tháng';

  @override
  String get periodYearly => 'Hằng năm';

  @override
  String get periodCustom => 'Tùy chọn';

  @override
  String get budgetStartDay => 'Ngày bắt đầu kỳ (1-31)';

  @override
  String get budgetStartWeekday => 'Kỳ bắt đầu vào';

  @override
  String get budgetFrom => 'Từ ngày';

  @override
  String get budgetTo => 'Đến ngày';

  @override
  String get budgetCategories => 'Danh mục áp dụng';

  @override
  String get budgetAllCategories => 'Mọi khoản chi';

  @override
  String get budgetWallets => 'Ví áp dụng';

  @override
  String get budgetAllWallets => 'Mọi ví cùng tiền tệ';

  @override
  String get budgetRollover => 'Chuyển phần dư/vượt sang kỳ sau';

  @override
  String get budgetAlertAt => 'Cảnh báo khi dùng tới (%)';

  @override
  String budgetSpentOf(String spent, String limit) {
    return 'Đã chi $spent / $limit';
  }

  @override
  String budgetRemaining(String amount) {
    return 'Còn $amount';
  }

  @override
  String budgetOver(String amount) {
    return 'Vượt $amount';
  }

  @override
  String budgetDaily(String amount) {
    return 'Mỗi ngày còn được tiêu $amount';
  }

  @override
  String get budgetStateOk => 'Trong hạn mức';

  @override
  String get budgetStateWarning => 'Sắp hết hạn mức';

  @override
  String get budgetStateOver => 'Đã vượt hạn mức';

  @override
  String budgetDeleteConfirm(String name) {
    return 'Xóa ngân sách \"$name\"?';
  }

  @override
  String get emptyBudgetsTitle => 'Chưa có ngân sách';

  @override
  String get emptyBudgetsBody => 'Đặt hạn mức chi theo tháng/tuần cho cả ví hoặc từng danh mục (phương pháp phong bì).';

  @override
  String jarsIncomeThisMonth(String currency) {
    return 'Thu nhập tháng này ($currency)';
  }

  @override
  String get jarsSimulate => 'Thử chia một khoản thu';

  @override
  String get jarsEdit => 'Sửa tỉ lệ các hũ';

  @override
  String get jarsReset => 'Về mặc định 6 hũ';

  @override
  String jarsTotalMustBe100(String total) {
    return 'Tổng tỉ lệ phải đúng 100% (hiện $total%)';
  }

  @override
  String jarsNoIncome(String currency) {
    return 'Chưa có khoản thu nào tháng này bằng $currency.';
  }

  @override
  String get jarNec => 'Thiết yếu';

  @override
  String get jarLts => 'Tiết kiệm dài hạn';

  @override
  String get jarEdu => 'Giáo dục';

  @override
  String get jarPly => 'Hưởng thụ';

  @override
  String get jarFfa => 'Tự do tài chính';

  @override
  String get jarGiv => 'Cho đi';

  @override
  String get jarsNote => 'Phương pháp 6 hũ: chia mọi khoản thu theo tỉ lệ cố định để chi tiêu có kỷ luật.';

  @override
  String get goalNew => 'Mục tiêu mới';

  @override
  String get goalEdit => 'Sửa mục tiêu';

  @override
  String get goalName => 'Tên mục tiêu';

  @override
  String get goalTarget => 'Số tiền cần';

  @override
  String get goalStarting => 'Đã có sẵn';

  @override
  String get goalDeadline => 'Hạn hoàn thành';

  @override
  String get goalNoDeadline => 'Không có hạn';

  @override
  String get goalAchieved => 'Đã hoàn thành';

  @override
  String goalProgress(String saved, String target, String percent) {
    return '$saved / $target ($percent%)';
  }

  @override
  String goalMonthly(String amount) {
    return 'Cần góp $amount mỗi tháng để kịp hạn';
  }

  @override
  String get goalContribute => 'Góp tiền';

  @override
  String goalDeleteConfirm(String name) {
    return 'Xóa mục tiêu \"$name\"? Giao dịch đã góp vẫn giữ nguyên.';
  }

  @override
  String get emptyGoalsTitle => 'Chưa có mục tiêu';

  @override
  String get emptyGoalsBody => 'Đặt mục tiêu tiết kiệm (mua xe, du lịch…) và theo dõi tiến độ.';

  @override
  String get clearValue => 'Bỏ chọn';

  @override
  String get selectAll => 'Tất cả';

  @override
  String get none => 'Không';

  @override
  String get moreRecurring => 'Định kỳ và hóa đơn';

  @override
  String get moreDebts => 'Sổ nợ / cho vay';

  @override
  String get moreEvents => 'Sự kiện, chuyến đi';

  @override
  String get moreRates => 'Tỉ giá';

  @override
  String get recurringNew => 'Khoản định kỳ mới';

  @override
  String get recurringEdit => 'Sửa khoản định kỳ';

  @override
  String get recurringName => 'Tên khoản';

  @override
  String get recurringFrequency => 'Lặp lại';

  @override
  String get freqDaily => 'Hằng ngày';

  @override
  String get freqWeekly => 'Hằng tuần';

  @override
  String get freqMonthly => 'Hằng tháng';

  @override
  String get freqYearly => 'Hằng năm';

  @override
  String get recurringInterval => 'Mỗi bao nhiêu kỳ';

  @override
  String get recurringStart => 'Bắt đầu từ';

  @override
  String get recurringUntil => 'Kết thúc (không bắt buộc)';

  @override
  String get recurringIsBill => 'Là hóa đơn (hiện trong lịch hóa đơn, có nhắc)';

  @override
  String get recurringAuto => 'Tự ghi giao dịch khi đến hạn';

  @override
  String get recurringAutoOff => 'Tắt: giao dịch được tạo ở trạng thái chờ bạn xác nhận';

  @override
  String get recurringRemind => 'Nhắc trước (ngày)';

  @override
  String get recurringPaused => 'Tạm dừng';

  @override
  String recurringNext(String date) {
    return 'Lần tới: $date';
  }

  @override
  String get recurringEnded => 'Đã kết thúc';

  @override
  String recurringDeleteConfirm(String name) {
    return 'Xóa khoản \"$name\"? Giao dịch đã tạo vẫn giữ nguyên.';
  }

  @override
  String get emptyRecurringTitle => 'Chưa có khoản định kỳ';

  @override
  String get emptyRecurringBody => 'Thêm tiền nhà, điện nước, lương… để app tự ghi và nhắc trước hạn.';

  @override
  String get billsUpcoming => 'Hóa đơn sắp đến hạn';

  @override
  String billDueIn(String date, int days) {
    return 'Đến hạn $date (còn $days ngày)';
  }

  @override
  String get billDueToday => 'Đến hạn hôm nay';

  @override
  String get billPay => 'Đã trả';

  @override
  String get billPaid => 'Đã ghi nhận thanh toán';

  @override
  String pendingTitle(int n) {
    return 'Chờ xác nhận ($n)';
  }

  @override
  String get pendingConfirm => 'Xác nhận';

  @override
  String get pendingSkip => 'Bỏ qua';

  @override
  String get pendingBanner => 'Giao dịch tự tạo, chưa tính vào số dư.';

  @override
  String get budgetAlertsTitle => 'Ngân sách cần chú ý';

  @override
  String get debtNew => 'Khoản nợ mới';

  @override
  String get debtEdit => 'Khoản nợ';

  @override
  String get debtKind => 'Loại';

  @override
  String get debtLend => 'Cho vay';

  @override
  String get debtBorrow => 'Đi vay';

  @override
  String get debtCounterparty => 'Người vay / cho vay';

  @override
  String get debtPrincipal => 'Số tiền gốc';

  @override
  String get debtStart => 'Ngày vay';

  @override
  String get debtDue => 'Hạn trả';

  @override
  String get debtInterest => 'Lãi suất năm (%)';

  @override
  String get debtRecordDisbursement => 'Ghi giao dịch tiền ra/vào ví ngay';

  @override
  String debtPaid(String amount) {
    return 'Đã trả $amount';
  }

  @override
  String debtRemaining(String amount) {
    return 'Còn lại $amount';
  }

  @override
  String get debtSettled => 'Đã tất toán';

  @override
  String get debtRecordPayment => 'Ghi nhận trả nợ';

  @override
  String get debtCollect => 'Ghi nhận thu nợ';

  @override
  String get debtClose => 'Đóng khoản nợ';

  @override
  String get debtClosed => 'Đã đóng';

  @override
  String get debtOverdue => 'Quá hạn';

  @override
  String get debtPayments => 'Lịch sử thanh toán';

  @override
  String debtDeleteConfirm(String name) {
    return 'Xóa khoản nợ với \"$name\"? Giao dịch đã ghi vẫn giữ nguyên.';
  }

  @override
  String get emptyDebtsTitle => 'Chưa có khoản nợ nào';

  @override
  String get emptyDebtsBody => 'Ghi lại tiền cho vay, đi vay và theo dõi trả dần.';

  @override
  String get debtsLendTotal => 'Đang cho vay';

  @override
  String get debtsBorrowTotal => 'Đang nợ';

  @override
  String get eventNew => 'Sự kiện mới';

  @override
  String get eventEdit => 'Sự kiện';

  @override
  String get eventName => 'Tên sự kiện / chuyến đi';

  @override
  String get eventStart => 'Bắt đầu';

  @override
  String get eventEnd => 'Kết thúc';

  @override
  String get eventBudget => 'Ngân sách (không bắt buộc)';

  @override
  String get eventBudgetCurrency => 'Tiền tệ ngân sách';

  @override
  String eventSpent(String amount) {
    return 'Đã chi $amount';
  }

  @override
  String get eventTxns => 'Giao dịch của sự kiện';

  @override
  String eventDeleteConfirm(String name) {
    return 'Xóa sự kiện \"$name\"? Giao dịch vẫn giữ nguyên.';
  }

  @override
  String get emptyEventsTitle => 'Chưa có sự kiện';

  @override
  String get emptyEventsBody => 'Gắn giao dịch vào chuyến đi, đám cưới… để tổng kết riêng.';

  @override
  String get txnEvent => 'Sự kiện';

  @override
  String get txnGoal => 'Góp cho mục tiêu';

  @override
  String get ratesBase => 'Tiền tệ quy đổi tổng';

  @override
  String get ratesNew => 'Thêm tỉ giá';

  @override
  String get ratesFrom => 'Từ tiền tệ';

  @override
  String ratesValue(String from, String to) {
    return '1 $from = ? $to';
  }

  @override
  String get ratesInvalid => 'Tỉ giá không hợp lệ';

  @override
  String get ratesNote => 'Tỉ giá nhập tay. Tự cập nhật qua máy chủ Quly Thu Chi sẽ có khi bật đồng bộ.';

  @override
  String ratesMissing(String codes) {
    return 'Chưa có tỉ giá cho: $codes';
  }

  @override
  String get emptyRatesTitle => 'Chưa có tỉ giá';

  @override
  String get emptyRatesBody => 'Chỉ cần khi bạn có ví bằng nhiều loại tiền.';

  @override
  String overviewTotalIn(String currency) {
    return 'Tổng quy đổi ($currency)';
  }

  @override
  String get errAlertRange => 'Ngưỡng cảnh báo từ 10% đến 100%';

  @override
  String get errDateRange => 'Ngày kết thúc phải sau ngày bắt đầu';

  @override
  String get errSameCurrency => 'Hai tiền tệ phải khác nhau';

  @override
  String get errRateInvalid => 'Giá trị không hợp lệ';

  @override
  String get errRemindRange => 'Số ngày nhắc từ 0 đến 30';

  @override
  String get errNotFound => 'Không còn tồn tại';

  @override
  String get errWalletLocked => 'Không đổi được ví của khoản này';

  @override
  String get weekday1 => 'Thứ Hai';

  @override
  String get weekday2 => 'Thứ Ba';

  @override
  String get weekday3 => 'Thứ Tư';

  @override
  String get weekday4 => 'Thứ Năm';

  @override
  String get weekday5 => 'Thứ Sáu';

  @override
  String get weekday6 => 'Thứ Bảy';

  @override
  String get weekday7 => 'Chủ Nhật';

  @override
  String get notifBillTitle => 'Hóa đơn sắp đến hạn';

  @override
  String get notifBillBody => 'Mở Quly Thu Chi để xem chi tiết.';

  @override
  String get settingsNotifications => 'Nhắc hóa đơn';

  @override
  String get settingsNotificationsSub => 'Thông báo không chứa tên hay số tiền, để không lộ trên màn hình khóa';

  @override
  String get pendingLabel => 'Chờ xác nhận';

  @override
  String get navReports => 'Báo cáo';

  @override
  String get reportThisMonth => 'Tháng này';

  @override
  String get reportLastMonth => 'Tháng trước';

  @override
  String get reportLast3Months => '3 tháng gần đây';

  @override
  String get reportThisYear => 'Năm nay';

  @override
  String get reportIncome => 'Thu';

  @override
  String get reportExpense => 'Chi';

  @override
  String get reportNet => 'Chênh lệch';

  @override
  String get reportSavingsRate => 'Tỉ lệ tiết kiệm';

  @override
  String get reportMonthly => 'Thu chi 6 tháng gần đây';

  @override
  String get reportByCategory => 'Chi theo danh mục';

  @override
  String get reportNetWorth => 'Tài sản ròng';

  @override
  String reportCalendar(String month) {
    return 'Lịch chi tiêu $month';
  }

  @override
  String get reportOther => 'Khác';

  @override
  String reportMonthReadout(String month, String income, String expense) {
    return 'Tháng $month: thu $income · chi $expense';
  }

  @override
  String reportPointReadout(String month, String amount) {
    return 'Tháng $month: $amount';
  }

  @override
  String reportDayReadout(String date, String amount) {
    return '$date: chi $amount';
  }

  @override
  String get reportTapDay => 'Chạm vào một ngày để xem số tiền';

  @override
  String get reportEmpty => 'Chưa có khoản chi nào trong kỳ này';

  @override
  String get reportShowTable => 'Xem dạng bảng';

  @override
  String get reportShowChart => 'Xem biểu đồ';

  @override
  String get reportColMonth => 'Tháng';

  @override
  String get reportColCategory => 'Danh mục';

  @override
  String get reportColAmount => 'Số tiền';

  @override
  String get reportColShare => 'Tỉ trọng';

  @override
  String get reportColDay => 'Ngày';

  @override
  String get reportLess => 'Ít';

  @override
  String get reportMore => 'Nhiều';

  @override
  String get weekdayShort1 => 'T2';

  @override
  String get weekdayShort2 => 'T3';

  @override
  String get weekdayShort3 => 'T4';

  @override
  String get weekdayShort4 => 'T5';

  @override
  String get weekdayShort5 => 'T6';

  @override
  String get weekdayShort6 => 'T7';

  @override
  String get weekdayShort7 => 'CN';

  @override
  String get safeTitle => 'An toàn để tiêu tháng này';

  @override
  String safePerDay(String amount) {
    return 'Khoảng $amount mỗi ngày tới cuối tháng';
  }

  @override
  String safeOver(String amount) {
    return 'Đã vượt kế hoạch tháng $amount';
  }

  @override
  String safeExplain(String income, String spent, String bills, String goals) {
    return 'Thu $income − đã chi $spent − hóa đơn sắp tới $bills − góp mục tiêu $goals';
  }

  @override
  String get filterTitle => 'Bộ lọc';

  @override
  String get filterKinds => 'Loại giao dịch';

  @override
  String get filterAllKinds => 'Mọi loại';

  @override
  String get filterWallets => 'Ví';

  @override
  String get filterAllWallets => 'Mọi ví';

  @override
  String get filterCategories => 'Danh mục';

  @override
  String get filterAllCategories => 'Mọi danh mục';

  @override
  String get filterUncategorized => 'Chỉ giao dịch chưa phân loại';

  @override
  String get filterMin => 'Số tiền từ';

  @override
  String get filterMax => 'Số tiền đến';

  @override
  String get filterApply => 'Áp dụng';

  @override
  String get filterClear => 'Xóa lọc';

  @override
  String get filterSave => 'Lưu bộ lọc';

  @override
  String get filterSaveName => 'Tên bộ lọc';

  @override
  String get filterSaved => 'Bộ lọc đã lưu';

  @override
  String filterActive(int n) {
    return 'Đang lọc: $n điều kiện';
  }

  @override
  String filterResultCount(int n) {
    return '$n giao dịch';
  }

  @override
  String get dataTitle => 'Dữ liệu: xuất, nhập, sao lưu';

  @override
  String get exportTitle => 'Xuất giao dịch';

  @override
  String get exportFormat => 'Định dạng';

  @override
  String get exportWarning => 'Tệp xuất KHÔNG mã hóa: ai có tệp sẽ đọc được toàn bộ giao dịch. Chỉ lưu ở nơi an toàn.';

  @override
  String exportDone(int n) {
    return 'Đã xuất $n giao dịch';
  }

  @override
  String get exportRange => 'Khoảng ngày';

  @override
  String get exportAllTime => 'Toàn bộ';

  @override
  String get exportCancelled => 'Đã hủy';

  @override
  String get importTitle => 'Nhập từ tệp CSV';

  @override
  String get importPick => 'Chọn tệp CSV';

  @override
  String get importMapping => 'Ghép cột';

  @override
  String get importColDate => 'Cột ngày';

  @override
  String get importColAmount => 'Cột số tiền';

  @override
  String get importColNote => 'Cột ghi chú';

  @override
  String get importColCategory => 'Cột danh mục';

  @override
  String get importColType => 'Cột loại (thu/chi)';

  @override
  String get importNone => '(không có)';

  @override
  String get importSignMode => 'Số âm là khoản chi';

  @override
  String get importWallet => 'Nhập vào ví';

  @override
  String importPreview(int n) {
    return 'Xem trước $n dòng đầu';
  }

  @override
  String importRun(int n) {
    return 'Nhập $n giao dịch';
  }

  @override
  String importDone(int ok, int skipped) {
    return 'Đã nhập $ok giao dịch, bỏ qua $skipped dòng lỗi';
  }

  @override
  String get importEmpty => 'Tệp trống hoặc không đọc được';

  @override
  String get importTooBig => 'Tệp quá lớn (tối đa 5 MB)';

  @override
  String get importDateFormat => 'Định dạng ngày';

  @override
  String get backupTitle => 'Sao lưu mã hóa';

  @override
  String get backupBody => 'Tệp sao lưu được mã hóa đầu-cuối; chỉ mở được bằng mật khẩu mã hóa hoặc 24 từ của bạn.';

  @override
  String get backupCreate => 'Tạo tệp sao lưu';

  @override
  String get backupDone => 'Đã lưu tệp sao lưu';

  @override
  String get restoreFromBackup => 'Khôi phục từ tệp sao lưu';

  @override
  String get restoreBackupBody => 'Chọn tệp .qtbak rồi nhập mật khẩu mã hóa của tài khoản đã sao lưu.';

  @override
  String get restoreBackupInvalid => 'Tệp không phải bản sao lưu Quly Thu Chi hoặc đã hỏng';

  @override
  String restoreBackupDone(int n) {
    return 'Đã khôi phục $n bản ghi';
  }

  @override
  String get restoreUseRecovery => 'Dùng 24 từ thay cho mật khẩu';

  @override
  String get exportColSubcategory => 'Danh mục con';

  @override
  String get exportColCurrency => 'Tiền tệ';

  @override
  String get importHasHeader => 'Dòng đầu là tiêu đề cột';

  @override
  String get importNeedWallet => 'Hãy tạo ví trước khi nhập';

  @override
  String get restoreWordsLabel => '24 từ khôi phục';

  @override
  String get backupPrivacyNote =>
      'Tệp sao lưu chứa toàn bộ dữ liệu đã mã hóa và gói khóa; mất mật khẩu và 24 từ thì không ai mở được.';

  @override
  String reportVsPrevious(String pct) {
    return '$pct so với kỳ trước';
  }
}
