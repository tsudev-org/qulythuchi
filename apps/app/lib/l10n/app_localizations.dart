import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('vi')];

  /// No description provided for @appTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quly Thu Chi'**
  String get appTitle;

  /// No description provided for @navOverview.
  ///
  /// In vi, this message translates to:
  /// **'Tổng quan'**
  String get navOverview;

  /// No description provided for @navTransactions.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch'**
  String get navTransactions;

  /// No description provided for @navWallets.
  ///
  /// In vi, this message translates to:
  /// **'Ví'**
  String get navWallets;

  /// No description provided for @navCategories.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục'**
  String get navCategories;

  /// No description provided for @navSettings.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get navSettings;

  /// No description provided for @actionSave.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get actionSave;

  /// No description provided for @actionCancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get actionCancel;

  /// No description provided for @actionDelete.
  ///
  /// In vi, this message translates to:
  /// **'Xóa'**
  String get actionDelete;

  /// No description provided for @actionEdit.
  ///
  /// In vi, this message translates to:
  /// **'Sửa'**
  String get actionEdit;

  /// No description provided for @actionAdd.
  ///
  /// In vi, this message translates to:
  /// **'Thêm'**
  String get actionAdd;

  /// No description provided for @actionContinue.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get actionContinue;

  /// No description provided for @actionBack.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get actionBack;

  /// No description provided for @actionDone.
  ///
  /// In vi, this message translates to:
  /// **'Xong'**
  String get actionDone;

  /// No description provided for @actionCopy.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép'**
  String get actionCopy;

  /// No description provided for @actionRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get actionRetry;

  /// No description provided for @loading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải…'**
  String get loading;

  /// No description provided for @working.
  ///
  /// In vi, this message translates to:
  /// **'Đang xử lý, vui lòng chờ…'**
  String get working;

  /// No description provided for @welcomeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chào mừng tới Quly Thu Chi'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu thu chi của bạn được mã hóa ngay trên thiết bị. Không ai khác, kể cả chúng tôi, đọc được.'**
  String get welcomeBody;

  /// No description provided for @welcomeStart.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu'**
  String get welcomeStart;

  /// No description provided for @welcomeRestore.
  ///
  /// In vi, this message translates to:
  /// **'Tôi đã có 24 từ khôi phục'**
  String get welcomeRestore;

  /// No description provided for @setupPasswordTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo mật khẩu mã hóa'**
  String get setupPasswordTitle;

  /// No description provided for @setupPasswordBody.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu này mở khóa dữ liệu của bạn. Chúng tôi không thể khôi phục nếu bạn quên - khi đó chỉ 24 từ khôi phục giúp được.'**
  String get setupPasswordBody;

  /// No description provided for @passwordLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu mã hóa'**
  String get passwordLabel;

  /// No description provided for @passwordConfirmLabel.
  ///
  /// In vi, this message translates to:
  /// **'Nhập lại mật khẩu'**
  String get passwordConfirmLabel;

  /// No description provided for @passwordTooShort.
  ///
  /// In vi, this message translates to:
  /// **'Cần ít nhất {min} ký tự'**
  String passwordTooShort(int min);

  /// No description provided for @passwordMismatch.
  ///
  /// In vi, this message translates to:
  /// **'Hai mật khẩu không khớp'**
  String get passwordMismatch;

  /// No description provided for @passwordWrong.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu không đúng'**
  String get passwordWrong;

  /// No description provided for @showPassword.
  ///
  /// In vi, this message translates to:
  /// **'Hiện mật khẩu'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In vi, this message translates to:
  /// **'Ẩn mật khẩu'**
  String get hidePassword;

  /// No description provided for @recoveryTitle.
  ///
  /// In vi, this message translates to:
  /// **'24 từ khôi phục'**
  String get recoveryTitle;

  /// No description provided for @recoveryBody.
  ///
  /// In vi, this message translates to:
  /// **'Chép tay 24 từ theo đúng thứ tự và cất nơi an toàn. Ai có 24 từ này sẽ đọc được toàn bộ dữ liệu. App sẽ không hiển thị lại.'**
  String get recoveryBody;

  /// No description provided for @recoveryConfirmCheck.
  ///
  /// In vi, this message translates to:
  /// **'Tôi đã chép lại đủ 24 từ'**
  String get recoveryConfirmCheck;

  /// No description provided for @recoveryVerifyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận từ khôi phục'**
  String get recoveryVerifyTitle;

  /// No description provided for @recoveryVerifyBody.
  ///
  /// In vi, this message translates to:
  /// **'Chọn đúng từ ở các vị trí được hỏi.'**
  String get recoveryVerifyBody;

  /// No description provided for @recoveryWordN.
  ///
  /// In vi, this message translates to:
  /// **'Từ thứ {n}'**
  String recoveryWordN(int n);

  /// No description provided for @recoveryVerifyWrong.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đúng. Kiểm tra lại bản chép tay.'**
  String get recoveryVerifyWrong;

  /// No description provided for @restoreTitle.
  ///
  /// In vi, this message translates to:
  /// **'Khôi phục bằng 24 từ'**
  String get restoreTitle;

  /// No description provided for @restoreBody.
  ///
  /// In vi, this message translates to:
  /// **'Nhập 24 từ cách nhau bằng dấu cách.'**
  String get restoreBody;

  /// No description provided for @restoreNeedsSync.
  ///
  /// In vi, this message translates to:
  /// **'Khôi phục dữ liệu từ máy chủ có ở bản đồng bộ (sắp ra mắt). Hiện tại chỉ mở khóa được dữ liệu trên chính thiết bị này.'**
  String get restoreNeedsSync;

  /// No description provided for @restoreInvalid.
  ///
  /// In vi, this message translates to:
  /// **'24 từ không hợp lệ'**
  String get restoreInvalid;

  /// No description provided for @pinSetupTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đặt PIN mở nhanh'**
  String get pinSetupTitle;

  /// No description provided for @pinSetupBody.
  ///
  /// In vi, this message translates to:
  /// **'PIN 6-12 chữ số để mở app nhanh trên thiết bị này. Sai 10 lần, PIN bị vô hiệu và cần mật khẩu.'**
  String get pinSetupBody;

  /// No description provided for @pinLabel.
  ///
  /// In vi, this message translates to:
  /// **'PIN'**
  String get pinLabel;

  /// No description provided for @pinConfirmLabel.
  ///
  /// In vi, this message translates to:
  /// **'Nhập lại PIN'**
  String get pinConfirmLabel;

  /// No description provided for @pinInvalid.
  ///
  /// In vi, this message translates to:
  /// **'PIN gồm 6-12 chữ số'**
  String get pinInvalid;

  /// No description provided for @pinMismatch.
  ///
  /// In vi, this message translates to:
  /// **'Hai PIN không khớp'**
  String get pinMismatch;

  /// No description provided for @pinSkip.
  ///
  /// In vi, this message translates to:
  /// **'Để sau'**
  String get pinSkip;

  /// No description provided for @lockTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đã khóa'**
  String get lockTitle;

  /// No description provided for @lockBody.
  ///
  /// In vi, this message translates to:
  /// **'Nhập PIN hoặc mật khẩu mã hóa để mở.'**
  String get lockBody;

  /// No description provided for @unlock.
  ///
  /// In vi, this message translates to:
  /// **'Mở khóa'**
  String get unlock;

  /// No description provided for @unlockWithPassword.
  ///
  /// In vi, this message translates to:
  /// **'Dùng mật khẩu'**
  String get unlockWithPassword;

  /// No description provided for @unlockWithPin.
  ///
  /// In vi, this message translates to:
  /// **'Dùng PIN'**
  String get unlockWithPin;

  /// No description provided for @unlockWithBiometric.
  ///
  /// In vi, this message translates to:
  /// **'Mở bằng sinh trắc'**
  String get unlockWithBiometric;

  /// No description provided for @unlockWithRecovery.
  ///
  /// In vi, this message translates to:
  /// **'Quên mật khẩu? Dùng 24 từ'**
  String get unlockWithRecovery;

  /// No description provided for @biometricReason.
  ///
  /// In vi, this message translates to:
  /// **'Xác thực để mở Quly Thu Chi'**
  String get biometricReason;

  /// No description provided for @pinWrong.
  ///
  /// In vi, this message translates to:
  /// **'PIN sai. Còn {n} lần thử.'**
  String pinWrong(int n);

  /// No description provided for @pinLockedOut.
  ///
  /// In vi, this message translates to:
  /// **'Sai nhiều lần. Thử lại sau {time}.'**
  String pinLockedOut(String time);

  /// No description provided for @pinDisabledMsg.
  ///
  /// In vi, this message translates to:
  /// **'PIN đã bị vô hiệu. Hãy mở bằng mật khẩu mã hóa.'**
  String get pinDisabledMsg;

  /// No description provided for @overviewTotal.
  ///
  /// In vi, this message translates to:
  /// **'Tổng số dư'**
  String get overviewTotal;

  /// No description provided for @overviewWallets.
  ///
  /// In vi, this message translates to:
  /// **'Các ví'**
  String get overviewWallets;

  /// No description provided for @overviewRecent.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch gần đây'**
  String get overviewRecent;

  /// No description provided for @overviewMonthIncome.
  ///
  /// In vi, this message translates to:
  /// **'Thu tháng này'**
  String get overviewMonthIncome;

  /// No description provided for @overviewMonthExpense.
  ///
  /// In vi, this message translates to:
  /// **'Chi tháng này'**
  String get overviewMonthExpense;

  /// No description provided for @seeAll.
  ///
  /// In vi, this message translates to:
  /// **'Xem tất cả'**
  String get seeAll;

  /// No description provided for @emptyWalletsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ví nào'**
  String get emptyWalletsTitle;

  /// No description provided for @emptyWalletsBody.
  ///
  /// In vi, this message translates to:
  /// **'Tạo ví đầu tiên (tiền mặt, tài khoản ngân hàng…) để bắt đầu ghi chép.'**
  String get emptyWalletsBody;

  /// No description provided for @emptyTxnsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có giao dịch'**
  String get emptyTxnsTitle;

  /// No description provided for @emptyTxnsBody.
  ///
  /// In vi, this message translates to:
  /// **'Bấm nút + để ghi khoản thu hoặc chi đầu tiên.'**
  String get emptyTxnsBody;

  /// No description provided for @noResults.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy kết quả'**
  String get noResults;

  /// No description provided for @hiddenAmount.
  ///
  /// In vi, this message translates to:
  /// **'Đã ẩn số tiền'**
  String get hiddenAmount;

  /// No description provided for @skippedRecords.
  ///
  /// In vi, this message translates to:
  /// **'{n} bản ghi không mở được (có thể đã hỏng) và đã được bỏ qua.'**
  String skippedRecords(int n);

  /// No description provided for @walletNew.
  ///
  /// In vi, this message translates to:
  /// **'Ví mới'**
  String get walletNew;

  /// No description provided for @walletEdit.
  ///
  /// In vi, this message translates to:
  /// **'Sửa ví'**
  String get walletEdit;

  /// No description provided for @walletName.
  ///
  /// In vi, this message translates to:
  /// **'Tên ví'**
  String get walletName;

  /// No description provided for @walletType.
  ///
  /// In vi, this message translates to:
  /// **'Loại ví'**
  String get walletType;

  /// No description provided for @walletCurrency.
  ///
  /// In vi, this message translates to:
  /// **'Tiền tệ'**
  String get walletCurrency;

  /// No description provided for @walletOpening.
  ///
  /// In vi, this message translates to:
  /// **'Số dư ban đầu'**
  String get walletOpening;

  /// No description provided for @walletCreditLimit.
  ///
  /// In vi, this message translates to:
  /// **'Hạn mức tín dụng'**
  String get walletCreditLimit;

  /// No description provided for @walletArchived.
  ///
  /// In vi, this message translates to:
  /// **'Lưu trữ (ẩn khỏi danh sách)'**
  String get walletArchived;

  /// No description provided for @walletExcludeTotal.
  ///
  /// In vi, this message translates to:
  /// **'Không tính vào tổng số dư'**
  String get walletExcludeTotal;

  /// No description provided for @walletBalance.
  ///
  /// In vi, this message translates to:
  /// **'Số dư'**
  String get walletBalance;

  /// No description provided for @walletDeleteConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xóa ví \"{name}\"?'**
  String walletDeleteConfirm(String name);

  /// No description provided for @walletTypeCash.
  ///
  /// In vi, this message translates to:
  /// **'Tiền mặt'**
  String get walletTypeCash;

  /// No description provided for @walletTypeBank.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản ngân hàng'**
  String get walletTypeBank;

  /// No description provided for @walletTypeCredit.
  ///
  /// In vi, this message translates to:
  /// **'Thẻ tín dụng'**
  String get walletTypeCredit;

  /// No description provided for @walletTypeEwallet.
  ///
  /// In vi, this message translates to:
  /// **'Ví điện tử'**
  String get walletTypeEwallet;

  /// No description provided for @walletTypeSaving.
  ///
  /// In vi, this message translates to:
  /// **'Tiết kiệm'**
  String get walletTypeSaving;

  /// No description provided for @walletTypeInvestment.
  ///
  /// In vi, this message translates to:
  /// **'Đầu tư'**
  String get walletTypeInvestment;

  /// No description provided for @walletTypeOther.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get walletTypeOther;

  /// No description provided for @showArchived.
  ///
  /// In vi, this message translates to:
  /// **'Hiện ví đã lưu trữ'**
  String get showArchived;

  /// No description provided for @categoryNew.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục mới'**
  String get categoryNew;

  /// No description provided for @categoryEdit.
  ///
  /// In vi, this message translates to:
  /// **'Sửa danh mục'**
  String get categoryEdit;

  /// No description provided for @categoryName.
  ///
  /// In vi, this message translates to:
  /// **'Tên danh mục'**
  String get categoryName;

  /// No description provided for @categoryParent.
  ///
  /// In vi, this message translates to:
  /// **'Thuộc nhóm'**
  String get categoryParent;

  /// No description provided for @categoryNoParent.
  ///
  /// In vi, this message translates to:
  /// **'(Nhóm chính)'**
  String get categoryNoParent;

  /// No description provided for @categoryExpense.
  ///
  /// In vi, this message translates to:
  /// **'Chi'**
  String get categoryExpense;

  /// No description provided for @categoryIncome.
  ///
  /// In vi, this message translates to:
  /// **'Thu'**
  String get categoryIncome;

  /// No description provided for @categoryDeleteConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xóa danh mục \"{name}\"? Danh mục con cũng bị xóa; giao dịch cũ chuyển thành \"Chưa phân loại\".'**
  String categoryDeleteConfirm(String name);

  /// No description provided for @uncategorized.
  ///
  /// In vi, this message translates to:
  /// **'Chưa phân loại'**
  String get uncategorized;

  /// No description provided for @txnNew.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch mới'**
  String get txnNew;

  /// No description provided for @txnEdit.
  ///
  /// In vi, this message translates to:
  /// **'Sửa giao dịch'**
  String get txnEdit;

  /// No description provided for @txnExpense.
  ///
  /// In vi, this message translates to:
  /// **'Chi'**
  String get txnExpense;

  /// No description provided for @txnIncome.
  ///
  /// In vi, this message translates to:
  /// **'Thu'**
  String get txnIncome;

  /// No description provided for @txnTransfer.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển ví'**
  String get txnTransfer;

  /// No description provided for @txnAdjustment.
  ///
  /// In vi, this message translates to:
  /// **'Điều chỉnh số dư'**
  String get txnAdjustment;

  /// No description provided for @txnAmount.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền'**
  String get txnAmount;

  /// No description provided for @txnAmountHint.
  ///
  /// In vi, this message translates to:
  /// **'Có thể nhập phép tính, ví dụ 50.000+25.000'**
  String get txnAmountHint;

  /// No description provided for @txnAmountResult.
  ///
  /// In vi, this message translates to:
  /// **'= {value}'**
  String txnAmountResult(String value);

  /// No description provided for @txnAmountInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền không hợp lệ'**
  String get txnAmountInvalid;

  /// No description provided for @txnAmountPositive.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền phải lớn hơn 0'**
  String get txnAmountPositive;

  /// No description provided for @txnReceived.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền nhận ({currency})'**
  String txnReceived(String currency);

  /// No description provided for @txnFee.
  ///
  /// In vi, this message translates to:
  /// **'Phí chuyển'**
  String get txnFee;

  /// No description provided for @txnWallet.
  ///
  /// In vi, this message translates to:
  /// **'Ví'**
  String get txnWallet;

  /// No description provided for @txnFromWallet.
  ///
  /// In vi, this message translates to:
  /// **'Từ ví'**
  String get txnFromWallet;

  /// No description provided for @txnToWallet.
  ///
  /// In vi, this message translates to:
  /// **'Tới ví'**
  String get txnToWallet;

  /// No description provided for @txnCategory.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục'**
  String get txnCategory;

  /// No description provided for @txnDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày'**
  String get txnDate;

  /// No description provided for @txnNote.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú'**
  String get txnNote;

  /// No description provided for @txnPayee.
  ///
  /// In vi, this message translates to:
  /// **'Người nhận / nơi chi'**
  String get txnPayee;

  /// No description provided for @txnTransferTo.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển tới {wallet}'**
  String txnTransferTo(String wallet);

  /// No description provided for @txnTransferFrom.
  ///
  /// In vi, this message translates to:
  /// **'Nhận từ {wallet}'**
  String txnTransferFrom(String wallet);

  /// No description provided for @txnDeleteConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xóa giao dịch này?'**
  String get txnDeleteConfirm;

  /// No description provided for @txnDeleteTransferConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xóa cả hai vế của lần chuyển ví này?'**
  String get txnDeleteTransferConfirm;

  /// No description provided for @selectWallet.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ví'**
  String get selectWallet;

  /// No description provided for @searchHint.
  ///
  /// In vi, this message translates to:
  /// **'Tìm ghi chú, danh mục, ví…'**
  String get searchHint;

  /// No description provided for @searchLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tìm giao dịch'**
  String get searchLabel;

  /// No description provided for @today.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In vi, this message translates to:
  /// **'Hôm qua'**
  String get yesterday;

  /// No description provided for @settingsAppearance.
  ///
  /// In vi, this message translates to:
  /// **'Giao diện'**
  String get settingsAppearance;

  /// No description provided for @themeLight.
  ///
  /// In vi, this message translates to:
  /// **'Sáng'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In vi, this message translates to:
  /// **'Tối'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In vi, this message translates to:
  /// **'Hệ thống'**
  String get themeSystem;

  /// No description provided for @settingsLanguage.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get settingsLanguage;

  /// No description provided for @settingsPrivacy.
  ///
  /// In vi, this message translates to:
  /// **'Riêng tư và bảo mật'**
  String get settingsPrivacy;

  /// No description provided for @settingsHideBalance.
  ///
  /// In vi, this message translates to:
  /// **'Ẩn số dư'**
  String get settingsHideBalance;

  /// No description provided for @settingsHideBalanceSub.
  ///
  /// In vi, this message translates to:
  /// **'Che mọi số tiền cho tới khi bạn bật lại'**
  String get settingsHideBalanceSub;

  /// No description provided for @settingsPin.
  ///
  /// In vi, this message translates to:
  /// **'PIN mở nhanh'**
  String get settingsPin;

  /// No description provided for @settingsPinOn.
  ///
  /// In vi, this message translates to:
  /// **'Đang bật'**
  String get settingsPinOn;

  /// No description provided for @settingsPinOff.
  ///
  /// In vi, this message translates to:
  /// **'Đang tắt'**
  String get settingsPinOff;

  /// No description provided for @settingsPinChange.
  ///
  /// In vi, this message translates to:
  /// **'Đổi PIN'**
  String get settingsPinChange;

  /// No description provided for @settingsPinDisable.
  ///
  /// In vi, this message translates to:
  /// **'Tắt PIN'**
  String get settingsPinDisable;

  /// No description provided for @settingsBiometric.
  ///
  /// In vi, this message translates to:
  /// **'Mở khóa bằng sinh trắc'**
  String get settingsBiometric;

  /// No description provided for @settingsBiometricSub.
  ///
  /// In vi, this message translates to:
  /// **'Cần bật PIN trước'**
  String get settingsBiometricSub;

  /// No description provided for @settingsBiometricUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị không hỗ trợ sinh trắc'**
  String get settingsBiometricUnavailable;

  /// No description provided for @settingsQuickUnlockWeb.
  ///
  /// In vi, this message translates to:
  /// **'Bản web không có PIN/sinh trắc vì trình duyệt không có kho bí mật an toàn.'**
  String get settingsQuickUnlockWeb;

  /// No description provided for @settingsAutoLock.
  ///
  /// In vi, this message translates to:
  /// **'Tự khóa khi rời app hơn 60 giây'**
  String get settingsAutoLock;

  /// No description provided for @settingsLockNow.
  ///
  /// In vi, this message translates to:
  /// **'Khóa ngay'**
  String get settingsLockNow;

  /// No description provided for @settingsChangePassword.
  ///
  /// In vi, this message translates to:
  /// **'Đổi mật khẩu mã hóa'**
  String get settingsChangePassword;

  /// No description provided for @settingsOldPassword.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu hiện tại'**
  String get settingsOldPassword;

  /// No description provided for @settingsNewPassword.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu mới'**
  String get settingsNewPassword;

  /// No description provided for @settingsPasswordChanged.
  ///
  /// In vi, this message translates to:
  /// **'Đã đổi mật khẩu mã hóa'**
  String get settingsPasswordChanged;

  /// No description provided for @settingsAbout.
  ///
  /// In vi, this message translates to:
  /// **'Giới thiệu'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In vi, this message translates to:
  /// **'Phiên bản {version}'**
  String settingsVersion(String version);

  /// No description provided for @settingsLicense.
  ///
  /// In vi, this message translates to:
  /// **'Mã nguồn mở AGPL-3.0'**
  String get settingsLicense;

  /// No description provided for @settingsReset.
  ///
  /// In vi, this message translates to:
  /// **'Xóa toàn bộ dữ liệu trên thiết bị'**
  String get settingsReset;

  /// No description provided for @settingsResetConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xóa vĩnh viễn mọi ví, danh mục, giao dịch và khóa trên thiết bị này? Không hoàn tác được.'**
  String get settingsResetConfirm;

  /// No description provided for @settingsResetTypeHint.
  ///
  /// In vi, this message translates to:
  /// **'Gõ XOA để xác nhận'**
  String get settingsResetTypeHint;

  /// No description provided for @settingsResetWord.
  ///
  /// In vi, this message translates to:
  /// **'XOA'**
  String get settingsResetWord;

  /// No description provided for @saved.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu'**
  String get saved;

  /// No description provided for @deleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã xóa'**
  String get deleted;

  /// No description provided for @errNameRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập tên'**
  String get errNameRequired;

  /// No description provided for @errCurrencyLocked.
  ///
  /// In vi, this message translates to:
  /// **'Ví đã có giao dịch, không đổi được tiền tệ'**
  String get errCurrencyLocked;

  /// No description provided for @errWalletHasTxns.
  ///
  /// In vi, this message translates to:
  /// **'Ví còn giao dịch. Hãy lưu trữ ví thay vì xóa.'**
  String get errWalletHasTxns;

  /// No description provided for @errParentMissing.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm cha không còn tồn tại'**
  String get errParentMissing;

  /// No description provided for @errTwoLevelsOnly.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục chỉ có 2 tầng'**
  String get errTwoLevelsOnly;

  /// No description provided for @errKindMismatch.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục không cùng loại thu/chi'**
  String get errKindMismatch;

  /// No description provided for @errWalletMissing.
  ///
  /// In vi, this message translates to:
  /// **'Hãy chọn ví'**
  String get errWalletMissing;

  /// No description provided for @errSameWallet.
  ///
  /// In vi, this message translates to:
  /// **'Ví nguồn và ví đích phải khác nhau'**
  String get errSameWallet;

  /// No description provided for @errReceivedRequired.
  ///
  /// In vi, this message translates to:
  /// **'Hai ví khác tiền tệ: nhập số tiền nhận'**
  String get errReceivedRequired;

  /// No description provided for @errGeneric.
  ///
  /// In vi, this message translates to:
  /// **'Đã có lỗi xảy ra. Vui lòng thử lại.'**
  String get errGeneric;

  /// No description provided for @errStorage.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được kho dữ liệu an toàn của thiết bị.'**
  String get errStorage;

  /// No description provided for @walletArchivedBadge.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu trữ'**
  String get walletArchivedBadge;

  /// No description provided for @settingsNewRecovery.
  ///
  /// In vi, this message translates to:
  /// **'Cấp 24 từ khôi phục mới'**
  String get settingsNewRecovery;

  /// No description provided for @settingsNewRecoveryConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Bộ 24 từ cũ sẽ hết hiệu lực. Tiếp tục?'**
  String get settingsNewRecoveryConfirm;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In vi, this message translates to:
  /// **'Theo hệ thống'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsSecurityNote.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu được mã hóa đầu-cuối bằng libsodium. Mật khẩu và 24 từ không bao giờ rời thiết bị.'**
  String get settingsSecurityNote;

  /// No description provided for @iconLabel.
  ///
  /// In vi, this message translates to:
  /// **'Biểu tượng'**
  String get iconLabel;

  /// No description provided for @navPlan.
  ///
  /// In vi, this message translates to:
  /// **'Kế hoạch'**
  String get navPlan;

  /// No description provided for @navMore.
  ///
  /// In vi, this message translates to:
  /// **'Thêm'**
  String get navMore;

  /// No description provided for @planBudgets.
  ///
  /// In vi, this message translates to:
  /// **'Ngân sách'**
  String get planBudgets;

  /// No description provided for @planJars.
  ///
  /// In vi, this message translates to:
  /// **'6 hũ'**
  String get planJars;

  /// No description provided for @planGoals.
  ///
  /// In vi, this message translates to:
  /// **'Mục tiêu'**
  String get planGoals;

  /// No description provided for @budgetNew.
  ///
  /// In vi, this message translates to:
  /// **'Ngân sách mới'**
  String get budgetNew;

  /// No description provided for @budgetEdit.
  ///
  /// In vi, this message translates to:
  /// **'Sửa ngân sách'**
  String get budgetEdit;

  /// No description provided for @budgetName.
  ///
  /// In vi, this message translates to:
  /// **'Tên ngân sách'**
  String get budgetName;

  /// No description provided for @budgetAmount.
  ///
  /// In vi, this message translates to:
  /// **'Hạn mức mỗi kỳ'**
  String get budgetAmount;

  /// No description provided for @budgetPeriod.
  ///
  /// In vi, this message translates to:
  /// **'Chu kỳ'**
  String get budgetPeriod;

  /// No description provided for @periodWeekly.
  ///
  /// In vi, this message translates to:
  /// **'Hằng tuần'**
  String get periodWeekly;

  /// No description provided for @periodMonthly.
  ///
  /// In vi, this message translates to:
  /// **'Hằng tháng'**
  String get periodMonthly;

  /// No description provided for @periodYearly.
  ///
  /// In vi, this message translates to:
  /// **'Hằng năm'**
  String get periodYearly;

  /// No description provided for @periodCustom.
  ///
  /// In vi, this message translates to:
  /// **'Tùy chọn'**
  String get periodCustom;

  /// No description provided for @budgetStartDay.
  ///
  /// In vi, this message translates to:
  /// **'Ngày bắt đầu kỳ (1-31)'**
  String get budgetStartDay;

  /// No description provided for @budgetStartWeekday.
  ///
  /// In vi, this message translates to:
  /// **'Kỳ bắt đầu vào'**
  String get budgetStartWeekday;

  /// No description provided for @budgetFrom.
  ///
  /// In vi, this message translates to:
  /// **'Từ ngày'**
  String get budgetFrom;

  /// No description provided for @budgetTo.
  ///
  /// In vi, this message translates to:
  /// **'Đến ngày'**
  String get budgetTo;

  /// No description provided for @budgetCategories.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục áp dụng'**
  String get budgetCategories;

  /// No description provided for @budgetAllCategories.
  ///
  /// In vi, this message translates to:
  /// **'Mọi khoản chi'**
  String get budgetAllCategories;

  /// No description provided for @budgetWallets.
  ///
  /// In vi, this message translates to:
  /// **'Ví áp dụng'**
  String get budgetWallets;

  /// No description provided for @budgetAllWallets.
  ///
  /// In vi, this message translates to:
  /// **'Mọi ví cùng tiền tệ'**
  String get budgetAllWallets;

  /// No description provided for @budgetRollover.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển phần dư/vượt sang kỳ sau'**
  String get budgetRollover;

  /// No description provided for @budgetAlertAt.
  ///
  /// In vi, this message translates to:
  /// **'Cảnh báo khi dùng tới (%)'**
  String get budgetAlertAt;

  /// No description provided for @budgetSpentOf.
  ///
  /// In vi, this message translates to:
  /// **'Đã chi {spent} / {limit}'**
  String budgetSpentOf(String spent, String limit);

  /// No description provided for @budgetRemaining.
  ///
  /// In vi, this message translates to:
  /// **'Còn {amount}'**
  String budgetRemaining(String amount);

  /// No description provided for @budgetOver.
  ///
  /// In vi, this message translates to:
  /// **'Vượt {amount}'**
  String budgetOver(String amount);

  /// No description provided for @budgetDaily.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi ngày còn được tiêu {amount}'**
  String budgetDaily(String amount);

  /// No description provided for @budgetStateOk.
  ///
  /// In vi, this message translates to:
  /// **'Trong hạn mức'**
  String get budgetStateOk;

  /// No description provided for @budgetStateWarning.
  ///
  /// In vi, this message translates to:
  /// **'Sắp hết hạn mức'**
  String get budgetStateWarning;

  /// No description provided for @budgetStateOver.
  ///
  /// In vi, this message translates to:
  /// **'Đã vượt hạn mức'**
  String get budgetStateOver;

  /// No description provided for @budgetDeleteConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xóa ngân sách \"{name}\"?'**
  String budgetDeleteConfirm(String name);

  /// No description provided for @emptyBudgetsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ngân sách'**
  String get emptyBudgetsTitle;

  /// No description provided for @emptyBudgetsBody.
  ///
  /// In vi, this message translates to:
  /// **'Đặt hạn mức chi theo tháng/tuần cho cả ví hoặc từng danh mục (phương pháp phong bì).'**
  String get emptyBudgetsBody;

  /// No description provided for @jarsIncomeThisMonth.
  ///
  /// In vi, this message translates to:
  /// **'Thu nhập tháng này ({currency})'**
  String jarsIncomeThisMonth(String currency);

  /// No description provided for @jarsSimulate.
  ///
  /// In vi, this message translates to:
  /// **'Thử chia một khoản thu'**
  String get jarsSimulate;

  /// No description provided for @jarsEdit.
  ///
  /// In vi, this message translates to:
  /// **'Sửa tỉ lệ các hũ'**
  String get jarsEdit;

  /// No description provided for @jarsReset.
  ///
  /// In vi, this message translates to:
  /// **'Về mặc định 6 hũ'**
  String get jarsReset;

  /// No description provided for @jarsTotalMustBe100.
  ///
  /// In vi, this message translates to:
  /// **'Tổng tỉ lệ phải đúng 100% (hiện {total}%)'**
  String jarsTotalMustBe100(String total);

  /// No description provided for @jarsNoIncome.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có khoản thu nào tháng này bằng {currency}.'**
  String jarsNoIncome(String currency);

  /// No description provided for @jarNec.
  ///
  /// In vi, this message translates to:
  /// **'Thiết yếu'**
  String get jarNec;

  /// No description provided for @jarLts.
  ///
  /// In vi, this message translates to:
  /// **'Tiết kiệm dài hạn'**
  String get jarLts;

  /// No description provided for @jarEdu.
  ///
  /// In vi, this message translates to:
  /// **'Giáo dục'**
  String get jarEdu;

  /// No description provided for @jarPly.
  ///
  /// In vi, this message translates to:
  /// **'Hưởng thụ'**
  String get jarPly;

  /// No description provided for @jarFfa.
  ///
  /// In vi, this message translates to:
  /// **'Tự do tài chính'**
  String get jarFfa;

  /// No description provided for @jarGiv.
  ///
  /// In vi, this message translates to:
  /// **'Cho đi'**
  String get jarGiv;

  /// No description provided for @jarsNote.
  ///
  /// In vi, this message translates to:
  /// **'Phương pháp 6 hũ: chia mọi khoản thu theo tỉ lệ cố định để chi tiêu có kỷ luật.'**
  String get jarsNote;

  /// No description provided for @goalNew.
  ///
  /// In vi, this message translates to:
  /// **'Mục tiêu mới'**
  String get goalNew;

  /// No description provided for @goalEdit.
  ///
  /// In vi, this message translates to:
  /// **'Sửa mục tiêu'**
  String get goalEdit;

  /// No description provided for @goalName.
  ///
  /// In vi, this message translates to:
  /// **'Tên mục tiêu'**
  String get goalName;

  /// No description provided for @goalTarget.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền cần'**
  String get goalTarget;

  /// No description provided for @goalStarting.
  ///
  /// In vi, this message translates to:
  /// **'Đã có sẵn'**
  String get goalStarting;

  /// No description provided for @goalDeadline.
  ///
  /// In vi, this message translates to:
  /// **'Hạn hoàn thành'**
  String get goalDeadline;

  /// No description provided for @goalNoDeadline.
  ///
  /// In vi, this message translates to:
  /// **'Không có hạn'**
  String get goalNoDeadline;

  /// No description provided for @goalAchieved.
  ///
  /// In vi, this message translates to:
  /// **'Đã hoàn thành'**
  String get goalAchieved;

  /// No description provided for @goalProgress.
  ///
  /// In vi, this message translates to:
  /// **'{saved} / {target} ({percent}%)'**
  String goalProgress(String saved, String target, String percent);

  /// No description provided for @goalMonthly.
  ///
  /// In vi, this message translates to:
  /// **'Cần góp {amount} mỗi tháng để kịp hạn'**
  String goalMonthly(String amount);

  /// No description provided for @goalContribute.
  ///
  /// In vi, this message translates to:
  /// **'Góp tiền'**
  String get goalContribute;

  /// No description provided for @goalDeleteConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xóa mục tiêu \"{name}\"? Giao dịch đã góp vẫn giữ nguyên.'**
  String goalDeleteConfirm(String name);

  /// No description provided for @emptyGoalsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có mục tiêu'**
  String get emptyGoalsTitle;

  /// No description provided for @emptyGoalsBody.
  ///
  /// In vi, this message translates to:
  /// **'Đặt mục tiêu tiết kiệm (mua xe, du lịch…) và theo dõi tiến độ.'**
  String get emptyGoalsBody;

  /// No description provided for @clearValue.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ chọn'**
  String get clearValue;

  /// No description provided for @selectAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get selectAll;

  /// No description provided for @none.
  ///
  /// In vi, this message translates to:
  /// **'Không'**
  String get none;

  /// No description provided for @moreRecurring.
  ///
  /// In vi, this message translates to:
  /// **'Định kỳ và hóa đơn'**
  String get moreRecurring;

  /// No description provided for @moreDebts.
  ///
  /// In vi, this message translates to:
  /// **'Sổ nợ / cho vay'**
  String get moreDebts;

  /// No description provided for @moreEvents.
  ///
  /// In vi, this message translates to:
  /// **'Sự kiện, chuyến đi'**
  String get moreEvents;

  /// No description provided for @moreRates.
  ///
  /// In vi, this message translates to:
  /// **'Tỉ giá'**
  String get moreRates;

  /// No description provided for @recurringNew.
  ///
  /// In vi, this message translates to:
  /// **'Khoản định kỳ mới'**
  String get recurringNew;

  /// No description provided for @recurringEdit.
  ///
  /// In vi, this message translates to:
  /// **'Sửa khoản định kỳ'**
  String get recurringEdit;

  /// No description provided for @recurringName.
  ///
  /// In vi, this message translates to:
  /// **'Tên khoản'**
  String get recurringName;

  /// No description provided for @recurringFrequency.
  ///
  /// In vi, this message translates to:
  /// **'Lặp lại'**
  String get recurringFrequency;

  /// No description provided for @freqDaily.
  ///
  /// In vi, this message translates to:
  /// **'Hằng ngày'**
  String get freqDaily;

  /// No description provided for @freqWeekly.
  ///
  /// In vi, this message translates to:
  /// **'Hằng tuần'**
  String get freqWeekly;

  /// No description provided for @freqMonthly.
  ///
  /// In vi, this message translates to:
  /// **'Hằng tháng'**
  String get freqMonthly;

  /// No description provided for @freqYearly.
  ///
  /// In vi, this message translates to:
  /// **'Hằng năm'**
  String get freqYearly;

  /// No description provided for @recurringInterval.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi bao nhiêu kỳ'**
  String get recurringInterval;

  /// No description provided for @recurringStart.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu từ'**
  String get recurringStart;

  /// No description provided for @recurringUntil.
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc (không bắt buộc)'**
  String get recurringUntil;

  /// No description provided for @recurringIsBill.
  ///
  /// In vi, this message translates to:
  /// **'Là hóa đơn (hiện trong lịch hóa đơn, có nhắc)'**
  String get recurringIsBill;

  /// No description provided for @recurringAuto.
  ///
  /// In vi, this message translates to:
  /// **'Tự ghi giao dịch khi đến hạn'**
  String get recurringAuto;

  /// No description provided for @recurringAutoOff.
  ///
  /// In vi, this message translates to:
  /// **'Tắt: giao dịch được tạo ở trạng thái chờ bạn xác nhận'**
  String get recurringAutoOff;

  /// No description provided for @recurringRemind.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc trước (ngày)'**
  String get recurringRemind;

  /// No description provided for @recurringPaused.
  ///
  /// In vi, this message translates to:
  /// **'Tạm dừng'**
  String get recurringPaused;

  /// No description provided for @recurringNext.
  ///
  /// In vi, this message translates to:
  /// **'Lần tới: {date}'**
  String recurringNext(String date);

  /// No description provided for @recurringEnded.
  ///
  /// In vi, this message translates to:
  /// **'Đã kết thúc'**
  String get recurringEnded;

  /// No description provided for @recurringDeleteConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xóa khoản \"{name}\"? Giao dịch đã tạo vẫn giữ nguyên.'**
  String recurringDeleteConfirm(String name);

  /// No description provided for @emptyRecurringTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có khoản định kỳ'**
  String get emptyRecurringTitle;

  /// No description provided for @emptyRecurringBody.
  ///
  /// In vi, this message translates to:
  /// **'Thêm tiền nhà, điện nước, lương… để app tự ghi và nhắc trước hạn.'**
  String get emptyRecurringBody;

  /// No description provided for @billsUpcoming.
  ///
  /// In vi, this message translates to:
  /// **'Hóa đơn sắp đến hạn'**
  String get billsUpcoming;

  /// No description provided for @billDueIn.
  ///
  /// In vi, this message translates to:
  /// **'Đến hạn {date} (còn {days} ngày)'**
  String billDueIn(String date, int days);

  /// No description provided for @billDueToday.
  ///
  /// In vi, this message translates to:
  /// **'Đến hạn hôm nay'**
  String get billDueToday;

  /// No description provided for @billPay.
  ///
  /// In vi, this message translates to:
  /// **'Đã trả'**
  String get billPay;

  /// No description provided for @billPaid.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi nhận thanh toán'**
  String get billPaid;

  /// No description provided for @pendingTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chờ xác nhận ({n})'**
  String pendingTitle(int n);

  /// No description provided for @pendingConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận'**
  String get pendingConfirm;

  /// No description provided for @pendingSkip.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua'**
  String get pendingSkip;

  /// No description provided for @pendingBanner.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch tự tạo, chưa tính vào số dư.'**
  String get pendingBanner;

  /// No description provided for @budgetAlertsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ngân sách cần chú ý'**
  String get budgetAlertsTitle;

  /// No description provided for @debtNew.
  ///
  /// In vi, this message translates to:
  /// **'Khoản nợ mới'**
  String get debtNew;

  /// No description provided for @debtEdit.
  ///
  /// In vi, this message translates to:
  /// **'Khoản nợ'**
  String get debtEdit;

  /// No description provided for @debtKind.
  ///
  /// In vi, this message translates to:
  /// **'Loại'**
  String get debtKind;

  /// No description provided for @debtLend.
  ///
  /// In vi, this message translates to:
  /// **'Cho vay'**
  String get debtLend;

  /// No description provided for @debtBorrow.
  ///
  /// In vi, this message translates to:
  /// **'Đi vay'**
  String get debtBorrow;

  /// No description provided for @debtCounterparty.
  ///
  /// In vi, this message translates to:
  /// **'Người vay / cho vay'**
  String get debtCounterparty;

  /// No description provided for @debtPrincipal.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền gốc'**
  String get debtPrincipal;

  /// No description provided for @debtStart.
  ///
  /// In vi, this message translates to:
  /// **'Ngày vay'**
  String get debtStart;

  /// No description provided for @debtDue.
  ///
  /// In vi, this message translates to:
  /// **'Hạn trả'**
  String get debtDue;

  /// No description provided for @debtInterest.
  ///
  /// In vi, this message translates to:
  /// **'Lãi suất năm (%)'**
  String get debtInterest;

  /// No description provided for @debtRecordDisbursement.
  ///
  /// In vi, this message translates to:
  /// **'Ghi giao dịch tiền ra/vào ví ngay'**
  String get debtRecordDisbursement;

  /// No description provided for @debtPaid.
  ///
  /// In vi, this message translates to:
  /// **'Đã trả {amount}'**
  String debtPaid(String amount);

  /// No description provided for @debtRemaining.
  ///
  /// In vi, this message translates to:
  /// **'Còn lại {amount}'**
  String debtRemaining(String amount);

  /// No description provided for @debtSettled.
  ///
  /// In vi, this message translates to:
  /// **'Đã tất toán'**
  String get debtSettled;

  /// No description provided for @debtRecordPayment.
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhận trả nợ'**
  String get debtRecordPayment;

  /// No description provided for @debtCollect.
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhận thu nợ'**
  String get debtCollect;

  /// No description provided for @debtClose.
  ///
  /// In vi, this message translates to:
  /// **'Đóng khoản nợ'**
  String get debtClose;

  /// No description provided for @debtClosed.
  ///
  /// In vi, this message translates to:
  /// **'Đã đóng'**
  String get debtClosed;

  /// No description provided for @debtOverdue.
  ///
  /// In vi, this message translates to:
  /// **'Quá hạn'**
  String get debtOverdue;

  /// No description provided for @debtPayments.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử thanh toán'**
  String get debtPayments;

  /// No description provided for @debtDeleteConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xóa khoản nợ với \"{name}\"? Giao dịch đã ghi vẫn giữ nguyên.'**
  String debtDeleteConfirm(String name);

  /// No description provided for @emptyDebtsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có khoản nợ nào'**
  String get emptyDebtsTitle;

  /// No description provided for @emptyDebtsBody.
  ///
  /// In vi, this message translates to:
  /// **'Ghi lại tiền cho vay, đi vay và theo dõi trả dần.'**
  String get emptyDebtsBody;

  /// No description provided for @debtsLendTotal.
  ///
  /// In vi, this message translates to:
  /// **'Đang cho vay'**
  String get debtsLendTotal;

  /// No description provided for @debtsBorrowTotal.
  ///
  /// In vi, this message translates to:
  /// **'Đang nợ'**
  String get debtsBorrowTotal;

  /// No description provided for @eventNew.
  ///
  /// In vi, this message translates to:
  /// **'Sự kiện mới'**
  String get eventNew;

  /// No description provided for @eventEdit.
  ///
  /// In vi, this message translates to:
  /// **'Sự kiện'**
  String get eventEdit;

  /// No description provided for @eventName.
  ///
  /// In vi, this message translates to:
  /// **'Tên sự kiện / chuyến đi'**
  String get eventName;

  /// No description provided for @eventStart.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu'**
  String get eventStart;

  /// No description provided for @eventEnd.
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc'**
  String get eventEnd;

  /// No description provided for @eventBudget.
  ///
  /// In vi, this message translates to:
  /// **'Ngân sách (không bắt buộc)'**
  String get eventBudget;

  /// No description provided for @eventBudgetCurrency.
  ///
  /// In vi, this message translates to:
  /// **'Tiền tệ ngân sách'**
  String get eventBudgetCurrency;

  /// No description provided for @eventSpent.
  ///
  /// In vi, this message translates to:
  /// **'Đã chi {amount}'**
  String eventSpent(String amount);

  /// No description provided for @eventTxns.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch của sự kiện'**
  String get eventTxns;

  /// No description provided for @eventDeleteConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xóa sự kiện \"{name}\"? Giao dịch vẫn giữ nguyên.'**
  String eventDeleteConfirm(String name);

  /// No description provided for @emptyEventsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có sự kiện'**
  String get emptyEventsTitle;

  /// No description provided for @emptyEventsBody.
  ///
  /// In vi, this message translates to:
  /// **'Gắn giao dịch vào chuyến đi, đám cưới… để tổng kết riêng.'**
  String get emptyEventsBody;

  /// No description provided for @txnEvent.
  ///
  /// In vi, this message translates to:
  /// **'Sự kiện'**
  String get txnEvent;

  /// No description provided for @txnGoal.
  ///
  /// In vi, this message translates to:
  /// **'Góp cho mục tiêu'**
  String get txnGoal;

  /// No description provided for @ratesBase.
  ///
  /// In vi, this message translates to:
  /// **'Tiền tệ quy đổi tổng'**
  String get ratesBase;

  /// No description provided for @ratesNew.
  ///
  /// In vi, this message translates to:
  /// **'Thêm tỉ giá'**
  String get ratesNew;

  /// No description provided for @ratesFrom.
  ///
  /// In vi, this message translates to:
  /// **'Từ tiền tệ'**
  String get ratesFrom;

  /// No description provided for @ratesValue.
  ///
  /// In vi, this message translates to:
  /// **'1 {from} = ? {to}'**
  String ratesValue(String from, String to);

  /// No description provided for @ratesInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Tỉ giá không hợp lệ'**
  String get ratesInvalid;

  /// No description provided for @ratesNote.
  ///
  /// In vi, this message translates to:
  /// **'Tỉ giá nhập tay. Tự cập nhật qua máy chủ Quly Thu Chi sẽ có khi bật đồng bộ.'**
  String get ratesNote;

  /// No description provided for @ratesMissing.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có tỉ giá cho: {codes}'**
  String ratesMissing(String codes);

  /// No description provided for @emptyRatesTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có tỉ giá'**
  String get emptyRatesTitle;

  /// No description provided for @emptyRatesBody.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ cần khi bạn có ví bằng nhiều loại tiền.'**
  String get emptyRatesBody;

  /// No description provided for @overviewTotalIn.
  ///
  /// In vi, this message translates to:
  /// **'Tổng quy đổi ({currency})'**
  String overviewTotalIn(String currency);

  /// No description provided for @errAlertRange.
  ///
  /// In vi, this message translates to:
  /// **'Ngưỡng cảnh báo từ 10% đến 100%'**
  String get errAlertRange;

  /// No description provided for @errDateRange.
  ///
  /// In vi, this message translates to:
  /// **'Ngày kết thúc phải sau ngày bắt đầu'**
  String get errDateRange;

  /// No description provided for @errSameCurrency.
  ///
  /// In vi, this message translates to:
  /// **'Hai tiền tệ phải khác nhau'**
  String get errSameCurrency;

  /// No description provided for @errRateInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Giá trị không hợp lệ'**
  String get errRateInvalid;

  /// No description provided for @errRemindRange.
  ///
  /// In vi, this message translates to:
  /// **'Số ngày nhắc từ 0 đến 30'**
  String get errRemindRange;

  /// No description provided for @errNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không còn tồn tại'**
  String get errNotFound;

  /// No description provided for @errWalletLocked.
  ///
  /// In vi, this message translates to:
  /// **'Không đổi được ví của khoản này'**
  String get errWalletLocked;

  /// No description provided for @weekday1.
  ///
  /// In vi, this message translates to:
  /// **'Thứ Hai'**
  String get weekday1;

  /// No description provided for @weekday2.
  ///
  /// In vi, this message translates to:
  /// **'Thứ Ba'**
  String get weekday2;

  /// No description provided for @weekday3.
  ///
  /// In vi, this message translates to:
  /// **'Thứ Tư'**
  String get weekday3;

  /// No description provided for @weekday4.
  ///
  /// In vi, this message translates to:
  /// **'Thứ Năm'**
  String get weekday4;

  /// No description provided for @weekday5.
  ///
  /// In vi, this message translates to:
  /// **'Thứ Sáu'**
  String get weekday5;

  /// No description provided for @weekday6.
  ///
  /// In vi, this message translates to:
  /// **'Thứ Bảy'**
  String get weekday6;

  /// No description provided for @weekday7.
  ///
  /// In vi, this message translates to:
  /// **'Chủ Nhật'**
  String get weekday7;

  /// No description provided for @notifBillTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hóa đơn sắp đến hạn'**
  String get notifBillTitle;

  /// No description provided for @notifBillBody.
  ///
  /// In vi, this message translates to:
  /// **'Mở Quly Thu Chi để xem chi tiết.'**
  String get notifBillBody;

  /// No description provided for @settingsNotifications.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc hóa đơn'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationsSub.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo không chứa tên hay số tiền, để không lộ trên màn hình khóa'**
  String get settingsNotificationsSub;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
