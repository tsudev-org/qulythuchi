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

  @override
  String get navPlan => 'Plan';

  @override
  String get navMore => 'More';

  @override
  String get planBudgets => 'Budgets';

  @override
  String get planJars => '6 jars';

  @override
  String get planGoals => 'Goals';

  @override
  String get budgetNew => 'New budget';

  @override
  String get budgetEdit => 'Edit budget';

  @override
  String get budgetName => 'Budget name';

  @override
  String get budgetAmount => 'Limit per period';

  @override
  String get budgetPeriod => 'Period';

  @override
  String get periodWeekly => 'Weekly';

  @override
  String get periodMonthly => 'Monthly';

  @override
  String get periodYearly => 'Yearly';

  @override
  String get periodCustom => 'Custom';

  @override
  String get budgetStartDay => 'Period start day (1-31)';

  @override
  String get budgetStartWeekday => 'Week starts on';

  @override
  String get budgetFrom => 'From';

  @override
  String get budgetTo => 'To';

  @override
  String get budgetCategories => 'Categories';

  @override
  String get budgetAllCategories => 'All spending';

  @override
  String get budgetWallets => 'Wallets';

  @override
  String get budgetAllWallets => 'All wallets in this currency';

  @override
  String get budgetRollover => 'Carry leftover/overspend to next period';

  @override
  String get budgetAlertAt => 'Warn at (%)';

  @override
  String budgetSpentOf(String spent, String limit) {
    return 'Spent $spent of $limit';
  }

  @override
  String budgetRemaining(String amount) {
    return '$amount left';
  }

  @override
  String budgetOver(String amount) {
    return 'Over by $amount';
  }

  @override
  String budgetDaily(String amount) {
    return 'You can spend $amount per day';
  }

  @override
  String get budgetStateOk => 'On track';

  @override
  String get budgetStateWarning => 'Near the limit';

  @override
  String get budgetStateOver => 'Over budget';

  @override
  String budgetDeleteConfirm(String name) {
    return 'Delete budget \"$name\"?';
  }

  @override
  String get emptyBudgetsTitle => 'No budgets yet';

  @override
  String get emptyBudgetsBody =>
      'Set weekly or monthly spending limits for all wallets or per category (envelope method).';

  @override
  String jarsIncomeThisMonth(String currency) {
    return 'Income this month ($currency)';
  }

  @override
  String get jarsSimulate => 'Try splitting an amount';

  @override
  String get jarsEdit => 'Edit jar ratios';

  @override
  String get jarsReset => 'Reset to 6 jars';

  @override
  String jarsTotalMustBe100(String total) {
    return 'Ratios must total 100% (now $total%)';
  }

  @override
  String jarsNoIncome(String currency) {
    return 'No $currency income this month yet.';
  }

  @override
  String get jarNec => 'Necessities';

  @override
  String get jarLts => 'Long-term savings';

  @override
  String get jarEdu => 'Education';

  @override
  String get jarPly => 'Play';

  @override
  String get jarFfa => 'Financial freedom';

  @override
  String get jarGiv => 'Give';

  @override
  String get jarsNote => '6-jar method: split every income by fixed ratios for disciplined spending.';

  @override
  String get goalNew => 'New goal';

  @override
  String get goalEdit => 'Edit goal';

  @override
  String get goalName => 'Goal name';

  @override
  String get goalTarget => 'Target amount';

  @override
  String get goalStarting => 'Already saved';

  @override
  String get goalDeadline => 'Deadline';

  @override
  String get goalNoDeadline => 'No deadline';

  @override
  String get goalAchieved => 'Achieved';

  @override
  String goalProgress(String saved, String target, String percent) {
    return '$saved of $target ($percent%)';
  }

  @override
  String goalMonthly(String amount) {
    return 'Save $amount per month to meet the deadline';
  }

  @override
  String get goalContribute => 'Contribute';

  @override
  String goalDeleteConfirm(String name) {
    return 'Delete goal \"$name\"? Contribution transactions are kept.';
  }

  @override
  String get emptyGoalsTitle => 'No goals yet';

  @override
  String get emptyGoalsBody => 'Set savings goals (a bike, a trip…) and track progress.';

  @override
  String get clearValue => 'Clear';

  @override
  String get selectAll => 'All';

  @override
  String get none => 'None';

  @override
  String get moreRecurring => 'Recurring & bills';

  @override
  String get moreDebts => 'Debts & loans';

  @override
  String get moreEvents => 'Events & trips';

  @override
  String get moreRates => 'Exchange rates';

  @override
  String get recurringNew => 'New recurring item';

  @override
  String get recurringEdit => 'Edit recurring item';

  @override
  String get recurringName => 'Name';

  @override
  String get recurringFrequency => 'Repeats';

  @override
  String get freqDaily => 'Daily';

  @override
  String get freqWeekly => 'Weekly';

  @override
  String get freqMonthly => 'Monthly';

  @override
  String get freqYearly => 'Yearly';

  @override
  String get recurringInterval => 'Every N periods';

  @override
  String get recurringStart => 'Starts on';

  @override
  String get recurringUntil => 'Ends on (optional)';

  @override
  String get recurringIsBill => 'Bill (shown in bill calendar, with reminders)';

  @override
  String get recurringAuto => 'Record automatically when due';

  @override
  String get recurringAutoOff => 'Off: transactions wait for your confirmation';

  @override
  String get recurringRemind => 'Remind days before';

  @override
  String get recurringPaused => 'Paused';

  @override
  String recurringNext(String date) {
    return 'Next: $date';
  }

  @override
  String get recurringEnded => 'Ended';

  @override
  String recurringDeleteConfirm(String name) {
    return 'Delete \"$name\"? Created transactions are kept.';
  }

  @override
  String get emptyRecurringTitle => 'No recurring items';

  @override
  String get emptyRecurringBody => 'Add rent, utilities, salary… so the app records them and reminds you.';

  @override
  String get billsUpcoming => 'Upcoming bills';

  @override
  String billDueIn(String date, int days) {
    return 'Due $date (in $days days)';
  }

  @override
  String get billDueToday => 'Due today';

  @override
  String get billPay => 'Mark paid';

  @override
  String get billPaid => 'Payment recorded';

  @override
  String pendingTitle(int n) {
    return 'Awaiting confirmation ($n)';
  }

  @override
  String get pendingConfirm => 'Confirm';

  @override
  String get pendingSkip => 'Skip';

  @override
  String get pendingBanner => 'Auto-created, not counted in balances yet.';

  @override
  String get budgetAlertsTitle => 'Budgets to watch';

  @override
  String get debtNew => 'New debt';

  @override
  String get debtEdit => 'Debt';

  @override
  String get debtKind => 'Type';

  @override
  String get debtLend => 'I lent';

  @override
  String get debtBorrow => 'I borrowed';

  @override
  String get debtCounterparty => 'Person';

  @override
  String get debtPrincipal => 'Principal';

  @override
  String get debtStart => 'Start date';

  @override
  String get debtDue => 'Due date';

  @override
  String get debtInterest => 'Annual interest (%)';

  @override
  String get debtRecordDisbursement => 'Record the money movement in the wallet now';

  @override
  String debtPaid(String amount) {
    return 'Paid $amount';
  }

  @override
  String debtRemaining(String amount) {
    return 'Remaining $amount';
  }

  @override
  String get debtSettled => 'Settled';

  @override
  String get debtRecordPayment => 'Record payment';

  @override
  String get debtCollect => 'Record repayment';

  @override
  String get debtClose => 'Close debt';

  @override
  String get debtClosed => 'Closed';

  @override
  String get debtOverdue => 'Overdue';

  @override
  String get debtPayments => 'Payment history';

  @override
  String debtDeleteConfirm(String name) {
    return 'Delete the debt with \"$name\"? Recorded transactions are kept.';
  }

  @override
  String get emptyDebtsTitle => 'No debts';

  @override
  String get emptyDebtsBody => 'Track money you lent or borrowed and repayments.';

  @override
  String get debtsLendTotal => 'Owed to you';

  @override
  String get debtsBorrowTotal => 'You owe';

  @override
  String get eventNew => 'New event';

  @override
  String get eventEdit => 'Event';

  @override
  String get eventName => 'Event or trip name';

  @override
  String get eventStart => 'Starts';

  @override
  String get eventEnd => 'Ends';

  @override
  String get eventBudget => 'Budget (optional)';

  @override
  String get eventBudgetCurrency => 'Budget currency';

  @override
  String eventSpent(String amount) {
    return 'Spent $amount';
  }

  @override
  String get eventTxns => 'Event transactions';

  @override
  String eventDeleteConfirm(String name) {
    return 'Delete event \"$name\"? Transactions are kept.';
  }

  @override
  String get emptyEventsTitle => 'No events';

  @override
  String get emptyEventsBody => 'Tag transactions to trips or occasions for a separate summary.';

  @override
  String get txnEvent => 'Event';

  @override
  String get txnGoal => 'Towards goal';

  @override
  String get ratesBase => 'Base currency for totals';

  @override
  String get ratesNew => 'Add rate';

  @override
  String get ratesFrom => 'From';

  @override
  String ratesValue(String from, String to) {
    return '1 $from = ? $to';
  }

  @override
  String get ratesInvalid => 'Invalid rate';

  @override
  String get ratesNote => 'Rates are entered manually. Automatic updates via the Quly Thu Chi server arrive with sync.';

  @override
  String ratesMissing(String codes) {
    return 'No rate yet for: $codes';
  }

  @override
  String get emptyRatesTitle => 'No rates';

  @override
  String get emptyRatesBody => 'Only needed if you hold several currencies.';

  @override
  String overviewTotalIn(String currency) {
    return 'Total in $currency';
  }

  @override
  String get errAlertRange => 'Warning threshold must be 10%-100%';

  @override
  String get errDateRange => 'End date must be after start date';

  @override
  String get errSameCurrency => 'Currencies must differ';

  @override
  String get errRateInvalid => 'Invalid value';

  @override
  String get errRemindRange => 'Reminder must be 0-30 days';

  @override
  String get errNotFound => 'No longer exists';

  @override
  String get errWalletLocked => 'The wallet of this item cannot change';

  @override
  String get weekday1 => 'Monday';

  @override
  String get weekday2 => 'Tuesday';

  @override
  String get weekday3 => 'Wednesday';

  @override
  String get weekday4 => 'Thursday';

  @override
  String get weekday5 => 'Friday';

  @override
  String get weekday6 => 'Saturday';

  @override
  String get weekday7 => 'Sunday';

  @override
  String get notifBillTitle => 'A bill is due soon';

  @override
  String get notifBillBody => 'Open Quly Thu Chi for details.';

  @override
  String get settingsNotifications => 'Bill reminders';

  @override
  String get settingsNotificationsSub => 'Notifications never show names or amounts on the lock screen';

  @override
  String get pendingLabel => 'Pending';

  @override
  String get navReports => 'Reports';

  @override
  String get reportThisMonth => 'This month';

  @override
  String get reportLastMonth => 'Last month';

  @override
  String get reportLast3Months => 'Last 3 months';

  @override
  String get reportThisYear => 'This year';

  @override
  String get reportIncome => 'Income';

  @override
  String get reportExpense => 'Spending';

  @override
  String get reportNet => 'Net';

  @override
  String get reportSavingsRate => 'Savings rate';

  @override
  String get reportMonthly => 'Income & spending, last 6 months';

  @override
  String get reportByCategory => 'Spending by category';

  @override
  String get reportNetWorth => 'Net worth';

  @override
  String reportCalendar(String month) {
    return 'Spending calendar $month';
  }

  @override
  String get reportOther => 'Other';

  @override
  String reportMonthReadout(String month, String income, String expense) {
    return '$month: income $income · spending $expense';
  }

  @override
  String reportPointReadout(String month, String amount) {
    return '$month: $amount';
  }

  @override
  String reportDayReadout(String date, String amount) {
    return '$date: spent $amount';
  }

  @override
  String get reportTapDay => 'Tap a day to see the amount';

  @override
  String get reportEmpty => 'No spending in this period';

  @override
  String get reportShowTable => 'Show as table';

  @override
  String get reportShowChart => 'Show chart';

  @override
  String get reportColMonth => 'Month';

  @override
  String get reportColCategory => 'Category';

  @override
  String get reportColAmount => 'Amount';

  @override
  String get reportColShare => 'Share';

  @override
  String get reportColDay => 'Day';

  @override
  String get reportLess => 'Less';

  @override
  String get reportMore => 'More';

  @override
  String get weekdayShort1 => 'Mo';

  @override
  String get weekdayShort2 => 'Tu';

  @override
  String get weekdayShort3 => 'We';

  @override
  String get weekdayShort4 => 'Th';

  @override
  String get weekdayShort5 => 'Fr';

  @override
  String get weekdayShort6 => 'Sa';

  @override
  String get weekdayShort7 => 'Su';

  @override
  String get safeTitle => 'Safe to spend this month';

  @override
  String safePerDay(String amount) {
    return 'About $amount per day until month end';
  }

  @override
  String safeOver(String amount) {
    return 'Over this month\'s plan by $amount';
  }

  @override
  String safeExplain(String income, String spent, String bills, String goals) {
    return 'Income $income − spent $spent − upcoming bills $bills − goal savings $goals';
  }

  @override
  String get filterTitle => 'Filters';

  @override
  String get filterKinds => 'Transaction types';

  @override
  String get filterAllKinds => 'All types';

  @override
  String get filterWallets => 'Wallets';

  @override
  String get filterAllWallets => 'All wallets';

  @override
  String get filterCategories => 'Categories';

  @override
  String get filterAllCategories => 'All categories';

  @override
  String get filterUncategorized => 'Uncategorized only';

  @override
  String get filterMin => 'Amount from';

  @override
  String get filterMax => 'Amount to';

  @override
  String get filterApply => 'Apply';

  @override
  String get filterClear => 'Clear filters';

  @override
  String get filterSave => 'Save filter';

  @override
  String get filterSaveName => 'Filter name';

  @override
  String get filterSaved => 'Saved filters';

  @override
  String filterActive(int n) {
    return 'Filtering: $n conditions';
  }

  @override
  String filterResultCount(int n) {
    return '$n transactions';
  }

  @override
  String get dataTitle => 'Data: export, import, backup';

  @override
  String get exportTitle => 'Export transactions';

  @override
  String get exportFormat => 'Format';

  @override
  String get exportWarning =>
      'Exported files are NOT encrypted: anyone with the file can read every transaction. Store it safely.';

  @override
  String exportDone(int n) {
    return 'Exported $n transactions';
  }

  @override
  String get exportRange => 'Date range';

  @override
  String get exportAllTime => 'All time';

  @override
  String get exportCancelled => 'Cancelled';

  @override
  String get importTitle => 'Import from CSV';

  @override
  String get importPick => 'Choose a CSV file';

  @override
  String get importMapping => 'Map columns';

  @override
  String get importColDate => 'Date column';

  @override
  String get importColAmount => 'Amount column';

  @override
  String get importColNote => 'Note column';

  @override
  String get importColCategory => 'Category column';

  @override
  String get importColType => 'Type column (income/expense)';

  @override
  String get importNone => '(none)';

  @override
  String get importSignMode => 'Negative amounts are spending';

  @override
  String get importWallet => 'Import into wallet';

  @override
  String importPreview(int n) {
    return 'Preview of first $n rows';
  }

  @override
  String importRun(int n) {
    return 'Import $n transactions';
  }

  @override
  String importDone(int ok, int skipped) {
    return 'Imported $ok transactions, skipped $skipped invalid rows';
  }

  @override
  String get importEmpty => 'The file is empty or unreadable';

  @override
  String get importTooBig => 'File too large (max 5 MB)';

  @override
  String get importDateFormat => 'Date format';

  @override
  String get backupTitle => 'Encrypted backup';

  @override
  String get backupBody => 'The backup is end-to-end encrypted; only your encryption password or 24 words can open it.';

  @override
  String get backupCreate => 'Create backup file';

  @override
  String get backupDone => 'Backup saved';

  @override
  String get restoreFromBackup => 'Restore from a backup file';

  @override
  String get restoreBackupBody => 'Choose a .qtbak file, then enter the encryption password of the backed-up account.';

  @override
  String get restoreBackupInvalid => 'Not a Quly Thu Chi backup, or it is corrupted';

  @override
  String restoreBackupDone(int n) {
    return 'Restored $n records';
  }

  @override
  String get restoreUseRecovery => 'Use 24 words instead of the password';

  @override
  String get exportColSubcategory => 'Subcategory';

  @override
  String get exportColCurrency => 'Currency';

  @override
  String get importHasHeader => 'First row is a header';

  @override
  String get importNeedWallet => 'Create a wallet before importing';

  @override
  String get restoreWordsLabel => '24 recovery words';

  @override
  String get backupPrivacyNote =>
      'The backup holds all your encrypted data and key bundle; without your password or 24 words nobody can open it.';

  @override
  String reportVsPrevious(String pct) {
    return '$pct vs previous period';
  }

  @override
  String get syncTitle => 'Account & sync';

  @override
  String get syncWelcomeSignIn => 'Sign in to get your synced data';

  @override
  String get syncSignIn => 'Sign in with TsuDEV account';

  @override
  String get syncWaitingBrowser => 'Waiting for sign-in in the browser…';

  @override
  String get syncSignedOutTitle => 'Sync is off';

  @override
  String get syncSignedOutBody => 'Sign in to back up encrypted data to the server and share it across devices.';

  @override
  String get syncE2eeNote =>
      'The server only receives ciphertext. Your encryption password and 24 words never leave the device.';

  @override
  String get syncStatusSyncing => 'Syncing…';

  @override
  String get syncStatusNever => 'Not synced yet';

  @override
  String syncStatusLast(String time) {
    return 'Last synced $time';
  }

  @override
  String syncPending(int n) {
    return '$n changes waiting';
  }

  @override
  String get syncQuotaFull => 'Sync storage is full';

  @override
  String syncRejected(int n) {
    return '$n records rejected by the server';
  }

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncRetry => 'Retry';

  @override
  String get syncSignOut => 'Sign out';

  @override
  String get syncSignOutBody => 'Stop syncing on this device. Data on this device is kept.';

  @override
  String get syncSignOutConfirm =>
      'Sign out of sync? This device is revoked on the server; data on this device is kept.';

  @override
  String get syncUsage => 'Server storage';

  @override
  String syncUsageDetail(int count, String recMb, String recQuota, String fileMb, String fileQuota) {
    return '$count records · $recMb/$recQuota MB · files $fileMb/$fileQuota MB';
  }

  @override
  String get syncDevices => 'Signed-in devices';

  @override
  String get syncThisDevice => 'This device';

  @override
  String syncLastSeen(String time) {
    return 'Active $time';
  }

  @override
  String get syncRevoke => 'Revoke';

  @override
  String syncRevokeConfirm(String name) {
    return 'Revoke \"$name\"? That device is signed out immediately and can no longer sync.';
  }

  @override
  String get syncExport => 'Export server data';

  @override
  String get syncExportBody => 'A JSON file of everything the server holds (still encrypted).';

  @override
  String get syncExportDone => 'Export saved';

  @override
  String get syncDeleteAccount => 'Delete sync account';

  @override
  String get syncDeleteBody => 'Deletes all server data after 30 days. Can be cancelled meanwhile.';

  @override
  String get syncDeleteConfirm =>
      'Delete the sync account? After 30 days all ciphertext, keys and files on the server are permanently deleted. Meanwhile it is read-only and can be cancelled. Data on this device is not deleted.';

  @override
  String syncDeletionPending(int days) {
    return 'Account will be deleted in $days days';
  }

  @override
  String get syncDeletionCancel => 'Cancel deletion';

  @override
  String get syncNoRemoteAccount => 'This account has no synced data yet. Create a new encryption password.';

  @override
  String get syncUnlockRemoteTitle => 'Open synced data';

  @override
  String get syncUnlockRemoteBody =>
      'Enter the encryption password (or 24 recovery words) you set on your other device.';

  @override
  String get syncRemoteInvalid => 'The key data on the server is invalid.';

  @override
  String get syncErrNetwork => 'Can\'t reach the server. Will retry later.';

  @override
  String get syncErrTls =>
      'Insecure connection (server certificate mismatch). Sync stopped; data on this device still works.';

  @override
  String get syncErrSignedOut => 'Session ended or this device was revoked. Please sign in again.';

  @override
  String get syncErrDenied => 'Sign-in was declined.';

  @override
  String get syncErrNoBrowser => 'Couldn\'t open a browser.';

  @override
  String get syncErrRateLimited => 'Too many requests. Try again in a few minutes.';

  @override
  String get syncErrGeneric => 'Sync failed. Will retry later.';

  @override
  String get syncBlockDifferentAccount =>
      'The sync account already holds data encrypted with a DIFFERENT key than this device. The two will not be mixed: back up, then reset the app and choose \"Sign in to get your synced data\", or sign out.';

  @override
  String get syncBlockIdentityChanged =>
      'The encryption key on the server changed unexpectedly. Sync stopped to protect your data. If you didn\'t reset your account, please contact us.';

  @override
  String get syncBlockRollback => 'Server data was rolled back unexpectedly. Sync stopped to protect your data.';

  @override
  String get syncBlockPendingDeletion => 'Account is pending deletion - the server accepts no new changes.';

  @override
  String get syncBlockOtherUser =>
      'This device already syncs with another TsuDEV account. Sign in with that account or reset the app.';

  @override
  String get autoImportTitle => 'Auto import';

  @override
  String get autoConfirm => 'Confirm automatically';

  @override
  String get autoConfirmHint =>
      'Add straight to balances, skipping the review queue. Keep off until you trust the reader.';

  @override
  String get bankNotifTitle => 'Bank notifications';

  @override
  String get bankNotifAndroidOnly => 'Android only: other systems don\'t let apps read other apps\' notifications.';

  @override
  String get bankNotifExplain =>
      'Reads balance-change notifications from the banking apps you choose and turns them into transactions to review. Processed on this device only, encrypted while waiting, never sent anywhere.';

  @override
  String get bankNotifEnable => 'Read bank notifications';

  @override
  String get bankNotifDisclosure =>
      'Quly Thu Chi will ask for \"Notification access\". It keeps only notifications from the banking apps you choose, ignores every other app and OTP messages, and never sends their content off this device. You can revoke access any time in system Settings.';

  @override
  String get bankNotifDisclosureOk => 'Agree and continue';

  @override
  String get bankNotifNoPermission => 'Notification access not granted';

  @override
  String get bankNotifGrant => 'Grant';

  @override
  String get bankNotifAddApp => 'Add banking app';

  @override
  String get bankNotifPickApp => 'Choose app';

  @override
  String get bankNotifKnownApps => 'Common banks and e-wallets are listed first';

  @override
  String bankNotifLastRun(int added, int ignored) {
    return 'Last run: added $added transactions to review, skipped $ignored notifications';
  }

  @override
  String get captureMobileOnly => 'Voice and receipt scanning run on phones (Android/iOS), recognised on the device.';

  @override
  String get importAsPending => 'Add to the review queue';

  @override
  String get importAsPendingHint => 'Not counted in balances until you confirm';

  @override
  String get importColDebit => 'Debit column (money out)';

  @override
  String get importColCredit => 'Credit column (money in)';

  @override
  String importDoneDup(int ok, int skipped, int dup) {
    return 'Imported $ok transactions, skipped $skipped invalid and $dup already-recorded rows';
  }

  @override
  String get quickTitle => 'Quick add';

  @override
  String get quickExplain =>
      'Type or say a sentence like \"lunch 50k\", \"yesterday fuel 80k\", \"salary 15 triệu\". The app picks out the amount, date, income/spending and suggests a category.';

  @override
  String get quickLabel => 'Quick entry';

  @override
  String get quickHint => 'lunch 50k';

  @override
  String get quickNeedVndWallet => 'Quick add needs a VND wallet.';

  @override
  String get quickNoAmount => 'No amount found yet';

  @override
  String get quickMaybeDuplicate => 'A similar transaction exists within a day - check before adding a duplicate.';

  @override
  String get quickSaved => 'Saved';

  @override
  String get scanReceipt => 'Scan receipt';

  @override
  String get scanDefaultNote => 'Receipt';

  @override
  String get scanFailed => 'Couldn\'t read the image';

  @override
  String get scanNoTotal => 'No total found on the receipt - type the amount';

  @override
  String get statementTitle => 'Bank statements';

  @override
  String get statementExplain =>
      'Import a CSV or XLSX file downloaded from your bank. The app finds the transaction table and debit/credit columns, skips rows you already have and suggests categories. PDF statements: download the Excel/CSV version from your bank.';

  @override
  String get statementOpen => 'Import statement';

  @override
  String get voiceStart => 'Speak';

  @override
  String get voiceConsent =>
      'This device has no offline speech recogniser. The system recognition service can be used - audio may be sent to the system provider (Google/Apple). Quly Thu Chi never receives or stores audio. Continue?';

  @override
  String get voiceConsentOk => 'Use system service';

  @override
  String get voiceDenied => 'Microphone permission not granted';

  @override
  String get voiceUnavailable => 'Speech recognition unavailable';

  @override
  String get moreAutoImport => 'Auto import';

  @override
  String get emailTitle => 'Email forwarding';

  @override
  String get emailExplain =>
      'Forward your bank\'s transaction emails to a private address; the app turns them into transactions to review. Off by default.';

  @override
  String get emailNeedSignIn => 'Sign in to sync to use this';

  @override
  String get emailEnable => 'Turn on email forwarding';

  @override
  String get emailDisclosure =>
      'This is the ONLY exception to end-to-end encryption: email travels the Internet unencrypted, and the Quly Thu Chi server sees the content for a few milliseconds while sealing it with your key. The server never stores the plain text; sealed mail is deleted once the app downloads it or after 30 days. Forward only transaction alerts, never mail with passwords/OTPs.';

  @override
  String get emailCopy => 'Copy';

  @override
  String get emailCopied => 'Address copied';

  @override
  String get emailRotate => 'New address';

  @override
  String get emailRotateConfirm =>
      'The current address stops accepting mail immediately. You\'ll need to update the forwarding rule in your mailbox.';

  @override
  String get emailDisable => 'Turn off';

  @override
  String get emailDisableConfirm => 'Turn off email forwarding? The address and any undownloaded mail are deleted.';

  @override
  String get emailWarning =>
      'E2EE exception: the server sees email content while sealing it. Keep the address private - anyone who knows it can send mail to it.';

  @override
  String get copied => 'Copied';

  @override
  String get currencyPick => 'Choose currency';

  @override
  String get currencySearch => 'Search by code or name (USD, yen, pound...)';

  @override
  String get currencyPopular => 'Popular';

  @override
  String currencyAll(int count) {
    return 'All ($count ISO 4217 currencies)';
  }

  @override
  String get currencyNone => 'No matching currency.';

  @override
  String get guestModeNote =>
      'Without signing in you can use every feature in guest mode: data stays on this device, encrypted with your password.';

  @override
  String get welcomeGuest => 'Use now without an account';

  @override
  String get welcomeGuestNote => 'Guest mode: data stays on this device. You can sign in to sync at any time.';

  @override
  String get signInGoogle => 'Continue with Google';

  @override
  String get signInGithub => 'Continue with GitHub';

  @override
  String get signInTsudev => 'tsudev account (email)';

  @override
  String get signInLastUsed => 'You used this last time';

  @override
  String get signInOr => 'or';

  @override
  String get settingsCarryOver => 'Carry balance over to next month';

  @override
  String get settingsCarryOverSub =>
      'Last month\'s closing balance becomes this month\'s opening balance on the monthly card. Turn off to see only the month\'s income and spending.';

  @override
  String get settingsTaxReminders => 'Tax deadline and payment reminders';

  @override
  String get settingsTaxRemindersSub =>
      'Notify 7 days and 1 day before the personal income tax deadline, and on income installment due dates.';

  @override
  String periodTitle(int month, int year) {
    return '$month/$year';
  }

  @override
  String get periodPrev => 'Previous period';

  @override
  String get periodNext => 'Next period';

  @override
  String get periodThisMonth => 'This month';

  @override
  String periodOpening(int month) {
    return 'Opening balance (carried from month $month)';
  }

  @override
  String get periodIncome => 'Income this month';

  @override
  String get periodExpense => 'Spending this month';

  @override
  String get periodOther => 'Transfers, fees, adjustments';

  @override
  String get periodWithheld => 'Tax withheld (not deducted from balance)';

  @override
  String periodClosing(int month) {
    return 'Closing balance (carried to month $month)';
  }

  @override
  String get periodNet => 'Income minus spending';

  @override
  String periodSavingRate(String rate) {
    return 'Savings rate: $rate';
  }

  @override
  String get incomeTitle => 'Income';

  @override
  String get incomeRecord => 'Record income';

  @override
  String get incomePlanNew => 'New multi-payment income';

  @override
  String get incomePlanEdit => 'Edit income';

  @override
  String incomeYear(int year) {
    return 'Year $year';
  }

  @override
  String get incomeByMonth => 'Monthly';

  @override
  String get incomeByYear => 'Yearly';

  @override
  String get incomeTotalReceived => 'Total received';

  @override
  String incomeReceipts(int count) {
    return '$count payments';
  }

  @override
  String incomeWithheldTotal(String amount) {
    return 'tax withheld $amount';
  }

  @override
  String incomeGrossTotal(String amount) {
    return 'before tax $amount';
  }

  @override
  String get incomeSumBy => 'Income by';

  @override
  String get incomeByPayer => 'Payer';

  @override
  String get incomeByCategory => 'Category';

  @override
  String get incomeByPlan => 'Income plan';

  @override
  String get incomeNoPayer => '(No payer)';

  @override
  String get incomeNoPlan => '(One-off, not in a plan)';

  @override
  String get incomeNone => 'No income in this period.';

  @override
  String incomeLast(String date) {
    return 'last $date';
  }

  @override
  String get incomePlansTitle => 'Multi-payment income';

  @override
  String get incomePlansHelp =>
      'Track freelance jobs, contracts, rent... paid in several installments: what\'s received, what\'s left, what\'s late.';

  @override
  String get incomePlansEmpty => 'No income plans yet. Tap \"New multi-payment income\" to start.';

  @override
  String incomeShowClosed(int count) {
    return 'Show $count finished/cancelled';
  }

  @override
  String get incomeHideClosed => 'Hide finished';

  @override
  String get incomeStatusActive => 'Active';

  @override
  String get incomeStatusDone => 'Completed';

  @override
  String get incomeStatusCancelled => 'Cancelled';

  @override
  String get incomeStatus => 'Status';

  @override
  String incomeProgress(String received, String total) {
    return 'Received $received of $total';
  }

  @override
  String incomeReceivedSoFar(String amount) {
    return 'Received $amount';
  }

  @override
  String incomeNext(String label, String amount, String date) {
    return 'Next: $label $amount, due $date';
  }

  @override
  String get incomeInstallment => 'Installment';

  @override
  String incomeOverdue(String amount) {
    return 'Overdue, not received: $amount';
  }

  @override
  String get incomePlanName => 'Job/project name';

  @override
  String get incomePlanNameHint => 'e.g. Coffee shop website';

  @override
  String get incomePayer => 'Payer (client)';

  @override
  String get incomePlanTotal => 'Agreed total (leave empty if open-ended)';

  @override
  String get incomeDefaultWallet => 'Default receiving wallet';

  @override
  String get incomeStart => 'Start date';

  @override
  String get incomeDue => 'Due date';

  @override
  String get incomeWithholding => 'Payer withholds 10% tax';

  @override
  String get incomeWithholdingSub =>
      'Casual income (no or under-3-month labour contract): the app computes the withheld tax when you record a payment.';

  @override
  String get incomeInstallments => 'Planned installments';

  @override
  String get incomeInstallmentsHelp => 'Optional. e.g. 30% deposit, 40% draft, 30% on delivery.';

  @override
  String incomeInstallmentLabel(int n) {
    return 'Installment $n';
  }

  @override
  String get incomeInstallmentHint => 'Deposit, delivery...';

  @override
  String get incomeAddInstallment => 'Add installment';

  @override
  String get incomeReceive => 'Record a payment';

  @override
  String get incomeGrossAmount => 'Contract amount (before tax)';

  @override
  String incomeWithholdHint(String threshold) {
    return 'Leave empty: the app computes 10% if the payment is $threshold or more.';
  }

  @override
  String incomeNetPreview(String amount) {
    return 'Net to wallet: $amount';
  }

  @override
  String incomeNoWalletForCurrency(String currency) {
    return 'You need a $currency wallet to record payments.';
  }

  @override
  String incomePlanDeleteConfirm(String name) {
    return 'Delete \"$name\"? Recorded payments are kept.';
  }

  @override
  String get incomeReceiptsTitle => 'Payments received';

  @override
  String get incomePlanField => 'Income plan';

  @override
  String get txnTaxWithheld => 'Income tax withheld';

  @override
  String get txnTaxWithheldHelp =>
      'Amount is what you actually RECEIVED. Enter the tax the payer withheld so gross income and tax settlement are right.';

  @override
  String get taxTitle => 'Personal income tax';

  @override
  String get taxDisclaimer =>
      'Estimate for reference under Vietnamese rules, not tax advice. Check the official texts and the tax office before filing.';

  @override
  String get taxProfile => 'Tax profile';

  @override
  String get taxDependents => 'Dependents';

  @override
  String taxDependentsN(int count) {
    return '$count dependents';
  }

  @override
  String get taxLess => 'Less';

  @override
  String get taxMore => 'More';

  @override
  String get taxInsurance => 'Mandatory insurance per month';

  @override
  String get taxInsuranceHelp =>
      'Leave empty: estimate 10.5% of salary (social 8%, health 1.5%, unemployment 1%) within the cap.';

  @override
  String taxInsuranceN(String amount) {
    return 'insurance $amount/month';
  }

  @override
  String get taxResident => 'Tax resident';

  @override
  String get taxNonResident => 'Non-resident';

  @override
  String get taxResidentSub =>
      'In Vietnam 183+ days a year or with a permanent residence. Non-residents: flat 20% on salary, no deductions.';

  @override
  String get taxBusiness => 'Run a business (household or individual)';

  @override
  String get taxBusinessSub =>
      'Enables quarterly filing reminders and a warning when yearly revenue exceeds the tax-free threshold.';

  @override
  String taxUnclassified(int count) {
    return '$count income categories have no tax type: their income is left out of the estimate.';
  }

  @override
  String get taxStandardCategories => 'Add standard income categories (with tax types)';

  @override
  String taxStandardDone(int count) {
    return 'Added/updated $count categories';
  }

  @override
  String taxEstimateTitle(int year) {
    return '$year settlement estimate';
  }

  @override
  String get taxSalaryIncome => 'Salary and wages';

  @override
  String get taxCasualIncome => 'Casual and freelance income';

  @override
  String get taxBusinessRevenue => 'Business revenue (taxed separately)';

  @override
  String get taxInvestmentIncome => 'Investment income (taxed separately)';

  @override
  String get taxExemptIncome => 'Tax-exempt income';

  @override
  String get taxUnclassifiedIncome => 'Unclassified income';

  @override
  String get taxInsuranceYear => 'Mandatory insurance';

  @override
  String get taxDeductionYear => 'Family deductions (12 months)';

  @override
  String get taxTaxable => 'Taxable income';

  @override
  String get taxDue => 'Tax due for the year';

  @override
  String get taxWithheld => 'Already withheld';

  @override
  String get taxPayMore => 'Estimated amount to pay';

  @override
  String get taxRefund => 'Estimated refund';

  @override
  String taxSettlementNote(String date) {
    return 'Self-settlement deadline $date. File at thuedientu.gdt.gov.vn or the eTax Mobile app.';
  }

  @override
  String taxBusinessOver(String amount) {
    return 'Business revenue exceeds $amount/year: you may need to file and pay tax.';
  }

  @override
  String get taxCalcTitle => 'Gross / net salary calculator';

  @override
  String get taxFromGross => 'From gross';

  @override
  String get taxFromNet => 'From net';

  @override
  String get taxGrossSalary => 'Gross salary';

  @override
  String get taxNetSalary => 'Net salary (take-home)';

  @override
  String get taxInsuranceMonth => 'Mandatory insurance';

  @override
  String get taxDeductionMonth => 'Family deductions';

  @override
  String get taxMonthTax => 'Monthly income tax';

  @override
  String get taxDeadlines => 'Upcoming deadlines';

  @override
  String taxDeadlineSelf(int year) {
    return 'Self-settlement deadline for $year';
  }

  @override
  String taxDeadlineAuthorize(int year) {
    return 'Give your employer the $year settlement authorization (if delegating)';
  }

  @override
  String get taxDeadlineBusiness => 'Quarterly business tax filing';

  @override
  String taxDeadlineIn(String date, int days) {
    return '$date ($days days left)';
  }

  @override
  String taxRulesTitle(int year) {
    return 'Rules in force from $year';
  }

  @override
  String get taxPersonalDeduction => 'Personal deduction / month';

  @override
  String get taxDependentDeduction => 'Per dependent / month';

  @override
  String taxBracketUpTo(int n, String amount) {
    return 'Bracket $n: up to $amount/month';
  }

  @override
  String taxBracketOver(int n, String amount) {
    return 'Bracket $n: over $amount/month';
  }

  @override
  String taxCasualRule(String amount) {
    return 'Casual-income withholding from $amount per payment';
  }

  @override
  String get taxBusinessThreshold => 'Tax-free business revenue / year';

  @override
  String taxSource(String source, String date) {
    return 'Source: $source. Updated $date.';
  }

  @override
  String get taxCategoriesTitle => 'Tax type of income categories';

  @override
  String get taxInherit => 'Same as parent';

  @override
  String get taxTypeUnknown => 'Not set';

  @override
  String get taxTypeUnknownHelp => 'Left out of the estimate';

  @override
  String get taxTypeSalary => 'Salary';

  @override
  String get taxTypeSalaryHelp => 'Labour contract of 3+ months, taxable bonuses and allowances';

  @override
  String get taxTypeCasual => 'Casual / freelance';

  @override
  String get taxTypeCasualHelp => 'No contract or under 3 months; payer withholds 10%';

  @override
  String get taxTypeBusiness => 'Business / rental';

  @override
  String get taxTypeBusinessHelp => 'Taxed on revenue, with a tax-free threshold';

  @override
  String get taxTypeInvestment => 'Investment';

  @override
  String get taxTypeInvestmentHelp => 'Dividends, bond interest... separate rates';

  @override
  String get taxTypeExempt => 'Tax-exempt';

  @override
  String get taxTypeExemptHelp => 'Bank deposit interest, family gifts, refunds';

  @override
  String get qrTitle => 'Payment QR';

  @override
  String get qrTabPay => 'Scan to pay';

  @override
  String get qrTabReceive => 'Receive';

  @override
  String get qrPayIntro =>
      'Scan the payee\'s VietQR/EMVCo code to check account, amount and message, then open your bank app and record the expense. Codes are read on this device.';

  @override
  String get qrNoCamera => 'Camera scanning isn\'t available here. Paste the QR content (starts with 000201) below.';

  @override
  String get qrCameraError => 'Can\'t open the camera. Allow camera access or paste the code content.';

  @override
  String get qrPasteLabel => 'QR content';

  @override
  String get qrPaste => 'Paste';

  @override
  String get qrRead => 'Read code';

  @override
  String get qrErrCrc => 'This QR is corrupted or was altered (CRC mismatch). Don\'t pay with it.';

  @override
  String get qrErrNotPayment => 'This isn\'t an EMVCo/VietQR payment code.';

  @override
  String get qrErrInvalid => 'The QR code is malformed.';

  @override
  String get qrNoAmount => 'No amount in the code: enter it in your bank app.';

  @override
  String get qrPayee => 'Payee';

  @override
  String get qrBank => 'Bank';

  @override
  String get qrAccount => 'Account number';

  @override
  String get qrMessage => 'Transfer message';

  @override
  String get qrCity => 'Location';

  @override
  String get qrIsCard => 'Identifier is a card number.';

  @override
  String get qrOpenBank => 'Open bank app (prefilled)';

  @override
  String get qrOpenBankNote =>
      'Or open your bank app\'s QR scanner and scan this code again; always check the payee name before confirming.';

  @override
  String get qrForeignNote =>
      'Foreign code: pay with a wallet or bank app that supports it, then record the expense here.';

  @override
  String get qrConsentTitle => 'Open bank app via VietQR.io';

  @override
  String get qrConsentBody =>
      'To prefill the transfer, the app sends the PAYEE\'s account, amount and message to dl.vietqr.io (a third-party service) to hand over to the bank app you choose. None of your ledger data is sent. Continue?';

  @override
  String get qrConsentOk => 'Agree and open';

  @override
  String get qrChooseBankApp => 'Choose your bank app';

  @override
  String get qrLastUsed => 'Used last time';

  @override
  String get qrOpenFailed => 'Couldn\'t open the bank app on this device.';

  @override
  String get qrRecordExpense => 'Record this expense';

  @override
  String get qrScanAgain => 'Scan another code';

  @override
  String get qrReceiveIntro =>
      'Create a VietQR code for clients to pay you. It\'s generated on this device; the account number isn\'t stored or sent.';

  @override
  String get qrAmountOptional => 'Amount (empty: payer enters it)';

  @override
  String get qrMessageHelp => 'Up to 25 characters; accents are removed for bank compatibility.';

  @override
  String get qrCreate => 'Create code';

  @override
  String get qrErrAccount => 'Account number: letters and digits only, up to 19.';

  @override
  String get qrImageLabel => 'Payment request QR code';

  @override
  String get qrCopyContent => 'Copy code content';

  @override
  String get importTemplateHelp =>
      'Moving from another app: download the template, paste your old data into its columns (Date, Type, Amount, Wallet...), then pick the file. Missing wallets and categories are created automatically.';

  @override
  String get importTemplateCsv => 'CSV template';

  @override
  String get importTemplateXlsx => 'Excel template';

  @override
  String get importTemplateSaved => 'Template saved';

  @override
  String get importTemplateDetected => 'Quly Thu Chi template detected';

  @override
  String importTemplateSummary(int rows, int wallets, int categories) {
    return '$rows transactions; $wallets new wallets and $categories new categories.';
  }

  @override
  String importTemplateNewWallets(String names) {
    return 'New wallets: $names';
  }

  @override
  String importTemplateDuplicates(int count) {
    return 'Skipping $count rows that duplicate existing transactions.';
  }

  @override
  String importTemplateSkipped(int count, String rows) {
    return 'Skipping $count rows with missing/invalid data (rows $rows).';
  }

  @override
  String importTemplateRun(int count) {
    return 'Import $count transactions';
  }

  @override
  String importTemplateDone(int count, int wallets, int categories) {
    return 'Imported $count transactions, created $wallets wallets and $categories categories.';
  }

  @override
  String get shareTitle => 'Shared wallet';

  @override
  String get shareMembersEntry => 'Sharing and members';

  @override
  String get shareBadge => 'Shared';

  @override
  String get shareIntro =>
      'Invite family members to record in this wallet together. The wallet key is handed over end-to-end encrypted: the server only sees ciphertext and cannot read amounts or notes.';

  @override
  String get shareStart => 'Share this wallet';

  @override
  String get shareNeedSignIn => 'Sign in and sync to use shared wallets.';

  @override
  String get shareGoSignIn => 'Go to Account and sync';

  @override
  String get shareNotLoaded => 'Could not load the member list.';

  @override
  String get shareRetry => 'Retry';

  @override
  String get shareMembers => 'Members';

  @override
  String get shareInvites => 'Open invitations';

  @override
  String get shareInvite => 'Invite a member';

  @override
  String get shareRoleOwner => 'Owner';

  @override
  String get shareRoleEditor => 'Editor';

  @override
  String get shareRoleViewer => 'Viewer';

  @override
  String get shareRoleEditorHint => 'Add, edit and delete transactions in the wallet';

  @override
  String get shareRoleViewerHint => 'View only';

  @override
  String shareYourRole(String role) {
    return 'Your role: $role';
  }

  @override
  String get shareYou => 'You';

  @override
  String shareSafetyCode(String code) {
    return 'Safety code: $code';
  }

  @override
  String shareMySafetyCode(String code) {
    return 'Your safety code: $code. Compare safety codes by phone or in person with people in this wallet.';
  }

  @override
  String shareChangeTo(String role) {
    return 'Change to $role';
  }

  @override
  String get shareRemove => 'Remove from wallet';

  @override
  String shareRemoveConfirm(String name) {
    return 'Remove $name? The wallet gets a new key and is re-encrypted; this person can no longer read new data.';
  }

  @override
  String get shareRemoved => 'Removed and the wallet key was rotated.';

  @override
  String get shareInviteWaiting => 'Waiting for the recipient';

  @override
  String shareInviteAccepted(String name) {
    return '$name accepted - finishing up';
  }

  @override
  String get shareInviteCancel => 'Cancel invitation';

  @override
  String get shareInviteRoleTitle => 'Invite as';

  @override
  String get shareInviteCreate => 'Create invitation';

  @override
  String get shareInviteCodeTitle => 'Send the invitation code';

  @override
  String get shareInviteCodeBody =>
      'Send this code or link privately, or let them scan the QR code. It works once within 7 days. Anyone with the code can accept, so do not post it publicly.';

  @override
  String get shareCopyCode => 'Copy code';

  @override
  String get shareCopyLink => 'Copy link';

  @override
  String get shareCopied => 'Copied.';

  @override
  String get shareLeave => 'Leave shared wallet';

  @override
  String shareLeaveConfirm(String name) {
    return 'Leave \"$name\"? The wallet\'s data will be removed from this device.';
  }

  @override
  String get shareLeft => 'You left the shared wallet.';

  @override
  String get shareReadOnlyNote => 'Shared wallet: only the owner can edit wallet details.';

  @override
  String shareBadInvites(int count) {
    return 'Cancelled $count invitation(s) because the proof did not match (someone may not have the real code).';
  }

  @override
  String get joinTitle => 'Join a shared wallet';

  @override
  String get joinCodeLabel => 'Invitation code or link';

  @override
  String get joinPreview => 'View invitation';

  @override
  String get joinInvalidCode => 'The invitation code is not valid.';

  @override
  String joinFrom(String name) {
    return 'Invitation from $name';
  }

  @override
  String joinRole(String role) {
    return 'Role: $role';
  }

  @override
  String get joinAccept => 'Join';

  @override
  String get joinSent => 'Invitation accepted. The wallet appears once the owner opens the app.';

  @override
  String get joinPending => 'Waiting for the owner';

  @override
  String get joinOwnerUnknown => 'the owner';

  @override
  String get joinAlreadyAccepted => 'You already accepted this invitation.';

  @override
  String get shareErrInviteGone => 'The invitation does not exist or has expired.';

  @override
  String get shareErrInviteTaken => 'Someone else already used this invitation. Ask the owner for a new code.';

  @override
  String get shareErrInviteOwn => 'This invitation is for your own wallet.';

  @override
  String get shareErrAlreadyMember => 'You are already in this wallet.';

  @override
  String get shareErrNoKeys => 'Sync once to upload your encryption keys first.';

  @override
  String get shareErrLimit => 'The limit of shared wallets or members was reached.';

  @override
  String get shareErrStale => 'The wallet just changed. Sync and try again.';

  @override
  String get shareErrMissingSecret =>
      'This device lacks a member\'s sharing secret. Sync, or try on the device that created the invitation.';

  @override
  String get shareErrForbidden => 'Only the owner can do this.';

  @override
  String get errReadOnly => 'You can only view this shared wallet.';

  @override
  String get errOwnerOnly => 'Only the owner can edit shared wallet details.';
}
