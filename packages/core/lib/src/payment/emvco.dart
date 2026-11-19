import 'package:meta/meta.dart';

import '../money/currency.dart';
import '../money/money.dart';
import 'vn_banks.dart';

/// Lỗi đọc mã QR thanh toán. [code] là mã máy (không chứa nội dung QR - có thể là dữ liệu tài chính).
final class PaymentQrException implements Exception {
  const PaymentQrException(this.code);

  /// `not_emv` (không phải QR EMVCo), `bad_tlv`, `bad_crc`, `too_long`.
  final String code;

  @override
  String toString() => 'PaymentQrException($code)';
}

/// Hệ QR thanh toán nhận ra từ GUID/AID của thông tin tài khoản người nhận.
enum PaymentQrScheme {
  /// VietQR (NAPAS 247), Việt Nam.
  vietQr,

  /// PromptPay, Thái Lan.
  promptPay,

  /// PayNow, Singapore.
  payNow,

  /// DuitNow, Malaysia.
  duitNow,

  /// QRIS, Indonesia.
  qris,

  /// QR Ph, Philippines.
  qrPh,

  /// KHQR (Bakong), Campuchia.
  khqr,

  /// UPI (Bharat QR), Ấn Độ.
  upi,

  /// QR EMVCo khác (thẻ quốc tế, ví...).
  other,
}

/// Một phần tử TLV EMVCo: thẻ 2 số, độ dài 2 số, giá trị.
@immutable
final class EmvTlv {
  const EmvTlv(this.tag, this.value);
  final String tag;
  final String value;
}

/// Đọc chuỗi TLV EMVCo. Ném [PaymentQrException] nếu sai cấu trúc.
List<EmvTlv> parseEmvTlv(String s) {
  final out = <EmvTlv>[];
  var i = 0;
  while (i < s.length) {
    if (i + 4 > s.length) throw const PaymentQrException('bad_tlv');
    final tag = s.substring(i, i + 2);
    final len = int.tryParse(s.substring(i + 2, i + 4));
    if (len == null || !RegExp(r'^\d\d$').hasMatch(tag) || i + 4 + len > s.length) {
      throw const PaymentQrException('bad_tlv');
    }
    out.add(EmvTlv(tag, s.substring(i + 4, i + 4 + len)));
    i += 4 + len;
  }
  return out;
}

/// CRC-16/CCITT-FALSE (đa thức 0x1021, khởi tạo 0xFFFF) theo EMVCo, trên mã UTF-8 của chuỗi; trả 4 ký tự hex HOA.
String emvCrc16(String data) {
  var crc = 0xFFFF;
  for (final b in _utf8(data)) {
    crc ^= b << 8;
    for (var k = 0; k < 8; k++) {
      crc = (crc & 0x8000) != 0 ? ((crc << 1) ^ 0x1021) & 0xFFFF : (crc << 1) & 0xFFFF;
    }
  }
  return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
}

List<int> _utf8(String s) {
  final out = <int>[];
  for (final r in s.runes) {
    if (r < 0x80) {
      out.add(r);
    } else if (r < 0x800) {
      out.addAll([0xC0 | (r >> 6), 0x80 | (r & 0x3F)]);
    } else if (r < 0x10000) {
      out.addAll([0xE0 | (r >> 12), 0x80 | ((r >> 6) & 0x3F), 0x80 | (r & 0x3F)]);
    } else {
      out.addAll([0xF0 | (r >> 18), 0x80 | ((r >> 12) & 0x3F), 0x80 | ((r >> 6) & 0x3F), 0x80 | (r & 0x3F)]);
    }
  }
  return out;
}

/// Độ dài TLV tính theo KÝ TỰ (EMVCo dùng ký tự; VietQR khuyến nghị chỉ dùng ASCII - xem [VietQr.build]).
String _tlv(String tag, String value) {
  if (value.length > 99) throw ArgumentError.value(value.length, tag, 'Giá trị TLV tối đa 99 ký tự');
  return '$tag${value.length.toString().padLeft(2, '0')}$value';
}

/// Nội dung một mã QR thanh toán EMVCo (Merchant-Presented Mode) đã đọc.
@immutable
final class PaymentQr {
  const PaymentQr({
    required this.raw,
    required this.scheme,
    required this.isDynamic,
    this.bankBin,
    this.accountNumber,
    this.isCard = false,
    this.currency,
    this.amount,
    this.merchantName,
    this.merchantCity,
    this.countryCode,
    this.message,
    this.billNumber,
    this.reference,
    this.categoryCode,
  });

  /// Chuỗi gốc (giữ để hiển thị lại mã cho app ngân hàng quét).
  final String raw;
  final PaymentQrScheme scheme;

  /// Mã động (`01 = 12`, thường kèm số tiền, dùng một lần) hay tĩnh (`11`).
  final bool isDynamic;

  /// VietQR: mã BIN ngân hàng người nhận.
  final String? bankBin;

