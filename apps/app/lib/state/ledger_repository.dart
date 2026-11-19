import 'package:flutter/foundation.dart' show immutable;
import 'package:qulythuchi_core/qulythuchi_core.dart';
import 'package:uuid/uuid.dart';

import '../data/record_store.dart';
import '../domain/default_categories.dart';
import '../domain/extra_models.dart';
import '../domain/txn_filter.dart';
import '../domain/vn_search.dart';
import '../security/vault.dart';

/// Ảnh chụp bất biến của dữ liệu đã giải mã, đưa cho giao diện.
@immutable
final class LedgerData {
  const LedgerData({
    this.wallets = const [],
    this.categories = const [],
    this.txns = const [],
    this.budgets = const [],
    this.recurrings = const [],
    this.debts = const [],
    this.goals = const [],
    this.events = const [],
    this.rates = const [],
    this.jarPlan,
    this.savedFilters = const [],
    this.incomePlans = const [],
    this.taxProfile = const TaxProfile(),
    this.skipped = 0,
  });

  final List<Wallet> wallets;
  final List<Category> categories;

  /// Mới nhất trước.
  final List<Txn> txns;
  final List<Budget> budgets;
  final List<Recurring> recurrings;
  final List<Debt> debts;
  final List<Goal> goals;
  final List<Event> events;

  /// Mới nhất trước (theo ngày).
  final List<FxRate> rates;

  /// null = chưa thiết lập (giao diện dùng mặc định 6 hũ).
  final JarPlan? jarPlan;
  final List<SavedFilter> savedFilters;

  /// Khoản thu nhiều đợt, đang thu trước rồi theo tên.
  final List<IncomePlan> incomePlans;
  final TaxProfile taxProfile;

  /// Số bản ghi không mở được (hỏng hoặc bị tráo) - chỉ đếm, không ghi nội dung ra log.
  final int skipped;

  Wallet? wallet(String? id) => wallets.where((w) => w.id == id).firstOrNull;
  Category? category(String? id) => categories.where((c) => c.id == id).firstOrNull;
  Txn? txn(String id) => txns.where((t) => t.id == id).firstOrNull;
  Budget? budget(String? id) => budgets.where((b) => b.id == id).firstOrNull;
  Recurring? recurring(String? id) => recurrings.where((r) => r.id == id).firstOrNull;
  Debt? debt(String? id) => debts.where((d) => d.id == id).firstOrNull;
  Goal? goal(String? id) => goals.where((g) => g.id == id).firstOrNull;
  Event? event(String? id) => events.where((e) => e.id == id).firstOrNull;
  IncomePlan? incomePlan(String? id) => incomePlans.where((p) => p.id == id).firstOrNull;

  /// Giao dịch đối ứng của một vế chuyển ví.
  Txn? counterpart(Txn t) =>
      t.transferId == null ? null : txns.where((o) => o.transferId == t.transferId && o.id != t.id).firstOrNull;

  Money balance(Wallet w) => Ledger.walletBalance(w, txns);

  /// Giao dịch tự sinh đang chờ người dùng xác nhận.
  List<Txn> get pendingTxns => [
    for (final t in txns)
      if (t.pending) t,
  ];

  /// Tổng số dư theo từng tiền tệ (ví lưu trữ hoặc "không tính vào tổng" bị bỏ qua).
  Map<Currency, Money> totals() {
    final out = <Currency, Money>{};
    for (final w in wallets) {
      if (w.archived || w.excludeFromTotal) continue;
      out[w.currency] = (out[w.currency] ?? Money.zero(w.currency)) + balance(w);
    }
    return out;
  }

  /// Tỉ giá mới nhất để đổi [from] sang [to] (thuận hoặc nghịch đảo không hỗ trợ - nhập theo chiều cần dùng).
  String? rate(Currency from, Currency to) {
    if (from == to) return '1';
    for (final r in rates) {
      if (r.from == from && r.to == to) return r.rate;
    }
    return null;
  }

  /// Tổng quy đổi về [base]. Tiền tệ chưa có tỉ giá nằm trong `missing` (không bị cộng lẫn).
  ({Money total, List<Currency> missing}) totalIn(Currency base) {
    var total = Money.zero(base);
    final missing = <Currency>[];
    totals().forEach((cur, m) {
      final r = rate(cur, base);
      if (r == null) {
        missing.add(cur);
      } else {
        total += m.convert(base, r);
      }
    });
    return (total: total, missing: missing);
  }

