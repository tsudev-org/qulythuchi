import 'package:meta/meta.dart';

import '../money/money.dart';

/// Số tiền VND tìm thấy trong một câu, kèm vị trí token (để cắt khỏi ghi chú).
@immutable
final class SpokenAmount {
  const SpokenAmount(this.amount, this.startToken, this.endToken);

  /// Số tiền (đồng, số nguyên dương).
  final int amount;

  /// Chỉ số token đầu (gồm) và cuối (không gồm) trong danh sách tách bằng khoảng trắng.
  final int startToken;
  final int endToken;
}

const _units = {
  'không': 0,
  'một': 1,
  'mốt': 1,
  'hai': 2,
  'ba': 3,
  'bốn': 4,
  'tư': 4,
  'năm': 5,
  'lăm': 5,
  'nhăm': 5,
  'sáu': 6,
  'bảy': 7,
  'bẩy': 7,
  'tám': 8,
  'chín': 9,
};

const _scales = {
  'k': 1000,
  'nghìn': 1000,
  'nghin': 1000,
  'ngàn': 1000,
  'ngan': 1000,
  'ng': 1000,
  'tr': 1000000,
  'triệu': 1000000,
  'trieu': 1000000,
  'củ': 1000000,
  'cu': 1000000,
  'tỷ': 1000000000,
  'tỉ': 1000000000,
  'ty': 1000000000,
  'ti': 1000000000,
};

const _currencyWords = {'đ', 'đồng', 'dong', 'vnd', 'vnđ', 'd'};

// Mục đã phân loại của một khoảng số.
sealed class _Item {}

final class _Num extends _Item {
  _Num(this.milli, this.digits, {this.fromDigits = false});

  /// Giá trị × 1000 (để biểu diễn "1,5" không cần số thực).
  final int milli;

  /// Số chữ số phần nguyên như được viết (cho cách nói tắt "1 triệu 2").
  final int digits;
  final bool fromDigits;
}

final class _Ten extends _Item {}

final class _Ten10 extends _Item {}

final class _Hundred extends _Item {}

final class _Scale extends _Item {
  _Scale(this.value);
  final int value;
}

final class _Half extends _Item {}

final class _Link extends _Item {}

final class _Currency extends _Item {}

final _compound = RegExp(r'^(\d+(?:[.,]\d+)*)(k|nghìn|nghin|ngàn|ngan|tr|triệu|trieu|củ|tỷ|tỉ|đ|vnd|vnđ)?(\d{1,3})?$');

String _clean(String token) =>
    token.toLowerCase().replaceAll(RegExp(r'^[^\p{L}\p{N}]+|[^\p{L}\p{N}]+$', unicode: true), '');

/// Đọc số viết bằng chữ số "50.000", "1,5", "120000" ⇒ giá trị × 1000 và số chữ số phần nguyên.
_Num? _digitNumber(String s) {
  final groups = s.split(RegExp(r'[.,]'));
  final seps = RegExp(r'[.,]').allMatches(s).length;
  if (seps == 0) return _Num(int.parse(s) * 1000, s.length, fromDigits: true);
  // Mọi nhóm sau dấu đều 3 chữ số ⇒ phân tách nghìn.
  if (groups.skip(1).every((g) => g.length == 3)) {
    final whole = groups.join();
    if (whole.length > 13) return null;
    return _Num(int.parse(whole) * 1000, whole.length, fromDigits: true);
  }
  // Một dấu và phần sau ngắn ⇒ phần thập phân ("1,5 triệu", "2.25tr").
  if (seps == 1 && groups[1].length <= 3 && groups[0].length <= 13) {
    final frac = groups[1].padRight(3, '0');
    return _Num(int.parse(groups[0]) * 1000 + int.parse(frac), groups[0].length, fromDigits: true);
  }
  return null;
}

List<_Item>? _classify(String raw, bool afterNumber) {
  final t = _clean(raw);
  if (t.isEmpty) return null;
  final m = _compound.firstMatch(t);
  if (m != null) {
    final n = _digitNumber(m.group(1)!);
    if (n == null) return null;
    final suffix = m.group(2);
    final tail = m.group(3);
    final out = <_Item>[n];
    if (suffix != null) {
      if (_scales.containsKey(suffix)) {
        out.add(_Scale(_scales[suffix]!));
      } else {
        out.add(_Currency());
      }
    }
    if (tail != null) {
      if (suffix == null || !_scales.containsKey(suffix)) return null;
      out.add(_Num(int.parse(tail) * 1000, tail.length, fromDigits: true));
    }
    return out;
  }
  if (_units.containsKey(t)) return [_Num(_units[t]! * 1000, 1)];
  if (t == 'mười') return [_Ten10()];
  if (t == 'mươi') return [_Ten()];
  if (t == 'trăm') return [_Hundred()];
  if (t == 'lẻ' || t == 'linh') return afterNumber ? [_Link()] : null;
  if (t == 'rưỡi' || t == 'rưởi') return afterNumber ? [_Half()] : null;
  // Từ chỉ đơn vị không dấu ("cu", "ti", "ty", "d") dễ trùng chữ thường ⇒ chỉ nhận ngay sau một số.
  if (_scales.containsKey(t)) {
    if (!afterNumber && !RegExp('[^a-z]').hasMatch(t)) return null;
    return [_Scale(_scales[t]!)];
  }
  if (_currencyWords.contains(t)) return afterNumber ? [_Currency()] : null;
  return null;
}

