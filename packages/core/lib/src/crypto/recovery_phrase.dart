import 'dart:typed_data';

import 'package:crypto/crypto.dart' show sha256;

import 'bip39_english.dart';

/// Cụm 24 từ không hợp lệ (sai từ, sai số lượng, sai tổng kiểm).
final class RecoveryPhraseException implements Exception {
  const RecoveryPhraseException(this.reason);
  final String reason;
  @override
  String toString() => 'RecoveryPhraseException: $reason';
}

/// Khóa khôi phục: 256 bit entropy ⇄ 24 từ BIP39 tiếng Anh (8 bit tổng kiểm SHA-256).
abstract final class RecoveryPhrase {
  static const wordCount = 24;
  static const entropyBytes = 32;
  static final Map<String, int> _index = {for (var i = 0; i < bip39English.length; i++) bip39English[i]: i};

  static List<String> fromEntropy(Uint8List entropy) {
    if (entropy.length != entropyBytes) throw ArgumentError('Entropy phải 32 byte');
    final checksum = sha256.convert(entropy).bytes[0];
    final bits = StringBuffer();
    for (final b in entropy) {
      bits.write(b.toRadixString(2).padLeft(8, '0'));
    }
    bits.write(checksum.toRadixString(2).padLeft(8, '0'));
    final s = bits.toString();
    return [for (var i = 0; i < wordCount; i++) bip39English[int.parse(s.substring(i * 11, i * 11 + 11), radix: 2)]];
  }

  /// Chuẩn hóa đầu vào người dùng (khoảng trắng thừa, chữ hoa) rồi tách từ.
  static List<String> normalize(String input) =>
      input.trim().toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

  static Uint8List toEntropy(List<String> words) {
    if (words.length != wordCount) throw const RecoveryPhraseException('Cần đúng 24 từ');
    final bits = StringBuffer();
    for (final w in words) {
      final i = _index[w];
      if (i == null) throw RecoveryPhraseException('Từ không có trong từ điển: vị trí ${words.indexOf(w) + 1}');
      bits.write(i.toRadixString(2).padLeft(11, '0'));
    }
    final s = bits.toString();
    final entropy = Uint8List(entropyBytes);
    for (var i = 0; i < entropyBytes; i++) {
      entropy[i] = int.parse(s.substring(i * 8, i * 8 + 8), radix: 2);
    }
    final checksum = int.parse(s.substring(256, 264), radix: 2);
    if (sha256.convert(entropy).bytes[0] != checksum) {
      throw const RecoveryPhraseException('Sai tổng kiểm - kiểm lại thứ tự và chính tả');
    }
    return entropy;
  }
}