  /// Tổng chi của các giao dịch gắn sự kiện, theo tiền tệ.
  Map<Currency, Money> eventSpending(String eventId) {
    final out = <Currency, Money>{};
    for (final t in txns) {
      if (t.eventId != eventId || t.pending) continue;
      final cur = wallet(t.walletId)?.currency;
      if (cur == null) continue;
      final delta = switch (t.kind) {
        TxnKind.expense => t.amount,
        TxnKind.income => -t.amount,
        _ => 0,
      };
      out[cur] = (out[cur] ?? Money.zero(cur)) + Money(delta, cur);
    }
    return out;
  }
}

/// Lỗi nghiệp vụ hiển thị được cho người dùng (mã ổn định để dịch).
final class LedgerException implements Exception {
  const LedgerException(this.code);
  final String code;
  @override
  String toString() => 'LedgerException($code)';
}

/// Đọc/ghi bản ghi: mọi thứ ra khỏi lớp này xuống SQLite đều đã niêm phong bằng khóa ví/khóa tài khoản.
final class LedgerRepository {
  LedgerRepository(this._store, this._vault) : _clock = HlcClock(_vault.nodeId);

  final RecordStore _store;
  final Vault _vault;
  final HlcClock _clock;
  final Map<String, SyncRecord> _records = {};
  static const _uuid = Uuid();

  String newId() => _uuid.v4();

  /// Giải mã toàn bộ bản ghi (gọi ngay sau khi mở khóa).
  LedgerData load() {
    _records.clear();
    var skipped = 0;
    for (final row in _store.allRecords()) {
      try {
        if (row.walletId != null && !_vault.hasWalletKey(row.walletId!)) {
          skipped++;
          continue;
        }
        final r = _vault.cipher.open(
          row.sealed,
          _vault.keyFor(row.walletId),
          type: row.type,
          recordId: row.id,
          walletId: row.walletId,
        );
        _records[r.id] = r;
        final h = r.maxHlc;
        if (h != null) {
          try {
            _clock.receive(h);
          } on ClockDriftException {
            // Giờ máy đang lùi so với dữ liệu: vẫn đọc được, HLC tự tăng bộ đếm.
          }
        }
      } on EnvelopeException {
        skipped++;
      }
    }
    return snapshot(skipped: skipped);
  }

  LedgerData snapshot({int skipped = 0}) {
    final wallets = <Wallet>[];
    final categories = <Category>[];
    final txns = <Txn>[];
    final budgets = <Budget>[];
    final recurrings = <Recurring>[];
    final debts = <Debt>[];
    final goals = <Goal>[];
    final events = <Event>[];
    final rates = <FxRate>[];
    final savedFilters = <SavedFilter>[];
    final incomePlans = <IncomePlan>[];
    var taxProfile = const TaxProfile();
    SyncRecord? jarRecord;
    for (final r in _records.values) {
      if (r.isDeleted) continue;
      try {
        switch (r.type) {
          case RecordTypes.wallet:
            wallets.add(Wallet.fromRecord(r));
          case RecordTypes.category:
            categories.add(Category.fromRecord(r));
          case RecordTypes.transaction:
            txns.add(Txn.fromRecord(r));
          case RecordTypes.budget:
            budgets.add(Budget.fromRecord(r));
          case RecordTypes.recurring:
            recurrings.add(Recurring.fromRecord(r));
          case RecordTypes.debt:
            debts.add(Debt.fromRecord(r));
          case RecordTypes.goal:
            goals.add(Goal.fromRecord(r));
          case RecordTypes.event:
            events.add(Event.fromRecord(r));
          case AppRecordTypes.fxRate:
            final rate = FxRate.fromRecord(r);
            if (rate != null) rates.add(rate);
          case SavedFilter.recordType:
            final f = SavedFilter.fromRecord(r);
            if (f != null) savedFilters.add(f);
          case RecordTypes.incomePlan:
            incomePlans.add(IncomePlan.fromRecord(r));
          case RecordTypes.taxProfile:
            taxProfile = TaxProfile.fromRecord(r);
          case RecordTypes.jarPlan:
            // Nhiều thiết bị cùng tạo kế hoạch: bản ghi có HLC mới nhất thắng.
            if (jarRecord == null || (r.maxHlc != null && jarRecord.maxHlc != null && r.maxHlc! > jarRecord.maxHlc!)) {
              jarRecord = r;
            }
        }
      } on Object {
        // Bản ghi giải mã được nhưng sai cấu trúc (phiên bản khác/hỏng): bỏ qua, không lộ nội dung.
        skipped++;
      }
    }
    wallets.sort((a, b) {
      final c = a.sortOrder.compareTo(b.sortOrder);
      return c != 0 ? c : _byName(a.name, b.name);
    });
    categories.sort((a, b) => _byName(a.name, b.name));
    budgets.sort((a, b) => _byName(a.name, b.name));
    recurrings.sort((a, b) => _byName(a.name, b.name));
    goals.sort((a, b) => _byName(a.name, b.name));
    debts.sort((a, b) => _byName(a.counterparty, b.counterparty));
    events.sort((a, b) => b.start.compareTo(a.start));
    rates.sort((a, b) => b.date.compareTo(a.date));
    txns.sort((a, b) {
      final c = b.date.compareTo(a.date);
      if (c != 0) return c;
      // Cùng ngày: bản ghi mới tạo trước (theo HLC trường đầu tiên).
      final ha = _records[a.id]?.fields['kind']?.hlc;
      final hb = _records[b.id]?.fields['kind']?.hlc;
      if (ha == null || hb == null) return 0;
      return hb.compareTo(ha);
    });
    return LedgerData(
      wallets: wallets,
      categories: categories,
      txns: txns,
      budgets: budgets,
      recurrings: recurrings,
      debts: debts,
      goals: goals,
      events: events,
      rates: rates,
      jarPlan: jarRecord == null ? null : JarPlanCodec.fromRecord(jarRecord),
      savedFilters: savedFilters..sort((a, b) => _byName(a.name, b.name)),
      incomePlans: incomePlans
        ..sort((a, b) {
          final c = a.status.index.compareTo(b.status.index);
          return c != 0 ? c : _byName(a.name, b.name);
        }),
      taxProfile: taxProfile,
      skipped: skipped,
    );
  }

