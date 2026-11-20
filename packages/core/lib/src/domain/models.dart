import 'package:meta/meta.dart';

import '../money/currency.dart';
import '../money/money.dart';
import '../sync/sync_record.dart';
import 'civil_date.dart';

/// Loại bản ghi đồng bộ (trường `type` của [SyncRecord]).
abstract final class RecordTypes {
  static const wallet = 'wallet';
  static const category = 'category';
  static const transaction = 'txn';
  static const budget = 'budget';
  static const recurring = 'recurring';
  static const debt = 'debt';
  static const goal = 'goal';
  static const event = 'event';
  static const jarPlan = 'jar_plan';

  /// Khoản thu dự kiến nhận nhiều đợt (dự án freelance, hợp đồng) - [IncomePlan].
  static const incomePlan = 'income_plan';

  /// Hồ sơ thuế thu nhập cá nhân (một bản ghi id [TaxProfile.recordId]).
  static const taxProfile = 'tax_profile';

  /// Ảnh đính kèm của giao dịch (ADR-0017): khóa tệp + siêu dữ liệu; nội dung ở tệp mã hóa riêng.
  static const attachment = 'attachment';
}

T _enum<T extends Enum>(List<T> values, Object? raw, T fallback) {
  for (final v in values) {
    if (v.name == raw) return v;
  }
  return fallback;
}

String _str(Map<String, Object?> v, String k, [String fallback = '']) => v[k] is String ? v[k]! as String : fallback;
String? _strOrNull(Map<String, Object?> v, String k) => v[k] is String ? v[k]! as String : null;
int _int(Map<String, Object?> v, String k, [int fallback = 0]) => v[k] is int ? v[k]! as int : fallback;
int? _intOrNull(Map<String, Object?> v, String k) => v[k] is int ? v[k]! as int : null;
bool _bool(Map<String, Object?> v, String k) => v[k] == true;
List<String> _strList(Map<String, Object?> v, String k) => v[k] is List
    ? [
        for (final e in v[k]! as List)
          if (e is String) e,
      ]
    : const [];
CivilDate? _date(Map<String, Object?> v, String k) {
  final s = _strOrNull(v, k);
  if (s == null) return null;
  try {
    return CivilDate.parse(s);
  } on FormatException {
    return null;
  }
}

Currency _currency(Map<String, Object?> v) {
  final code = _str(v, 'currency', 'VND');
  try {
    return Currency.of(code, minorDigits: _intOrNull(v, 'currencyDigits'));
  } on ArgumentError {
    return Currency.vnd;
  }
}

Map<String, Object?> _currencyFields(Currency c) => {
  'currency': c.code,
  if (!Currency.isIso(c.code)) 'currencyDigits': c.minorDigits,
};

// ---------------------------------------------------------------- Ví

enum WalletType { cash, bank, credit, ewallet, saving, investment, other }

@immutable
final class Wallet {
  const Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    this.openingBalance = 0,
    this.creditLimit,
    this.statementDay,
    this.dueDay,
    this.archived = false,
    this.excludeFromTotal = false,
    this.icon,
    this.color,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final WalletType type;
  final Currency currency;

  /// Số dư đầu kỳ (đơn vị nhỏ nhất).
  final int openingBalance;
  final int? creditLimit;
  final int? statementDay;
  final int? dueDay;
  final bool archived;
  final bool excludeFromTotal;
  final String? icon;
  final String? color;
  final int sortOrder;

  Money get opening => Money(openingBalance, currency);

  Map<String, Object?> toValues() => {
    'name': name,
    'type': type.name,
    ..._currencyFields(currency),
    'openingBalance': openingBalance,
    'creditLimit': creditLimit,
    'statementDay': statementDay,
    'dueDay': dueDay,
    'archived': archived,
    'excludeFromTotal': excludeFromTotal,
    'icon': icon,
    'color': color,
    'sortOrder': sortOrder,
  };

  static Wallet fromRecord(SyncRecord r) {
    final v = r.values;
    return Wallet(
      id: r.id,
      name: _str(v, 'name'),
      type: _enum(WalletType.values, v['type'], WalletType.other),
      currency: _currency(v),
      openingBalance: _int(v, 'openingBalance'),
      creditLimit: _intOrNull(v, 'creditLimit'),
      statementDay: _intOrNull(v, 'statementDay'),
      dueDay: _intOrNull(v, 'dueDay'),
      archived: _bool(v, 'archived'),
      excludeFromTotal: _bool(v, 'excludeFromTotal'),
      icon: _strOrNull(v, 'icon'),
      color: _strOrNull(v, 'color'),
      sortOrder: _int(v, 'sortOrder'),
    );
  }
}