  /// VietQR: số tài khoản/số thẻ người nhận. Hệ khác: định danh (số điện thoại, UEN...) nếu đọc được.
  final String? accountNumber;

  /// VietQR: định danh là số thẻ (`QRIBFTTC`) thay vì số tài khoản (`QRIBFTTA`).
  final bool isCard;

  /// Tiền tệ (thẻ 53, mã số ISO 4217). Null nếu mã không ghi hoặc mã số lạ.
  final Currency? currency;

  /// Số tiền (thẻ 54) theo đơn vị nhỏ nhất của [currency]. Null = người trả tự nhập.
  final Money? amount;
  final String? merchantName;
  final String? merchantCity;
  final String? countryCode;

  /// Nội dung chuyển khoản/mục đích (thẻ 62.08).
  final String? message;
  final String? billNumber;
  final String? reference;

  /// Mã ngành hàng MCC (thẻ 52).
  final String? categoryCode;

  VnBank? get bank => bankBin == null ? null : VnBank.byBin(bankBin!);

  /// Tên người nhận nên hiển thị: tên đơn vị/cửa hàng, hoặc ngân hàng + số tài khoản.
  String? get payeeLabel {
    if (merchantName != null && merchantName!.isNotEmpty) return merchantName;
    if (accountNumber == null) return null;
    final b = bank?.shortName;
    return b == null ? accountNumber : '$b $accountNumber';
  }

  /// Đọc một mã QR. [s] là nội dung văn bản của mã. Kiểm CRC khi có thẻ 63 (bắt buộc theo EMVCo).
  static PaymentQr parse(String s) {
    final text = s.trim();
    if (text.length > 512) throw const PaymentQrException('too_long');
    if (!text.startsWith('000201')) throw const PaymentQrException('not_emv');
    final top = parseEmvTlv(text);
    final crcIndex = text.lastIndexOf('6304');
    final crc = _first(top, '63');
    if (crc == null || crcIndex < 0 || crcIndex + 8 != text.length) throw const PaymentQrException('bad_crc');
    if (emvCrc16(text.substring(0, crcIndex + 4)) != crc.toUpperCase()) throw const PaymentQrException('bad_crc');

    var scheme = PaymentQrScheme.other;
    String? bin, account;
    var card = false;
    for (final t in top) {
      final n = int.parse(t.tag);
      if (n < 26 || n > 51) continue;
      List<EmvTlv> sub;
      try {
        sub = parseEmvTlv(t.value);
      } on PaymentQrException {
        continue;
      }
      final guid = (_first(sub, '00') ?? '').toUpperCase();
      if (guid == 'A000000727') {
        scheme = PaymentQrScheme.vietQr;
        final beneficiary = _first(sub, '01');
        if (beneficiary != null) {
          try {
            final b = parseEmvTlv(beneficiary);
            bin = _first(b, '00');
            account = _first(b, '01');
          } on PaymentQrException {
            // Bỏ qua phần lỗi, vẫn trả các trường khác.
          }
        }
        card = _first(sub, '02') == 'QRIBFTTC';
        break;
      }
      final s2 = switch (guid) {
        'A000000677010111' || 'A000000677010112' || 'A000000677010113' => PaymentQrScheme.promptPay,
        'SG.PAYNOW' => PaymentQrScheme.payNow,
        'A0000006150001' || 'MY.COM.PAYNET' => PaymentQrScheme.duitNow,
        'ID.CO.QRIS.WWW' => PaymentQrScheme.qris,
        'COM.P2PQRPAY' || 'PH.PPMI.P2M' => PaymentQrScheme.qrPh,
        'KHQR' || 'BAKONG' => PaymentQrScheme.khqr,
        'A000000524' => PaymentQrScheme.upi,
        _ => null,
      };
      if (s2 != null && scheme == PaymentQrScheme.other) {
        scheme = s2;
        account ??= _first(sub, '01') ?? _first(sub, '02');
      }
    }

    final currencyNum = int.tryParse(_first(top, '53') ?? '');
    var currency = currencyNum == null ? null : Currency.byNumeric(currencyNum);
    final country = _first(top, '58');
    if (currency == null && scheme == PaymentQrScheme.vietQr) currency = Currency.vnd;
    Money? amount;
    final amountText = _first(top, '54');
    if (amountText != null && currency != null) amount = _parseAmount(amountText, currency);

    String? message, bill, ref;
    final add = _first(top, '62');
    if (add != null) {
      try {
        final a = parseEmvTlv(add);
        message = _first(a, '08');
        bill = _first(a, '01');
        ref = _first(a, '05');
      } on PaymentQrException {
        // Thẻ bổ sung lỗi: bỏ qua.
      }
    }
    return PaymentQr(
      raw: text,
      scheme: scheme,
      isDynamic: _first(top, '01') == '12',
      bankBin: bin,
      accountNumber: account,
      isCard: card,
      currency: currency,
      amount: amount,
      merchantName: _first(top, '59'),
      merchantCity: _first(top, '60'),
      countryCode: country,
      message: message,
      billNumber: bill,
      reference: ref,
      categoryCode: _first(top, '52'),
    );
  }