  /// Sắp xếp tên kiểu tiếng Việt: "Ăn uống", "Đi lại" đứng đúng chỗ thay vì cuối danh sách.
  static int _byName(String a, String b) {
    final c = normalizeVi(a).compareTo(normalizeVi(b));
    return c != 0 ? c : a.compareTo(b);
  }

  SyncRecord _base(String id, String type, String? walletId) =>
      _records[id] ?? SyncRecord(id: id, type: type, walletId: walletId);

  /// Chỉ ghi các trường thật sự thay đổi (giữ HLC cũ cho trường không đổi ⇒ hợp nhất theo trường đúng ý).
  SyncRecord _apply(SyncRecord base, Map<String, Object?> values) {
    final changed = <String, Object?>{
      for (final e in values.entries)
        if (!base.fields.containsKey(e.key) || !_same(base[e.key], e.value)) e.key: e.value,
    };
    return changed.isEmpty ? base : base.setAll(changed, _clock);
  }

  static bool _same(Object? a, Object? b) => canonicalJson(a) == canonicalJson(b);

  void _persist(List<SyncRecord> records) {
    final rows = [
      for (final r in records)
        SealedRow(
          id: r.id,
          type: r.type,
          walletId: r.walletId,
          sealed: _vault.cipher.seal(r, _vault.keyFor(r.walletId)),
        ),
    ];
    _store.putRecords(rows);
    for (final r in records) {
      _records[r.id] = r;
    }
  }

  // ------------------------------------------------------------------ Ví

  Wallet saveWallet(Wallet w) {
    if (w.name.trim().isEmpty) throw const LedgerException('nameRequired');
    final existing = _records[w.id];
    if (existing == null) {
      _vault.createWalletKey(w.id);
    } else if (Wallet.fromRecord(existing).currency != w.currency && _hasTxns(w.id)) {
      throw const LedgerException('currencyLocked');
    }
    _persist([_apply(_base(w.id, RecordTypes.wallet, w.id), w.toValues())]);
    return w;
  }

  bool _hasTxns(String walletId) =>
      _records.values.any((r) => !r.isDeleted && r.type == RecordTypes.transaction && (r.walletId == walletId));

  /// Xóa ví chỉ khi không còn giao dịch; còn giao dịch thì nên lưu trữ.
  void deleteWallet(String id) {
    if (_hasTxns(id)) throw const LedgerException('walletHasTxns');
    final r = _records[id];
    if (r == null) return;
    _persist([r.markDeleted(_clock)]);
  }

  // ------------------------------------------------------------------ Danh mục