// ---------------------------------------------------------------- Danh mục

enum CategoryKind { expense, income }

/// Phân loại thuế TNCN của danh mục THU (Việt Nam), để ước tính thuế và nhắc hạn.
enum IncomeTaxType {
  /// Chưa phân loại.
  unknown,

  /// Tiền lương, tiền công (có hợp đồng lao động từ 3 tháng).
  salary,

  /// Thu nhập vãng lai/freelance (không hợp đồng hoặc dưới 3 tháng) - bên trả khấu trừ 10% khi đạt ngưỡng.
  casual,

  /// Kinh doanh (hộ, cá nhân kinh doanh, bán hàng online).
  business,

  /// Đầu tư vốn (cổ tức, lãi trái phiếu...) - thuế suất riêng.
  investment,

  /// Không chịu/miễn thuế (lãi tiền gửi ngân hàng, quà tặng trong gia đình, hoàn tiền...).
  exempt,
}

@immutable
final class Category {
  const Category({
    required this.id,
    required this.name,
    required this.kind,
    this.parentId,
    this.icon,
    this.color,
    this.archived = false,
    this.taxType = IncomeTaxType.unknown,
  });

  final String id;
  final String name;
  final CategoryKind kind;

  /// Chỉ có nghĩa với danh mục thu.
  final IncomeTaxType taxType;
  final String? parentId;
  final String? icon;
  final String? color;
  final bool archived;

  Map<String, Object?> toValues() => {
    'name': name,
    'kind': kind.name,
    'parentId': parentId,
    'icon': icon,
    'color': color,
    'archived': archived,
    if (taxType != IncomeTaxType.unknown) 'taxType': taxType.name,
  };

  static Category fromRecord(SyncRecord r) {
    final v = r.values;
    return Category(
      id: r.id,
      name: _str(v, 'name'),
      kind: _enum(CategoryKind.values, v['kind'], CategoryKind.expense),
      parentId: _strOrNull(v, 'parentId'),
      icon: _strOrNull(v, 'icon'),
      color: _strOrNull(v, 'color'),
      archived: _bool(v, 'archived'),
      taxType: _enum(IncomeTaxType.values, v['taxType'], IncomeTaxType.unknown),
    );
  }
}

// ---------------------------------------------------------------- Giao dịch

/// Chuyển ví được ghi thành HAI bản ghi (`transferOut` ở ví nguồn, `transferIn` ở ví đích) cùng `transferId`,
/// để mỗi bản ghi chỉ cần khóa của ví chứa nó (quan trọng với ví chung E2EE).
enum TxnKind { expense, income, transferOut, transferIn, adjustment }

/// Nguồn tạo giao dịch.
enum TxnSource { manual, recurring, notification, statement, ocr, voice, email, import }

/// Giao dịch tự nhập chờ người dùng xác nhận thì [pending] = true và KHÔNG tính vào số dư.
@immutable
final class Txn {
  const Txn({
    required this.id,
    required this.walletId,
    required this.kind,
    required this.amount,
    required this.date,
    this.categoryId,
    this.note,
    this.payee,
    this.tags = const [],
    this.transferId,
    this.counterWalletId,
    this.fee = 0,
    this.eventId,
    this.debtId,
    this.goalId,
    this.recurringId,
    this.source = TxnSource.manual,
    this.pending = false,
    this.excludeFromReports = false,
    this.attachmentIds = const [],
    this.incomePlanId,
    this.taxWithheld = 0,
  });

  final String id;
  final String walletId;
  final TxnKind kind;

  /// Số tiền theo tiền tệ của ví. Dương với mọi loại, trừ `adjustment` (có dấu: + tăng, - giảm số dư).
  final int amount;
  final CivilDate date;
  final String? categoryId;
  final String? note;
  final String? payee;
  final List<String> tags;
  final String? transferId;
  final String? counterWalletId;

  /// Phí chuyển (chỉ ở `transferOut`), trừ thêm vào ví nguồn.
  final int fee;
  final String? eventId;
  final String? debtId;
  final String? goalId;
  final String? recurringId;
  final TxnSource source;
  final bool pending;
  final bool excludeFromReports;
  final List<String> attachmentIds;

