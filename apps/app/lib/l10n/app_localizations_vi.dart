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
  String get settingsMadeBy => 'Một sản phẩm của TsuDEV';

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
  String get importPick => 'Chọn tệp CSV, XLSX hoặc PDF';

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
  String get importTooBig => 'Tệp quá lớn (tối đa 5 MB, PDF 15 MB)';

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

  @override
  String get syncTitle => 'Tài khoản & đồng bộ';

  @override
  String get syncWelcomeSignIn => 'Đăng nhập để lấy dữ liệu đã đồng bộ';

  @override
  String get syncSignIn => 'Đăng nhập bằng tài khoản TsuDEV';

  @override
  String get syncWaitingBrowser => 'Đang chờ đăng nhập trong trình duyệt…';

  @override
  String get syncSignedOutTitle => 'Chưa bật đồng bộ';

  @override
  String get syncSignedOutBody => 'Đăng nhập để sao lưu bản mã lên máy chủ và dùng chung dữ liệu giữa các thiết bị.';

  @override
  String get syncE2eeNote => 'Máy chủ chỉ nhận bản mã. Mật khẩu mã hóa và 24 từ không bao giờ rời thiết bị.';

  @override
  String get syncStatusSyncing => 'Đang đồng bộ…';

  @override
  String get syncStatusNever => 'Chưa đồng bộ lần nào';

  @override
  String syncStatusLast(String time) {
    return 'Đồng bộ lần cuối $time';
  }

  @override
  String syncPending(int n) {
    return '$n thay đổi chờ gửi';
  }

  @override
  String get syncQuotaFull => 'Đã hết dung lượng đồng bộ';

  @override
  String syncRejected(int n) {
    return '$n bản ghi bị máy chủ từ chối';
  }

  @override
  String get syncNow => 'Đồng bộ ngay';

  @override
  String get syncRetry => 'Thử lại';

  @override
  String get syncSignOut => 'Đăng xuất';

  @override
  String get syncSignOutBody => 'Dừng đồng bộ trên thiết bị này. Dữ liệu trên máy vẫn giữ nguyên.';

  @override
  String get syncSignOutConfirm =>
      'Đăng xuất khỏi đồng bộ? Thiết bị này bị thu hồi trên máy chủ; dữ liệu trên máy vẫn giữ nguyên.';

  @override
  String get syncUsage => 'Dung lượng máy chủ';

  @override
  String syncUsageDetail(int count, String recMb, String recQuota, String fileMb, String fileQuota) {
    return '$count bản ghi · $recMb/$recQuota MB · tệp $fileMb/$fileQuota MB';
  }

  @override
  String get syncDevices => 'Thiết bị đang đăng nhập';

  @override
  String get syncThisDevice => 'Thiết bị này';

  @override
  String syncLastSeen(String time) {
    return 'Hoạt động $time';
  }

  @override
  String get syncRevoke => 'Thu hồi';

  @override
  String syncRevokeConfirm(String name) {
    return 'Thu hồi \"$name\"? Thiết bị đó bị đăng xuất ngay và không đồng bộ được nữa.';
  }

  @override
  String get syncExport => 'Xuất dữ liệu máy chủ';

  @override
  String get syncExportBody => 'Tệp JSON mọi thứ máy chủ đang giữ (vẫn là bản mã).';

  @override
  String get syncExportDone => 'Đã lưu tệp xuất';

  @override
  String get syncDeleteAccount => 'Xóa tài khoản đồng bộ';

  @override
  String get syncDeleteBody => 'Xóa toàn bộ dữ liệu trên máy chủ sau 30 ngày. Hủy được trong thời gian chờ.';

  @override
  String get syncDeleteConfirm =>
      'Xóa tài khoản đồng bộ? Sau 30 ngày mọi bản mã, khóa và tệp trên máy chủ bị xóa hẳn. Trong thời gian chờ chỉ đọc được, hủy được. Dữ liệu trên máy này không bị xóa.';

  @override
  String syncDeletionPending(int days) {
    return 'Tài khoản sẽ bị xóa sau $days ngày';
  }

  @override
  String get syncDeletionCancel => 'Hủy xóa';

  @override
  String get syncNoRemoteAccount => 'Tài khoản chưa có dữ liệu đồng bộ. Hãy tạo mật khẩu mã hóa mới.';

  @override
  String get syncUnlockRemoteTitle => 'Mở dữ liệu đã đồng bộ';

  @override
  String get syncUnlockRemoteBody => 'Nhập mật khẩu mã hóa (hoặc 24 từ khôi phục) đã đặt trên thiết bị trước.';

  @override
  String get syncRemoteInvalid => 'Dữ liệu khóa trên máy chủ không hợp lệ.';

  @override
  String get syncErrNetwork => 'Không kết nối được máy chủ. Sẽ thử lại sau.';

  @override
  String get syncErrTls =>
      'Kết nối không an toàn (chứng chỉ máy chủ không khớp). Đồng bộ đã dừng; dữ liệu trên máy vẫn dùng bình thường.';

  @override
  String get syncErrSignedOut => 'Phiên đăng nhập đã hết hoặc thiết bị đã bị thu hồi. Hãy đăng nhập lại.';

  @override
  String get syncErrDenied => 'Bạn đã từ chối đăng nhập.';

  @override
  String get syncErrNoBrowser => 'Không mở được trình duyệt.';

  @override
  String get syncErrRateLimited => 'Thao tác quá nhanh. Hãy thử lại sau ít phút.';

  @override
  String get syncErrGeneric => 'Đồng bộ gặp lỗi. Sẽ thử lại sau.';

  @override
  String get syncBlockDifferentAccount =>
      'Tài khoản đồng bộ đã có dữ liệu mã hóa bằng mật khẩu KHÁC dữ liệu trên máy này. Không trộn hai bộ dữ liệu: hãy sao lưu, rồi đặt lại app và chọn \"Đăng nhập để lấy dữ liệu đã đồng bộ\", hoặc đăng xuất.';

  @override
  String get syncBlockIdentityChanged =>
      'Khóa mã hóa trên máy chủ đã đổi bất thường. Đồng bộ đã dừng để bảo vệ dữ liệu. Nếu bạn không đặt lại tài khoản, hãy báo cho chúng tôi.';

  @override
  String get syncBlockRollback => 'Dữ liệu trên máy chủ bị quay lui bất thường. Đồng bộ đã dừng để bảo vệ dữ liệu.';

  @override
  String get syncBlockPendingDeletion => 'Tài khoản đang chờ xóa - máy chủ không nhận thay đổi mới.';

  @override
  String get syncBlockOtherUser =>
      'Máy này đã đồng bộ với tài khoản TsuDEV khác. Đăng nhập đúng tài khoản đó, hoặc đặt lại app.';

  @override
  String get autoImportTitle => 'Tự nhập';

  @override
  String get autoConfirm => 'Tự xác nhận';

  @override
  String get autoConfirmHint => 'Ghi thẳng vào số dư, không qua hàng chờ. Nên để tắt cho tới khi bạn tin bộ đọc.';

  @override
  String get bankNotifTitle => 'Thông báo ngân hàng';

  @override
  String get bankNotifAndroidOnly => 'Chỉ có trên Android: hệ điều hành khác không cho app đọc thông báo của app khác.';

  @override
  String get bankNotifExplain =>
      'Đọc thông báo biến động số dư của app ngân hàng bạn chọn để tạo giao dịch chờ xác nhận. Nội dung chỉ xử lý trên máy, được mã hóa khi chờ, không gửi đi đâu.';

  @override
  String get bankNotifEnable => 'Đọc thông báo ngân hàng';

  @override
  String get bankNotifDisclosure =>
      'Quly Thu Chi sẽ xin quyền \"Truy cập thông báo\". App chỉ giữ thông báo của các app ngân hàng bạn chọn, bỏ qua mọi app khác và tin OTP, và không gửi nội dung ra khỏi máy. Bạn có thể thu hồi quyền bất cứ lúc nào trong Cài đặt của hệ thống.';

  @override
  String get bankNotifDisclosureOk => 'Đồng ý, tiếp tục';

  @override
  String get bankNotifNoPermission => 'Chưa cấp quyền truy cập thông báo';

  @override
  String get bankNotifGrant => 'Cấp quyền';

  @override
  String get bankNotifAddApp => 'Thêm app ngân hàng';

  @override
  String get bankNotifPickApp => 'Chọn app';

  @override
  String get bankNotifKnownApps => 'Ngân hàng và ví điện tử phổ biến được xếp trước';

  @override
  String bankNotifLastRun(int added, int ignored) {
    return 'Lần gần nhất: thêm $added giao dịch chờ xác nhận, bỏ qua $ignored thông báo';
  }

  @override
  String get captureMobileOnly =>
      'Giọng nói và quét hóa đơn chạy trên điện thoại (Android/iOS), nhận dạng ngay trên máy.';

  @override
  String get importAsPending => 'Đưa vào hàng chờ xác nhận';

  @override
  String get importAsPendingHint => 'Chưa tính vào số dư cho tới khi bạn xác nhận';

  @override
  String get importColDebit => 'Cột ghi nợ (tiền ra)';

  @override
  String get importColCredit => 'Cột ghi có (tiền vào)';

  @override
  String importDoneDup(int ok, int skipped, int dup) {
    return 'Đã nhập $ok giao dịch, bỏ qua $skipped dòng lỗi và $dup dòng đã có';
  }

  @override
  String get quickTitle => 'Ghi nhanh';

  @override
  String get quickExplain =>
      'Gõ hoặc nói một câu như \"ăn trưa 50 nghìn\", \"hôm qua đổ xăng 80k\", \"nhận lương 15 triệu\". App tự tách số tiền, ngày, thu/chi và gợi ý danh mục.';

  @override
  String get quickLabel => 'Câu ghi nhanh';

  @override
  String get quickHint => 'ăn trưa 50 nghìn';

  @override
  String get quickNeedVndWallet => 'Cần một ví VND để ghi nhanh.';

  @override
  String get quickNoAmount => 'Chưa thấy số tiền trong câu';

  @override
  String get quickMaybeDuplicate => 'Có giao dịch giống khoản này trong 1 ngày qua - kiểm tra để tránh ghi trùng.';

  @override
  String get quickSaved => 'Đã ghi';

  @override
  String get scanReceipt => 'Quét hóa đơn';

  @override
  String get scanDefaultNote => 'Hóa đơn';

  @override
  String get scanFailed => 'Không đọc được ảnh';

  @override
  String get scanNoTotal => 'Không tìm thấy tổng tiền trên hóa đơn - hãy gõ số tiền';

  @override
  String get statementTitle => 'Sao kê ngân hàng';

  @override
  String get statementExplain =>
      'Nhập sao kê CSV, XLSX hoặc PDF (kể cả PDF có mật khẩu) tải từ ngân hàng. App tự tìm bảng giao dịch, cột ghi nợ/ghi có, bỏ dòng đã có và gợi ý danh mục.';

  @override
  String get statementOpen => 'Nhập sao kê';

  @override
  String get voiceStart => 'Nói';

  @override
  String get voiceConsent =>
      'Máy này không có bộ nhận dạng giọng nói ngoại tuyến. Có thể dùng dịch vụ nhận dạng của hệ điều hành - âm thanh có thể được gửi tới nhà cung cấp hệ điều hành (Google/Apple). Quly Thu Chi không nhận hay lưu âm thanh. Tiếp tục?';

  @override
  String get voiceConsentOk => 'Dùng dịch vụ hệ điều hành';

  @override
  String get voiceDenied => 'Chưa cấp quyền micro';

  @override
  String get voiceUnavailable => 'Không nhận dạng được giọng nói';

  @override
  String get moreAutoImport => 'Tự nhập';

  @override
  String get emailTitle => 'Email chuyển tiếp';

  @override
  String get emailExplain =>
      'Chuyển tiếp email báo giao dịch của ngân hàng tới một địa chỉ riêng; app tạo giao dịch chờ xác nhận. Tắt mặc định.';

  @override
  String get emailNeedSignIn => 'Đăng nhập đồng bộ để dùng';

  @override
  String get emailEnable => 'Bật email chuyển tiếp';

  @override
  String get emailDisclosure =>
      'Đây là NGOẠI LỆ DUY NHẤT của mã hóa đầu-cuối: email đi qua Internet ở dạng thường, và máy chủ Quly Thu Chi thấy nội dung trong vài mili giây khi nhận để niêm phong bằng khóa của bạn. Máy chủ không lưu bản rõ; thư niêm phong bị xóa khi app tải về hoặc sau 30 ngày. Chỉ chuyển tiếp email báo giao dịch, đừng chuyển thư có mật khẩu/OTP.';

  @override
  String get emailCopy => 'Sao chép';

  @override
  String get emailCopied => 'Đã sao chép địa chỉ';

  @override
  String get emailRotate => 'Đổi địa chỉ';

  @override
  String get emailRotateConfirm =>
      'Địa chỉ hiện tại sẽ ngừng nhận thư ngay. Bạn cần cập nhật quy tắc chuyển tiếp ở hộp thư của mình.';

  @override
  String get emailDisable => 'Tắt';

  @override
  String get emailDisableConfirm => 'Tắt email chuyển tiếp? Địa chỉ bị xóa cùng mọi thư chưa tải về.';

  @override
  String get emailWarning =>
      'Ngoại lệ E2EE: máy chủ thấy nội dung email trong lúc niêm phong. Địa chỉ là bí mật - ai biết địa chỉ đều gửi thư vào được.';

  @override
  String get copied => 'Đã sao chép';

  @override
  String get currencyPick => 'Chọn tiền tệ';

  @override
  String get currencySearch => 'Tìm theo mã hoặc tên (USD, yên, bảng Anh...)';

  @override
  String get currencyPopular => 'Hay dùng';

  @override
  String currencyAll(int count) {
    return 'Tất cả ($count tiền tệ ISO 4217)';
  }

  @override
  String get currencyNone => 'Không tìm thấy tiền tệ phù hợp.';

  @override
  String get guestModeNote =>
      'Không đăng nhập vẫn dùng đầy đủ mọi tính năng ở chế độ khách: dữ liệu chỉ nằm trên máy này, mã hóa bằng mật khẩu của bạn.';

  @override
  String get welcomeGuest => 'Dùng ngay, không cần tài khoản';

  @override
  String get welcomeGuestNote =>
      'Chế độ khách: dữ liệu chỉ lưu trên máy này. Có thể đăng nhập để đồng bộ bất cứ lúc nào.';

  @override
  String get signInGoogle => 'Tiếp tục với Google';

  @override
  String get signInGithub => 'Tiếp tục với GitHub';

  @override
  String get signInApple => 'Tiếp tục với Apple';

  @override
  String get signInTsudev => 'Tài khoản tsudev (email)';

  @override
  String get signInLastUsed => 'Lần trước bạn dùng cách này';

  @override
  String get signInOr => 'hoặc';

  @override
  String get settingsCarryOver => 'Chuyển số dư sang tháng sau';

  @override
  String get settingsCarryOverSub =>
      'Số dư cuối tháng trước thành số dư đầu tháng này trên thẻ Số dư theo tháng. Tắt để chỉ xem thu, chi trong tháng.';

  @override
  String get settingsTaxReminders => 'Nhắc hạn thuế và đợt thu';

  @override
  String get settingsTaxRemindersSub =>
      'Báo trước 7 ngày và 1 ngày hạn quyết toán thuế TNCN; báo ngày đến hạn đợt thu của khoản thu.';

  @override
  String periodTitle(int month, int year) {
    return 'Tháng $month/$year';
  }

  @override
  String get periodPrev => 'Kỳ trước';

  @override
  String get periodNext => 'Kỳ sau';

  @override
  String get periodThisMonth => 'Tháng này';

  @override
  String periodOpening(int month) {
    return 'Số dư đầu kỳ (chuyển từ tháng $month)';
  }

  @override
  String get periodIncome => 'Thu trong tháng';

  @override
  String get periodExpense => 'Chi trong tháng';

  @override
  String get periodOther => 'Chuyển ví, phí, điều chỉnh';

  @override
  String get periodWithheld => 'Thuế đã bị khấu trừ (không trừ số dư)';

  @override
  String periodClosing(int month) {
    return 'Số dư cuối kỳ (chuyển sang tháng $month)';
  }

  @override
  String get periodNet => 'Chênh lệch thu - chi';

  @override
  String periodSavingRate(String rate) {
    return 'Tỉ lệ để dành: $rate';
  }

  @override
  String get incomeTitle => 'Khoản thu';

  @override
  String get incomeRecord => 'Ghi khoản thu';

  @override
  String get incomePlanNew => 'Thêm khoản thu nhiều đợt';

  @override
  String get incomePlanEdit => 'Sửa khoản thu';

  @override
  String incomeYear(int year) {
    return 'Năm $year';
  }

  @override
  String get incomeByMonth => 'Theo tháng';

  @override
  String get incomeByYear => 'Cả năm';

  @override
  String get incomeTotalReceived => 'Tổng thực nhận';

  @override
  String incomeReceipts(int count) {
    return '$count lần nhận';
  }

  @override
  String incomeWithheldTotal(String amount) {
    return 'thuế khấu trừ $amount';
  }

  @override
  String incomeGrossTotal(String amount) {
    return 'trước thuế $amount';
  }

  @override
  String get incomeSumBy => 'Cộng thu theo';

  @override
  String get incomeByPayer => 'Người trả';

  @override
  String get incomeByCategory => 'Danh mục';

  @override
  String get incomeByPlan => 'Khoản thu';

  @override
  String get incomeNoPayer => '(Chưa ghi người trả)';

  @override
  String get incomeNoPlan => '(Thu lẻ, không thuộc khoản thu)';

  @override
  String get incomeNone => 'Chưa có khoản thu trong kỳ này.';

  @override
  String incomeLast(String date) {
    return 'gần nhất $date';
  }

  @override
  String get incomePlansTitle => 'Khoản thu nhiều đợt';

  @override
  String get incomePlansHelp =>
      'Theo dõi job freelance, hợp đồng, tiền cho thuê... nhận tiền nhiều đợt: đã nhận bao nhiêu, còn bao nhiêu, đợt nào trễ.';

  @override
  String get incomePlansEmpty => 'Chưa có khoản thu nào. Bấm \"Thêm khoản thu nhiều đợt\" để bắt đầu.';

  @override
  String incomeShowClosed(int count) {
    return 'Hiện $count khoản đã xong/hủy';
  }

  @override
  String get incomeHideClosed => 'Ẩn khoản đã xong';

  @override
  String get incomeStatusActive => 'Đang thu';

  @override
  String get incomeStatusDone => 'Đã xong';

  @override
  String get incomeStatusCancelled => 'Đã hủy';

  @override
  String get incomeStatus => 'Trạng thái';

  @override
  String incomeProgress(String received, String total) {
    return 'Đã nhận $received / $total';
  }

  @override
  String incomeReceivedSoFar(String amount) {
    return 'Đã nhận $amount';
  }

  @override
  String incomeNext(String label, String amount, String date) {
    return 'Đợt kế tiếp: $label $amount, hạn $date';
  }

  @override
  String get incomeInstallment => 'Đợt';

  @override
  String incomeOverdue(String amount) {
    return 'Quá hạn chưa nhận: $amount';
  }

  @override
  String get incomePlanName => 'Tên job/dự án';

  @override
  String get incomePlanNameHint => 'Ví dụ: Thiết kế web quán cà phê';

  @override
  String get incomePayer => 'Người/đơn vị trả tiền';

  @override
  String get incomePlanTotal => 'Tổng giá trị thỏa thuận (để trống nếu chưa chốt)';

  @override
  String get incomeDefaultWallet => 'Ví nhận tiền mặc định';

  @override
  String get incomeStart => 'Ngày bắt đầu';

  @override
  String get incomeDue => 'Hạn hoàn thành';

  @override
  String get incomeWithholding => 'Bên trả khấu trừ thuế 10%';

  @override
  String get incomeWithholdingSub =>
      'Thu nhập vãng lai (không hợp đồng lao động hoặc dưới 3 tháng): khi ghi lần nhận tiền, app tự tính thuế bị khấu trừ.';

  @override
  String get incomeInstallments => 'Các đợt dự kiến';

  @override
  String get incomeInstallmentsHelp => 'Không bắt buộc. Ví dụ: đặt cọc 30%, bản thử 40%, nghiệm thu 30%.';

  @override
  String incomeInstallmentLabel(int n) {
    return 'Đợt $n';
  }

  @override
  String get incomeInstallmentHint => 'Đặt cọc, nghiệm thu...';

  @override
  String get incomeAddInstallment => 'Thêm đợt';

  @override
  String get incomeReceive => 'Ghi lần nhận tiền';

  @override
  String get incomeGrossAmount => 'Số tiền theo hợp đồng (trước thuế)';

  @override
  String incomeWithholdHint(String threshold) {
    return 'Để trống: app tự tính 10% nếu lần trả từ $threshold trở lên.';
  }

  @override
  String incomeNetPreview(String amount) {
    return 'Thực nhận vào ví: $amount';
  }

  @override
  String incomeNoWalletForCurrency(String currency) {
    return 'Cần một ví $currency để ghi lần nhận tiền.';
  }

  @override
  String incomePlanDeleteConfirm(String name) {
    return 'Xóa khoản thu \"$name\"? Các lần nhận tiền đã ghi vẫn giữ nguyên.';
  }

  @override
  String get incomeReceiptsTitle => 'Các lần đã nhận';

  @override
  String get incomePlanField => 'Thuộc khoản thu';

  @override
  String get txnTaxWithheld => 'Thuế TNCN bị khấu trừ';

  @override
  String get txnTaxWithheldHelp =>
      'Số tiền là số THỰC NHẬN. Ghi phần thuế bên trả đã giữ lại để tính đúng thu nhập trước thuế và quyết toán.';

  @override
  String get taxTitle => 'Thuế thu nhập cá nhân';

  @override
  String get taxDisclaimer =>
      'Ước tính để tham khảo theo quy định Việt Nam, không thay thế tư vấn thuế. Hãy đối chiếu văn bản gốc và cơ quan thuế trước khi khai, nộp.';

  @override
  String get taxProfile => 'Hồ sơ thuế';

  @override
  String get taxDependents => 'Người phụ thuộc';

  @override
  String taxDependentsN(int count) {
    return '$count người phụ thuộc';
  }

  @override
  String get taxLess => 'Bớt';

  @override
  String get taxMore => 'Thêm';

  @override
  String get taxInsurance => 'Bảo hiểm bắt buộc đóng mỗi tháng';

  @override
  String get taxInsuranceHelp => 'Để trống: ước tính 10,5% lương (BHXH 8%, BHYT 1,5%, BHTN 1%) trong mức trần.';

  @override
  String taxInsuranceN(String amount) {
    return 'bảo hiểm $amount/tháng';
  }

  @override
  String get taxResident => 'Cá nhân cư trú';

  @override
  String get taxNonResident => 'Không cư trú';

  @override
  String get taxResidentSub =>
      'Ở Việt Nam từ 183 ngày/năm hoặc có nơi ở thường xuyên. Không cư trú: thuế 20% trên lương, không giảm trừ.';

  @override
  String get taxBusiness => 'Có kinh doanh (hộ, cá nhân kinh doanh)';

  @override
  String get taxBusinessSub =>
      'Bật nhắc hạn khai thuế theo quý và cảnh báo khi doanh thu năm vượt ngưỡng không chịu thuế.';

  @override
  String taxUnclassified(int count) {
    return '$count danh mục thu chưa phân loại thuế: thu nhập trong đó không được tính vào ước tính.';
  }

  @override
  String get taxStandardCategories => 'Bổ sung danh mục thu chuẩn (đã phân loại thuế)';

  @override
  String taxStandardDone(int count) {
    return 'Đã thêm/cập nhật $count danh mục';
  }

  @override
  String taxEstimateTitle(int year) {
    return 'Ước tính quyết toán năm $year';
  }

  @override
  String get taxSalaryIncome => 'Thu nhập từ tiền lương, tiền công';

  @override
  String get taxCasualIncome => 'Thu nhập vãng lai, freelance';

  @override
  String get taxBusinessRevenue => 'Doanh thu kinh doanh (tính riêng)';

  @override
  String get taxInvestmentIncome => 'Thu nhập đầu tư vốn (tính riêng)';

  @override
  String get taxExemptIncome => 'Thu nhập miễn thuế';

  @override
  String get taxUnclassifiedIncome => 'Thu nhập chưa phân loại';

  @override
  String get taxInsuranceYear => 'Bảo hiểm bắt buộc';

  @override
  String get taxDeductionYear => 'Giảm trừ gia cảnh (12 tháng)';

  @override
  String get taxTaxable => 'Thu nhập tính thuế';

  @override
  String get taxDue => 'Thuế phải nộp cả năm';

  @override
  String get taxWithheld => 'Đã bị khấu trừ tại nguồn';

  @override
  String get taxPayMore => 'Ước tính phải nộp thêm';

  @override
  String get taxRefund => 'Ước tính được hoàn';

  @override
  String taxSettlementNote(String date) {
    return 'Tự quyết toán hạn chót $date. Nộp trên thuedientu.gdt.gov.vn hoặc app eTax Mobile.';
  }

  @override
  String taxBusinessOver(String amount) {
    return 'Doanh thu kinh doanh vượt $amount/năm: có thể phải khai, nộp thuế.';
  }

  @override
  String get taxCalcTitle => 'Tính lương gross / net';

  @override
  String get taxFromGross => 'Từ gross';

  @override
  String get taxFromNet => 'Từ net';

  @override
  String get taxGrossSalary => 'Lương gross (trước thuế, bảo hiểm)';

  @override
  String get taxNetSalary => 'Lương net (thực nhận)';

  @override
  String get taxInsuranceMonth => 'Bảo hiểm bắt buộc';

  @override
  String get taxDeductionMonth => 'Giảm trừ gia cảnh';

  @override
  String get taxMonthTax => 'Thuế TNCN tháng';

  @override
  String get taxDeadlines => 'Hạn sắp tới';

  @override
  String taxDeadlineSelf(int year) {
    return 'Hạn tự quyết toán thuế TNCN năm $year';
  }

  @override
  String taxDeadlineAuthorize(int year) {
    return 'Nộp giấy ủy quyền quyết toán năm $year cho công ty (nếu ủy quyền)';
  }

  @override
  String get taxDeadlineBusiness => 'Hạn khai thuế quý (hộ kinh doanh)';

  @override
  String taxDeadlineIn(String date, int days) {
    return '$date (còn $days ngày)';
  }

  @override
  String taxRulesTitle(int year) {
    return 'Quy định áp dụng từ $year';
  }

  @override
  String get taxPersonalDeduction => 'Giảm trừ bản thân / tháng';

  @override
  String get taxDependentDeduction => 'Giảm trừ mỗi người phụ thuộc / tháng';

  @override
  String taxBracketUpTo(int n, String amount) {
    return 'Bậc $n: đến $amount/tháng';
  }

  @override
  String taxBracketOver(int n, String amount) {
    return 'Bậc $n: trên $amount/tháng';
  }

  @override
  String taxCasualRule(String amount) {
    return 'Khấu trừ vãng lai khi mỗi lần trả từ $amount';
  }

  @override
  String get taxBusinessThreshold => 'Doanh thu kinh doanh không chịu thuế / năm';

  @override
  String taxSource(String source, String date) {
    return 'Nguồn: $source. Cập nhật $date.';
  }

  @override
  String get taxCategoriesTitle => 'Phân loại thuế của danh mục thu';

  @override
  String get taxInherit => 'Theo danh mục cha';

  @override
  String get taxTypeUnknown => 'Chưa phân loại';

  @override
  String get taxTypeUnknownHelp => 'Không tính vào ước tính thuế';

  @override
  String get taxTypeSalary => 'Tiền lương, tiền công';

  @override
  String get taxTypeSalaryHelp => 'Hợp đồng lao động từ 3 tháng, thưởng, phụ cấp chịu thuế';

  @override
  String get taxTypeCasual => 'Vãng lai, freelance';

  @override
  String get taxTypeCasualHelp => 'Không hợp đồng hoặc dưới 3 tháng; bên trả khấu trừ 10%';

  @override
  String get taxTypeBusiness => 'Kinh doanh, cho thuê';

  @override
  String get taxTypeBusinessHelp => 'Tính theo doanh thu, có ngưỡng không chịu thuế';

  @override
  String get taxTypeInvestment => 'Đầu tư vốn';

  @override
  String get taxTypeInvestmentHelp => 'Cổ tức, lãi trái phiếu... thuế suất riêng';

  @override
  String get taxTypeExempt => 'Miễn thuế';

  @override
  String get taxTypeExemptHelp => 'Lãi tiền gửi ngân hàng, quà tặng trong gia đình, hoàn tiền';

  @override
  String get qrTitle => 'QR thanh toán';

  @override
  String get qrTabPay => 'Quét để trả';

  @override
  String get qrTabReceive => 'Mã nhận tiền';

  @override
  String get qrPayIntro =>
      'Quét mã VietQR/EMVCo của người nhận để xem đúng số tài khoản, số tiền, nội dung, rồi mở app ngân hàng và ghi khoản chi. Mã được đọc ngay trên máy.';

  @override
  String get qrNoCamera =>
      'Thiết bị này chưa quét bằng camera được. Dán nội dung mã QR (chuỗi bắt đầu bằng 000201) vào ô dưới.';

  @override
  String get qrCameraError => 'Không mở được camera. Hãy cấp quyền camera hoặc dán nội dung mã.';

  @override
  String get qrPasteLabel => 'Nội dung mã QR';

  @override
  String get qrPaste => 'Dán';

  @override
  String get qrRead => 'Đọc mã';

  @override
  String get qrErrCrc => 'Mã QR bị sai hoặc đã bị sửa (kiểm tra CRC không khớp). Đừng thanh toán bằng mã này.';

  @override
  String get qrErrNotPayment => 'Đây không phải mã QR thanh toán EMVCo/VietQR.';

  @override
  String get qrErrInvalid => 'Mã QR không đúng cấu trúc.';

  @override
  String get qrNoAmount => 'Mã không ghi số tiền: bạn tự nhập trong app ngân hàng.';

  @override
  String get qrPayee => 'Người nhận';

  @override
  String get qrBank => 'Ngân hàng';

  @override
  String get qrAccount => 'Số tài khoản';

  @override
  String get qrMessage => 'Nội dung chuyển khoản';

  @override
  String get qrCity => 'Nơi nhận';

  @override
  String get qrIsCard => 'Định danh là số thẻ.';

  @override
  String get qrOpenBank => 'Mở app ngân hàng (điền sẵn)';

  @override
  String get qrOpenBankNote =>
      'Hoặc mở app ngân hàng, chọn quét QR và quét lại mã này; luôn kiểm tra tên người nhận trước khi xác nhận.';

  @override
  String get qrForeignNote =>
      'Mã nước ngoài: thanh toán bằng app ví/ngân hàng hỗ trợ hệ này, rồi ghi khoản chi tại đây.';

  @override
  String get qrConsentTitle => 'Mở app ngân hàng qua VietQR.io';

  @override
  String get qrConsentBody =>
      'Để điền sẵn lệnh chuyển, app gửi số tài khoản NGƯỜI NHẬN, số tiền và nội dung tới dl.vietqr.io (dịch vụ bên thứ ba) để chuyển sang app ngân hàng bạn chọn. Không gửi dữ liệu sổ thu chi của bạn. Đồng ý?';

  @override
  String get qrConsentOk => 'Đồng ý, mở app';

  @override
  String get qrChooseBankApp => 'Chọn app ngân hàng của bạn';

  @override
  String get qrLastUsed => 'Dùng lần trước';

  @override
  String get qrOpenFailed => 'Không mở được app ngân hàng trên thiết bị này.';

  @override
  String get qrRecordExpense => 'Ghi khoản chi này';

  @override
  String get qrScanAgain => 'Quét mã khác';

  @override
  String get qrReceiveIntro =>
      'Tạo mã VietQR để khách hàng quét chuyển tiền cho bạn. Mã tạo ngay trên máy, số tài khoản không được lưu hay gửi đi.';

  @override
  String get qrAmountOptional => 'Số tiền (để trống: người trả tự nhập)';

  @override
  String get qrMessageHelp => 'Tối đa 25 ký tự, tự bỏ dấu để mọi ngân hàng đọc được.';

  @override
  String get qrCreate => 'Tạo mã';

  @override
  String get qrErrAccount => 'Số tài khoản chỉ gồm chữ và số, tối đa 19 ký tự.';

  @override
  String get qrImageLabel => 'Mã QR nhận tiền';

  @override
  String get qrCopyContent => 'Sao chép nội dung mã';

  @override
  String get importTemplateHelp =>
      'Chuyển dữ liệu từ app khác: tải tệp mẫu, dán dữ liệu cũ vào đúng cột (Ngày, Loại, Số tiền, Ví...), rồi chọn tệp để nhập. Ví và danh mục chưa có được tạo tự động.';

  @override
  String get importTemplateCsv => 'Tệp mẫu CSV';

  @override
  String get importTemplateXlsx => 'Tệp mẫu Excel';

  @override
  String get importTemplateSaved => 'Đã lưu tệp mẫu';

  @override
  String get importTemplateDetected => 'Đã nhận ra tệp mẫu Quly Thu Chi';

  @override
  String importTemplateSummary(int rows, int wallets, int categories) {
    return '$rows giao dịch, tạo mới $wallets ví và $categories danh mục.';
  }

  @override
  String importTemplateNewWallets(String names) {
    return 'Ví mới: $names';
  }

  @override
  String importTemplateDuplicates(int count) {
    return 'Bỏ $count dòng trùng giao dịch đã có.';
  }

  @override
  String importTemplateSkipped(int count, String rows) {
    return 'Bỏ $count dòng thiếu/sai dữ liệu (dòng $rows).';
  }

  @override
  String importTemplateRun(int count) {
    return 'Nhập $count giao dịch';
  }

  @override
  String importTemplateDone(int count, int wallets, int categories) {
    return 'Đã nhập $count giao dịch, tạo $wallets ví, $categories danh mục.';
  }

  @override
  String get shareTitle => 'Ví chung';

  @override
  String get shareMembersEntry => 'Chia sẻ và thành viên';

  @override
  String get shareBadge => 'Ví chung';

  @override
  String get shareIntro =>
      'Mời người trong gia đình cùng ghi chép ví này. Khóa ví được trao qua mã hóa đầu-cuối: máy chủ chỉ thấy bản mã, không đọc được số tiền hay ghi chú.';

  @override
  String get shareStart => 'Chia sẻ ví này';

  @override
  String get shareNeedSignIn => 'Cần đăng nhập và đồng bộ để dùng ví chung.';

  @override
  String get shareGoSignIn => 'Đến Tài khoản và đồng bộ';

  @override
  String get shareNotLoaded => 'Chưa tải được danh sách thành viên.';

  @override
  String get shareRetry => 'Thử lại';

  @override
  String get shareMembers => 'Thành viên';

  @override
  String get shareInvites => 'Lời mời đang mở';

  @override
  String get shareInvite => 'Mời thành viên';

  @override
  String get shareRoleOwner => 'Chủ ví';

  @override
  String get shareRoleEditor => 'Người ghi';

  @override
  String get shareRoleViewer => 'Người xem';

  @override
  String get shareRoleEditorHint => 'Thêm, sửa, xóa giao dịch trong ví';

  @override
  String get shareRoleViewerHint => 'Chỉ xem, không ghi';

  @override
  String shareYourRole(String role) {
    return 'Quyền của bạn: $role';
  }

  @override
  String get shareYou => 'Bạn';

  @override
  String shareSafetyCode(String code) {
    return 'Mã an toàn: $code';
  }

  @override
  String shareMySafetyCode(String code) {
    return 'Mã an toàn của bạn: $code. Hai người cùng ví nên so mã an toàn qua điện thoại hoặc gặp mặt.';
  }

  @override
  String shareChangeTo(String role) {
    return 'Đổi thành $role';
  }

  @override
  String get shareRemove => 'Thu hồi quyền';

  @override
  String shareRemoveConfirm(String name) {
    return 'Thu hồi quyền của $name? Ví sẽ được đổi khóa mới và mã hóa lại; người này không đọc được dữ liệu mới nữa.';
  }

  @override
  String get shareRemoved => 'Đã thu hồi và đổi khóa ví.';

  @override
  String get shareInviteWaiting => 'Chờ người nhận';

  @override
  String shareInviteAccepted(String name) {
    return '$name đã nhận - đang hoàn tất';
  }

  @override
  String get shareInviteCancel => 'Hủy lời mời';

  @override
  String get shareInviteRoleTitle => 'Mời với quyền';

  @override
  String get shareInviteCreate => 'Tạo lời mời';

  @override
  String get shareInviteCodeTitle => 'Gửi mã mời';

  @override
  String get shareInviteCodeBody =>
      'Gửi mã hoặc liên kết này cho người được mời qua tin nhắn riêng, hoặc cho họ quét mã QR. Mã dùng được một lần trong 7 ngày. Ai có mã đều có thể nhận lời mời, nên đừng đăng công khai.';

  @override
  String get shareCopyCode => 'Sao chép mã';

  @override
  String get shareCopyLink => 'Sao chép liên kết';

  @override
  String get shareCopied => 'Đã sao chép.';

  @override
  String get shareLeave => 'Rời ví chung';

  @override
  String shareLeaveConfirm(String name) {
    return 'Rời ví \"$name\"? Dữ liệu của ví sẽ bị xóa khỏi máy này.';
  }

  @override
  String get shareLeft => 'Đã rời ví chung.';

  @override
  String get shareReadOnlyNote => 'Ví chung: chỉ chủ ví sửa được thông tin ví.';

  @override
  String shareBadInvites(int count) {
    return 'Đã hủy $count lời mời vì bằng chứng không khớp (có thể ai đó không có mã thật).';
  }

  @override
  String get joinTitle => 'Tham gia ví chung';

  @override
  String get joinCodeLabel => 'Mã hoặc liên kết mời';

  @override
  String get joinPreview => 'Xem lời mời';

  @override
  String get joinInvalidCode => 'Mã mời không đúng định dạng.';

  @override
  String joinFrom(String name) {
    return 'Lời mời từ $name';
  }

  @override
  String joinRole(String role) {
    return 'Quyền: $role';
  }

  @override
  String get joinAccept => 'Tham gia';

  @override
  String get joinSent => 'Đã nhận lời mời. Ví sẽ xuất hiện khi chủ ví mở app.';

  @override
  String get joinPending => 'Đang chờ chủ ví xác nhận';

  @override
  String get joinOwnerUnknown => 'chủ ví';

  @override
  String get joinAlreadyAccepted => 'Bạn đã nhận lời mời này.';

  @override
  String get shareErrInviteGone => 'Lời mời không tồn tại hoặc đã hết hạn.';

  @override
  String get shareErrInviteTaken => 'Lời mời đã được người khác dùng. Hãy xin chủ ví mã mới.';

  @override
  String get shareErrInviteOwn => 'Đây là lời mời vào ví của chính bạn.';

  @override
  String get shareErrAlreadyMember => 'Bạn đã ở trong ví này.';

  @override
  String get shareErrNoKeys => 'Hãy đồng bộ một lần để tải khóa mã hóa lên trước.';

  @override
  String get shareErrLimit => 'Đã đạt giới hạn số ví chung hoặc thành viên.';

  @override
  String get shareErrStale => 'Ví vừa thay đổi. Hãy đồng bộ rồi thử lại.';

  @override
  String get shareErrMissingSecret =>
      'Máy này chưa có đủ thông tin của một thành viên. Hãy đồng bộ hoặc thử trên máy đã tạo lời mời.';

  @override
  String get shareErrForbidden => 'Chỉ chủ ví được làm việc này.';

  @override
  String get errReadOnly => 'Bạn chỉ có quyền xem ví chung này.';

  @override
  String get errOwnerOnly => 'Chỉ chủ ví được sửa thông tin ví chung.';

  @override
  String get attTitle => 'Ảnh hóa đơn';

  @override
  String get attAdd => 'Thêm ảnh';

  @override
  String get attCamera => 'Chụp ảnh';

  @override
  String get attGallery => 'Chọn từ thư viện';

  @override
  String get attFile => 'Chọn tệp ảnh';

  @override
  String attLimit(int count) {
    return 'Tối đa $count ảnh mỗi giao dịch';
  }

  @override
  String get attPrivacy =>
      'Ảnh được thu nhỏ, xóa vị trí GPS và thông tin máy chụp, rồi mã hóa trên máy trước khi đồng bộ.';

  @override
  String get attNewHint => 'Ảnh sẽ được gắn khi bạn lưu giao dịch.';

  @override
  String get attProcessing => 'Đang xử lý ảnh…';

  @override
  String get attPending => 'Chưa đồng bộ - ảnh đang lưu an toàn trên máy này';

  @override
  String get attProBlocked => 'Đồng bộ ảnh cần TsuDEV Pro. Ảnh vẫn lưu đầy đủ trên máy này.';

  @override
  String attFilesPending(int count) {
    return '$count ảnh chờ đồng bộ (đang lưu trên máy)';
  }

  @override
  String get attNotAvailable => 'Ảnh chưa có trên máy này. Đăng nhập đồng bộ để tải về.';

  @override
  String get attOpenFailed => 'Không mở được ảnh (tệp hỏng hoặc không đúng giao dịch).';

  @override
  String get attDelete => 'Xóa ảnh';

  @override
  String get attDeleteConfirm => 'Xóa ảnh này khỏi giao dịch trên mọi thiết bị?';

  @override
  String attView(int index) {
    return 'Xem ảnh $index';
  }

  @override
  String get attRejectTooLarge => 'Ảnh quá lớn (tối đa 25 MB).';

  @override
  String get attRejectPixels => 'Ảnh có độ phân giải quá lớn.';

  @override
  String get attRejectUnsupported => 'Không đọc được ảnh này. Hãy chọn ảnh JPEG hoặc PNG.';

  @override
  String get errTooManyAttachments => 'Đã đủ số ảnh tối đa cho giao dịch này.';

  @override
  String get errAttachmentsNotLocal =>
      'Ảnh đính kèm của giao dịch này chưa tải về máy. Hãy mở xem các ảnh (để tải về) rồi đổi ví.';

  @override
  String get proMenu => 'TsuDEV Pro và Ủng hộ';

  @override
  String get proMenuSub => 'Đồng bộ, sao lưu đám mây, ví chung';

  @override
  String proStatusActive(String date) {
    return 'Pro còn hạn tới ngày $date';
  }

  @override
  String proStatusExpired(String date) {
    return 'Pro đã hết hạn ngày $date';
  }

  @override
  String get proStatusFree =>
      'Bạn đang dùng bản miễn phí: đủ mọi tính năng trên máy, dữ liệu chỉ lưu trên thiết bị này.';

  @override
  String get proFeaturesTitle => 'TsuDEV Pro gồm';

  @override
  String get proFeatSync => 'Đồng bộ và sao lưu đám mây mã hóa đầu-cuối giữa các thiết bị';

  @override
  String get proFeatShared => 'Tạo ví chung và mời người nhà (người được mời không cần Pro)';

  @override
  String get proFeatAttach => 'Đồng bộ ảnh hóa đơn, hộp thư nhập tự động';

  @override
  String get proFeatQuota => 'Hạn mức 200 MiB dữ liệu + 1 GiB ảnh';

  @override
  String get proFeatOneAccount => 'Một gói dùng cho mọi ứng dụng TsuDEV cùng tài khoản';

  @override
  String get proPlanYear => 'TsuDEV Pro - 1 năm';

  @override
  String proTerms(String price) {
    return 'TsuDEV Pro $price cho 1 năm, KHÔNG tự gia hạn. Gia hạn sớm được cộng thêm 1 năm vào thời hạn còn lại. Hết hạn mà chưa gia hạn, ứng dụng trở về bản miễn phí và ngừng đồng bộ lên đám mây; dữ liệu trên thiết bị vẫn giữ nguyên, bản sao trên đám mây còn tải về được 90 ngày rồi bị xoá.';
  }

  @override
  String get proBuyStore => 'Mua 1 năm';

  @override
  String get proRenewStore => 'Gia hạn thêm 1 năm';

  @override
  String get proBuyWeb => 'Mua trên tsudev.com';

  @override
  String get proCheckAgain => 'Tôi đã thanh toán - kiểm tra lại';

  @override
  String get proSignInFirst => 'Đăng nhập tài khoản TsuDEV để mua Pro hoặc ủng hộ.';

  @override
  String get proSignIn => 'Đăng nhập';

  @override
  String get proAppStoreSoon => 'Mua trong ứng dụng trên iPhone/iPad sẽ có khi ứng dụng phát hành trên App Store.';

  @override
  String get proStoreUnavailable => 'Cửa hàng chưa sẵn sàng. Hãy thử lại sau.';

  @override
  String get proOutcomeVerified => 'Cảm ơn bạn! Giao dịch đã được xác nhận.';

  @override
  String get proOutcomePending => 'Giao dịch đang chờ xác nhận. Ứng dụng sẽ tự kiểm tra lại.';

  @override
  String get proOutcomeInvalid => 'Không xác nhận được giao dịch này.';

  @override
  String get proOutcomeError => 'Không mở được giao dịch. Hãy thử lại.';

  @override
  String get donateTitle => 'Ủng hộ TsuDEV';

  @override
  String get donateBody =>
      'Tự nguyện, không mở khóa tính năng nào. Lần ủng hộ đầu tiên được xác nhận sẽ có huy hiệu Ủng hộ.';

  @override
  String get donateWeb => 'Ủng hộ trên tsudev.com';

  @override
  String proServerDataUntil(String date) {
    return 'Bản sao trên đám mây còn tải về được tới ngày $date, sau đó bị xoá. Dữ liệu trên thiết bị không bị ảnh hưởng.';
  }

  @override
  String get proBlockNoPro => 'Đồng bộ lên đám mây cần TsuDEV Pro. Dữ liệu vẫn lưu đầy đủ trên máy này.';

  @override
  String get proBlockReauth => 'Cần đăng nhập lại để xác nhận gói TsuDEV Pro. Dữ liệu vẫn lưu đầy đủ trên máy này.';

  @override
  String get proBlockOwner =>
      'Chủ ví chung chưa có TsuDEV Pro nên thay đổi trong ví chung chưa đồng bộ được. Thay đổi vẫn lưu trên máy này.';

  @override
  String get proSeePlans => 'Xem gói Pro';

  @override
  String get proSignInAgain => 'Đăng nhập lại';

  @override
  String get proPurgeTitle => 'Bản sao đám mây sắp bị xoá';

  @override
  String proPurgeBody(int days, String date) {
    return 'Gói TsuDEV Pro đã hết hạn. Bản sao dữ liệu trên đám mây sẽ bị xoá sau $days ngày (ngày $date). Dữ liệu trên thiết bị vẫn giữ nguyên. Gia hạn để giữ bản sao, hoặc tải về trước ngày đó.';
  }

  @override
  String get proClose => 'Đóng';

  @override
  String get proRenew => 'Gia hạn';

  @override
  String get importPdfPasswordTitle => 'Sao kê PDF có mật khẩu';

  @override
  String get importPdfPasswordBody =>
      'Nhập mật khẩu ngân hàng đặt cho tệp (thường là ngày sinh hoặc số giấy tờ). Mật khẩu chỉ dùng để mở tệp trên máy này, không được lưu.';

  @override
  String get importPdfPasswordWrong => 'Mật khẩu PDF không đúng';

  @override
  String get importPdfNoText =>
      'PDF không có lớp chữ (ảnh quét). Hãy tải bản PDF điện tử, CSV hoặc Excel từ ngân hàng, hoặc chụp từng trang ở Tự nhập > Hóa đơn.';
}
