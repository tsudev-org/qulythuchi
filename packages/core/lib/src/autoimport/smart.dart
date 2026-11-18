import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

import '../domain/civil_date.dart';
import '../domain/models.dart';
import 'vn_text.dart';

/// Dấu vân tay chống trùng khi nhập sao kê: (ngày, số tiền có dấu, nội dung bỏ dấu, bỏ ký tự không phải chữ/số).
/// Tính lại từ giao dịch đã có nên không cần lưu thêm trường nào vào bản ghi.
String txnFingerprint(CivilDate date, int signedAmount, String? text) {
  final t = foldVi(text ?? '').replaceAll(RegExp(r'[^a-z0-9]'), '');
  return sha256.convert(utf8.encode('$date|$signedAmount|$t')).toString().substring(0, 32);
}

/// Số tiền có dấu của giao dịch (+ thu, - chi) để so trùng.
int signedAmountOf(Txn t) => switch (t.kind) {
  TxnKind.income || TxnKind.transferIn => t.amount,
  TxnKind.adjustment => t.amount,
  TxnKind.expense || TxnKind.transferOut => -t.amount,
};

Iterable<String> _words(String text) =>
    foldVi(text).split(RegExp(r'[^a-z0-9]+')).where((w) => w.length >= 2 && !RegExp(r'^\d+$').hasMatch(w));

/// Một mẫu lịch sử để học: nội dung (ghi chú/người nhận) và danh mục người dùng đã chọn.
@immutable
final class CategorySample {
  const CategorySample(this.text, this.kind, this.categoryId);
  final String text;
  final CategoryKind kind;
  final String categoryId;
}

/// Gợi ý danh mục hoàn toàn trên máy: (1) nội dung giống hệt đã gặp ⇒ danh mục dùng nhiều nhất; (2) điểm theo từ
/// học từ lịch sử; (3) luật từ khóa mặc định. Không gửi gì ra ngoài.
final class CategorySuggester {
  CategorySuggester({required Iterable<CategorySample> history, Map<String, List<String>> rules = const {}})
    : _rules = {
        for (final e in rules.entries) e.key: [for (final k in e.value) foldVi(k)],
      } {
    for (final s in history) {
      if (s.text.trim().isEmpty) continue;
      final exact = (s.kind, foldVi(s.text));
      (_exact[exact] ??= {}).update(s.categoryId, (c) => c + 1, ifAbsent: () => 1);
      for (final w in _words(s.text).toSet()) {
        (_byWord[(s.kind, w)] ??= {}).update(s.categoryId, (c) => c + 1, ifAbsent: () => 1);
      }
    }
  }

  final _exact = <(CategoryKind, String), Map<String, int>>{};
  final _byWord = <(CategoryKind, String), Map<String, int>>{};

  /// id danh mục ⇒ từ khóa (đã bỏ dấu); id phải thuộc đúng loại khi gọi [suggest] với [ruleKinds].
  final Map<String, List<String>> _rules;

  static String? _best(Map<String, num> scores, {num minScore = 0}) {
    String? best;
    num top = minScore;
    var tie = false;
    for (final e in scores.entries) {
      if (e.value > top) {
        best = e.key;
        top = e.value;
        tie = false;
      } else if (e.value == top && best != null) {
        tie = true;
      }
    }
    return tie ? null : best;
  }

  /// Gợi ý id danh mục cho [text] thuộc loại [kind]; null nếu không đủ chắc. [ruleKinds] cho biết loại của từng id
  /// trong luật (luật sai loại bị bỏ qua).
  String? suggest(String text, CategoryKind kind, {Map<String, CategoryKind> ruleKinds = const {}}) {
    final f = foldVi(text);
    if (f.isEmpty) return null;
    final exact = _exact[(kind, f)];
    if (exact != null) {
      final b = _best(exact);
      if (b != null) return b;
    }
    final scores = <String, double>{};
    for (final w in _words(text).toSet()) {
      final counts = _byWord[(kind, w)];
      if (counts == null) continue;
      final total = counts.values.fold<int>(0, (a, b) => a + b);
      for (final e in counts.entries) {
        // Từ chỉ gắn với một danh mục có trọng số cao; từ chung chung bị chia nhỏ.
        scores.update(e.key, (s) => s + e.value / total, ifAbsent: () => e.value / total);
      }
    }
    final learned = _best(scores, minScore: 0.75);
    if (learned != null) return learned;
    // Luật: cụm từ khóa dài nhất khớp trọn từ thắng.
    String? ruleHit;
    var ruleLen = 0;
    for (final e in _rules.entries) {
      if (ruleKinds[e.key] != null && ruleKinds[e.key] != kind) continue;
      for (final k in e.value) {
        if (k.length > ruleLen && RegExp('(^|[^a-z0-9])${RegExp.escape(k)}([^a-z0-9]|\$)').hasMatch(f)) {
          ruleHit = e.key;
          ruleLen = k.length;
        }
      }
    }
    return ruleHit;
  }
}

/// Giao dịch đã có có thể trùng với [candidate]: cùng ví, cùng chiều tiền, cùng số tiền, ngày lệch ≤ 1 và (một bên
/// không có nội dung hoặc nội dung bỏ dấu giống nhau/chứa nhau). Bỏ qua chính nó (cùng id).
List<Txn> possibleDuplicates(Txn candidate, Iterable<Txn> existing) {
  final a = foldVi('${candidate.note ?? ''} ${candidate.payee ?? ''}');
  final out = <Txn>[];
  for (final t in existing) {
    if (t.id == candidate.id || t.walletId != candidate.walletId) continue;
    if (signedAmountOf(t) != signedAmountOf(candidate)) continue;
    if (t.date.daysUntil(candidate.date).abs() > 1) continue;
    final b = foldVi('${t.note ?? ''} ${t.payee ?? ''}');
    if (a.isEmpty || b.isEmpty || a.contains(b) || b.contains(a) || t.source != candidate.source) out.add(t);
  }
  return out;
}

/// Khoản chi bất thường: cùng danh mục có ≥ 5 khoản trong 90 ngày trước và số tiền > 3 lần trung vị.
/// Chỉ dùng số nguyên.
bool isUnusualExpense(Txn t, Iterable<Txn> history) {
  if (t.kind != TxnKind.expense || t.categoryId == null) return false;
  final from = t.date.addDays(-90);
  final amounts = [
    for (final h in history)
      if (h.id != t.id &&
          !h.pending &&
          h.kind == TxnKind.expense &&
          h.categoryId == t.categoryId &&
          h.date.compareTo(from) >= 0 &&
          h.date.compareTo(t.date) <= 0)
        h.amount,
  ]..sort();
  if (amounts.length < 5) return false;
  final median = amounts[amounts.length ~/ 2];
  return median > 0 && t.amount > median * 3;
}