  /// Khoản thu ([IncomePlan]) mà lần nhận tiền này thuộc về.
  final String? incomePlanId;

  /// Thuế TNCN bên trả đã khấu trừ tại nguồn (chỉ khoản thu). [amount] là số THỰC NHẬN; tổng thu nhập =
  /// [amount] + [taxWithheld]. Không ảnh hưởng số dư.
  final int taxWithheld;

  /// Thu nhập trước thuế khấu trừ (chỉ có nghĩa với khoản thu).
  int get grossAmount => amount + taxWithheld;

  /// Ảnh hưởng tới số dư ví (đơn vị nhỏ nhất).
  int get balanceEffect {
    if (pending) return 0;
    return switch (kind) {
      TxnKind.income || TxnKind.transferIn => amount,
      TxnKind.expense => -amount,
      TxnKind.transferOut => -(amount + fee),
      TxnKind.adjustment => amount,
    };
  }

  Map<String, Object?> toValues() => {
    'kind': kind.name,
    'amount': amount,
    'date': date.toString(),
    'categoryId': categoryId,
    'note': note,
    'payee': payee,
    'tags': tags,
    'transferId': transferId,
    'counterWalletId': counterWalletId,
    'fee': fee,
    'eventId': eventId,
    'debtId': debtId,
    'goalId': goalId,
    'recurringId': recurringId,
    'source': source.name,
    'pending': pending,
    'excludeFromReports': excludeFromReports,
    'attachmentIds': attachmentIds,
    if (incomePlanId != null) 'incomePlanId': incomePlanId,
    if (taxWithheld != 0) 'taxWithheld': taxWithheld,
  };

  static Txn fromRecord(SyncRecord r) {
    final v = r.values;
    return Txn(
      id: r.id,
      walletId: r.walletId ?? '',
      kind: _enum(TxnKind.values, v['kind'], TxnKind.expense),
      amount: _int(v, 'amount'),
      date: _date(v, 'date') ?? CivilDate(1970, 1, 1),
      categoryId: _strOrNull(v, 'categoryId'),
      note: _strOrNull(v, 'note'),
      payee: _strOrNull(v, 'payee'),
      tags: _strList(v, 'tags'),
      transferId: _strOrNull(v, 'transferId'),
      counterWalletId: _strOrNull(v, 'counterWalletId'),
      fee: _int(v, 'fee'),
      eventId: _strOrNull(v, 'eventId'),
      debtId: _strOrNull(v, 'debtId'),
      goalId: _strOrNull(v, 'goalId'),
      recurringId: _strOrNull(v, 'recurringId'),
      source: _enum(TxnSource.values, v['source'], TxnSource.manual),
      pending: _bool(v, 'pending'),
      excludeFromReports: _bool(v, 'excludeFromReports'),
      attachmentIds: _strList(v, 'attachmentIds'),
      incomePlanId: _strOrNull(v, 'incomePlanId'),
      taxWithheld: _int(v, 'taxWithheld'),
    );
  }

  /// Bản sao đổi một số trường (giữ nguyên các trường còn lại).
  Txn copyWith({
    String? walletId,
    TxnKind? kind,
    int? amount,
    CivilDate? date,
    String? categoryId,
    String? note,
    String? payee,
    String? incomePlanId,
    int? taxWithheld,
    bool? pending,
  }) => Txn(
    id: id,
    walletId: walletId ?? this.walletId,
    kind: kind ?? this.kind,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    categoryId: categoryId ?? this.categoryId,
    note: note ?? this.note,
    payee: payee ?? this.payee,
    tags: tags,
    transferId: transferId,
    counterWalletId: counterWalletId,
    fee: fee,
    eventId: eventId,
    debtId: debtId,
    goalId: goalId,
    recurringId: recurringId,
    source: source,
    pending: pending ?? this.pending,
    excludeFromReports: excludeFromReports,
    attachmentIds: attachmentIds,
    incomePlanId: incomePlanId ?? this.incomePlanId,
    taxWithheld: taxWithheld ?? this.taxWithheld,
  );
}

// ---------------------------------------------------------------- Ngân sách

enum BudgetPeriod { weekly, monthly, yearly, custom }

@immutable
final class Budget {
  const Budget({
    required this.id,
    required this.name,
    required this.amount,
    required this.currency,
    required this.period,
    this.categoryIds = const [],
    this.walletIds = const [],
    this.startDay = 1,
    this.customStart,
    this.customEnd,
    this.rollover = false,
    this.alertAtBp = 8000,
  });

