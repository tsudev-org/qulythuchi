import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';
import 'package:sodium/sodium_sumo.dart';

import '../data/key_storage.dart';
import '../data/record_store.dart';
import '../domain/default_categories.dart';
import '../domain/extra_models.dart';
import '../domain/txn_filter.dart';
import '../security/vault.dart';
import '../services/reminders.dart';
import 'ledger_repository.dart';
import 'sync_controller.dart';

/// Dịch vụ dựng một lần lúc khởi động (`main.dart`), ghi đè vào [servicesProvider].
final class AppServices {
  AppServices({required this.sodium, required this.store, required this.keyStorage, required this.vault});
  final SodiumSumo sodium;
  final RecordStore store;
  final KeyStorage keyStorage;
  final Vault vault;
}

final servicesProvider = Provider<AppServices>((ref) => throw UnimplementedError('Ghi đè trong main()'));

enum SessionStatus {
  /// Chưa có tài khoản cục bộ.
  needsSetup,

  /// Đã tạo khóa, đang hiển thị/kiểm tra 24 từ và đặt PIN.
  onboarding,
  locked,
  unlocked,
}

final sessionProvider = NotifierProvider<SessionNotifier, SessionStatus>(SessionNotifier.new);

final class SessionNotifier extends Notifier<SessionStatus> {
  Vault get _vault => ref.read(servicesProvider).vault;

  @override
  SessionStatus build() {
    final vault = ref.watch(servicesProvider).vault;
    if (!vault.hasAccount) return SessionStatus.needsSetup;
    return vault.isUnlocked ? SessionStatus.unlocked : SessionStatus.locked;
  }

  /// Tạo tài khoản + bộ danh mục mặc định; trả 24 từ để hiển thị một lần.
  List<String> createAccount(String password, DefaultCategoryLocale locale) {
    final words = _vault.createAccount(password);
    final services = ref.read(servicesProvider);
    LedgerRepository(services.store, _vault).seedDefaultCategories(locale);
    state = SessionStatus.onboarding;
    return words;
  }

  void finishOnboarding() => state = SessionStatus.unlocked;

  /// Kho khóa vừa được mở ở nơi khác (nhận tài khoản từ máy chủ - `SyncController.adoptRemote`).
  void markUnlocked() {
    if (_vault.isUnlocked) state = SessionStatus.unlocked;
  }

  Future<void> unlockWithPassword(String password) async {
    await _vault.unlockWithPassword(password);
    state = SessionStatus.unlocked;
  }

  Future<void> unlockWithRecovery(List<String> words) async {
    await _vault.unlockWithRecovery(words);
    state = SessionStatus.unlocked;
  }

  Future<PinResult> unlockWithPin(String pin) async {
    final r = await _vault.unlockWithPin(pin);
    if (r is PinOk) state = SessionStatus.unlocked;
    return r;
  }

  Future<void> unlockWithBiometric() async {
    await _vault.unlockWithBiometric();
    state = SessionStatus.unlocked;
  }

  /// Khôi phục từ tệp sao lưu trên thiết bị mới (xem `Vault.restoreBackup`).
  Future<int> restoreBackup(Uint8List file, {String? password, List<String>? words}) async {
    final n = await _vault.restoreBackup(file, password: password, words: words);
    state = SessionStatus.unlocked;
    return n;
  }

  void lock() {
    if (!_vault.hasAccount) return;
    _vault.lock();
    state = SessionStatus.locked;
  }

  Future<void> wipe() async {
    // Đăng xuất đồng bộ trước (thu hồi thiết bị, xóa refresh token khỏi kho bí mật).
    if (ref.read(syncProvider).signedIn) await ref.read(syncProvider.notifier).signOut();
    await _vault.wipe();
    state = SessionStatus.needsSetup;
  }
}

/// Repository chỉ dùng được khi đã mở khóa.
final repositoryProvider = Provider<LedgerRepository>((ref) {
  ref.watch(sessionProvider);
  final s = ref.watch(servicesProvider);
  return LedgerRepository(s.store, s.vault);
});

final ledgerProvider = NotifierProvider<LedgerNotifier, LedgerData>(LedgerNotifier.new);

/// Dữ liệu đã giải mã trong bộ nhớ. Khóa app ⇒ trạng thái về rỗng (bản rõ bị bỏ).
final class LedgerNotifier extends Notifier<LedgerData> {
  LedgerRepository get _repo => ref.read(repositoryProvider);