  Category saveCategory(Category c) {
    if (c.name.trim().isEmpty) throw const LedgerException('nameRequired');
    if (c.parentId != null) {
      final parent = _records[c.parentId];
      if (parent == null || parent.isDeleted) throw const LedgerException('parentMissing');
      final p = Category.fromRecord(parent);
      // Chỉ 2 tầng; cha phải cùng loại thu/chi.
      if (p.parentId != null || p.id == c.id) throw const LedgerException('twoLevelsOnly');
      if (p.kind != c.kind) throw const LedgerException('kindMismatch');
      final hasChildren = _records.values.any(
        (r) => !r.isDeleted && r.type == RecordTypes.category && r['parentId'] == c.id,
      );
      if (hasChildren) throw const LedgerException('twoLevelsOnly');
    }
    _persist([_apply(_base(c.id, RecordTypes.category, null), c.toValues())]);
    return c;
  }

  /// Xóa danh mục: giao dịch cũ giữ nguyên id (hiển thị "Chưa phân loại"); danh mục con bị xóa theo.
  void deleteCategory(String id) {
    final targets = [
      for (final r in _records.values)
        if (!r.isDeleted && r.type == RecordTypes.category && (r.id == id || r['parentId'] == id))
          r.markDeleted(_clock),
    ];
    if (targets.isNotEmpty) _persist(targets);
  }

  /// Tạo bộ danh mục mặc định nếu chưa có danh mục nào.
  void seedDefaultCategories(DefaultCategoryLocale locale) {
    if (_records.values.any((r) => r.type == RecordTypes.category)) return;
    final out = <SyncRecord>[];
    for (final group in defaultCategories) {
      final parentId = newId();
      out.add(
        _apply(
          SyncRecord(id: parentId, type: RecordTypes.category, walletId: null),
          Category(
            id: parentId,
            name: group.name(locale),
            kind: group.kind,
            icon: group.icon,
            taxType: group.taxType,
          ).toValues(),
        ),
      );
      for (final child in group.children) {
        final id = newId();
        out.add(
          _apply(
            SyncRecord(id: id, type: RecordTypes.category, walletId: null),
            Category(
              id: id,
              name: child.name(locale),
              kind: group.kind,
              parentId: parentId,
              icon: child.icon,
              taxType: child.taxType,
            ).toValues(),
          ),
        );
      }
    }
    _persist(out);
  }

  /// Bổ sung bộ danh mục thu chuẩn cho tài khoản cũ: thêm mục còn thiếu (so tên không dấu, cả hai ngôn ngữ) và gán
  /// loại thuế cho danh mục thu trùng tên chưa phân loại. Trả số danh mục được thêm hoặc cập nhật.
  int ensureStandardIncomeCategories(DefaultCategoryLocale locale) {
    final existing = <String, Category>{};
    for (final r in _records.values) {
      if (r.isDeleted || r.type != RecordTypes.category) continue;
      final c = Category.fromRecord(r);
      if (c.kind == CategoryKind.income) existing[normalizeVi(c.name)] = c;
    }
    Category? find(DefaultCategory d) => existing[normalizeVi(d.vi)] ?? existing[normalizeVi(d.en)];
    final out = <SyncRecord>[];
    void upsert(DefaultCategory d, String? parentId, void Function(String id) withId) {
      final found = find(d);
      if (found != null) {
        if (found.taxType == IncomeTaxType.unknown && d.taxType != IncomeTaxType.unknown) {
          out.add(_apply(_records[found.id]!, {'taxType': d.taxType.name}));
        }
        withId(found.id);
        return;
      }
      final id = newId();
      out.add(
        _apply(
          SyncRecord(id: id, type: RecordTypes.category, walletId: null),
          Category(
            id: id,
            name: d.name(locale),
            kind: CategoryKind.income,
            parentId: parentId,
            icon: d.icon,
            taxType: d.taxType,
          ).toValues(),
        ),
      );
      withId(id);
    }

    for (final group in standardIncomeCategories) {
      upsert(group, null, (pid) {
        for (final child in group.children) {
          upsert(child, pid, (_) {});
        }
      });
    }
    _persist(out);
    return out.length;
  }

  // ------------------------------------------------------------------ Giao dịch