  final String id;
  final String name;
  final int amount;
  final Currency currency;
  final BudgetPeriod period;

  /// Rỗng = mọi danh mục chi. Danh mục cha bao gồm danh mục con.
  final List<String> categoryIds;

  /// Rỗng = mọi ví cùng tiền tệ.
  final List<String> walletIds;

  /// monthly: ngày bắt đầu kỳ (1-31, kẹp cuối tháng); weekly: thứ bắt đầu (1 = Thứ Hai).
  final int startDay;
  final CivilDate? customStart;
  final CivilDate? customEnd;

  /// Chuyển phần còn dư (hoặc vượt) sang kỳ sau.
  final bool rollover;

  /// Ngưỡng cảnh báo theo phần vạn (8000 = 80%).
  final int alertAtBp;

  Money get limit => Money(amount, currency);

  Map<String, Object?> toValues() => {
    'name': name,
    'amount': amount,
    ..._currencyFields(currency),
    'period': period.name,
    'categoryIds': categoryIds,
    'walletIds': walletIds,
    'startDay': startDay,
    'customStart': customStart?.toString(),
    'customEnd': customEnd?.toString(),
    'rollover': rollover,
    'alertAtBp': alertAtBp,
  };

  static Budget fromRecord(SyncRecord r) {
    final v = r.values;
    return Budget(
      id: r.id,
      name: _str(v, 'name'),
      amount: _int(v, 'amount'),
      currency: _currency(v),
      period: _enum(BudgetPeriod.values, v['period'], BudgetPeriod.monthly),
      categoryIds: _strList(v, 'categoryIds'),
      walletIds: _strList(v, 'walletIds'),
      startDay: _int(v, 'startDay', 1),
      customStart: _date(v, 'customStart'),
      customEnd: _date(v, 'customEnd'),
      rollover: _bool(v, 'rollover'),
      alertAtBp: _int(v, 'alertAtBp', 8000),
    );
  }
}

// ---------------------------------------------------------------- Nợ / vay

enum DebtKind { lend, borrow }

@immutable
final class Debt {
  const Debt({
    required this.id,
    required this.walletId,
    required this.kind,
    required this.counterparty,
    required this.principal,
    required this.startDate,
    this.dueDate,
    this.annualInterestBp = 0,
    this.note,
    this.closed = false,
  });

  final String id;
  final String walletId;
  final DebtKind kind;
  final String counterparty;
  final int principal;
  final CivilDate startDate;
  final CivilDate? dueDate;

  /// Lãi suất năm theo phần vạn (1200 = 12%/năm), chỉ để hiển thị/ước tính.
  final int annualInterestBp;
  final String? note;
  final bool closed;

  Map<String, Object?> toValues() => {
    'kind': kind.name,
    'counterparty': counterparty,
    'principal': principal,
    'startDate': startDate.toString(),
    'dueDate': dueDate?.toString(),
    'annualInterestBp': annualInterestBp,
    'note': note,
    'closed': closed,
  };

  static Debt fromRecord(SyncRecord r) {
    final v = r.values;
    return Debt(
      id: r.id,
      walletId: r.walletId ?? '',
      kind: _enum(DebtKind.values, v['kind'], DebtKind.lend),
      counterparty: _str(v, 'counterparty'),
      principal: _int(v, 'principal'),
      startDate: _date(v, 'startDate') ?? CivilDate(1970, 1, 1),
      dueDate: _date(v, 'dueDate'),
      annualInterestBp: _int(v, 'annualInterestBp'),
      note: _strOrNull(v, 'note'),
      closed: _bool(v, 'closed'),
    );
  }
}

// ---------------------------------------------------------------- Mục tiêu, sự kiện, 6 hũ

@immutable
final class Goal {
  const Goal({
    required this.id,
    required this.name,
    required this.target,
    required this.currency,
    this.deadline,
    this.startingAmount = 0,
    this.icon,
    this.achieved = false,
  });

  final String id;
  final String name;
  final int target;
  final Currency currency;
  final CivilDate? deadline;
  final int startingAmount;
  final String? icon;
  final bool achieved;

  Map<String, Object?> toValues() => {
    'name': name,
    'target': target,
    ..._currencyFields(currency),
    'deadline': deadline?.toString(),
    'startingAmount': startingAmount,
    'icon': icon,
    'achieved': achieved,
  };

