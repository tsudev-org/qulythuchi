import 'dart:convert';
import 'dart:typed_data';

import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../state/ledger_repository.dart';

/// Luật từ khóa mặc định theo TÊN danh mục mặc định tiếng Việt (`domain/default_categories.dart`). Danh mục người
/// dùng đã đổi tên thì luật đó không áp - lịch sử ghi chép sẽ dạy lại bộ gợi ý.
const defaultCategoryRules = <String, List<String>>{
  'Ăn ngoài': ['ăn trưa', 'ăn sáng', 'ăn tối', 'cơm', 'phở', 'bún', 'quán', 'nhà hàng', 'grabfood', 'shopeefood'],
  'Cà phê, đồ uống': ['cà phê', 'cafe', 'coffee', 'highlands', 'trà sữa', 'starbucks', 'phúc long', 'katinat'],
  'Đi chợ, siêu thị': ['đi chợ', 'siêu thị', 'winmart', 'coopmart', 'co.opmart', 'bách hóa xanh', 'lotte mart', 'aeon'],
  'Tiền nhà': ['tiền nhà', 'thuê nhà', 'tiền phòng'],
  'Điện': ['tiền điện', 'evn', 'evnhcmc', 'evnhanoi'],
  'Nước': ['tiền nước', 'cấp nước', 'sawaco'],
  'Internet, điện thoại': [
    'internet',
    'wifi',
    'fpt telecom',
    'viettel',
    'vnpt',
    'mobifone',
    'vinaphone',
    'nạp điện thoại',
  ],
  'Xăng xe': ['xăng', 'đổ xăng', 'petrolimex'],
  'Gửi xe, cầu đường': ['gửi xe', 'phí đường', 'vetc', 'epass', 'cầu đường'],
  'Taxi, xe công nghệ': ['grab', 'xanh sm', 'gojek', 'taxi', 'xe ôm'],
  'Quần áo': ['quần áo', 'giày', 'uniqlo'],
  'Thuốc, khám bệnh': ['thuốc', 'nhà thuốc', 'khám bệnh', 'bệnh viện', 'pharmacity', 'long châu'],
  'Bảo hiểm': ['bảo hiểm', 'bhyt', 'prudential', 'manulife'],
  'Giáo dục': ['học phí', 'khóa học', 'sách'],
  'Giải trí': ['xem phim', 'cgv', 'netflix', 'spotify', 'karaoke'],
  'Du lịch': ['khách sạn', 'vé máy bay', 'vietjet', 'vietnam airlines', 'du lịch', 'agoda'],
  'Hiếu hỷ, quà tặng': ['đám cưới', 'mừng cưới', 'đám hiếu', 'quà', 'sinh nhật', 'phúng viếng'],
  'Lương': ['lương', 'salary'],
  'Thưởng': ['thưởng', 'bonus'],
  'Lãi tiết kiệm': ['tiền lãi', 'lãi tiết kiệm', 'interest'],
};

/// Bộ gợi ý danh mục cho dữ liệu hiện tại: học từ ghi chú/người nhận của giao dịch đã có danh mục (không tính bản
/// chờ xác nhận) và luật mặc định ánh xạ theo tên danh mục.
final class LedgerCategorySuggester {
  LedgerCategorySuggester(LedgerData data) : _data = data {
    final byName = {for (final c in data.categories.where((c) => !c.archived)) foldVi(c.name): c};
    final rules = <String, List<String>>{};
    for (final e in defaultCategoryRules.entries) {
      final c = byName[foldVi(e.key)];
      if (c != null) rules[c.id] = e.value;
    }
    _ruleKinds = {for (final c in data.categories) c.id: c.kind};
    _inner = CategorySuggester(
      history: [
        for (final t in data.txns)
          if (!t.pending && t.categoryId != null && (t.kind == TxnKind.income || t.kind == TxnKind.expense))
            CategorySample(
              [t.note, t.payee].whereType<String>().join(' '),
              t.kind == TxnKind.income ? CategoryKind.income : CategoryKind.expense,
              t.categoryId!,
            ),
      ],
      rules: rules,
    );
  }

  final LedgerData _data;
  late final CategorySuggester _inner;
  late final Map<String, CategoryKind> _ruleKinds;

  /// id danh mục còn hiệu lực cho nội dung [text] của giao dịch thu/chi.
  String? suggest(String? text, TxnKind kind) {
    if (text == null || text.trim().isEmpty) return null;
    final k = kind == TxnKind.income ? CategoryKind.income : CategoryKind.expense;
    final id = _inner.suggest(text, k, ruleKinds: _ruleKinds);
    final c = _data.category(id);
    return c == null || c.archived || c.kind != k ? null : id;
  }
}