  void _checkTxn(Txn t) {
    final w = _records[t.walletId];
    if (w == null || w.isDeleted) throw const LedgerException('walletMissing');
    if (t.kind != TxnKind.adjustment && t.amount <= 0) throw const LedgerException('amountPositive');
    if (t.fee < 0) throw const LedgerException('amountPositive');
    if (t.taxWithheld < 0 || (t.taxWithheld > 0 && t.kind != TxnKind.income)) {
      throw const LedgerException('amountPositive');
    }
    if (t.incomePlanId != null && t.kind != TxnKind.income) throw const LedgerException('kindMismatch');
    if (t.categoryId != null) {
      final c = _records[t.categoryId];
      if (c != null && !c.isDeleted) {
        final kind = Category.fromRecord(c).kind;
        final ok = switch (t.kind) {
          TxnKind.expense => kind == CategoryKind.expense,
          TxnKind.income => kind == CategoryKind.income,
          _ => true,
        };
        if (!ok) throw const LedgerException('kindMismatch');
      }
    }
  }

  /// Lưu giao dịch thu/chi/điều chỉnh. Không dùng cho chuyển ví (xem [saveTransfer]).
  Txn saveTxn(Txn t) {
    if (t.kind == TxnKind.transferIn || t.kind == TxnKind.transferOut) throw ArgumentError('Dùng saveTransfer');
    _checkTxn(t);
    final old = _records[t.id];
    if (old != null && old.walletId != t.walletId) {
      // Đổi ví = bản ghi thuộc ví khác (khóa khác): xóa bản cũ, tạo bản mới với id mới.
      final moved = t._withId(newId());
      _persist([
        old.markDeleted(_clock),
        _apply(SyncRecord(id: moved.id, type: RecordTypes.transaction, walletId: t.walletId), moved.toValues()),
      ]);
      return moved;
    }
    _persist([_apply(_base(t.id, RecordTypes.transaction, t.walletId), t.toValues())]);
    return t;
  }

  /// Nhập hàng loạt (CSV): kiểm từng giao dịch rồi ghi tất cả trong MỘT lần ghi. Chỉ nhận thu/chi.
  int importTxns(List<Txn> txns) {
    for (final t in txns) {
      if (t.kind != TxnKind.income && t.kind != TxnKind.expense) throw ArgumentError('Chỉ nhập thu/chi');
      _checkTxn(t);
    }
    _persist([for (final t in txns) _apply(_base(t.id, RecordTypes.transaction, t.walletId), t.toValues())]);
    return txns.length;
  }

  /// Lưu chuyển ví: HAI bản ghi cùng `transferId`, ghi trong một giao tác.
  /// [received] khác [amount] khi hai ví khác tiền tệ (P2: người dùng tự nhập số tiền nhận).
  (Txn, Txn) saveTransfer({
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
  }) {
    if (fromWalletId == toWalletId) throw const LedgerException('sameWallet');
    final from = _records[fromWalletId];
    final to = _records[toWalletId];
    if (from == null || to == null || from.isDeleted || to.isDeleted) throw const LedgerException('walletMissing');
    final sameCurrency = Wallet.fromRecord(from).currency == Wallet.fromRecord(to).currency;
    final inAmount = sameCurrency ? amount : (received ?? (throw const LedgerException('receivedRequired')));
    if (amount <= 0 || inAmount <= 0 || fee < 0) throw const LedgerException('amountPositive');

    final tid = transferId ?? newId();
    final old = _records.values.where(
      (r) => !r.isDeleted && r.type == RecordTypes.transaction && r['transferId'] == tid,
    );
    final out = <SyncRecord>[];
    String idFor(TxnKind kind, String walletId) {
      for (final r in old) {
        if (r['kind'] == kind.name && r.walletId == walletId) return r.id;
      }
      return newId();
    }

    final outId = idFor(TxnKind.transferOut, fromWalletId);
    final inId = idFor(TxnKind.transferIn, toWalletId);
    // Vế cũ ở ví khác (người dùng đổi ví) ⇒ đánh dấu xóa.
    for (final r in old) {
      if (r.id != outId && r.id != inId) out.add(r.markDeleted(_clock));
    }
    final tOut = Txn(
      id: outId,
      walletId: fromWalletId,
      kind: TxnKind.transferOut,
      amount: amount,
      fee: fee,
      date: date,
      note: note,
      transferId: tid,
      counterWalletId: toWalletId,
      eventId: eventId,
    );
    final tIn = Txn(
      id: inId,
      walletId: toWalletId,
      kind: TxnKind.transferIn,
      amount: inAmount,
      date: date,
      note: note,
      transferId: tid,
      counterWalletId: fromWalletId,
      eventId: eventId,
      goalId: goalId,
    );
    out
      ..add(_apply(_base(outId, RecordTypes.transaction, fromWalletId), tOut.toValues()))
      ..add(_apply(_base(inId, RecordTypes.transaction, toWalletId), tIn.toValues()));
    _persist(out);
    return (tOut, tIn);
  }