  static Goal fromRecord(SyncRecord r) {
    final v = r.values;
    return Goal(
      id: r.id,
      name: _str(v, 'name'),
      target: _int(v, 'target'),
      currency: _currency(v),
      deadline: _date(v, 'deadline'),
      startingAmount: _int(v, 'startingAmount'),
      icon: _strOrNull(v, 'icon'),
      achieved: _bool(v, 'achieved'),
    );
  }
}

@immutable
final class Event {
  const Event({
    required this.id,
    required this.name,
    required this.start,
    this.end,
    this.budget,
    this.archived = false,
  });

  final String id;
  final String name;
  final CivilDate start;
  final CivilDate? end;
  final int? budget;
  final bool archived;

  Map<String, Object?> toValues() => {
    'name': name,
    'start': start.toString(),
    'end': end?.toString(),
    'budget': budget,
    'archived': archived,
  };

  static Event fromRecord(SyncRecord r) {
    final v = r.values;
    return Event(
      id: r.id,
      name: _str(v, 'name'),
      start: _date(v, 'start') ?? CivilDate(1970, 1, 1),
      end: _date(v, 'end'),
      budget: _intOrNull(v, 'budget'),
      archived: _bool(v, 'archived'),
    );
  }
}

/// Một hũ trong phương pháp 6 hũ: tỉ lệ theo phần vạn.
@immutable
final class Jar {
  const Jar(this.key, this.name, this.basisPoints);
  final String key;
  final String name;
  final int basisPoints;

  Map<String, Object?> toJson() => {'key': key, 'name': name, 'bp': basisPoints};
}

/// Kế hoạch chia hũ. Mặc định 6 hũ: thiết yếu 55%, tiết kiệm dài hạn 10%, giáo dục 10%,
/// hưởng thụ 10%, tự do tài chính 10%, cho đi 5%.
@immutable
final class JarPlan {
  JarPlan(this.jars) {
    final total = jars.fold<int>(0, (a, j) => a + j.basisPoints);
    if (jars.isEmpty || total != 10000 || jars.any((j) => j.basisPoints < 0)) {
      throw ArgumentError('Tổng tỉ lệ các hũ phải đúng 100%');
    }
  }

  factory JarPlan.sixJars() => JarPlan(const [
    Jar('nec', 'Thiết yếu', 5500),
    Jar('lts', 'Tiết kiệm dài hạn', 1000),
    Jar('edu', 'Giáo dục', 1000),
    Jar('ply', 'Hưởng thụ', 1000),
    Jar('ffa', 'Tự do tài chính', 1000),
    Jar('giv', 'Cho đi', 500),
  ]);

  final List<Jar> jars;

  /// Chia một khoản thu nhập vào các hũ, tổng luôn khớp đến từng đồng.
  Map<String, Money> allocate(Money income) {
    final parts = income.allocate([for (final j in jars) j.basisPoints]);
    return {for (var i = 0; i < jars.length; i++) jars[i].key: parts[i]};
  }
}

// ---------------------------------------------------------------- Khoản thu nhiều đợt

enum IncomePlanStatus { active, completed, cancelled }

/// Một đợt thu dự kiến (mốc thanh toán của hợp đồng: đặt cọc, nghiệm thu...).
@immutable
final class PlannedInstallment {
  const PlannedInstallment({required this.date, required this.amount, this.label});
  final CivilDate date;

  /// Số tiền dự kiến (trước thuế khấu trừ), đơn vị nhỏ nhất.
  final int amount;
  final String? label;

  Map<String, Object?> toJson() => {'date': date.toString(), 'amount': amount, if (label != null) 'label': label};

  static PlannedInstallment? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final m = raw.cast<String, Object?>();
    final d = _date(m, 'date');
    if (d == null) return null;
    return PlannedInstallment(date: d, amount: _int(m, 'amount'), label: _strOrNull(m, 'label'));
  }
}

/// Khoản thu dự kiến nhận nhiều đợt: một job/dự án freelance, hợp đồng dịch vụ, tiền cho thuê... Mỗi lần nhận tiền là
/// một giao dịch thu có `incomePlanId`; tiến độ luôn TÍNH từ giao dịch (không lưu số đã nhận).
@immutable
final class IncomePlan {
  const IncomePlan({
    required this.id,
    required this.name,
    required this.currency,
    this.payer,
    this.total = 0,
    this.defaultWalletId,
    this.categoryId,
    this.startDate,
    this.dueDate,
    this.installments = const [],
    this.status = IncomePlanStatus.active,
    this.withholdingBp = 0,
    this.note,
  });