/// Giao dịch từ câu ghi nhanh (gõ hoặc giọng nói). Người dùng đã xem trước nên không cần chờ xác nhận.
Txn txnFromQuickEntry(
  QuickEntry e,
  Wallet wallet,
  LedgerCategorySuggester suggester,
  String id, {
  TxnSource source = TxnSource.manual,
}) => Txn(
  id: id,
  walletId: wallet.id,
  kind: e.kind,
  amount: e.amount,
  date: e.date,
  note: e.note.isEmpty ? null : e.note,
  categoryId: suggester.suggest(e.note, e.kind),
  source: source,
);

/// Kết quả xử lý một lô thông báo ngân hàng.
final class NoticeImport {
  NoticeImport(this.txns, {this.ignored = 0, this.duplicates = 0});
  final List<Txn> txns;

  /// Không phải giao dịch, không có ví đích, hoặc khác tiền tệ ví.
  final int ignored;
  final int duplicates;
}

/// Một thông báo thô nhận từ bộ nghe Android (đã giải mã ở phía native).
final class RawNotification {
  const RawNotification({required this.packageName, required this.title, required this.text, required this.postedAt});
  final String packageName;
  final String title;
  final String text;
  final DateTime postedAt;
}

/// Chuyển thông báo thành giao dịch CHỜ XÁC NHẬN (trừ khi [autoConfirm]). [walletFor] trả ví đích theo gói app;
/// thông báo trùng (cùng số tiền, ngày, nội dung với giao dịch tự nhập đã có) bị bỏ.
NoticeImport txnsFromNotifications(
  Iterable<RawNotification> raws,
  LedgerData data,
  String? Function(String packageName) walletFor,
  String Function() newId, {
  bool autoConfirm = false,
  TxnSource source = TxnSource.notification,
}) {
  final suggester = LedgerCategorySuggester(data);
  final out = <Txn>[];
  var ignored = 0, duplicates = 0;
  for (final raw in raws) {
    final n = parseBankNotification(packageName: raw.packageName, title: raw.title, text: raw.text);
    final wallet = data.wallet(walletFor(raw.packageName));
    if (n == null || wallet == null || wallet.archived || wallet.currency.code != n.currency.code) {
      ignored++;
      continue;
    }
    final kind = n.incoming ? TxnKind.income : TxnKind.expense;
    final t = Txn(
      id: newId(),
      walletId: wallet.id,
      kind: kind,
      amount: n.amount,
      date: n.date ?? CivilDate.fromDateTime(raw.postedAt.toLocal()),
      note: n.description,
      categoryId: suggester.suggest(n.description, kind),
      source: source,
      pending: !autoConfirm,
    );
    final same = possibleDuplicates(t, [
      ...data.txns,
      ...out,
    ]).where((o) => o.source == TxnSource.notification && o.note == t.note);
    if (same.isNotEmpty) {
      duplicates++;
      continue;
    }
    out.add(t);
  }
  return NoticeImport(out, ignored: ignored, duplicates: duplicates);
}

/// Thư chuyển tiếp đã mở (JSON do Email Worker niêm phong: `{v, from, subject, date, text}`).
RawNotification? openedEmailToRaw(Uint8List plain, DateTime receivedAt) {
  try {
    final m = (jsonDecode(utf8.decode(plain)) as Map).cast<String, Object?>();
    if (m['v'] != 1) return null;
    return RawNotification(
      packageName: 'email:${m['from'] is String ? m['from'] : ''}',
      title: m['subject'] is String ? m['subject']! as String : '',
      text: m['text'] is String ? m['text']! as String : '',
      postedAt: receivedAt,
    );
  } on Object {
    return null;
  }
}

/// Xử lý một trang hộp thư: mở từng thư bằng [open] (lỗi ⇒ bỏ thư đó), đọc như thông báo ngân hàng, gửi vào ví
/// [walletId]. Trả giao dịch chờ xác nhận và id MỌI thư đã xử lý (kể cả thư không phải giao dịch) để xóa khỏi máy chủ.
(NoticeImport, List<String>) txnsFromInbox(
  List<Map<String, Object?>> items,
  Uint8List Function(Uint8List sealed) open,
  LedgerData data,
  String? walletId,
  String Function() newId, {
  bool autoConfirm = false,
}) {
  final raws = <RawNotification>[];
  final done = <String>[];
  var broken = 0;
  for (final it in items) {
    final id = it['id'];
    final sealed = it['sealed'];
    if (id is! String || sealed is! String) continue;
    done.add(id);
    try {
      final at = DateTime.fromMillisecondsSinceEpoch(it['received_at'] is int ? it['received_at']! as int : 0);
      final raw = openedEmailToRaw(open(base64.decode(sealed)), at);
      if (raw == null) {
        broken++;
      } else {
        raws.add(raw);
      }
    } on Object {
      broken++;
    }
  }
  final r = txnsFromNotifications(
    raws,
    data,
    (_) => walletId,
    newId,
    autoConfirm: autoConfirm,
    source: TxnSource.email,
  );
  return (NoticeImport(r.txns, ignored: r.ignored + broken, duplicates: r.duplicates), done);
}