  /// Xóa giao dịch; nếu là chuyển ví thì xóa cả hai vế.
  void deleteTxn(String id) {
    final r = _records[id];
    if (r == null || r.isDeleted) return;
    final tid = r['transferId'];
    final targets = [
      for (final o in _records.values)
        if (!o.isDeleted &&
            o.type == RecordTypes.transaction &&
            (o.id == id || (tid != null && o['transferId'] == tid)))
          o.markDeleted(_clock),
    ];
    _persist(targets);
  }

  // ------------------------------------------------------------------ Bản ghi cấp tài khoản dùng chung

  void _saveAccountRecord(String id, String type, Map<String, Object?> values) =>
      _persist([_apply(_base(id, type, null), values)]);

  void _deleteRecord(String id) {
    final r = _records[id];
    if (r == null || r.isDeleted) return;
    _persist([r.markDeleted(_clock)]);
  }

  // ------------------------------------------------------------------ Ngân sách, mục tiêu, sự kiện, 6 hũ, tỉ giá

  Budget saveBudget(Budget b) {
    if (b.name.trim().isEmpty) throw const LedgerException('nameRequired');
    if (b.amount <= 0) throw const LedgerException('amountPositive');
    if (b.alertAtBp < 1000 || b.alertAtBp > 10000) throw const LedgerException('alertRange');
    if (b.period == BudgetPeriod.custom &&
        (b.customStart == null || b.customEnd == null || b.customEnd! < b.customStart!)) {
      throw const LedgerException('dateRange');
    }
    _saveAccountRecord(b.id, RecordTypes.budget, b.toValues());
    return b;
  }

  void deleteBudget(String id) => _deleteRecord(id);

  Goal saveGoal(Goal g) {
    if (g.name.trim().isEmpty) throw const LedgerException('nameRequired');
    if (g.target <= 0 || g.startingAmount < 0) throw const LedgerException('amountPositive');
    _saveAccountRecord(g.id, RecordTypes.goal, g.toValues());
    return g;
  }

  void deleteGoal(String id) => _deleteRecord(id);

  Event saveEvent(Event e) {
    if (e.name.trim().isEmpty) throw const LedgerException('nameRequired');
    if (e.end != null && e.end! < e.start) throw const LedgerException('dateRange');
    if (e.budget != null && e.budget! <= 0) throw const LedgerException('amountPositive');
    _saveAccountRecord(e.id, RecordTypes.event, e.toValues());
    return e;
  }

  void deleteEvent(String id) => _deleteRecord(id);

  /// Lưu kế hoạch chia hũ (một bản ghi duy nhất cho tài khoản).
  JarPlan saveJarPlan(JarPlan plan) {
    final existing = _records.values
        .where((r) => !r.isDeleted && r.type == RecordTypes.jarPlan)
        .map((r) => r.id)
        .firstOrNull;
    _saveAccountRecord(existing ?? newId(), RecordTypes.jarPlan, JarPlanCodec.toValues(plan));
    return plan;
  }

  FxRate saveRate(FxRate r) {
    if (r.from == r.to) throw const LedgerException('sameCurrency');
    if (!FxRate.ratePattern.hasMatch(r.rate)) throw const LedgerException('rateInvalid');
    _saveAccountRecord(r.id, AppRecordTypes.fxRate, r.toValues());
    return r;
  }

  void deleteRate(String id) => _deleteRecord(id);

  SavedFilter saveFilter(SavedFilter f) {
    if (f.name.trim().isEmpty) throw const LedgerException('nameRequired');
    _saveAccountRecord(f.id, SavedFilter.recordType, f.toValues());
    return f;
  }

  void deleteFilter(String id) => _deleteRecord(id);

  // ------------------------------------------------------------------ Định kỳ / hóa đơn

