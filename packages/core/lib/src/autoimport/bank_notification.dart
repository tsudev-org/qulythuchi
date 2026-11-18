import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

import '../domain/civil_date.dart';
import '../money/currency.dart';
import 'vn_text.dart';

/// App ngân hàng/ví điện tử Việt Nam đã biết (gói Android ⇒ tên hiển thị). Chỉ dùng để gợi ý và gắn nhãn;
/// người dùng tự chọn app nào được nghe, kể cả app không có trong danh sách.
const knownBankApps = <String, String>{
  'com.VCB': 'Vietcombank',
  'vn.com.techcombank.bb.app': 'Techcombank',
  'com.mbmobile': 'MB Bank',
  'com.vnpay.bidv': 'BIDV SmartBanking',
  'com.vietinbank.ipay': 'VietinBank iPay',
  'mobile.acb.com.vn': 'ACB ONE',
  'com.tpb.mb.gprsandroid': 'TPBank Mobile',
  'com.mservice.momo': 'MoMo',
  'vn.com.vng.zalopay': 'ZaloPay',
};

/// Giao dịch đọc được từ một thông báo biến động số dư.
@immutable
final class BankNotice {
  const BankNotice({
    required this.incoming,
    required this.amount,
    required this.currency,
    required this.fingerprint,
    this.balanceAfter,
    this.accountTail,
    this.date,
    this.description,
  });

  /// true: tiền vào (ghi có); false: tiền ra (ghi nợ).
  final bool incoming;

  /// Đơn vị nhỏ nhất của [currency], dương.
  final int amount;
  final Currency currency;
  final int? balanceAfter;

  /// Tối đa 4 ký tự cuối số tài khoản/thẻ (để gợi ý ví), không giữ số đầy đủ.
  final String? accountTail;
  final CivilDate? date;

  /// Nội dung chuyển khoản (đã cắt 200 ký tự).
  final String? description;

  /// Dấu vân tay chống trùng (ngân hàng hay đăng lại cùng một thông báo).
  final String fingerprint;
}

final _signedAmount = RegExp(
  r'(?:^|[\s:(])([+-])\s?((?:\d{1,3}(?:[.,]\d{3})+|\d+)(?:[.,]\d{1,2})?)\s*(VND|VNĐ|đ|USD|EUR)?',
  caseSensitive: false,
);
final _labelledAmount = RegExp(
  r'\b(?:so tien(?: gd| giao dich)?|ps|gd|giao dich|amount|bien dong)\s*[:=]?\s*([+-]?)\s?((?:\d{1,3}(?:[.,]\d{3})+|\d+)(?:[.,]\d{1,2})?)\s*(vnd|d|usd|eur)?',
);
final _plainAmount = RegExp(r'((?:\d{1,3}(?:[.,]\d{3})+|\d+)(?:[.,]\d{1,2})?)\s*(vnd|d|usd|eur)\b');
final _balance = RegExp(
  r'\b(?:so du(?: cuoi| kha dung| hien tai)?|sd(?:c|kd)?|balance|avail(?:able)? bal)\s*[:=]?\s*((?:\d{1,3}(?:[.,]\d{3})+|\d+)(?:[.,]\d{1,2})?)',
);
final _account = RegExp(r'\b(?:tk|tai khoan|the|acc(?:ount)?|so tk)\s*[:.]?\s*(?:[a-z]{2,6}\s+)?([0-9x*.]{3,24})');
final _description = RegExp(
  r'\b(?:noi dung|nd(?: gd)?|ndck|mo ta|dien giai|description|ly do|content|memo)\s*[:=]\s*(.+)$',
  multiLine: true,
);
final _date = RegExp(r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{2,4})');
final _otp = RegExp(r'\b(otp|ma xac thuc|ma xac nhan|verification code|mat khau)\b');
final _incomingWords = RegExp(r'\b(ghi co|nhan(?: duoc)?|tang|cong|credit|received|hoan tien|tien vao)\b');
final _outgoingWords = RegExp(r'\b(ghi no|giam|tru|thanh toan|chuyen tien di|da chuyen|debit|rut tien|tien ra|chi)\b');

