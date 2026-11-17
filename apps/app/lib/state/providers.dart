import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';
import 'package:sodium/sodium_sumo.dart';

import '../data/key_storage.dart';
import '../data/record_store.dart';
import '../domain/default_categories.dart';
import '../security/vault.dart';
import 'ledger_repository.dart';

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

  void lock() {
    if (!_vault.hasAccount) return;
    _vault.lock();
    state = SessionStatus.locked;
  }

  Future<void> wipe() async {
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
    return ref.watch(repositoryProvider).load();
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

  void saveTransfer({
    String? transferId,
    required String fromWalletId,
    required String toWalletId,
    required int amount,
    int? received,
    int fee = 0,
    required CivilDate date,
    String? note,
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
    ),
  );
}