  final String id;

  /// Tên job/dự án, ví dụ "Thiết kế logo cho quán A".
  final String name;

  /// Người/đơn vị trả tiền (khách hàng).
  final String? payer;
  final Currency currency;

  /// Tổng giá trị thỏa thuận (trước thuế khấu trừ). 0 = chưa chốt/không cố định.
  final int total;
  final String? defaultWalletId;
  final String? categoryId;
  final CivilDate? startDate;
  final CivilDate? dueDate;
  final List<PlannedInstallment> installments;
  final IncomePlanStatus status;

  /// Tỉ lệ bên trả dự kiến khấu trừ thuế, phần vạn (1000 = 10%) - gợi ý khi ghi một lần nhận tiền.
  final int withholdingBp;
  final String? note;

  Map<String, Object?> toValues() => {
    'name': name,
    'payer': payer,
    ..._currencyFields(currency),
    'total': total,
    'defaultWalletId': defaultWalletId,
    'categoryId': categoryId,
    'startDate': startDate?.toString(),
    'dueDate': dueDate?.toString(),
    'installments': [for (final i in installments) i.toJson()],
    'status': status.name,
    'withholdingBp': withholdingBp,
    'note': note,
  };

  static IncomePlan fromRecord(SyncRecord r) {
    final v = r.values;
    final raw = v['installments'];
    return IncomePlan(
      id: r.id,
      name: _str(v, 'name'),
      payer: _strOrNull(v, 'payer'),
      currency: _currency(v),
      total: _int(v, 'total'),
      defaultWalletId: _strOrNull(v, 'defaultWalletId'),
      categoryId: _strOrNull(v, 'categoryId'),
      startDate: _date(v, 'startDate'),
      dueDate: _date(v, 'dueDate'),
      installments: [
        if (raw is List)
          for (final e in raw) ?PlannedInstallment.fromJson(e),
      ]..sort((a, b) => a.date.compareTo(b.date)),
      status: _enum(IncomePlanStatus.values, v['status'], IncomePlanStatus.active),
      withholdingBp: _int(v, 'withholdingBp'),
      note: _strOrNull(v, 'note'),
    );
  }
}

// ---------------------------------------------------------------- Hồ sơ thuế

enum TaxResidency { resident, nonResident }

/// Thông tin để ước tính thuế TNCN (Việt Nam). Được mã hóa đầu-cuối như mọi bản ghi khác.
@immutable
final class TaxProfile {
  const TaxProfile({
    this.dependents = 0,
    this.residency = TaxResidency.resident,
    this.monthlyInsurance,
    this.monthlyCharity = 0,
    this.remindersEnabled = true,
    this.businessHousehold = false,
  });

  /// UUID cố định của bản ghi hồ sơ thuế (mỗi tài khoản một bản).
  static const recordId = '7a000000-0000-4000-8000-000000000001';

  /// Số người phụ thuộc đã đăng ký giảm trừ.
  final int dependents;
  final TaxResidency residency;

  /// Bảo hiểm bắt buộc người lao động đóng mỗi tháng (VND). Null ⇒ ước tính 10,5% lương trong hạn mức.
  final int? monthlyInsurance;

  /// Đóng góp từ thiện/nhân đạo được trừ mỗi tháng (bình quân).
  final int monthlyCharity;
  final bool remindersEnabled;

  /// Có hoạt động kinh doanh (hộ/cá nhân kinh doanh) - bật nhắc ngưỡng doanh thu.
  final bool businessHousehold;

  Map<String, Object?> toValues() => {
    'dependents': dependents,
    'residency': residency.name,
    'monthlyInsurance': monthlyInsurance,
    'monthlyCharity': monthlyCharity,
    'remindersEnabled': remindersEnabled,
    'businessHousehold': businessHousehold,
  };

  static TaxProfile fromRecord(SyncRecord r) {
    final v = r.values;
    return TaxProfile(
      dependents: _int(v, 'dependents').clamp(0, 50),
      residency: _enum(TaxResidency.values, v['residency'], TaxResidency.resident),
      monthlyInsurance: _intOrNull(v, 'monthlyInsurance'),
      monthlyCharity: _int(v, 'monthlyCharity'),
      remindersEnabled: v['remindersEnabled'] != false,
      businessHousehold: _bool(v, 'businessHousehold'),
    );
  }
}