int _digitsOf(int milli) {
  final v = milli ~/ 1000;
  return v < 10 ? 1 : (v < 100 ? 2 : 3);
}

int _pow10(int n) {
  var r = 1;
  for (var i = 0; i < n; i++) {
    r *= 10;
  }
  return r;
}

/// Tính giá trị (đồng) của một khoảng đã phân loại; null nếu không hợp lệ.
int? _evaluate(List<_Item> items) {
  var total = 0; // milli
  var section = 0; // milli, phần dưới đơn vị lớn đang dựng
  int? cur; // milli
  var curDigits = 0;
  var curShort = true; // cur là một số đơn (có thể là cách nói tắt)
  var lastMul = 0; // 100 sau "trăm", hoặc giá trị đơn vị lớn
  var lastScale = 0;
  var linked = false;
  var hasCurrency = false;
  var hasScale = false;

  int takeCur({required bool afterHundred}) {
    final c = cur ?? 0;
    if (afterHundred && cur != null && curShort && curDigits == 1 && !linked) return c * 10; // "trăm hai" = 120
    return c;
  }

  for (final it in items) {
    switch (it) {
      case _Num():
        if (cur == null) {
          cur = it.milli;
          curDigits = it.digits;
          curShort = true;
        } else {
          cur = cur + it.milli; // "mười lăm", "hai mươi lăm"
          curShort = false;
          curDigits = _digitsOf(cur);
        }
      case _Ten():
        cur = (cur ?? 1000) * 10;
        curShort = false;
        curDigits = 2;
      case _Ten10():
        cur = (cur ?? 0) + 10000;
        curShort = false;
        curDigits = 2;
      case _Hundred():
        section += (cur ?? 1000) * 100;
        cur = null;
        lastMul = 100;
        linked = false;
      case _Link():
        linked = true;
      case _Scale():
        var group = section + takeCur(afterHundred: lastMul == 100);
        if (group == 0) group = 1000;
        if (lastScale != 0 && it.value > lastScale) {
          if (total + group > Money.maxSafe ~/ it.value) return null;
          total = (total + group) * it.value; // "một trăm nghìn triệu" hiếm gặp: nhân dồn
        } else {
          if (group > (Money.maxSafe - total) ~/ it.value) return null;
          total += group * it.value;
        }
        section = 0;
        cur = null;
        lastMul = it.value;
        lastScale = it.value;
        linked = false;
        hasScale = true;
      case _Half():
        if (lastMul == 100) {
          section += 50000;
        } else if (lastMul > 0) {
          total += lastMul * 500;
        } else {
          return null;
        }
        lastMul = 0;
      case _Currency():
        hasCurrency = true;
    }
    if (total > Money.maxSafe) return null;
  }

  final trailing = section + takeCur(afterHundred: lastMul == 100 && section > 0);
  if (trailing > 0) {
    if (lastScale > 0 && !linked) {
      // Cách nói tắt sau đơn vị lớn: "1 triệu 2" = 1,2 triệu, "2 triệu 500" = 2,5 triệu.
      final d = section > 0 ? 3 : (curShort ? curDigits : _digitsOf(trailing));
      if (d > 3) return null;
      total += trailing * lastScale ~/ _pow10(d);
    } else if (lastScale > 0) {
      total += trailing;
    } else {
      total = trailing;
    }
  }
  var amount = total ~/ 1000;
  // Số trần nhỏ không đơn vị ("ăn trưa 50") ⇒ hiểu là nghìn đồng, như thói quen ghi chép ở Việt Nam.
  if (!hasScale && !hasCurrency && amount > 0 && amount < 1000) amount *= 1000;
  if (amount <= 0 || amount > Money.maxSafe) return null;
  return amount;
}

/// Tìm số tiền đầu tiên trong câu nói/viết tiếng Việt: "50 nghìn", "50k", "1tr2", "1,5 triệu", "hai trăm rưỡi",
/// "năm mươi nghìn", "120.000đ". Số chữ nhỏ hơn 1000 không kèm đơn vị hiểu là nghìn đồng.
/// Số viết bằng chữ ("ba", "năm") chỉ được nhận khi đi kèm đơn vị (trăm/nghìn/triệu...) để tránh nhầm nghĩa khác.
/// Khoảng có đơn vị (nghìn, triệu, đ...) được ưu tiên hơn số trần ("năm 2026 ... 2 triệu" lấy 2 triệu).
SpokenAmount? findSpokenAmount(String text) {
  SpokenAmount? weak;
  final tokens = text.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  var i = 0;
  while (i < tokens.length) {
    final first = _classify(tokens[i], false);
    if (first == null || first.first is! _Num && first.first is! _Ten10 && first.first is! _Hundred) {
      i++;
      continue;
    }
    final items = [...first];
    var j = i + 1;
    while (j < tokens.length) {
      final next = _classify(tokens[j], true);
      if (next == null) break;
      // Hai số chữ số liền nhau là hai số khác nhau.
      if (next.first is _Num && (next.first as _Num).fromDigits && items.last is _Num) break;
      items.addAll(next);
      j++;
      if (next.last is _Currency) break;
    }
    final hasDigits = items.any((x) => x is _Num && x.fromDigits);
    final hasUnitWord = items.any((x) => x is _Scale || x is _Hundred || x is _Ten || x is _Currency);
    if (hasDigits || hasUnitWord) {
      final v = _evaluate(items);
      if (v != null) {
        if (hasUnitWord) return SpokenAmount(v, i, j);
        weak ??= SpokenAmount(v, i, j);
      }
    }
    i = j;
  }
  return weak;
}