  Recurring saveRecurring(Recurring r) {
    if (r.name.trim().isEmpty) throw const LedgerException('nameRequired');
    if (r.amount <= 0) throw const LedgerException('amountPositive');
    if (r.kind != TxnKind.expense && r.kind != TxnKind.income) throw const LedgerException('kindMismatch');
    if (r.remindDaysBefore < 0 || r.remindDaysBefore > 30) throw const LedgerException('remindRange');
    final w = _records[r.walletId];
    if (w == null || w.isDeleted) throw const LedgerException('walletMissing');
    final old = _records[r.id];
    if (old != null && old.walletId != r.walletId) {
      // Mẫu định kỳ mã hóa bằng khóa của ví ⇒ đổi ví = xóa bản cũ, tạo bản mới.
      final moved = Recurring(
        id: newId(),
        walletId: r.walletId,
        name: r.name,
        kind: r.kind,
        amount: r.amount,
        rule: r.rule,
        categoryId: r.categoryId,
        note: r.note,
        isBill: r.isBill,
        autoCreate: r.autoCreate,
        remindDaysBefore: r.remindDaysBefore,
        generatedThrough: r.generatedThrough,
        paused: r.paused,
      );
      _persist([
        old.markDeleted(_clock),
        _apply(SyncRecord(id: moved.id, type: RecordTypes.recurring, walletId: moved.walletId), moved.toValues()),
      ]);
      return moved;
    }
    _persist([_apply(_base(r.id, RecordTypes.recurring, r.walletId), r.toValues())]);
    return r;
  }

  void deleteRecurring(String id) => _deleteRecord(id);

  /// Giới hạn số giao dịch sinh mỗi mẫu trong một lần (chống mẫu "hằng ngày từ năm 2000" sinh hàng nghìn bản ghi).
  static const maxMaterializePerRun = 400;

  /// Sinh giao dịch đến hạn cho mọi mẫu định kỳ tới hết [today]; cập nhật `generatedThrough` CÙNG giao tác.
  /// Trả về số giao dịch đã sinh.
  int materializeRecurring(CivilDate today) {
    final out = <SyncRecord>[];
    var created = 0;
    for (final rec in _records.values.toList()) {
      if (rec.isDeleted || rec.type != RecordTypes.recurring) continue;
      final Recurring r;
      try {
        r = Recurring.fromRecord(rec);
      } on Object {
        continue;
      }
      final w = _records[r.walletId];
      if (w == null || w.isDeleted) continue;
      var txns = r.materialize(today, newId);
      if (txns.isEmpty) continue;
      if (txns.length > maxMaterializePerRun) txns = txns.sublist(txns.length - maxMaterializePerRun);
      for (final t in txns) {
        out.add(_apply(SyncRecord(id: t.id, type: RecordTypes.transaction, walletId: t.walletId), t.toValues()));
      }
      out.add(_apply(rec, {'generatedThrough': today.toString()}));
      created += txns.length;
    }
    if (out.isNotEmpty) _persist(out);
    return created;
  }

  /// Xác nhận giao dịch chờ (tự sinh) ⇒ bắt đầu tính vào số dư.
  void confirmPending(String txnId) {
    final r = _records[txnId];
    if (r == null || r.isDeleted || r['pending'] != true) return;
    _persist([
      _apply(r, {'pending': false}),
    ]);
  }

  /// Đánh dấu hóa đơn đã trả cho lần đến hạn [due]: tạo giao dịch thật và đẩy `generatedThrough` qua [due].
  Txn payBill(String recurringId, CivilDate due, {CivilDate? paidOn, int? amount}) {
    final rec = _records[recurringId];
    if (rec == null || rec.isDeleted) throw const LedgerException('notFound');
    final r = Recurring.fromRecord(rec);
    final t = Txn(
      id: newId(),
      walletId: r.walletId,
      kind: r.kind,
      amount: amount ?? r.amount,
      date: paidOn ?? due,
      categoryId: r.categoryId,
      note: r.note ?? r.name,
      recurringId: r.id,
      source: TxnSource.recurring,
    );
    _checkTxn(t);
    final through = r.generatedThrough;
    _persist([
      _apply(SyncRecord(id: t.id, type: RecordTypes.transaction, walletId: t.walletId), t.toValues()),
      if (through == null || through < due) _apply(rec, {'generatedThrough': due.toString()}),
    ]);
    return t;
  }

  // ------------------------------------------------------------------ Nợ / vay