  @override
  LedgerData build() {
    final status = ref.watch(sessionProvider);
    if (status != SessionStatus.unlocked && status != SessionStatus.onboarding) return const LedgerData();
    final repo = ref.watch(repositoryProvider);
    final loaded = repo.load();
    // Sinh giao dịch định kỳ đến hạn ngay khi mở khóa (chỉ lúc này mới có khóa để niêm phong).
    final created = repo.materializeRecurring(CivilDate.fromDateTime(DateTime.now()));
    return created == 0 ? loaded : repo.snapshot(skipped: loaded.skipped);
  }

  /// Nạp lại từ CSDL sau khi đồng bộ ghi bản ghi mới (gọi đồng bộ, không await).
  void reload() {
    if (ref.read(sessionProvider) != SessionStatus.unlocked) return;
    final loaded = _repo.load();
    state = loaded;
  }

  T _mutate<T>(T Function(LedgerRepository repo) action) {
    final result = action(_repo);
    state = _repo.snapshot();
    return result;
  }

  String newId() => _repo.newId();

  Wallet saveWallet(Wallet w) => _mutate((r) => r.saveWallet(w));
  void deleteWallet(String id) => _mutate((r) => r.deleteWallet(id));
  Category saveCategory(Category c) => _mutate((r) => r.saveCategory(c));
  void deleteCategory(String id) => _mutate((r) => r.deleteCategory(id));
  Txn saveTxn(Txn t) => _mutate((r) => r.saveTxn(t));
  void deleteTxn(String id) => _mutate((r) => r.deleteTxn(id));
  int importTxns(List<Txn> txns) => _mutate((r) => r.importTxns(txns));

  void saveTransfer({
    String? transferId,
    required String fromWalletId,
    required String toWalletId,
    required int amount,
    int? received,
    int fee = 0,
    required CivilDate date,
    String? note,
    String? goalId,
    String? eventId,
  }) => _mutate(
    (r) => r.saveTransfer(
      transferId: transferId,
      fromWalletId: fromWalletId,
      toWalletId: toWalletId,
      amount: amount,
      received: received,
      fee: fee,
      date: date,
      note: note,
      goalId: goalId,
      eventId: eventId,
    ),
  );

  Budget saveBudget(Budget b) => _mutate((r) => r.saveBudget(b));
  void deleteBudget(String id) => _mutate((r) => r.deleteBudget(id));
  Goal saveGoal(Goal g) => _mutate((r) => r.saveGoal(g));
  void deleteGoal(String id) => _mutate((r) => r.deleteGoal(id));
  Event saveEvent(Event e) => _mutate((r) => r.saveEvent(e));
  void deleteEvent(String id) => _mutate((r) => r.deleteEvent(id));
  JarPlan saveJarPlan(JarPlan p) => _mutate((r) => r.saveJarPlan(p));
  FxRate saveRate(FxRate x) => _mutate((r) => r.saveRate(x));
  void deleteRate(String id) => _mutate((r) => r.deleteRate(id));
  SavedFilter saveFilter(SavedFilter f) => _mutate((r) => r.saveFilter(f));
  void deleteFilter(String id) => _mutate((r) => r.deleteFilter(id));

  /// Lưu rồi sinh ngay các lần đã đến hạn (không đợi lần mở khóa sau).
  Recurring saveRecurring(Recurring x) => _mutate((r) {
    final saved = r.saveRecurring(x);
    r.materializeRecurring(CivilDate.fromDateTime(DateTime.now()));
    return saved;
  });
  void deleteRecurring(String id) => _mutate((r) => r.deleteRecurring(id));
  void confirmPending(String id) => _mutate((r) => r.confirmPending(id));
  Txn payBill(String recurringId, CivilDate due, {CivilDate? paidOn, int? amount}) =>
      _mutate((r) => r.payBill(recurringId, due, paidOn: paidOn, amount: amount));
  Debt saveDebt(Debt d, {bool recordDisbursement = false}) =>
      _mutate((r) => r.saveDebt(d, recordDisbursement: recordDisbursement));
  Txn recordDebtPayment(String debtId, int amount, CivilDate date, {String? note}) =>
      _mutate((r) => r.recordDebtPayment(debtId, amount, date, note: note));
  void deleteDebt(String id) => _mutate((r) => r.deleteDebt(id));
}

/// Bộ lên lịch thông báo (ghi đè trong test bằng [NoopReminderScheduler]).
final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => LocalNotificationScheduler.platformSupported ? LocalNotificationScheduler() : NoopReminderScheduler(),
);
