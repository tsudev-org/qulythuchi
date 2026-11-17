/// Chuẩn hóa chuỗi để tìm kiếm tiếng Việt không dấu (SEARCH_AND_FILTER.md mục 3): chữ thường, bỏ dấu, đ → d,
/// gộp khoảng trắng.
String normalizeVi(String input) {
  final lower = input.toLowerCase();
  final b = StringBuffer();
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    b.write(_map[ch] ?? ch);
  }
  return b.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Mọi từ của [query] (đã chuẩn hóa) đều xuất hiện trong [text].
bool matchesVi(String text, String query) {
  final hay = normalizeVi(text);
  return normalizeVi(query).split(' ').where((w) => w.isNotEmpty).every(hay.contains);
}

const _groups = {
  'a': 'àáạảãâầấậẩẫăằắặẳẵ',
  'e': 'èéẹẻẽêềếệểễ',
  'i': 'ìíịỉĩ',
  'o': 'òóọỏõôồốộổỗơờớợởỡ',
  'u': 'ùúụủũưừứựửữ',
  'y': 'ỳýỵỷỹ',
  'd': 'đ',
};

final Map<String, String> _map = {
  for (final e in _groups.entries)
    for (final ch in e.value.split('')) ch: e.key,
  // Dấu tổ hợp (chuỗi chưa chuẩn hóa NFC): bỏ đi.
  for (final c in ['̀', '́', '̃', '̉', '̣', '̂', '̆', '̛']) c: '',
};
