import 'package:flutter/foundation.dart' show immutable, setEquals;
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../state/ledger_repository.dart';
import 'reports.dart';

/// Nhóm loại giao dịch dùng trong bộ lọc.
enum FilterKind { expense, income, transfer, adjustment }

FilterKind filterKindOf(TxnKind k) => switch (k) {
  TxnKind.expense => FilterKind.expense,
  TxnKind.income => FilterKind.income,
  TxnKind.transferIn || TxnKind.transferOut => FilterKind.transfer,
  TxnKind.adjustment => FilterKind.adjustment,
};

/// Bộ lọc giao dịch (không trạng thái, tuần tự hóa được để lưu - SEARCH_AND_FILTER.md).
@immutable
final class TxnFilter {
  const TxnFilter({
    this.kinds = const {},
    this.walletIds = const {},
    this.categoryIds = const {},
    this.uncategorizedOnly = false,
    this.from,
    this.to,
    this.minMinor,
    this.maxMinor,
  });

  final Set<FilterKind> kinds;
  final Set<String> walletIds;

  /// Danh mục được chọn (gồm cả con khi khớp).
  final Set<String> categoryIds;
  final bool uncategorizedOnly;
  final CivilDate? from;
  final CivilDate? to;

  /// Khoảng tiền theo tiền tệ báo cáo (đơn vị nhỏ nhất), so trên số tiền đã quy đổi.
  final int? minMinor;
  final int? maxMinor;

  static const empty = TxnFilter();

  int get activeCount =>
      (kinds.isEmpty ? 0 : 1) +
      (walletIds.isEmpty ? 0 : 1) +
      (categoryIds.isEmpty && !uncategorizedOnly ? 0 : 1) +
      (from == null && to == null ? 0 : 1) +
      (minMinor == null && maxMinor == null ? 0 : 1);

  bool get isEmpty => activeCount == 0;

  /// Tạo bộ lọc từ tham số URL (từ trang Báo cáo): `cat=<id>|none`, `from`, `to` (YYYY-MM-DD).
  static TxnFilter fromQuery(Map<String, String> q) {
    CivilDate? d(String? s) {
      if (s == null) return null;
      try {
        return CivilDate.parse(s);
      } on FormatException {
        return null;
      }
    }

    final cat = q['cat'];
    return TxnFilter(
      categoryIds: cat == null || cat == 'none' ? const {} : {cat},
      uncategorizedOnly: cat == 'none',
      kinds: cat == null ? const {} : const {FilterKind.expense},
      from: d(q['from']),
      to: d(q['to']),
    );
  }

  bool matches(Txn t, LedgerData data, Reports reports) {
    if (kinds.isNotEmpty && !kinds.contains(filterKindOf(t.kind))) return false;
    if (walletIds.isNotEmpty && !walletIds.contains(t.walletId)) return false;
    if (from != null && t.date < from!) return false;
    if (to != null && t.date > to!) return false;
    if (uncategorizedOnly && data.category(t.categoryId) != null) return false;
    if (categoryIds.isNotEmpty) {
      final c = data.category(t.categoryId);
      if (c == null || !(categoryIds.contains(c.id) || (c.parentId != null && categoryIds.contains(c.parentId)))) {
        return false;
      }
    }
    if (minMinor != null || maxMinor != null) {
      final cur = data.wallet(t.walletId)?.currency;
      final m = cur == null ? null : reports.toBase(t.amount.abs(), cur);
      if (m == null) return false;
      if (minMinor != null && m.minor < minMinor!) return false;
      if (maxMinor != null && m.minor > maxMinor!) return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
    'kinds': [for (final k in kinds) k.name],
    'wallets': walletIds.toList(),
    'cats': categoryIds.toList(),
    'uncat': uncategorizedOnly,
    'from': from?.toString(),
    'to': to?.toString(),
    'min': minMinor,
    'max': maxMinor,
  };

  static TxnFilter fromJson(Map<String, Object?> j) {
    Set<String> strs(Object? v) => {
      for (final e in (v as List? ?? const []))
        if (e is String) e,
    };
    CivilDate? d(Object? v) {
      try {
        return v is String ? CivilDate.parse(v) : null;
      } on FormatException {
        return null;
      }
    }

    return TxnFilter(
      kinds: {for (final n in strs(j['kinds'])) ?FilterKind.values.asNameMap()[n]},
      walletIds: strs(j['wallets']),
      categoryIds: strs(j['cats']),
      uncategorizedOnly: j['uncat'] == true,
      from: d(j['from']),
      to: d(j['to']),
      minMinor: j['min'] is int ? j['min']! as int : null,
      maxMinor: j['max'] is int ? j['max']! as int : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TxnFilter &&
      setEquals(other.kinds, kinds) &&
      setEquals(other.walletIds, walletIds) &&
      setEquals(other.categoryIds, categoryIds) &&
      other.uncategorizedOnly == uncategorizedOnly &&
      other.from == from &&
      other.to == to &&
      other.minMinor == minMinor &&
      other.maxMinor == maxMinor;

  @override
  int get hashCode => Object.hash(kinds.length, walletIds.length, categoryIds.length, from, to, minMinor, maxMinor);
}

/// Bộ lọc đã lưu (bản ghi cấp tài khoản `saved_filter`, mã hóa như mọi bản ghi).
@immutable
final class SavedFilter {
  const SavedFilter({required this.id, required this.name, required this.filter});
  final String id;
  final String name;
  final TxnFilter filter;

  static const recordType = 'saved_filter';

  Map<String, Object?> toValues() => {'name': name, 'filter': filter.toJson()};

  static SavedFilter? fromRecord(SyncRecord r) {
    try {
      return SavedFilter(
        id: r.id,
        name: r.values['name']! as String,
        filter: TxnFilter.fromJson((r.values['filter']! as Map).cast<String, Object?>()),
      );
    } on Object {
      return null;
    }
  }
}
