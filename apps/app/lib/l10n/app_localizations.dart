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

  /// No description provided for @pendingLabel.
  ///
  /// In vi, this message translates to:
  /// **'Chờ xác nhận'**
  String get pendingLabel;

  /// No description provided for @navReports.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo'**
  String get navReports;

  /// No description provided for @reportThisMonth.
  ///
  /// In vi, this message translates to:
  /// **'Tháng này'**
  String get reportThisMonth;

  /// No description provided for @reportLastMonth.
  ///
  /// In vi, this message translates to:
  /// **'Tháng trước'**
  String get reportLastMonth;

  /// No description provided for @reportLast3Months.
  ///
  /// In vi, this message translates to:
  /// **'3 tháng gần đây'**
  String get reportLast3Months;

  /// No description provided for @reportThisYear.
  ///
  /// In vi, this message translates to:
  /// **'Năm nay'**
  String get reportThisYear;

  /// No description provided for @reportIncome.
  ///
  /// In vi, this message translates to:
  /// **'Thu'**
  String get reportIncome;

  /// No description provided for @reportExpense.
  ///
  /// In vi, this message translates to:
  /// **'Chi'**
  String get reportExpense;

  /// No description provided for @reportNet.
  ///
  /// In vi, this message translates to:
  /// **'Chênh lệch'**
  String get reportNet;

  /// No description provided for @reportSavingsRate.
  ///
  /// In vi, this message translates to:
  /// **'Tỉ lệ tiết kiệm'**
  String get reportSavingsRate;

  /// No description provided for @reportMonthly.
  ///
  /// In vi, this message translates to:
  /// **'Thu chi 6 tháng gần đây'**
  String get reportMonthly;

  /// No description provided for @reportByCategory.
  ///
  /// In vi, this message translates to:
  /// **'Chi theo danh mục'**
  String get reportByCategory;

  /// No description provided for @reportNetWorth.
  ///
  /// In vi, this message translates to:
  /// **'Tài sản ròng'**
  String get reportNetWorth;

  /// No description provided for @reportCalendar.
  ///
  /// In vi, this message translates to:
  /// **'Lịch chi tiêu {month}'**
  String reportCalendar(String month);

  /// No description provided for @reportOther.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get reportOther;

  /// No description provided for @reportMonthReadout.
  ///
  /// In vi, this message translates to:
  /// **'Tháng {month}: thu {income} · chi {expense}'**
  String reportMonthReadout(String month, String income, String expense);

  /// No description provided for @reportPointReadout.
  ///
  /// In vi, this message translates to:
  /// **'Tháng {month}: {amount}'**
  String reportPointReadout(String month, String amount);

  /// No description provided for @reportDayReadout.
  ///
  /// In vi, this message translates to:
  /// **'{date}: chi {amount}'**
  String reportDayReadout(String date, String amount);

  /// No description provided for @reportTapDay.
  ///
  /// In vi, this message translates to:
  /// **'Chạm vào một ngày để xem số tiền'**
  String get reportTapDay;

  /// No description provided for @reportEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có khoản chi nào trong kỳ này'**
  String get reportEmpty;

  /// No description provided for @reportShowTable.
  ///
  /// In vi, this message translates to:
  /// **'Xem dạng bảng'**
  String get reportShowTable;

  /// No description provided for @reportShowChart.
  ///
  /// In vi, this message translates to:
  /// **'Xem biểu đồ'**
  String get reportShowChart;

  /// No description provided for @reportColMonth.
  ///
  /// In vi, this message translates to:
  /// **'Tháng'**
  String get reportColMonth;

  /// No description provided for @reportColCategory.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục'**
  String get reportColCategory;

  /// No description provided for @reportColAmount.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền'**
  String get reportColAmount;

  /// No description provided for @reportColShare.
  ///
  /// In vi, this message translates to:
  /// **'Tỉ trọng'**
  String get reportColShare;

  /// No description provided for @reportColDay.
  ///
  /// In vi, this message translates to:
  /// **'Ngày'**
  String get reportColDay;

  /// No description provided for @reportLess.
  ///
  /// In vi, this message translates to:
  /// **'Ít'**
  String get reportLess;

  /// No description provided for @reportMore.
  ///
  /// In vi, this message translates to:
  /// **'Nhiều'**
  String get reportMore;

  /// No description provided for @weekdayShort1.
  ///
  /// In vi, this message translates to:
  /// **'T2'**
  String get weekdayShort1;

  /// No description provided for @weekdayShort2.
  ///
  /// In vi, this message translates to:
  /// **'T3'**
  String get weekdayShort2;

  /// No description provided for @weekdayShort3.
  ///
  /// In vi, this message translates to:
  /// **'T4'**
  String get weekdayShort3;

  /// No description provided for @weekdayShort4.
  ///
  /// In vi, this message translates to:
  /// **'T5'**
  String get weekdayShort4;

  /// No description provided for @weekdayShort5.
  ///
  /// In vi, this message translates to:
  /// **'T6'**
  String get weekdayShort5;

  /// No description provided for @weekdayShort6.
  ///
  /// In vi, this message translates to:
  /// **'T7'**
  String get weekdayShort6;

  /// No description provided for @weekdayShort7.
  ///
  /// In vi, this message translates to:
  /// **'CN'**
  String get weekdayShort7;

  /// No description provided for @safeTitle.
  ///
  /// In vi, this message translates to:
  /// **'An toàn để tiêu tháng này'**
  String get safeTitle;

  /// No description provided for @safePerDay.
  ///
  /// In vi, this message translates to:
  /// **'Khoảng {amount} mỗi ngày tới cuối tháng'**
  String safePerDay(String amount);

  /// No description provided for @safeOver.
  ///
  /// In vi, this message translates to:
  /// **'Đã vượt kế hoạch tháng {amount}'**
  String safeOver(String amount);

  /// No description provided for @safeExplain.
  ///
  /// In vi, this message translates to:
  /// **'Thu {income} − đã chi {spent} − hóa đơn sắp tới {bills} − góp mục tiêu {goals}'**
  String safeExplain(String income, String spent, String bills, String goals);

  /// No description provided for @filterTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bộ lọc'**
  String get filterTitle;

  /// No description provided for @filterKinds.
  ///
  /// In vi, this message translates to:
  /// **'Loại giao dịch'**
  String get filterKinds;

  /// No description provided for @filterAllKinds.
  ///
  /// In vi, this message translates to:
  /// **'Mọi loại'**
  String get filterAllKinds;

  /// No description provided for @filterWallets.
  ///
  /// In vi, this message translates to:
  /// **'Ví'**
  String get filterWallets;

  /// No description provided for @filterAllWallets.
  ///
  /// In vi, this message translates to:
  /// **'Mọi ví'**
  String get filterAllWallets;

  /// No description provided for @filterCategories.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục'**
  String get filterCategories;

  /// No description provided for @filterAllCategories.
  ///
  /// In vi, this message translates to:
  /// **'Mọi danh mục'**
  String get filterAllCategories;

  /// No description provided for @filterUncategorized.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ giao dịch chưa phân loại'**
  String get filterUncategorized;

  /// No description provided for @filterMin.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền từ'**
  String get filterMin;

  /// No description provided for @filterMax.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền đến'**
  String get filterMax;

  /// No description provided for @filterApply.
  ///
  /// In vi, this message translates to:
  /// **'Áp dụng'**
  String get filterApply;

  /// No description provided for @filterClear.
  ///
  /// In vi, this message translates to:
  /// **'Xóa lọc'**
  String get filterClear;

  /// No description provided for @filterSave.
  ///
  /// In vi, this message translates to:
  /// **'Lưu bộ lọc'**
  String get filterSave;

  /// No description provided for @filterSaveName.
  ///
  /// In vi, this message translates to:
  /// **'Tên bộ lọc'**
  String get filterSaveName;

  /// No description provided for @filterSaved.
  ///
  /// In vi, this message translates to:
  /// **'Bộ lọc đã lưu'**
  String get filterSaved;

  /// No description provided for @filterActive.
  ///
  /// In vi, this message translates to:
  /// **'Đang lọc: {n} điều kiện'**
  String filterActive(int n);

  /// No description provided for @filterResultCount.
  ///
  /// In vi, this message translates to:
  /// **'{n} giao dịch'**
  String filterResultCount(int n);

  /// No description provided for @dataTitle.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu: xuất, nhập, sao lưu'**
  String get dataTitle;

  /// No description provided for @exportTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xuất giao dịch'**
  String get exportTitle;

  /// No description provided for @exportFormat.
  ///
  /// In vi, this message translates to:
  /// **'Định dạng'**
  String get exportFormat;

  /// No description provided for @exportWarning.
  ///
  /// In vi, this message translates to:
  /// **'Tệp xuất KHÔNG mã hóa: ai có tệp sẽ đọc được toàn bộ giao dịch. Chỉ lưu ở nơi an toàn.'**
  String get exportWarning;

  /// No description provided for @exportDone.
  ///
  /// In vi, this message translates to:
  /// **'Đã xuất {n} giao dịch'**
  String exportDone(int n);

  /// No description provided for @exportRange.
  ///
  /// In vi, this message translates to:
  /// **'Khoảng ngày'**
  String get exportRange;

  /// No description provided for @exportAllTime.
  ///
  /// In vi, this message translates to:
  /// **'Toàn bộ'**
  String get exportAllTime;

  /// No description provided for @exportCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Đã hủy'**
  String get exportCancelled;

  /// No description provided for @importTitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhập từ tệp CSV'**
  String get importTitle;

  /// No description provided for @importPick.
  ///
  /// In vi, this message translates to:
  /// **'Chọn tệp CSV'**
  String get importPick;

  /// No description provided for @importMapping.
  ///
  /// In vi, this message translates to:
  /// **'Ghép cột'**
  String get importMapping;

  /// No description provided for @importColDate.
  ///
  /// In vi, this message translates to:
  /// **'Cột ngày'**
  String get importColDate;

  /// No description provided for @importColAmount.
  ///
  /// In vi, this message translates to:
  /// **'Cột số tiền'**
  String get importColAmount;

  /// No description provided for @importColNote.
  ///
  /// In vi, this message translates to:
  /// **'Cột ghi chú'**
  String get importColNote;

  /// No description provided for @importColCategory.
  ///
  /// In vi, this message translates to:
  /// **'Cột danh mục'**
  String get importColCategory;

  /// No description provided for @importColType.
  ///
  /// In vi, this message translates to:
  /// **'Cột loại (thu/chi)'**
  String get importColType;

  /// No description provided for @importNone.
  ///
  /// In vi, this message translates to:
  /// **'(không có)'**
  String get importNone;

  /// No description provided for @importSignMode.
  ///
  /// In vi, this message translates to:
  /// **'Số âm là khoản chi'**
  String get importSignMode;

  /// No description provided for @importWallet.
  ///
  /// In vi, this message translates to:
  /// **'Nhập vào ví'**
  String get importWallet;

  /// No description provided for @importPreview.
  ///
  /// In vi, this message translates to:
  /// **'Xem trước {n} dòng đầu'**
  String importPreview(int n);

  /// No description provided for @importRun.
  ///
  /// In vi, this message translates to:
  /// **'Nhập {n} giao dịch'**
  String importRun(int n);

  /// No description provided for @importDone.
  ///
  /// In vi, this message translates to:
  /// **'Đã nhập {ok} giao dịch, bỏ qua {skipped} dòng lỗi'**
  String importDone(int ok, int skipped);

  /// No description provided for @importEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Tệp trống hoặc không đọc được'**
  String get importEmpty;

  /// No description provided for @importTooBig.
  ///
  /// In vi, this message translates to:
  /// **'Tệp quá lớn (tối đa 5 MB)'**
  String get importTooBig;

  /// No description provided for @importDateFormat.
  ///
  /// In vi, this message translates to:
  /// **'Định dạng ngày'**
  String get importDateFormat;

  /// No description provided for @backupTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sao lưu mã hóa'**
  String get backupTitle;

  /// No description provided for @backupBody.
  ///
  /// In vi, this message translates to:
  /// **'Tệp sao lưu được mã hóa đầu-cuối; chỉ mở được bằng mật khẩu mã hóa hoặc 24 từ của bạn.'**
  String get backupBody;

  /// No description provided for @backupCreate.
  ///
  /// In vi, this message translates to:
  /// **'Tạo tệp sao lưu'**
  String get backupCreate;

  /// No description provided for @backupDone.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu tệp sao lưu'**
  String get backupDone;

  /// No description provided for @restoreFromBackup.
  ///
  /// In vi, this message translates to:
  /// **'Khôi phục từ tệp sao lưu'**
  String get restoreFromBackup;

  /// No description provided for @restoreBackupBody.
  ///
  /// In vi, this message translates to:
  /// **'Chọn tệp .qtbak rồi nhập mật khẩu mã hóa của tài khoản đã sao lưu.'**
  String get restoreBackupBody;

  /// No description provided for @restoreBackupInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Tệp không phải bản sao lưu Quly Thu Chi hoặc đã hỏng'**
  String get restoreBackupInvalid;

  /// No description provided for @restoreBackupDone.
  ///
  /// In vi, this message translates to:
  /// **'Đã khôi phục {n} bản ghi'**
  String restoreBackupDone(int n);

  /// No description provided for @restoreUseRecovery.
  ///
  /// In vi, this message translates to:
  /// **'Dùng 24 từ thay cho mật khẩu'**
  String get restoreUseRecovery;

  /// No description provided for @exportColSubcategory.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục con'**
  String get exportColSubcategory;

  /// No description provided for @exportColCurrency.
  ///
  /// In vi, this message translates to:
  /// **'Tiền tệ'**
  String get exportColCurrency;

  /// No description provided for @importHasHeader.
  ///
  /// In vi, this message translates to:
  /// **'Dòng đầu là tiêu đề cột'**
  String get importHasHeader;

  /// No description provided for @importNeedWallet.
  ///
  /// In vi, this message translates to:
  /// **'Hãy tạo ví trước khi nhập'**
  String get importNeedWallet;

  /// No description provided for @restoreWordsLabel.
  ///
  /// In vi, this message translates to:
  /// **'24 từ khôi phục'**
  String get restoreWordsLabel;

  /// No description provided for @backupPrivacyNote.
  ///
  /// In vi, this message translates to:
  /// **'Tệp sao lưu chứa toàn bộ dữ liệu đã mã hóa và gói khóa; mất mật khẩu và 24 từ thì không ai mở được.'**
  String get backupPrivacyNote;

  /// No description provided for @reportVsPrevious.
  ///
  /// In vi, this message translates to:
  /// **'{pct} so với kỳ trước'**
  String reportVsPrevious(String pct);

  /// No description provided for @syncTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản & đồng bộ'**
  String get syncTitle;

  /// No description provided for @syncWelcomeSignIn.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập để lấy dữ liệu đã đồng bộ'**
  String get syncWelcomeSignIn;

  /// No description provided for @syncSignIn.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập bằng tài khoản TsuDEV'**
  String get syncSignIn;

  /// No description provided for @syncWaitingBrowser.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ đăng nhập trong trình duyệt…'**
  String get syncWaitingBrowser;

  /// No description provided for @syncSignedOutTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa bật đồng bộ'**
  String get syncSignedOutTitle;

  /// No description provided for @syncSignedOutBody.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập để sao lưu bản mã lên máy chủ và dùng chung dữ liệu giữa các thiết bị.'**
  String get syncSignedOutBody;

  /// No description provided for @syncE2eeNote.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ chỉ nhận bản mã. Mật khẩu mã hóa và 24 từ không bao giờ rời thiết bị.'**
  String get syncE2eeNote;

  /// No description provided for @syncStatusSyncing.
  ///
  /// In vi, this message translates to:
  /// **'Đang đồng bộ…'**
  String get syncStatusSyncing;

  /// No description provided for @syncStatusNever.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đồng bộ lần nào'**
  String get syncStatusNever;

  /// No description provided for @syncStatusLast.
  ///
  /// In vi, this message translates to:
  /// **'Đồng bộ lần cuối {time}'**
  String syncStatusLast(String time);

  /// No description provided for @syncPending.
  ///
  /// In vi, this message translates to:
  /// **'{n} thay đổi chờ gửi'**
  String syncPending(int n);

  /// No description provided for @syncQuotaFull.
  ///
  /// In vi, this message translates to:
  /// **'Đã hết dung lượng đồng bộ'**
  String get syncQuotaFull;

  /// No description provided for @syncRejected.
  ///
  /// In vi, this message translates to:
  /// **'{n} bản ghi bị máy chủ từ chối'**
  String syncRejected(int n);

  /// No description provided for @syncNow.
  ///
  /// In vi, this message translates to:
  /// **'Đồng bộ ngay'**
  String get syncNow;

  /// No description provided for @syncRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get syncRetry;

  /// No description provided for @syncSignOut.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get syncSignOut;

  /// No description provided for @syncSignOutBody.
  ///
  /// In vi, this message translates to:
  /// **'Dừng đồng bộ trên thiết bị này. Dữ liệu trên máy vẫn giữ nguyên.'**
  String get syncSignOutBody;

  /// No description provided for @syncSignOutConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất khỏi đồng bộ? Thiết bị này bị thu hồi trên máy chủ; dữ liệu trên máy vẫn giữ nguyên.'**
  String get syncSignOutConfirm;

  /// No description provided for @syncUsage.
  ///
  /// In vi, this message translates to:
  /// **'Dung lượng máy chủ'**
  String get syncUsage;

  /// No description provided for @syncUsageDetail.
  ///
  /// In vi, this message translates to:
  /// **'{count} bản ghi · {recMb}/{recQuota} MB · tệp {fileMb}/{fileQuota} MB'**
  String syncUsageDetail(int count, String recMb, String recQuota, String fileMb, String fileQuota);

  /// No description provided for @syncDevices.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị đang đăng nhập'**
  String get syncDevices;

  /// No description provided for @syncThisDevice.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị này'**
  String get syncThisDevice;

  /// No description provided for @syncLastSeen.
  ///
  /// In vi, this message translates to:
  /// **'Hoạt động {time}'**
  String syncLastSeen(String time);

  /// No description provided for @syncRevoke.
  ///
  /// In vi, this message translates to:
  /// **'Thu hồi'**
  String get syncRevoke;

  /// No description provided for @syncRevokeConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Thu hồi \"{name}\"? Thiết bị đó bị đăng xuất ngay và không đồng bộ được nữa.'**
  String syncRevokeConfirm(String name);

  /// No description provided for @syncExport.
  ///
  /// In vi, this message translates to:
  /// **'Xuất dữ liệu máy chủ'**
  String get syncExport;

  /// No description provided for @syncExportBody.
  ///
  /// In vi, this message translates to:
  /// **'Tệp JSON mọi thứ máy chủ đang giữ (vẫn là bản mã).'**
  String get syncExportBody;

  /// No description provided for @syncExportDone.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu tệp xuất'**
  String get syncExportDone;

  /// No description provided for @syncDeleteAccount.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tài khoản đồng bộ'**
  String get syncDeleteAccount;

  /// No description provided for @syncDeleteBody.
  ///
  /// In vi, this message translates to:
  /// **'Xóa toàn bộ dữ liệu trên máy chủ sau 30 ngày. Hủy được trong thời gian chờ.'**
  String get syncDeleteBody;

  /// No description provided for @syncDeleteConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tài khoản đồng bộ? Sau 30 ngày mọi bản mã, khóa và tệp trên máy chủ bị xóa hẳn. Trong thời gian chờ chỉ đọc được, hủy được. Dữ liệu trên máy này không bị xóa.'**
  String get syncDeleteConfirm;

  /// No description provided for @syncDeletionPending.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản sẽ bị xóa sau {days} ngày'**
  String syncDeletionPending(int days);

  /// No description provided for @syncDeletionCancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy xóa'**
  String get syncDeletionCancel;

  /// No description provided for @syncNoRemoteAccount.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản chưa có dữ liệu đồng bộ. Hãy tạo mật khẩu mã hóa mới.'**
  String get syncNoRemoteAccount;

  /// No description provided for @syncUnlockRemoteTitle.
  ///
  /// In vi, this message translates to:
  /// **'Mở dữ liệu đã đồng bộ'**
  String get syncUnlockRemoteTitle;

  /// No description provided for @syncUnlockRemoteBody.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mật khẩu mã hóa (hoặc 24 từ khôi phục) đã đặt trên thiết bị trước.'**
  String get syncUnlockRemoteBody;

  /// No description provided for @syncRemoteInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu khóa trên máy chủ không hợp lệ.'**
  String get syncRemoteInvalid;

  /// No description provided for @syncErrNetwork.
  ///
  /// In vi, this message translates to:
  /// **'Không kết nối được máy chủ. Sẽ thử lại sau.'**
  String get syncErrNetwork;

  /// No description provided for @syncErrTls.
  ///
  /// In vi, this message translates to:
  /// **'Kết nối không an toàn (chứng chỉ máy chủ không khớp). Đồng bộ đã dừng; dữ liệu trên máy vẫn dùng bình thường.'**
  String get syncErrTls;

  /// No description provided for @syncErrSignedOut.
  ///
  /// In vi, this message translates to:
  /// **'Phiên đăng nhập đã hết hoặc thiết bị đã bị thu hồi. Hãy đăng nhập lại.'**
  String get syncErrSignedOut;

  /// No description provided for @syncErrDenied.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã từ chối đăng nhập.'**
  String get syncErrDenied;

  /// No description provided for @syncErrNoBrowser.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được trình duyệt.'**
  String get syncErrNoBrowser;

  /// No description provided for @syncErrRateLimited.
  ///
  /// In vi, this message translates to:
  /// **'Thao tác quá nhanh. Hãy thử lại sau ít phút.'**
  String get syncErrRateLimited;

  /// No description provided for @syncErrGeneric.
  ///
  /// In vi, this message translates to:
  /// **'Đồng bộ gặp lỗi. Sẽ thử lại sau.'**
  String get syncErrGeneric;

  /// No description provided for @syncBlockDifferentAccount.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản đồng bộ đã có dữ liệu mã hóa bằng mật khẩu KHÁC dữ liệu trên máy này. Không trộn hai bộ dữ liệu: hãy sao lưu, rồi đặt lại app và chọn \"Đăng nhập để lấy dữ liệu đã đồng bộ\", hoặc đăng xuất.'**
  String get syncBlockDifferentAccount;

  /// No description provided for @syncBlockIdentityChanged.
  ///
  /// In vi, this message translates to:
  /// **'Khóa mã hóa trên máy chủ đã đổi bất thường. Đồng bộ đã dừng để bảo vệ dữ liệu. Nếu bạn không đặt lại tài khoản, hãy báo cho chúng tôi.'**
  String get syncBlockIdentityChanged;

  /// No description provided for @syncBlockRollback.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu trên máy chủ bị quay lui bất thường. Đồng bộ đã dừng để bảo vệ dữ liệu.'**
  String get syncBlockRollback;

  /// No description provided for @syncBlockPendingDeletion.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản đang chờ xóa - máy chủ không nhận thay đổi mới.'**
  String get syncBlockPendingDeletion;

  /// No description provided for @syncBlockOtherUser.
  ///
  /// In vi, this message translates to:
  /// **'Máy này đã đồng bộ với tài khoản TsuDEV khác. Đăng nhập đúng tài khoản đó, hoặc đặt lại app.'**
  String get syncBlockOtherUser;

  /// No description provided for @autoImportTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tự nhập'**
  String get autoImportTitle;

  /// No description provided for @autoConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Tự xác nhận'**
  String get autoConfirm;

  /// No description provided for @autoConfirmHint.
  ///
  /// In vi, this message translates to:
  /// **'Ghi thẳng vào số dư, không qua hàng chờ. Nên để tắt cho tới khi bạn tin bộ đọc.'**
  String get autoConfirmHint;

  /// No description provided for @bankNotifTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo ngân hàng'**
  String get bankNotifTitle;

  /// No description provided for @bankNotifAndroidOnly.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ có trên Android: hệ điều hành khác không cho app đọc thông báo của app khác.'**
  String get bankNotifAndroidOnly;

  /// No description provided for @bankNotifExplain.
  ///
  /// In vi, this message translates to:
  /// **'Đọc thông báo biến động số dư của app ngân hàng bạn chọn để tạo giao dịch chờ xác nhận. Nội dung chỉ xử lý trên máy, được mã hóa khi chờ, không gửi đi đâu.'**
  String get bankNotifExplain;

  /// No description provided for @bankNotifEnable.
  ///
  /// In vi, this message translates to:
  /// **'Đọc thông báo ngân hàng'**
  String get bankNotifEnable;

  /// No description provided for @bankNotifDisclosure.
  ///
  /// In vi, this message translates to:
  /// **'Quly Thu Chi sẽ xin quyền \"Truy cập thông báo\". App chỉ giữ thông báo của các app ngân hàng bạn chọn, bỏ qua mọi app khác và tin OTP, và không gửi nội dung ra khỏi máy. Bạn có thể thu hồi quyền bất cứ lúc nào trong Cài đặt của hệ thống.'**
  String get bankNotifDisclosure;

  /// No description provided for @bankNotifDisclosureOk.
  ///
  /// In vi, this message translates to:
  /// **'Đồng ý, tiếp tục'**
  String get bankNotifDisclosureOk;

  /// No description provided for @bankNotifNoPermission.
  ///
  /// In vi, this message translates to:
  /// **'Chưa cấp quyền truy cập thông báo'**
  String get bankNotifNoPermission;

  /// No description provided for @bankNotifGrant.
  ///
  /// In vi, this message translates to:
  /// **'Cấp quyền'**
  String get bankNotifGrant;

  /// No description provided for @bankNotifAddApp.
  ///
  /// In vi, this message translates to:
  /// **'Thêm app ngân hàng'**
  String get bankNotifAddApp;

  /// No description provided for @bankNotifPickApp.
  ///
  /// In vi, this message translates to:
  /// **'Chọn app'**
  String get bankNotifPickApp;

  /// No description provided for @bankNotifKnownApps.
  ///
  /// In vi, this message translates to:
  /// **'Ngân hàng và ví điện tử phổ biến được xếp trước'**
  String get bankNotifKnownApps;

  /// No description provided for @bankNotifLastRun.
  ///
  /// In vi, this message translates to:
  /// **'Lần gần nhất: thêm {added} giao dịch chờ xác nhận, bỏ qua {ignored} thông báo'**
  String bankNotifLastRun(int added, int ignored);

  /// No description provided for @captureMobileOnly.
  ///
  /// In vi, this message translates to:
  /// **'Giọng nói và quét hóa đơn chạy trên điện thoại (Android/iOS), nhận dạng ngay trên máy.'**
  String get captureMobileOnly;

  /// No description provided for @importAsPending.
  ///
  /// In vi, this message translates to:
  /// **'Đưa vào hàng chờ xác nhận'**
  String get importAsPending;

  /// No description provided for @importAsPendingHint.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tính vào số dư cho tới khi bạn xác nhận'**
  String get importAsPendingHint;

  /// No description provided for @importColDebit.
  ///
  /// In vi, this message translates to:
  /// **'Cột ghi nợ (tiền ra)'**
  String get importColDebit;

  /// No description provided for @importColCredit.
  ///
  /// In vi, this message translates to:
  /// **'Cột ghi có (tiền vào)'**
  String get importColCredit;

  /// No description provided for @importDoneDup.
  ///
  /// In vi, this message translates to:
  /// **'Đã nhập {ok} giao dịch, bỏ qua {skipped} dòng lỗi và {dup} dòng đã có'**
  String importDoneDup(int ok, int skipped, int dup);

  /// No description provided for @quickTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhanh'**
  String get quickTitle;

  /// No description provided for @quickExplain.
  ///
  /// In vi, this message translates to:
  /// **'Gõ hoặc nói một câu như \"ăn trưa 50 nghìn\", \"hôm qua đổ xăng 80k\", \"nhận lương 15 triệu\". App tự tách số tiền, ngày, thu/chi và gợi ý danh mục.'**
  String get quickExplain;

  /// No description provided for @quickLabel.
  ///
  /// In vi, this message translates to:
  /// **'Câu ghi nhanh'**
  String get quickLabel;

  /// No description provided for @quickHint.
  ///
  /// In vi, this message translates to:
  /// **'ăn trưa 50 nghìn'**
  String get quickHint;

  /// No description provided for @quickNeedVndWallet.
  ///
  /// In vi, this message translates to:
  /// **'Cần một ví VND để ghi nhanh.'**
  String get quickNeedVndWallet;

  /// No description provided for @quickNoAmount.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thấy số tiền trong câu'**
  String get quickNoAmount;

  /// No description provided for @quickMaybeDuplicate.
  ///
  /// In vi, this message translates to:
  /// **'Có giao dịch giống khoản này trong 1 ngày qua - kiểm tra để tránh ghi trùng.'**
  String get quickMaybeDuplicate;

  /// No description provided for @quickSaved.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi'**
  String get quickSaved;

  /// No description provided for @scanReceipt.
  ///
  /// In vi, this message translates to:
  /// **'Quét hóa đơn'**
  String get scanReceipt;

  /// No description provided for @scanDefaultNote.
  ///
  /// In vi, this message translates to:
  /// **'Hóa đơn'**
  String get scanDefaultNote;

  /// No description provided for @scanFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không đọc được ảnh'**
  String get scanFailed;

  /// No description provided for @scanNoTotal.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy tổng tiền trên hóa đơn - hãy gõ số tiền'**
  String get scanNoTotal;

  /// No description provided for @statementTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sao kê ngân hàng'**
  String get statementTitle;

  /// No description provided for @statementExplain.
  ///
  /// In vi, this message translates to:
  /// **'Nhập tệp CSV hoặc XLSX tải từ ngân hàng. App tự tìm bảng giao dịch, cột ghi nợ/ghi có, bỏ dòng đã có và gợi ý danh mục. Sao kê PDF: hãy tải bản Excel/CSV từ ngân hàng.'**
  String get statementExplain;

  /// No description provided for @statementOpen.
  ///
  /// In vi, this message translates to:
  /// **'Nhập sao kê'**
  String get statementOpen;

  /// No description provided for @voiceStart.
  ///
  /// In vi, this message translates to:
  /// **'Nói'**
  String get voiceStart;

  /// No description provided for @voiceConsent.
  ///
  /// In vi, this message translates to:
  /// **'Máy này không có bộ nhận dạng giọng nói ngoại tuyến. Có thể dùng dịch vụ nhận dạng của hệ điều hành - âm thanh có thể được gửi tới nhà cung cấp hệ điều hành (Google/Apple). Quly Thu Chi không nhận hay lưu âm thanh. Tiếp tục?'**
  String get voiceConsent;

  /// No description provided for @voiceConsentOk.
  ///
  /// In vi, this message translates to:
  /// **'Dùng dịch vụ hệ điều hành'**
  String get voiceConsentOk;

  /// No description provided for @voiceDenied.
  ///
  /// In vi, this message translates to:
  /// **'Chưa cấp quyền micro'**
  String get voiceDenied;

  /// No description provided for @voiceUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Không nhận dạng được giọng nói'**
  String get voiceUnavailable;

  /// No description provided for @moreAutoImport.
  ///
  /// In vi, this message translates to:
  /// **'Tự nhập'**
  String get moreAutoImport;

  /// No description provided for @emailTitle.
  ///
  /// In vi, this message translates to:
  /// **'Email chuyển tiếp'**
  String get emailTitle;

  /// No description provided for @emailExplain.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển tiếp email báo giao dịch của ngân hàng tới một địa chỉ riêng; app tạo giao dịch chờ xác nhận. Tắt mặc định.'**
  String get emailExplain;

  /// No description provided for @emailNeedSignIn.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập đồng bộ để dùng'**
  String get emailNeedSignIn;

  /// No description provided for @emailEnable.
  ///
  /// In vi, this message translates to:
  /// **'Bật email chuyển tiếp'**
  String get emailEnable;

  /// No description provided for @emailDisclosure.
  ///
  /// In vi, this message translates to:
  /// **'Đây là NGOẠI LỆ DUY NHẤT của mã hóa đầu-cuối: email đi qua Internet ở dạng thường, và máy chủ Quly Thu Chi thấy nội dung trong vài mili giây khi nhận để niêm phong bằng khóa của bạn. Máy chủ không lưu bản rõ; thư niêm phong bị xóa khi app tải về hoặc sau 30 ngày. Chỉ chuyển tiếp email báo giao dịch, đừng chuyển thư có mật khẩu/OTP.'**
  String get emailDisclosure;

  /// No description provided for @emailCopy.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép'**
  String get emailCopy;

  /// No description provided for @emailCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép địa chỉ'**
  String get emailCopied;

  /// No description provided for @emailRotate.
  ///
  /// In vi, this message translates to:
  /// **'Đổi địa chỉ'**
  String get emailRotate;

  /// No description provided for @emailRotateConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Địa chỉ hiện tại sẽ ngừng nhận thư ngay. Bạn cần cập nhật quy tắc chuyển tiếp ở hộp thư của mình.'**
  String get emailRotateConfirm;

  /// No description provided for @emailDisable.
  ///
  /// In vi, this message translates to:
  /// **'Tắt'**
  String get emailDisable;

  /// No description provided for @emailDisableConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Tắt email chuyển tiếp? Địa chỉ bị xóa cùng mọi thư chưa tải về.'**
  String get emailDisableConfirm;

  /// No description provided for @emailWarning.
  ///
  /// In vi, this message translates to:
  /// **'Ngoại lệ E2EE: máy chủ thấy nội dung email trong lúc niêm phong. Địa chỉ là bí mật - ai biết địa chỉ đều gửi thư vào được.'**
  String get emailWarning;

  /// No description provided for @copied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép'**
  String get copied;

  /// No description provided for @currencyPick.
  ///
  /// In vi, this message translates to:
  /// **'Chọn tiền tệ'**
  String get currencyPick;

  /// No description provided for @currencySearch.
  ///
  /// In vi, this message translates to:
  /// **'Tìm theo mã hoặc tên (USD, yên, bảng Anh...)'**
  String get currencySearch;

  /// No description provided for @currencyPopular.
  ///
  /// In vi, this message translates to:
  /// **'Hay dùng'**
  String get currencyPopular;

  /// No description provided for @currencyAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả ({count} tiền tệ ISO 4217)'**
  String currencyAll(int count);

  /// No description provided for @currencyNone.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy tiền tệ phù hợp.'**
  String get currencyNone;

  /// No description provided for @guestModeNote.
  ///
  /// In vi, this message translates to:
  /// **'Không đăng nhập vẫn dùng đầy đủ mọi tính năng ở chế độ khách: dữ liệu chỉ nằm trên máy này, mã hóa bằng mật khẩu của bạn.'**
  String get guestModeNote;

  /// No description provided for @welcomeGuest.
  ///
  /// In vi, this message translates to:
  /// **'Dùng ngay, không cần tài khoản'**
  String get welcomeGuest;

  /// No description provided for @welcomeGuestNote.
  ///
  /// In vi, this message translates to:
  /// **'Chế độ khách: dữ liệu chỉ lưu trên máy này. Có thể đăng nhập để đồng bộ bất cứ lúc nào.'**
  String get welcomeGuestNote;

  /// No description provided for @signInGoogle.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục với Google'**
  String get signInGoogle;

  /// No description provided for @signInGithub.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục với GitHub'**
  String get signInGithub;

  /// No description provided for @signInTsudev.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản tsudev (email)'**
  String get signInTsudev;

  /// No description provided for @signInLastUsed.
  ///
  /// In vi, this message translates to:
  /// **'Lần trước bạn dùng cách này'**
  String get signInLastUsed;

  /// No description provided for @signInOr.
  ///
  /// In vi, this message translates to:
  /// **'hoặc'**
  String get signInOr;

  /// No description provided for @settingsCarryOver.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển số dư sang tháng sau'**
  String get settingsCarryOver;

  /// No description provided for @settingsCarryOverSub.
  ///
  /// In vi, this message translates to:
  /// **'Số dư cuối tháng trước thành số dư đầu tháng này trên thẻ Số dư theo tháng. Tắt để chỉ xem thu, chi trong tháng.'**
  String get settingsCarryOverSub;

  /// No description provided for @settingsTaxReminders.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc hạn thuế và đợt thu'**
  String get settingsTaxReminders;

  /// No description provided for @settingsTaxRemindersSub.
  ///
  /// In vi, this message translates to:
  /// **'Báo trước 7 ngày và 1 ngày hạn quyết toán thuế TNCN; báo ngày đến hạn đợt thu của khoản thu.'**
  String get settingsTaxRemindersSub;

  /// No description provided for @periodTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tháng {month}/{year}'**
  String periodTitle(int month, int year);

  /// No description provided for @periodPrev.
  ///
  /// In vi, this message translates to:
  /// **'Kỳ trước'**
  String get periodPrev;

  /// No description provided for @periodNext.
  ///
  /// In vi, this message translates to:
  /// **'Kỳ sau'**
  String get periodNext;

  /// No description provided for @periodThisMonth.
  ///
  /// In vi, this message translates to:
  /// **'Tháng này'**
  String get periodThisMonth;

  /// No description provided for @periodOpening.
  ///
  /// In vi, this message translates to:
  /// **'Số dư đầu kỳ (chuyển từ tháng {month})'**
  String periodOpening(int month);

  /// No description provided for @periodIncome.
  ///
  /// In vi, this message translates to:
  /// **'Thu trong tháng'**
  String get periodIncome;

  /// No description provided for @periodExpense.
  ///
  /// In vi, this message translates to:
  /// **'Chi trong tháng'**
  String get periodExpense;

  /// No description provided for @periodOther.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển ví, phí, điều chỉnh'**
  String get periodOther;

  /// No description provided for @periodWithheld.
  ///
  /// In vi, this message translates to:
  /// **'Thuế đã bị khấu trừ (không trừ số dư)'**
  String get periodWithheld;

  /// No description provided for @periodClosing.
  ///
  /// In vi, this message translates to:
  /// **'Số dư cuối kỳ (chuyển sang tháng {month})'**
  String periodClosing(int month);

  /// No description provided for @periodNet.
  ///
  /// In vi, this message translates to:
  /// **'Chênh lệch thu - chi'**
  String get periodNet;

  /// No description provided for @periodSavingRate.
  ///
  /// In vi, this message translates to:
  /// **'Tỉ lệ để dành: {rate}'**
  String periodSavingRate(String rate);

  /// No description provided for @incomeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Khoản thu'**
  String get incomeTitle;

  /// No description provided for @incomeRecord.
  ///
  /// In vi, this message translates to:
  /// **'Ghi khoản thu'**
  String get incomeRecord;

  /// No description provided for @incomePlanNew.
  ///
  /// In vi, this message translates to:
  /// **'Thêm khoản thu nhiều đợt'**
  String get incomePlanNew;

  /// No description provided for @incomePlanEdit.
  ///
  /// In vi, this message translates to:
  /// **'Sửa khoản thu'**
  String get incomePlanEdit;

  /// No description provided for @incomeYear.
  ///
  /// In vi, this message translates to:
  /// **'Năm {year}'**
  String incomeYear(int year);

  /// No description provided for @incomeByMonth.
  ///
  /// In vi, this message translates to:
  /// **'Theo tháng'**
  String get incomeByMonth;

  /// No description provided for @incomeByYear.
  ///
  /// In vi, this message translates to:
  /// **'Cả năm'**
  String get incomeByYear;

  /// No description provided for @incomeTotalReceived.
  ///
  /// In vi, this message translates to:
  /// **'Tổng thực nhận'**
  String get incomeTotalReceived;

  /// No description provided for @incomeReceipts.
  ///
  /// In vi, this message translates to:
  /// **'{count} lần nhận'**
  String incomeReceipts(int count);

  /// No description provided for @incomeWithheldTotal.
  ///
  /// In vi, this message translates to:
  /// **'thuế khấu trừ {amount}'**
  String incomeWithheldTotal(String amount);

  /// No description provided for @incomeGrossTotal.
  ///
  /// In vi, this message translates to:
  /// **'trước thuế {amount}'**
  String incomeGrossTotal(String amount);

  /// No description provided for @incomeSumBy.
  ///
  /// In vi, this message translates to:
  /// **'Cộng thu theo'**
  String get incomeSumBy;

  /// No description provided for @incomeByPayer.
  ///
  /// In vi, this message translates to:
  /// **'Người trả'**
  String get incomeByPayer;

  /// No description provided for @incomeByCategory.
  ///
  /// In vi, this message translates to:
  /// **'Danh mục'**
  String get incomeByCategory;

  /// No description provided for @incomeByPlan.
  ///
  /// In vi, this message translates to:
  /// **'Khoản thu'**
  String get incomeByPlan;

  /// No description provided for @incomeNoPayer.
  ///
  /// In vi, this message translates to:
  /// **'(Chưa ghi người trả)'**
  String get incomeNoPayer;

  /// No description provided for @incomeNoPlan.
  ///
  /// In vi, this message translates to:
  /// **'(Thu lẻ, không thuộc khoản thu)'**
  String get incomeNoPlan;

  /// No description provided for @incomeNone.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có khoản thu trong kỳ này.'**
  String get incomeNone;

  /// No description provided for @incomeLast.
  ///
  /// In vi, this message translates to:
  /// **'gần nhất {date}'**
  String incomeLast(String date);

  /// No description provided for @incomePlansTitle.
  ///
  /// In vi, this message translates to:
  /// **'Khoản thu nhiều đợt'**
  String get incomePlansTitle;

  /// No description provided for @incomePlansHelp.
  ///
  /// In vi, this message translates to:
  /// **'Theo dõi job freelance, hợp đồng, tiền cho thuê... nhận tiền nhiều đợt: đã nhận bao nhiêu, còn bao nhiêu, đợt nào trễ.'**
  String get incomePlansHelp;

  /// No description provided for @incomePlansEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có khoản thu nào. Bấm \"Thêm khoản thu nhiều đợt\" để bắt đầu.'**
  String get incomePlansEmpty;

  /// No description provided for @incomeShowClosed.
  ///
  /// In vi, this message translates to:
  /// **'Hiện {count} khoản đã xong/hủy'**
  String incomeShowClosed(int count);

  /// No description provided for @incomeHideClosed.
  ///
  /// In vi, this message translates to:
  /// **'Ẩn khoản đã xong'**
  String get incomeHideClosed;

  /// No description provided for @incomeStatusActive.
  ///
  /// In vi, this message translates to:
  /// **'Đang thu'**
  String get incomeStatusActive;

  /// No description provided for @incomeStatusDone.
  ///
  /// In vi, this message translates to:
  /// **'Đã xong'**
  String get incomeStatusDone;

  /// No description provided for @incomeStatusCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Đã hủy'**
  String get incomeStatusCancelled;

  /// No description provided for @incomeStatus.
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái'**
  String get incomeStatus;

  /// No description provided for @incomeProgress.
  ///
  /// In vi, this message translates to:
  /// **'Đã nhận {received} / {total}'**
  String incomeProgress(String received, String total);

  /// No description provided for @incomeReceivedSoFar.
  ///
  /// In vi, this message translates to:
  /// **'Đã nhận {amount}'**
  String incomeReceivedSoFar(String amount);

  /// No description provided for @incomeNext.
  ///
  /// In vi, this message translates to:
  /// **'Đợt kế tiếp: {label} {amount}, hạn {date}'**
  String incomeNext(String label, String amount, String date);

  /// No description provided for @incomeInstallment.
  ///
  /// In vi, this message translates to:
  /// **'Đợt'**
  String get incomeInstallment;

  /// No description provided for @incomeOverdue.
  ///
  /// In vi, this message translates to:
  /// **'Quá hạn chưa nhận: {amount}'**
  String incomeOverdue(String amount);

  /// No description provided for @incomePlanName.
  ///
  /// In vi, this message translates to:
  /// **'Tên job/dự án'**
  String get incomePlanName;

  /// No description provided for @incomePlanNameHint.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: Thiết kế web quán cà phê'**
  String get incomePlanNameHint;

  /// No description provided for @incomePayer.
  ///
  /// In vi, this message translates to:
  /// **'Người/đơn vị trả tiền'**
  String get incomePayer;

  /// No description provided for @incomePlanTotal.
  ///
  /// In vi, this message translates to:
  /// **'Tổng giá trị thỏa thuận (để trống nếu chưa chốt)'**
  String get incomePlanTotal;

  /// No description provided for @incomeDefaultWallet.
  ///
  /// In vi, this message translates to:
  /// **'Ví nhận tiền mặc định'**
  String get incomeDefaultWallet;

  /// No description provided for @incomeStart.
  ///
  /// In vi, this message translates to:
  /// **'Ngày bắt đầu'**
  String get incomeStart;

  /// No description provided for @incomeDue.
  ///
  /// In vi, this message translates to:
  /// **'Hạn hoàn thành'**
  String get incomeDue;

  /// No description provided for @incomeWithholding.
  ///
  /// In vi, this message translates to:
  /// **'Bên trả khấu trừ thuế 10%'**
  String get incomeWithholding;

  /// No description provided for @incomeWithholdingSub.
  ///
  /// In vi, this message translates to:
  /// **'Thu nhập vãng lai (không hợp đồng lao động hoặc dưới 3 tháng): khi ghi lần nhận tiền, app tự tính thuế bị khấu trừ.'**
  String get incomeWithholdingSub;

  /// No description provided for @incomeInstallments.
  ///
  /// In vi, this message translates to:
  /// **'Các đợt dự kiến'**
  String get incomeInstallments;

  /// No description provided for @incomeInstallmentsHelp.
  ///
  /// In vi, this message translates to:
  /// **'Không bắt buộc. Ví dụ: đặt cọc 30%, bản thử 40%, nghiệm thu 30%.'**
  String get incomeInstallmentsHelp;

  /// No description provided for @incomeInstallmentLabel.
  ///
  /// In vi, this message translates to:
  /// **'Đợt {n}'**
  String incomeInstallmentLabel(int n);

  /// No description provided for @incomeInstallmentHint.
  ///
  /// In vi, this message translates to:
  /// **'Đặt cọc, nghiệm thu...'**
  String get incomeInstallmentHint;

  /// No description provided for @incomeAddInstallment.
  ///
  /// In vi, this message translates to:
  /// **'Thêm đợt'**
  String get incomeAddInstallment;

  /// No description provided for @incomeReceive.
  ///
  /// In vi, this message translates to:
  /// **'Ghi lần nhận tiền'**
  String get incomeReceive;

  /// No description provided for @incomeGrossAmount.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền theo hợp đồng (trước thuế)'**
  String get incomeGrossAmount;

  /// No description provided for @incomeWithholdHint.
  ///
  /// In vi, this message translates to:
  /// **'Để trống: app tự tính 10% nếu lần trả từ {threshold} trở lên.'**
  String incomeWithholdHint(String threshold);

  /// No description provided for @incomeNetPreview.
  ///
  /// In vi, this message translates to:
  /// **'Thực nhận vào ví: {amount}'**
  String incomeNetPreview(String amount);

  /// No description provided for @incomeNoWalletForCurrency.
  ///
  /// In vi, this message translates to:
  /// **'Cần một ví {currency} để ghi lần nhận tiền.'**
  String incomeNoWalletForCurrency(String currency);

  /// No description provided for @incomePlanDeleteConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xóa khoản thu \"{name}\"? Các lần nhận tiền đã ghi vẫn giữ nguyên.'**
  String incomePlanDeleteConfirm(String name);

  /// No description provided for @incomeReceiptsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Các lần đã nhận'**
  String get incomeReceiptsTitle;

  /// No description provided for @incomePlanField.
  ///
  /// In vi, this message translates to:
  /// **'Thuộc khoản thu'**
  String get incomePlanField;

  /// No description provided for @txnTaxWithheld.
  ///
  /// In vi, this message translates to:
  /// **'Thuế TNCN bị khấu trừ'**
  String get txnTaxWithheld;

  /// No description provided for @txnTaxWithheldHelp.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền là số THỰC NHẬN. Ghi phần thuế bên trả đã giữ lại để tính đúng thu nhập trước thuế và quyết toán.'**
  String get txnTaxWithheldHelp;

  /// No description provided for @taxTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thuế thu nhập cá nhân'**
  String get taxTitle;

  /// No description provided for @taxDisclaimer.
  ///
  /// In vi, this message translates to:
  /// **'Ước tính để tham khảo theo quy định Việt Nam, không thay thế tư vấn thuế. Hãy đối chiếu văn bản gốc và cơ quan thuế trước khi khai, nộp.'**
  String get taxDisclaimer;

  /// No description provided for @taxProfile.
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ thuế'**
  String get taxProfile;

  /// No description provided for @taxDependents.
  ///
  /// In vi, this message translates to:
  /// **'Người phụ thuộc'**
  String get taxDependents;

  /// No description provided for @taxDependentsN.
  ///
  /// In vi, this message translates to:
  /// **'{count} người phụ thuộc'**
  String taxDependentsN(int count);

  /// No description provided for @taxLess.
  ///
  /// In vi, this message translates to:
  /// **'Bớt'**
  String get taxLess;

  /// No description provided for @taxMore.
  ///
  /// In vi, this message translates to:
  /// **'Thêm'**
  String get taxMore;

  /// No description provided for @taxInsurance.
  ///
  /// In vi, this message translates to:
  /// **'Bảo hiểm bắt buộc đóng mỗi tháng'**
  String get taxInsurance;

  /// No description provided for @taxInsuranceHelp.
  ///
  /// In vi, this message translates to:
  /// **'Để trống: ước tính 10,5% lương (BHXH 8%, BHYT 1,5%, BHTN 1%) trong mức trần.'**
  String get taxInsuranceHelp;

  /// No description provided for @taxInsuranceN.
  ///
  /// In vi, this message translates to:
  /// **'bảo hiểm {amount}/tháng'**
  String taxInsuranceN(String amount);

  /// No description provided for @taxResident.
  ///
  /// In vi, this message translates to:
  /// **'Cá nhân cư trú'**
  String get taxResident;

  /// No description provided for @taxNonResident.
  ///
  /// In vi, this message translates to:
  /// **'Không cư trú'**
  String get taxNonResident;

  /// No description provided for @taxResidentSub.
  ///
  /// In vi, this message translates to:
  /// **'Ở Việt Nam từ 183 ngày/năm hoặc có nơi ở thường xuyên. Không cư trú: thuế 20% trên lương, không giảm trừ.'**
  String get taxResidentSub;

  /// No description provided for @taxBusiness.
  ///
  /// In vi, this message translates to:
  /// **'Có kinh doanh (hộ, cá nhân kinh doanh)'**
  String get taxBusiness;

  /// No description provided for @taxBusinessSub.
  ///
  /// In vi, this message translates to:
  /// **'Bật nhắc hạn khai thuế theo quý và cảnh báo khi doanh thu năm vượt ngưỡng không chịu thuế.'**
  String get taxBusinessSub;

  /// No description provided for @taxUnclassified.
  ///
  /// In vi, this message translates to:
  /// **'{count} danh mục thu chưa phân loại thuế: thu nhập trong đó không được tính vào ước tính.'**
  String taxUnclassified(int count);

  /// No description provided for @taxStandardCategories.
  ///
  /// In vi, this message translates to:
  /// **'Bổ sung danh mục thu chuẩn (đã phân loại thuế)'**
  String get taxStandardCategories;

  /// No description provided for @taxStandardDone.
  ///
  /// In vi, this message translates to:
  /// **'Đã thêm/cập nhật {count} danh mục'**
  String taxStandardDone(int count);

  /// No description provided for @taxEstimateTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ước tính quyết toán năm {year}'**
  String taxEstimateTitle(int year);

  /// No description provided for @taxSalaryIncome.
  ///
  /// In vi, this message translates to:
  /// **'Thu nhập từ tiền lương, tiền công'**
  String get taxSalaryIncome;

  /// No description provided for @taxCasualIncome.
  ///
  /// In vi, this message translates to:
  /// **'Thu nhập vãng lai, freelance'**
  String get taxCasualIncome;

  /// No description provided for @taxBusinessRevenue.
  ///
  /// In vi, this message translates to:
  /// **'Doanh thu kinh doanh (tính riêng)'**
  String get taxBusinessRevenue;

  /// No description provided for @taxInvestmentIncome.
  ///
  /// In vi, this message translates to:
  /// **'Thu nhập đầu tư vốn (tính riêng)'**
  String get taxInvestmentIncome;

  /// No description provided for @taxExemptIncome.
  ///
  /// In vi, this message translates to:
  /// **'Thu nhập miễn thuế'**
  String get taxExemptIncome;

  /// No description provided for @taxUnclassifiedIncome.
  ///
  /// In vi, this message translates to:
  /// **'Thu nhập chưa phân loại'**
  String get taxUnclassifiedIncome;

  /// No description provided for @taxInsuranceYear.
  ///
  /// In vi, this message translates to:
  /// **'Bảo hiểm bắt buộc'**
  String get taxInsuranceYear;

  /// No description provided for @taxDeductionYear.
  ///
  /// In vi, this message translates to:
  /// **'Giảm trừ gia cảnh (12 tháng)'**
  String get taxDeductionYear;

  /// No description provided for @taxTaxable.
  ///
  /// In vi, this message translates to:
  /// **'Thu nhập tính thuế'**
  String get taxTaxable;

  /// No description provided for @taxDue.
  ///
  /// In vi, this message translates to:
  /// **'Thuế phải nộp cả năm'**
  String get taxDue;

  /// No description provided for @taxWithheld.
  ///
  /// In vi, this message translates to:
  /// **'Đã bị khấu trừ tại nguồn'**
  String get taxWithheld;

  /// No description provided for @taxPayMore.
  ///
  /// In vi, this message translates to:
  /// **'Ước tính phải nộp thêm'**
  String get taxPayMore;

  /// No description provided for @taxRefund.
  ///
  /// In vi, this message translates to:
  /// **'Ước tính được hoàn'**
  String get taxRefund;

  /// No description provided for @taxSettlementNote.
  ///
  /// In vi, this message translates to:
  /// **'Tự quyết toán hạn chót {date}. Nộp trên thuedientu.gdt.gov.vn hoặc app eTax Mobile.'**
  String taxSettlementNote(String date);

  /// No description provided for @taxBusinessOver.
  ///
  /// In vi, this message translates to:
  /// **'Doanh thu kinh doanh vượt {amount}/năm: có thể phải khai, nộp thuế.'**
  String taxBusinessOver(String amount);

  /// No description provided for @taxCalcTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tính lương gross / net'**
  String get taxCalcTitle;

  /// No description provided for @taxFromGross.
  ///
  /// In vi, this message translates to:
  /// **'Từ gross'**
  String get taxFromGross;

  /// No description provided for @taxFromNet.
  ///
  /// In vi, this message translates to:
  /// **'Từ net'**
  String get taxFromNet;

  /// No description provided for @taxGrossSalary.
  ///
  /// In vi, this message translates to:
  /// **'Lương gross (trước thuế, bảo hiểm)'**
  String get taxGrossSalary;

  /// No description provided for @taxNetSalary.
  ///
  /// In vi, this message translates to:
  /// **'Lương net (thực nhận)'**
  String get taxNetSalary;

  /// No description provided for @taxInsuranceMonth.
  ///
  /// In vi, this message translates to:
  /// **'Bảo hiểm bắt buộc'**
  String get taxInsuranceMonth;

  /// No description provided for @taxDeductionMonth.
  ///
  /// In vi, this message translates to:
  /// **'Giảm trừ gia cảnh'**
  String get taxDeductionMonth;

  /// No description provided for @taxMonthTax.
  ///
  /// In vi, this message translates to:
  /// **'Thuế TNCN tháng'**
  String get taxMonthTax;

  /// No description provided for @taxDeadlines.
  ///
  /// In vi, this message translates to:
  /// **'Hạn sắp tới'**
  String get taxDeadlines;

  /// No description provided for @taxDeadlineSelf.
  ///
  /// In vi, this message translates to:
  /// **'Hạn tự quyết toán thuế TNCN năm {year}'**
  String taxDeadlineSelf(int year);

  /// No description provided for @taxDeadlineAuthorize.
  ///
  /// In vi, this message translates to:
  /// **'Nộp giấy ủy quyền quyết toán năm {year} cho công ty (nếu ủy quyền)'**
  String taxDeadlineAuthorize(int year);

  /// No description provided for @taxDeadlineBusiness.
  ///
  /// In vi, this message translates to:
  /// **'Hạn khai thuế quý (hộ kinh doanh)'**
  String get taxDeadlineBusiness;

  /// No description provided for @taxDeadlineIn.
  ///
  /// In vi, this message translates to:
  /// **'{date} (còn {days} ngày)'**
  String taxDeadlineIn(String date, int days);

  /// No description provided for @taxRulesTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quy định áp dụng từ {year}'**
  String taxRulesTitle(int year);

  /// No description provided for @taxPersonalDeduction.
  ///
  /// In vi, this message translates to:
  /// **'Giảm trừ bản thân / tháng'**
  String get taxPersonalDeduction;

  /// No description provided for @taxDependentDeduction.
  ///
  /// In vi, this message translates to:
  /// **'Giảm trừ mỗi người phụ thuộc / tháng'**
  String get taxDependentDeduction;

  /// No description provided for @taxBracketUpTo.
  ///
  /// In vi, this message translates to:
  /// **'Bậc {n}: đến {amount}/tháng'**
  String taxBracketUpTo(int n, String amount);

  /// No description provided for @taxBracketOver.
  ///
  /// In vi, this message translates to:
  /// **'Bậc {n}: trên {amount}/tháng'**
  String taxBracketOver(int n, String amount);

  /// No description provided for @taxCasualRule.
  ///
  /// In vi, this message translates to:
  /// **'Khấu trừ vãng lai khi mỗi lần trả từ {amount}'**
  String taxCasualRule(String amount);

  /// No description provided for @taxBusinessThreshold.
  ///
  /// In vi, this message translates to:
  /// **'Doanh thu kinh doanh không chịu thuế / năm'**
  String get taxBusinessThreshold;

  /// No description provided for @taxSource.
  ///
  /// In vi, this message translates to:
  /// **'Nguồn: {source}. Cập nhật {date}.'**
  String taxSource(String source, String date);

  /// No description provided for @taxCategoriesTitle.
  ///
  /// In vi, this message translates to:
  /// **'Phân loại thuế của danh mục thu'**
  String get taxCategoriesTitle;

  /// No description provided for @taxInherit.
  ///
  /// In vi, this message translates to:
  /// **'Theo danh mục cha'**
  String get taxInherit;

  /// No description provided for @taxTypeUnknown.
  ///
  /// In vi, this message translates to:
  /// **'Chưa phân loại'**
  String get taxTypeUnknown;

  /// No description provided for @taxTypeUnknownHelp.
  ///
  /// In vi, this message translates to:
  /// **'Không tính vào ước tính thuế'**
  String get taxTypeUnknownHelp;

  /// No description provided for @taxTypeSalary.
  ///
  /// In vi, this message translates to:
  /// **'Tiền lương, tiền công'**
  String get taxTypeSalary;

  /// No description provided for @taxTypeSalaryHelp.
  ///
  /// In vi, this message translates to:
  /// **'Hợp đồng lao động từ 3 tháng, thưởng, phụ cấp chịu thuế'**
  String get taxTypeSalaryHelp;

  /// No description provided for @taxTypeCasual.
  ///
  /// In vi, this message translates to:
  /// **'Vãng lai, freelance'**
  String get taxTypeCasual;

  /// No description provided for @taxTypeCasualHelp.
  ///
  /// In vi, this message translates to:
  /// **'Không hợp đồng hoặc dưới 3 tháng; bên trả khấu trừ 10%'**
  String get taxTypeCasualHelp;

  /// No description provided for @taxTypeBusiness.
  ///
  /// In vi, this message translates to:
  /// **'Kinh doanh, cho thuê'**
  String get taxTypeBusiness;

  /// No description provided for @taxTypeBusinessHelp.
  ///
  /// In vi, this message translates to:
  /// **'Tính theo doanh thu, có ngưỡng không chịu thuế'**
  String get taxTypeBusinessHelp;

  /// No description provided for @taxTypeInvestment.
  ///
  /// In vi, this message translates to:
  /// **'Đầu tư vốn'**
  String get taxTypeInvestment;

  /// No description provided for @taxTypeInvestmentHelp.
  ///
  /// In vi, this message translates to:
  /// **'Cổ tức, lãi trái phiếu... thuế suất riêng'**
  String get taxTypeInvestmentHelp;

  /// No description provided for @taxTypeExempt.
  ///
  /// In vi, this message translates to:
  /// **'Miễn thuế'**
  String get taxTypeExempt;

  /// No description provided for @taxTypeExemptHelp.
  ///
  /// In vi, this message translates to:
  /// **'Lãi tiền gửi ngân hàng, quà tặng trong gia đình, hoàn tiền'**
  String get taxTypeExemptHelp;

  /// No description provided for @qrTitle.
  ///
  /// In vi, this message translates to:
  /// **'QR thanh toán'**
  String get qrTitle;

  /// No description provided for @qrTabPay.
  ///
  /// In vi, this message translates to:
  /// **'Quét để trả'**
  String get qrTabPay;

  /// No description provided for @qrTabReceive.
  ///
  /// In vi, this message translates to:
  /// **'Mã nhận tiền'**
  String get qrTabReceive;

  /// No description provided for @qrPayIntro.
  ///
  /// In vi, this message translates to:
  /// **'Quét mã VietQR/EMVCo của người nhận để xem đúng số tài khoản, số tiền, nội dung, rồi mở app ngân hàng và ghi khoản chi. Mã được đọc ngay trên máy.'**
  String get qrPayIntro;

  /// No description provided for @qrNoCamera.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị này chưa quét bằng camera được. Dán nội dung mã QR (chuỗi bắt đầu bằng 000201) vào ô dưới.'**
  String get qrNoCamera;

  /// No description provided for @qrCameraError.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được camera. Hãy cấp quyền camera hoặc dán nội dung mã.'**
  String get qrCameraError;

  /// No description provided for @qrPasteLabel.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung mã QR'**
  String get qrPasteLabel;

  /// No description provided for @qrPaste.
  ///
  /// In vi, this message translates to:
  /// **'Dán'**
  String get qrPaste;

  /// No description provided for @qrRead.
  ///
  /// In vi, this message translates to:
  /// **'Đọc mã'**
  String get qrRead;

  /// No description provided for @qrErrCrc.
  ///
  /// In vi, this message translates to:
  /// **'Mã QR bị sai hoặc đã bị sửa (kiểm tra CRC không khớp). Đừng thanh toán bằng mã này.'**
  String get qrErrCrc;

  /// No description provided for @qrErrNotPayment.
  ///
  /// In vi, this message translates to:
  /// **'Đây không phải mã QR thanh toán EMVCo/VietQR.'**
  String get qrErrNotPayment;

  /// No description provided for @qrErrInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Mã QR không đúng cấu trúc.'**
  String get qrErrInvalid;

  /// No description provided for @qrNoAmount.
  ///
  /// In vi, this message translates to:
  /// **'Mã không ghi số tiền: bạn tự nhập trong app ngân hàng.'**
  String get qrNoAmount;

  /// No description provided for @qrPayee.
  ///
  /// In vi, this message translates to:
  /// **'Người nhận'**
  String get qrPayee;

  /// No description provided for @qrBank.
  ///
  /// In vi, this message translates to:
  /// **'Ngân hàng'**
  String get qrBank;

  /// No description provided for @qrAccount.
  ///
  /// In vi, this message translates to:
  /// **'Số tài khoản'**
  String get qrAccount;

  /// No description provided for @qrMessage.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung chuyển khoản'**
  String get qrMessage;

  /// No description provided for @qrCity.
  ///
  /// In vi, this message translates to:
  /// **'Nơi nhận'**
  String get qrCity;

  /// No description provided for @qrIsCard.
  ///
  /// In vi, this message translates to:
  /// **'Định danh là số thẻ.'**
  String get qrIsCard;

  /// No description provided for @qrOpenBank.
  ///
  /// In vi, this message translates to:
  /// **'Mở app ngân hàng (điền sẵn)'**
  String get qrOpenBank;

  /// No description provided for @qrOpenBankNote.
  ///
  /// In vi, this message translates to:
  /// **'Hoặc mở app ngân hàng, chọn quét QR và quét lại mã này; luôn kiểm tra tên người nhận trước khi xác nhận.'**
  String get qrOpenBankNote;

  /// No description provided for @qrForeignNote.
  ///
  /// In vi, this message translates to:
  /// **'Mã nước ngoài: thanh toán bằng app ví/ngân hàng hỗ trợ hệ này, rồi ghi khoản chi tại đây.'**
  String get qrForeignNote;

  /// No description provided for @qrConsentTitle.
  ///
  /// In vi, this message translates to:
  /// **'Mở app ngân hàng qua VietQR.io'**
  String get qrConsentTitle;

  /// No description provided for @qrConsentBody.
  ///
  /// In vi, this message translates to:
  /// **'Để điền sẵn lệnh chuyển, app gửi số tài khoản NGƯỜI NHẬN, số tiền và nội dung tới dl.vietqr.io (dịch vụ bên thứ ba) để chuyển sang app ngân hàng bạn chọn. Không gửi dữ liệu sổ thu chi của bạn. Đồng ý?'**
  String get qrConsentBody;

  /// No description provided for @qrConsentOk.
  ///
  /// In vi, this message translates to:
  /// **'Đồng ý, mở app'**
  String get qrConsentOk;

  /// No description provided for @qrChooseBankApp.
  ///
  /// In vi, this message translates to:
  /// **'Chọn app ngân hàng của bạn'**
  String get qrChooseBankApp;

  /// No description provided for @qrLastUsed.
  ///
  /// In vi, this message translates to:
  /// **'Dùng lần trước'**
  String get qrLastUsed;

  /// No description provided for @qrOpenFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được app ngân hàng trên thiết bị này.'**
  String get qrOpenFailed;

  /// No description provided for @qrRecordExpense.
  ///
  /// In vi, this message translates to:
  /// **'Ghi khoản chi này'**
  String get qrRecordExpense;

  /// No description provided for @qrScanAgain.
  ///
  /// In vi, this message translates to:
  /// **'Quét mã khác'**
  String get qrScanAgain;

  /// No description provided for @qrReceiveIntro.
  ///
  /// In vi, this message translates to:
  /// **'Tạo mã VietQR để khách hàng quét chuyển tiền cho bạn. Mã tạo ngay trên máy, số tài khoản không được lưu hay gửi đi.'**
  String get qrReceiveIntro;

  /// No description provided for @qrAmountOptional.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền (để trống: người trả tự nhập)'**
  String get qrAmountOptional;

  /// No description provided for @qrMessageHelp.
  ///
  /// In vi, this message translates to:
  /// **'Tối đa 25 ký tự, tự bỏ dấu để mọi ngân hàng đọc được.'**
  String get qrMessageHelp;

  /// No description provided for @qrCreate.
  ///
  /// In vi, this message translates to:
  /// **'Tạo mã'**
  String get qrCreate;

  /// No description provided for @qrErrAccount.
  ///
  /// In vi, this message translates to:
  /// **'Số tài khoản chỉ gồm chữ và số, tối đa 19 ký tự.'**
  String get qrErrAccount;

  /// No description provided for @qrImageLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mã QR nhận tiền'**
  String get qrImageLabel;

  /// No description provided for @qrCopyContent.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép nội dung mã'**
  String get qrCopyContent;

  /// No description provided for @importTemplateHelp.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển dữ liệu từ app khác: tải tệp mẫu, dán dữ liệu cũ vào đúng cột (Ngày, Loại, Số tiền, Ví...), rồi chọn tệp để nhập. Ví và danh mục chưa có được tạo tự động.'**
  String get importTemplateHelp;

  /// No description provided for @importTemplateCsv.
  ///
  /// In vi, this message translates to:
  /// **'Tệp mẫu CSV'**
  String get importTemplateCsv;

  /// No description provided for @importTemplateXlsx.
  ///
  /// In vi, this message translates to:
  /// **'Tệp mẫu Excel'**
  String get importTemplateXlsx;

  /// No description provided for @importTemplateSaved.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu tệp mẫu'**
  String get importTemplateSaved;

  /// No description provided for @importTemplateDetected.
  ///
  /// In vi, this message translates to:
  /// **'Đã nhận ra tệp mẫu Quly Thu Chi'**
  String get importTemplateDetected;

  /// No description provided for @importTemplateSummary.
  ///
  /// In vi, this message translates to:
  /// **'{rows} giao dịch, tạo mới {wallets} ví và {categories} danh mục.'**
  String importTemplateSummary(int rows, int wallets, int categories);

  /// No description provided for @importTemplateNewWallets.
  ///
  /// In vi, this message translates to:
  /// **'Ví mới: {names}'**
  String importTemplateNewWallets(String names);

  /// No description provided for @importTemplateDuplicates.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ {count} dòng trùng giao dịch đã có.'**
  String importTemplateDuplicates(int count);

  /// No description provided for @importTemplateSkipped.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ {count} dòng thiếu/sai dữ liệu (dòng {rows}).'**
  String importTemplateSkipped(int count, String rows);

  /// No description provided for @importTemplateRun.
  ///
  /// In vi, this message translates to:
  /// **'Nhập {count} giao dịch'**
  String importTemplateRun(int count);

  /// No description provided for @importTemplateDone.
  ///
  /// In vi, this message translates to:
  /// **'Đã nhập {count} giao dịch, tạo {wallets} ví, {categories} danh mục.'**
  String importTemplateDone(int count, int wallets, int categories);

  /// No description provided for @shareTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ví chung'**
  String get shareTitle;

  /// No description provided for @shareMembersEntry.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ và thành viên'**
  String get shareMembersEntry;

  /// No description provided for @shareBadge.
  ///
  /// In vi, this message translates to:
  /// **'Ví chung'**
  String get shareBadge;

  /// No description provided for @shareIntro.
  ///
  /// In vi, this message translates to:
  /// **'Mời người trong gia đình cùng ghi chép ví này. Khóa ví được trao qua mã hóa đầu-cuối: máy chủ chỉ thấy bản mã, không đọc được số tiền hay ghi chú.'**
  String get shareIntro;

  /// No description provided for @shareStart.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ ví này'**
  String get shareStart;

  /// No description provided for @shareNeedSignIn.
  ///
  /// In vi, this message translates to:
  /// **'Cần đăng nhập và đồng bộ để dùng ví chung.'**
  String get shareNeedSignIn;

  /// No description provided for @shareGoSignIn.
  ///
  /// In vi, this message translates to:
  /// **'Đến Tài khoản và đồng bộ'**
  String get shareGoSignIn;

  /// No description provided for @shareNotLoaded.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tải được danh sách thành viên.'**
  String get shareNotLoaded;

  /// No description provided for @shareRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get shareRetry;

  /// No description provided for @shareMembers.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên'**
  String get shareMembers;

  /// No description provided for @shareInvites.
  ///
  /// In vi, this message translates to:
  /// **'Lời mời đang mở'**
  String get shareInvites;

  /// No description provided for @shareInvite.
  ///
  /// In vi, this message translates to:
  /// **'Mời thành viên'**
  String get shareInvite;

  /// No description provided for @shareRoleOwner.
  ///
  /// In vi, this message translates to:
  /// **'Chủ ví'**
  String get shareRoleOwner;

  /// No description provided for @shareRoleEditor.
  ///
  /// In vi, this message translates to:
  /// **'Người ghi'**
  String get shareRoleEditor;

  /// No description provided for @shareRoleViewer.
  ///
  /// In vi, this message translates to:
  /// **'Người xem'**
  String get shareRoleViewer;

  /// No description provided for @shareRoleEditorHint.
  ///
  /// In vi, this message translates to:
  /// **'Thêm, sửa, xóa giao dịch trong ví'**
  String get shareRoleEditorHint;

  /// No description provided for @shareRoleViewerHint.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ xem, không ghi'**
  String get shareRoleViewerHint;

  /// No description provided for @shareYourRole.
  ///
  /// In vi, this message translates to:
  /// **'Quyền của bạn: {role}'**
  String shareYourRole(String role);

  /// No description provided for @shareYou.
  ///
  /// In vi, this message translates to:
  /// **'Bạn'**
  String get shareYou;

  /// No description provided for @shareSafetyCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã an toàn: {code}'**
  String shareSafetyCode(String code);

  /// No description provided for @shareMySafetyCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã an toàn của bạn: {code}. Hai người cùng ví nên so mã an toàn qua điện thoại hoặc gặp mặt.'**
  String shareMySafetyCode(String code);

  /// No description provided for @shareChangeTo.
  ///
  /// In vi, this message translates to:
  /// **'Đổi thành {role}'**
  String shareChangeTo(String role);

  /// No description provided for @shareRemove.
  ///
  /// In vi, this message translates to:
  /// **'Thu hồi quyền'**
  String get shareRemove;

  /// No description provided for @shareRemoveConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Thu hồi quyền của {name}? Ví sẽ được đổi khóa mới và mã hóa lại; người này không đọc được dữ liệu mới nữa.'**
  String shareRemoveConfirm(String name);

  /// No description provided for @shareRemoved.
  ///
  /// In vi, this message translates to:
  /// **'Đã thu hồi và đổi khóa ví.'**
  String get shareRemoved;

  /// No description provided for @shareInviteWaiting.
  ///
  /// In vi, this message translates to:
  /// **'Chờ người nhận'**
  String get shareInviteWaiting;

  /// No description provided for @shareInviteAccepted.
  ///
  /// In vi, this message translates to:
  /// **'{name} đã nhận - đang hoàn tất'**
  String shareInviteAccepted(String name);

  /// No description provided for @shareInviteCancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy lời mời'**
  String get shareInviteCancel;

  /// No description provided for @shareInviteRoleTitle.
  ///
  /// In vi, this message translates to:
  /// **'Mời với quyền'**
  String get shareInviteRoleTitle;

  /// No description provided for @shareInviteCreate.
  ///
  /// In vi, this message translates to:
  /// **'Tạo lời mời'**
  String get shareInviteCreate;

  /// No description provided for @shareInviteCodeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Gửi mã mời'**
  String get shareInviteCodeTitle;

  /// No description provided for @shareInviteCodeBody.
  ///
  /// In vi, this message translates to:
  /// **'Gửi mã hoặc liên kết này cho người được mời qua tin nhắn riêng, hoặc cho họ quét mã QR. Mã dùng được một lần trong 7 ngày. Ai có mã đều có thể nhận lời mời, nên đừng đăng công khai.'**
  String get shareInviteCodeBody;

  /// No description provided for @shareCopyCode.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép mã'**
  String get shareCopyCode;

  /// No description provided for @shareCopyLink.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép liên kết'**
  String get shareCopyLink;

  /// No description provided for @shareCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép.'**
  String get shareCopied;

  /// No description provided for @shareLeave.
  ///
  /// In vi, this message translates to:
  /// **'Rời ví chung'**
  String get shareLeave;

  /// No description provided for @shareLeaveConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Rời ví \"{name}\"? Dữ liệu của ví sẽ bị xóa khỏi máy này.'**
  String shareLeaveConfirm(String name);

  /// No description provided for @shareLeft.
  ///
  /// In vi, this message translates to:
  /// **'Đã rời ví chung.'**
  String get shareLeft;

  /// No description provided for @shareReadOnlyNote.
  ///
  /// In vi, this message translates to:
  /// **'Ví chung: chỉ chủ ví sửa được thông tin ví.'**
  String get shareReadOnlyNote;

  /// No description provided for @shareBadInvites.
  ///
  /// In vi, this message translates to:
  /// **'Đã hủy {count} lời mời vì bằng chứng không khớp (có thể ai đó không có mã thật).'**
  String shareBadInvites(int count);

  /// No description provided for @joinTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tham gia ví chung'**
  String get joinTitle;

  /// No description provided for @joinCodeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mã hoặc liên kết mời'**
  String get joinCodeLabel;

  /// No description provided for @joinPreview.
  ///
  /// In vi, this message translates to:
  /// **'Xem lời mời'**
  String get joinPreview;

  /// No description provided for @joinInvalidCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã mời không đúng định dạng.'**
  String get joinInvalidCode;

  /// No description provided for @joinFrom.
  ///
  /// In vi, this message translates to:
  /// **'Lời mời từ {name}'**
  String joinFrom(String name);

  /// No description provided for @joinRole.
  ///
  /// In vi, this message translates to:
  /// **'Quyền: {role}'**
  String joinRole(String role);

  /// No description provided for @joinAccept.
  ///
  /// In vi, this message translates to:
  /// **'Tham gia'**
  String get joinAccept;

  /// No description provided for @joinSent.
  ///
  /// In vi, this message translates to:
  /// **'Đã nhận lời mời. Ví sẽ xuất hiện khi chủ ví mở app.'**
  String get joinSent;

  /// No description provided for @joinPending.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ chủ ví xác nhận'**
  String get joinPending;

  /// No description provided for @joinOwnerUnknown.
  ///
  /// In vi, this message translates to:
  /// **'chủ ví'**
  String get joinOwnerUnknown;

  /// No description provided for @joinAlreadyAccepted.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã nhận lời mời này.'**
  String get joinAlreadyAccepted;

  /// No description provided for @shareErrInviteGone.
  ///
  /// In vi, this message translates to:
  /// **'Lời mời không tồn tại hoặc đã hết hạn.'**
  String get shareErrInviteGone;

  /// No description provided for @shareErrInviteTaken.
  ///
  /// In vi, this message translates to:
  /// **'Lời mời đã được người khác dùng. Hãy xin chủ ví mã mới.'**
  String get shareErrInviteTaken;

  /// No description provided for @shareErrInviteOwn.
  ///
  /// In vi, this message translates to:
  /// **'Đây là lời mời vào ví của chính bạn.'**
  String get shareErrInviteOwn;

  /// No description provided for @shareErrAlreadyMember.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã ở trong ví này.'**
  String get shareErrAlreadyMember;

  /// No description provided for @shareErrNoKeys.
  ///
  /// In vi, this message translates to:
  /// **'Hãy đồng bộ một lần để tải khóa mã hóa lên trước.'**
  String get shareErrNoKeys;

  /// No description provided for @shareErrLimit.
  ///
  /// In vi, this message translates to:
  /// **'Đã đạt giới hạn số ví chung hoặc thành viên.'**
  String get shareErrLimit;

  /// No description provided for @shareErrStale.
  ///
  /// In vi, this message translates to:
  /// **'Ví vừa thay đổi. Hãy đồng bộ rồi thử lại.'**
  String get shareErrStale;

  /// No description provided for @shareErrMissingSecret.
  ///
  /// In vi, this message translates to:
  /// **'Máy này chưa có đủ thông tin của một thành viên. Hãy đồng bộ hoặc thử trên máy đã tạo lời mời.'**
  String get shareErrMissingSecret;

  /// No description provided for @shareErrForbidden.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ chủ ví được làm việc này.'**
  String get shareErrForbidden;

  /// No description provided for @errReadOnly.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chỉ có quyền xem ví chung này.'**
  String get errReadOnly;

  /// No description provided for @errOwnerOnly.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ chủ ví được sửa thông tin ví chung.'**
  String get errOwnerOnly;

  /// No description provided for @attTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh hóa đơn'**
  String get attTitle;

  /// No description provided for @attAdd.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ảnh'**
  String get attAdd;

  /// No description provided for @attCamera.
  ///
  /// In vi, this message translates to:
  /// **'Chụp ảnh'**
  String get attCamera;

  /// No description provided for @attGallery.
  ///
  /// In vi, this message translates to:
  /// **'Chọn từ thư viện'**
  String get attGallery;

  /// No description provided for @attFile.
  ///
  /// In vi, this message translates to:
  /// **'Chọn tệp ảnh'**
  String get attFile;

  /// No description provided for @attLimit.
  ///
  /// In vi, this message translates to:
  /// **'Tối đa {count} ảnh mỗi giao dịch'**
  String attLimit(int count);

  /// No description provided for @attPrivacy.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh được thu nhỏ, xóa vị trí GPS và thông tin máy chụp, rồi mã hóa trên máy trước khi đồng bộ.'**
  String get attPrivacy;

  /// No description provided for @attNewHint.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh sẽ được gắn khi bạn lưu giao dịch.'**
  String get attNewHint;

  /// No description provided for @attProcessing.
  ///
  /// In vi, this message translates to:
  /// **'Đang xử lý ảnh…'**
  String get attProcessing;

  /// No description provided for @attPending.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đồng bộ - ảnh đang lưu an toàn trên máy này'**
  String get attPending;

  /// No description provided for @attProBlocked.
  ///
  /// In vi, this message translates to:
  /// **'Đồng bộ ảnh cần TsuDEV Pro. Ảnh vẫn lưu đầy đủ trên máy này.'**
  String get attProBlocked;

  /// No description provided for @attFilesPending.
  ///
  /// In vi, this message translates to:
  /// **'{count} ảnh chờ đồng bộ (đang lưu trên máy)'**
  String attFilesPending(int count);

  /// No description provided for @attNotAvailable.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh chưa có trên máy này. Đăng nhập đồng bộ để tải về.'**
  String get attNotAvailable;

  /// No description provided for @attOpenFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được ảnh (tệp hỏng hoặc không đúng giao dịch).'**
  String get attOpenFailed;

  /// No description provided for @attDelete.
  ///
  /// In vi, this message translates to:
  /// **'Xóa ảnh'**
  String get attDelete;

  /// No description provided for @attDeleteConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xóa ảnh này khỏi giao dịch trên mọi thiết bị?'**
  String get attDeleteConfirm;

  /// No description provided for @attView.
  ///
  /// In vi, this message translates to:
  /// **'Xem ảnh {index}'**
  String attView(int index);

  /// No description provided for @attRejectTooLarge.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh quá lớn (tối đa 25 MB).'**
  String get attRejectTooLarge;

  /// No description provided for @attRejectPixels.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh có độ phân giải quá lớn.'**
  String get attRejectPixels;

  /// No description provided for @attRejectUnsupported.
  ///
  /// In vi, this message translates to:
  /// **'Không đọc được ảnh này. Hãy chọn ảnh JPEG hoặc PNG.'**
  String get attRejectUnsupported;

  /// No description provided for @errTooManyAttachments.
  ///
  /// In vi, this message translates to:
  /// **'Đã đủ số ảnh tối đa cho giao dịch này.'**
  String get errTooManyAttachments;

  /// No description provided for @errAttachmentsNotLocal.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh đính kèm của giao dịch này chưa tải về máy. Hãy mở xem các ảnh (để tải về) rồi đổi ví.'**
  String get errAttachmentsNotLocal;
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
