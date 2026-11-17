// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Quly Thu Chi';

  @override
  String get navOverview => 'Overview';

  @override
  String get navTransactions => 'Transactions';

  @override
  String get navWallets => 'Wallets';

  @override
  String get navCategories => 'Categories';

  @override
  String get navSettings => 'Settings';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionBack => 'Back';

  @override
  String get actionDone => 'Done';

  @override
  String get actionCopy => 'Copy';

  @override
  String get actionRetry => 'Try again';

  @override
  String get loading => 'Loading…';

  @override
  String get working => 'Working, please wait…';

  @override
  String get welcomeTitle => 'Welcome to Quly Thu Chi';

  @override
  String get welcomeBody => 'Your finances are encrypted on this device. Nobody else, including us, can read them.';

  @override
  String get welcomeStart => 'Get started';

  @override
  String get welcomeRestore => 'I have a recovery phrase';

  @override
  String get setupPasswordTitle => 'Create an encryption password';

  @override
  String get setupPasswordBody =>
      'This password unlocks your data. We cannot recover it - only your 24-word recovery phrase can.';

  @override
  String get passwordLabel => 'Encryption password';

  @override
  String get passwordConfirmLabel => 'Confirm password';

  @override
  String passwordTooShort(int min) {
    return 'At least $min characters';
  }

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get passwordWrong => 'Wrong password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get recoveryTitle => 'Your 24-word recovery phrase';

  @override
  String get recoveryBody =>
      'Write these 24 words down in order and keep them safe. Anyone with them can read all your data. They will not be shown again.';

  @override
  String get recoveryConfirmCheck => 'I have written down all 24 words';

  @override
  String get recoveryVerifyTitle => 'Confirm your recovery phrase';

  @override
  String get recoveryVerifyBody => 'Pick the correct word for each position.';

  @override
  String recoveryWordN(int n) {
    return 'Word #$n';
  }

  @override
  String get recoveryVerifyWrong => 'Not quite. Check your written copy.';

  @override
  String get restoreTitle => 'Restore with 24 words';

  @override
  String get restoreBody => 'Enter the 24 words separated by spaces.';

  @override
  String get restoreNeedsSync =>
      'Restoring data from the server arrives with sync (coming soon). For now, this only unlocks data already on this device.';

  @override
  String get restoreInvalid => 'Invalid recovery phrase';

  @override
  String get pinSetupTitle => 'Set a quick-unlock PIN';

  @override
  String get pinSetupBody =>
      'A 6-12 digit PIN to unlock quickly on this device. After 10 wrong tries the PIN is disabled and your password is required.';

  @override
  String get pinLabel => 'PIN';

  @override
  String get pinConfirmLabel => 'Confirm PIN';

  @override
  String get pinInvalid => 'PIN must be 6-12 digits';

  @override
  String get pinMismatch => 'PINs do not match';

  @override
  String get pinSkip => 'Skip for now';

  @override
  String get lockTitle => 'Locked';

  @override
  String get lockBody => 'Enter your PIN or encryption password to unlock.';

  @override
  String get unlock => 'Unlock';

  @override
  String get unlockWithPassword => 'Use password';

  @override
  String get unlockWithPin => 'Use PIN';

  @override
  String get unlockWithBiometric => 'Unlock with biometrics';

  @override
  String get unlockWithRecovery => 'Forgot password? Use recovery phrase';

  @override
  String get biometricReason => 'Authenticate to open Quly Thu Chi';

  @override
  String pinWrong(int n) {
    return 'Wrong PIN. $n tries left.';
  }

  @override
  String pinLockedOut(String time) {
    return 'Too many attempts. Try again at $time.';
  }

  @override
  String get pinDisabledMsg => 'PIN disabled. Unlock with your encryption password.';

  @override
  String get overviewTotal => 'Total balance';

  @override
  String get overviewWallets => 'Wallets';

  @override
  String get overviewRecent => 'Recent transactions';

  @override
  String get overviewMonthIncome => 'Income this month';

  @override
  String get overviewMonthExpense => 'Spending this month';

  @override
  String get seeAll => 'See all';

  @override
  String get emptyWalletsTitle => 'No wallets yet';

  @override
  String get emptyWalletsBody => 'Create your first wallet (cash, bank account…) to start tracking.';

  @override
  String get emptyTxnsTitle => 'No transactions yet';

  @override
  String get emptyTxnsBody => 'Tap + to record your first income or expense.';

  @override
  String get noResults => 'No results';

  @override
  String get hiddenAmount => 'Amount hidden';

  @override
  String skippedRecords(int n) {
    return '$n records could not be decrypted (possibly corrupted) and were skipped.';
  }

  @override
  String get walletNew => 'New wallet';

  @override
  String get walletEdit => 'Edit wallet';

  @override
  String get walletName => 'Wallet name';

  @override
  String get walletType => 'Wallet type';

  @override
  String get walletCurrency => 'Currency';

  @override
  String get walletOpening => 'Opening balance';

  @override
  String get walletCreditLimit => 'Credit limit';

  @override
  String get walletArchived => 'Archived (hidden from lists)';

  @override
  String get walletExcludeTotal => 'Exclude from total';

  @override
  String get walletBalance => 'Balance';

  @override
  String walletDeleteConfirm(String name) {
    return 'Delete wallet \"$name\"?';
  }

  @override
  String get walletTypeCash => 'Cash';

  @override
  String get walletTypeBank => 'Bank account';

  @override
  String get walletTypeCredit => 'Credit card';

  @override
  String get walletTypeEwallet => 'E-wallet';

  @override
  String get walletTypeSaving => 'Savings';

  @override
  String get walletTypeInvestment => 'Investment';

  @override
  String get walletTypeOther => 'Other';

  @override
  String get showArchived => 'Show archived wallets';

  @override
  String get categoryNew => 'New category';

  @override
  String get categoryEdit => 'Edit category';

  @override
  String get categoryName => 'Category name';

  @override
  String get categoryParent => 'Parent group';

  @override
  String get categoryNoParent => '(Top level)';

  @override
  String get categoryExpense => 'Expense';

  @override
  String get categoryIncome => 'Income';

  @override
  String categoryDeleteConfirm(String name) {
    return 'Delete category \"$name\"? Subcategories are deleted too; past transactions become \"Uncategorized\".';
  }

  @override
  String get uncategorized => 'Uncategorized';

  @override
  String get txnNew => 'New transaction';

  @override
  String get txnEdit => 'Edit transaction';

  @override
  String get txnExpense => 'Expense';

  @override
  String get txnIncome => 'Income';

  @override
  String get txnTransfer => 'Transfer';

  @override
  String get txnAdjustment => 'Balance adjustment';

  @override
  String get txnAmount => 'Amount';

  @override
  String get txnAmountHint => 'You can type a sum, e.g. 50,000+25,000';

  @override
  String txnAmountResult(String value) {
    return '= $value';
  }

  @override
  String get txnAmountInvalid => 'Invalid amount';

  @override
  String get txnAmountPositive => 'Amount must be greater than 0';

  @override
  String txnReceived(String currency) {
    return 'Amount received ($currency)';
  }

  @override
  String get txnFee => 'Transfer fee';

  @override
  String get txnWallet => 'Wallet';

  @override
  String get txnFromWallet => 'From wallet';

  @override
  String get txnToWallet => 'To wallet';

  @override
  String get txnCategory => 'Category';

  @override
  String get txnDate => 'Date';

  @override
  String get txnNote => 'Note';

  @override
  String get txnPayee => 'Payee';

  @override
  String txnTransferTo(String wallet) {
    return 'Transfer to $wallet';
  }

  @override
  String txnTransferFrom(String wallet) {
    return 'Transfer from $wallet';
  }

  @override
  String get txnDeleteConfirm => 'Delete this transaction?';

  @override
  String get txnDeleteTransferConfirm => 'Delete both sides of this transfer?';

  @override
  String get selectWallet => 'Choose a wallet';

  @override
  String get searchHint => 'Search notes, categories, wallets…';

  @override
  String get searchLabel => 'Search transactions';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsPrivacy => 'Privacy & security';

  @override
  String get settingsHideBalance => 'Hide balances';

  @override
  String get settingsHideBalanceSub => 'Mask all amounts until you turn this off';

  @override
  String get settingsPin => 'Quick-unlock PIN';

  @override
  String get settingsPinOn => 'On';

  @override
  String get settingsPinOff => 'Off';

  @override
  String get settingsPinChange => 'Change PIN';

  @override
  String get settingsPinDisable => 'Turn off PIN';

  @override
  String get settingsBiometric => 'Biometric unlock';

  @override
  String get settingsBiometricSub => 'Requires a PIN';

  @override
  String get settingsBiometricUnavailable => 'Biometrics are not available on this device';

  @override
  String get settingsQuickUnlockWeb =>
      'The web version has no PIN/biometrics because browsers lack a secure key store.';

  @override
  String get settingsAutoLock => 'Auto-lock after 60 seconds away';

  @override
  String get settingsLockNow => 'Lock now';

  @override
  String get settingsChangePassword => 'Change encryption password';

  @override
  String get settingsOldPassword => 'Current password';

  @override
  String get settingsNewPassword => 'New password';

  @override
  String get settingsPasswordChanged => 'Encryption password changed';

  @override
  String get settingsAbout => 'About';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsLicense => 'Open source, AGPL-3.0';

  @override
  String get settingsReset => 'Erase all data on this device';

  @override
  String get settingsResetConfirm =>
      'Permanently erase every wallet, category, transaction and key on this device? This cannot be undone.';

  @override
  String get settingsResetTypeHint => 'Type ERASE to confirm';

  @override
  String get settingsResetWord => 'ERASE';

  @override
  String get saved => 'Saved';

  @override
  String get deleted => 'Deleted';

  @override
  String get errNameRequired => 'Please enter a name';

  @override
  String get errCurrencyLocked => 'This wallet has transactions; its currency cannot change';

  @override
  String get errWalletHasTxns => 'This wallet has transactions. Archive it instead.';

  @override
  String get errParentMissing => 'The parent group no longer exists';

  @override
  String get errTwoLevelsOnly => 'Categories can only be two levels deep';

  @override
  String get errKindMismatch => 'Category type does not match';

  @override
  String get errWalletMissing => 'Please choose a wallet';

  @override
  String get errSameWallet => 'Source and destination must differ';

  @override
  String get errReceivedRequired => 'Different currencies: enter the amount received';

  @override
  String get errGeneric => 'Something went wrong. Please try again.';

  @override
  String get errStorage => 'Could not open the device\'s secure storage.';

  @override
  String get walletArchivedBadge => 'Archived';

  @override
  String get settingsNewRecovery => 'Issue a new recovery phrase';

  @override
  String get settingsNewRecoveryConfirm => 'Your old 24 words will stop working. Continue?';

  @override
  String get settingsLanguageSystem => 'System default';

  @override
  String get settingsSecurityNote =>
      'Your data is end-to-end encrypted with libsodium. Your password and 24 words never leave this device.';

  @override
  String get iconLabel => 'Icon';
}