/// Đọc một thông báo biến động số dư (tiêu đề + nội dung). Thông báo không phải giao dịch (OTP, khuyến mãi, không
/// có số tiền/chiều tiền) ⇒ null. Bộ đọc chung theo nhãn phổ biến ("+50,000VND", "PS: -1.000.000", "SD:", "ND:"),
/// không phụ thuộc mẫu riêng của từng ngân hàng để chịu được thay đổi định dạng nhỏ.
BankNotice? parseBankNotification({required String packageName, required String title, required String text}) {
  final raw = unorm.nfc('$title\n$text'.replaceAll('\r', ''));
  // Cùng độ dài với [raw] để cắt nội dung chuyển khoản từ chuỗi gốc còn dấu.
  final folded = foldViSameLength(raw).replaceAll(RegExp(r'[ \t]'), ' ');
  if (_otp.hasMatch(folded)) return null;

  String? sign;
  String? number;
  String? cur;
  // Ưu tiên số có nhãn ("PS", "Số tiền GD"), rồi tới số có dấu +/- đầu tiên không phải số dư.
  final labelled = _labelledAmount.firstMatch(folded);
  if (labelled != null) {
    sign = labelled.group(1)!.isEmpty ? null : labelled.group(1);
    number = labelled.group(2);
    cur = labelled.group(3);
  }
  if (number == null || sign == null) {
    for (final m in _signedAmount.allMatches(folded)) {
      final before = folded.substring(0, m.start);
      if (RegExp(r'(so du|sd|balance)\s*[:=]?\s*$').hasMatch(before)) continue;
      sign = m.group(1);
      number = m.group(2);
      cur = m.group(3);
      break;
    }
  }
  if (number == null) {
    // Ví điện tử: "Bạn vừa nhận 100.000đ" - số không dấu nhưng có đơn vị tiền; chiều tiền lấy từ từ khóa.
    for (final m in _plainAmount.allMatches(folded)) {
      final before = folded.substring(0, m.start);
      if (RegExp(r'(so du|sd|balance)\s*[:=]?\s*$').hasMatch(before)) continue;
      number = m.group(1);
      cur = m.group(2);
      break;
    }
  }
  if (number == null) return null;

  bool? incoming;
  if (sign != null) {
    incoming = sign == '+';
  } else if (_incomingWords.hasMatch(folded) && !_outgoingWords.hasMatch(folded)) {
    incoming = true;
  } else if (_outgoingWords.hasMatch(folded) && !_incomingWords.hasMatch(folded)) {
    incoming = false;
  }
  if (incoming == null) return null;

  final currency = switch (cur?.toUpperCase()) {
    'USD' => Currency.of('USD'),
    'EUR' => Currency.of('EUR'),
    _ => Currency.vnd,
  };
  final amount = parseAmountText(number, currency)?.abs();
  if (amount == null || amount == 0) return null;

  final bal = _balance.firstMatch(folded);
  final balanceAfter = bal == null ? null : parseAmountText(bal.group(1)!, currency);
  final acc = _account.firstMatch(folded);
  String? tail;
  if (acc != null) {
    final digits = acc.group(1)!.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 3) tail = digits.substring(digits.length > 4 ? digits.length - 4 : 0);
  }
  CivilDate? date;
  final dm = _date.firstMatch(folded);
  if (dm != null) date = parseDateText(dm.group(0)!);

  // Nội dung lấy từ chuỗi gốc (giữ dấu) theo cùng vị trí; dừng ở dòng kết thúc hoặc nhãn kế tiếp ("SD:").
  String? description;
  final dm2 = _description.firstMatch(folded);
  if (dm2 != null && raw.length == folded.length) {
    var value = raw.substring(dm2.end - dm2.group(1)!.length, dm2.end);
    final next = RegExp(r'\s(?:sd|so du|luc|time)\s*[:=]', caseSensitive: false).firstMatch(foldViSameLength(value));
    if (next != null) value = value.substring(0, next.start);
    value = value.trim().replaceFirst(RegExp(r'[.;,]$'), '');
    if (value.isNotEmpty) description = value.length > 200 ? value.substring(0, 200) : value;
  }

  final fp = sha256
      .convert(utf8.encode([packageName, incoming, amount, currency.code, balanceAfter, tail, folded.trim()].join('|')))
      .toString()
      .substring(0, 32);
  return BankNotice(
    incoming: incoming,
    amount: amount,
    currency: currency,
    balanceAfter: balanceAfter,
    accountTail: tail,
    date: date,
    description: description,
    fingerprint: fp,
  );
}