  static String? _first(List<EmvTlv> l, String tag) {
    for (final t in l) {
      if (t.tag == tag) return t.value;
    }
    return null;
  }

  /// Số tiền EMVCo: chữ số với dấu chấm thập phân tùy chọn ("50000", "12.5"). Không dùng double.
  static Money? _parseAmount(String s, Currency c) {
    final m = RegExp(r'^(\d{1,13})(?:\.(\d{0,4}))?$').firstMatch(s.trim());
    if (m == null) return null;
    var frac = m.group(2) ?? '';
    if (frac.length > c.minorDigits) {
      // Chữ số thừa phải là 0, nếu không thì mã sai - không làm tròn tiền.
      if (frac.substring(c.minorDigits).replaceAll('0', '').isNotEmpty) return null;
      frac = frac.substring(0, c.minorDigits);
    }
    final padded = frac.padRight(c.minorDigits, '0');
    final minor = int.parse(m.group(1)!) * _pow10(c.minorDigits) + (padded.isEmpty ? 0 : int.parse(padded));
    return Money(minor, c);
  }
}

int _pow10(int n) {
  var r = 1;
  for (var i = 0; i < n; i++) {
    r *= 10;
  }
  return r;
}

/// Tạo mã VietQR (chuẩn NAPAS dựa trên EMVCo) để NHẬN tiền vào tài khoản của mình.
abstract final class VietQr {
  /// Bỏ dấu tiếng Việt và ký tự ngoài ASCII in được (nhiều app ngân hàng chỉ nhận ASCII trong nội dung).
  static String asciiOnly(String s) {
    const from = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const to = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    final out = StringBuffer();
    for (final ch in s.runes.map(String.fromCharCode)) {
      final lower = ch.toLowerCase();
      final i = from.indexOf(lower);
      final c = i >= 0 ? (lower == ch ? to[i] : to[i].toUpperCase()) : ch;
      final code = c.codeUnitAt(0);
      if (code >= 0x20 && code < 0x7F) out.write(c);
    }
    return out.toString();
  }

  /// [bin] 6 số, [account] tối đa 19 ký tự chữ-số. [amount] VND (null = người trả tự nhập ⇒ mã tĩnh).
  /// [message] tự bỏ dấu, cắt 25 ký tự (giới hạn của nhiều ngân hàng).
  static String build({required String bin, required String account, int? amount, String? message, bool card = false}) {
    if (!RegExp(r'^\d{6}$').hasMatch(bin)) throw ArgumentError.value(bin, 'bin', 'BIN phải 6 chữ số');
    if (!RegExp(r'^[0-9A-Za-z]{1,19}$').hasMatch(account)) {
      throw ArgumentError.value(account, 'account', 'Số tài khoản 1-19 ký tự chữ-số');
    }
    if (amount != null && (amount <= 0 || amount > 9999999999999)) {
      throw ArgumentError.value(amount, 'amount', 'Số tiền không hợp lệ');
    }
    final beneficiary = _tlv('00', bin) + _tlv('01', account);
    final merchant = _tlv('00', 'A000000727') + _tlv('01', beneficiary) + _tlv('02', card ? 'QRIBFTTC' : 'QRIBFTTA');
    var msg = message == null ? '' : asciiOnly(message).trim();
    if (msg.length > 25) msg = msg.substring(0, 25);
    final b = StringBuffer()
      ..write(_tlv('00', '01'))
      ..write(_tlv('01', amount == null ? '11' : '12'))
      ..write(_tlv('38', merchant))
      ..write(_tlv('53', '704'));
    if (amount != null) b.write(_tlv('54', '$amount'));
    b.write(_tlv('58', 'VN'));
    if (msg.isNotEmpty) b.write(_tlv('62', _tlv('08', msg)));
    b.write('6304');
    final body = b.toString();
    return body + emvCrc16(body);
  }

  /// Liên kết mở app ngân hàng [appId] với lệnh chuyển điền sẵn (dịch vụ dl.vietqr.io của bên thứ ba - CHỈ gọi khi
  /// người dùng đồng ý, xem ADR-0014). Trả null nếu thiếu BIN/tài khoản.
  static Uri? bankAppLink(PaymentQr qr, String appId) {
    if (qr.scheme != PaymentQrScheme.vietQr || qr.bankBin == null || qr.accountNumber == null) return null;
    return Uri.https('dl.vietqr.io', '/pay', {
      'app': appId,
      'ba': '${qr.accountNumber}@${qr.bankBin}',
      if (qr.amount != null && qr.amount!.currency.code == 'VND') 'am': '${qr.amount!.minor}',
      if (qr.message != null && qr.message!.isNotEmpty) 'tn': qr.message!,
    });
  }
}