  /// Lưu khoản nợ. Khi tạo mới và [recordDisbursement] = true: ghi luôn giao dịch giải ngân vào ví
  /// (cho vay = chi, đi vay = thu), không tính vào báo cáo thu chi.
  Debt saveDebt(Debt d, {bool recordDisbursement = false}) {
    if (d.counterparty.trim().isEmpty) throw const LedgerException('nameRequired');
    if (d.principal <= 0) throw const LedgerException('amountPositive');
    if (d.annualInterestBp < 0 || d.annualInterestBp > 100000) throw const LedgerException('rateInvalid');
    if (d.dueDate != null && d.dueDate! < d.startDate) throw const LedgerException('dateRange');
    final w = _records[d.walletId];
    if (w == null || w.isDeleted) throw const LedgerException('walletMissing');
    final old = _records[d.id];
    if (old != null && old.walletId != d.walletId) throw const LedgerException('walletLocked');
    final records = [_apply(_base(d.id, RecordTypes.debt, d.walletId), d.toValues())];
    if (old == null && recordDisbursement) {
      final t = Txn(
        id: newId(),
        walletId: d.walletId,
        kind: d.kind == DebtKind.lend ? TxnKind.expense : TxnKind.income,
        amount: d.principal,
        date: d.startDate,
        note: d.counterparty,
        debtId: d.id,
        excludeFromReports: true,
      );
      records.add(_apply(SyncRecord(id: t.id, type: RecordTypes.transaction, walletId: t.walletId), t.toValues()));
    }
    _persist(records);
    return d;
  }

  /// Ghi một lần trả/thu nợ (cho vay: thu về; đi vay: trả đi) vào ví của khoản nợ.
  Txn recordDebtPayment(String debtId, int amount, CivilDate date, {String? note}) {
    final rec = _records[debtId];
    if (rec == null || rec.isDeleted) throw const LedgerException('notFound');
    if (amount <= 0) throw const LedgerException('amountPositive');
    final d = Debt.fromRecord(rec);
    final t = Txn(
      id: newId(),
      walletId: d.walletId,
      kind: d.kind == DebtKind.lend ? TxnKind.income : TxnKind.expense,
      amount: amount,
      date: date,
      note: note ?? d.counterparty,
      debtId: d.id,
      excludeFromReports: true,
    );
    return saveTxn(t);
  }

  /// Xóa khoản nợ; giao dịch đã ghi giữ nguyên (số dư ví không đổi).
  void deleteDebt(String id) => _deleteRecord(id);

  // ------------------------------------------------------------------ Khoản thu nhiều đợt, hồ sơ thuế

  IncomePlan saveIncomePlan(IncomePlan p) {
    if (p.name.trim().isEmpty) throw const LedgerException('nameRequired');
    if (p.total < 0 || p.withholdingBp < 0 || p.withholdingBp > 5000) throw const LedgerException('amountPositive');
    if (p.installments.any((i) => i.amount <= 0)) throw const LedgerException('amountPositive');
    if (p.startDate != null && p.dueDate != null && p.dueDate! < p.startDate!) {
      throw const LedgerException('dateRange');
    }
    _saveAccountRecord(p.id, RecordTypes.incomePlan, p.toValues());
    return p;
  }

  /// Xóa khoản thu; các lần nhận tiền đã ghi giữ nguyên (chỉ mất liên kết).
  void deleteIncomePlan(String id) => _deleteRecord(id);

  /// Ghi một lần nhận tiền của khoản thu: [net] thực nhận, [withheld] thuế bên trả khấu trừ.
  Txn recordIncomeReceipt(
    String planId, {
    required String walletId,
    required int net,
    int withheld = 0,
    required CivilDate date,
    String? note,
  }) {
    final r = _records[planId];
    if (r == null || r.isDeleted) throw const LedgerException('notFound');
    final p = IncomePlan.fromRecord(r);
    final t = Txn(
      id: newId(),
      walletId: walletId,
      kind: TxnKind.income,
      amount: net,
      date: date,
      categoryId: p.categoryId,
      payee: p.payer,
      note: note ?? p.name,
      incomePlanId: p.id,
      taxWithheld: withheld,
    );
    return saveTxn(t);
  }

  TaxProfile saveTaxProfile(TaxProfile p) {
    if (p.dependents < 0 || p.dependents > 50 || (p.monthlyInsurance ?? 0) < 0 || p.monthlyCharity < 0) {
      throw const LedgerException('amountPositive');
    }
    _saveAccountRecord(TaxProfile.recordId, RecordTypes.taxProfile, p.toValues());
    return p;
  }
}

extension on Txn {
  /// Bản sao với id khác.
  Txn _withId(String newId) => Txn(
    id: newId,
    walletId: walletId,
    kind: kind,
    amount: amount,
    date: date,
    categoryId: categoryId,
    note: note,
    payee: payee,
    tags: tags,
    fee: fee,
    eventId: eventId,
    debtId: debtId,
    goalId: goalId,
    recurringId: recurringId,
    source: source,
    pending: pending,
    excludeFromReports: excludeFromReports,
    attachmentIds: attachmentIds,
    incomePlanId: incomePlanId,
    taxWithheld: taxWithheld,
  );
}
