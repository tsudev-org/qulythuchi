import 'package:flutter/foundation.dart' show immutable;

/// Kết quả thử nghe giọng nói.
enum VoiceStatus { ok, unavailable, denied, needsConsent, cancelled }

@immutable
final class VoiceResult {
  const VoiceResult(this.status, [this.text]);
  final VoiceStatus status;
  final String? text;
}

/// Nhận dạng giọng nói. Mặc định CHỈ nhận dạng trên máy; khi nền tảng không có bộ nhận dạng trên máy, trả
/// [VoiceStatus.needsConsent] để giao diện hỏi người dùng có đồng ý dùng dịch vụ nhận dạng của hệ điều hành (có thể
/// gửi âm thanh tới nhà cung cấp HĐH) hay không - ADR-0006.
abstract interface class VoiceInput {
  bool get supported;
  Future<VoiceResult> listen({required String localeId, required bool allowOsService});
  Future<void> stop();
}

final class NoVoiceInput implements VoiceInput {
  const NoVoiceInput();
  @override
  bool get supported => false;
  @override
  Future<VoiceResult> listen({required String localeId, required bool allowOsService}) async =>
      const VoiceResult(VoiceStatus.unavailable);
  @override
  Future<void> stop() async {}
}

/// Ảnh hóa đơn đã chụp + văn bản OCR (nhận dạng TRÊN MÁY, ảnh không rời thiết bị).
@immutable
final class ScannedReceipt {
  const ScannedReceipt({required this.text, required this.imageBytes, required this.mimeType});
  final String text;
  final List<int> imageBytes;
  final String mimeType;
}

/// Engine OCR không dùng được trên máy này: `no_language` (Windows chưa cài gói ngôn ngữ có nhận dạng chữ) hoặc
/// `no_engine` (Linux thiếu Tesseract) - ADR-0021.
final class OcrUnavailable implements Exception {
  const OcrUnavailable(this.reason);
  final String reason;
  @override
  String toString() => 'OcrUnavailable($reason)';
}

abstract interface class ReceiptScanner {
  bool get supported;

  /// Có camera để chụp (điện thoại). Desktop chỉ chọn tệp ảnh (ADR-0021).
  bool get camera;

  /// null = người dùng hủy. [fromCamera] false ⇒ chọn từ thư viện ảnh.
  Future<ScannedReceipt?> scan({required bool fromCamera});
}

final class NoReceiptScanner implements ReceiptScanner {
  const NoReceiptScanner();
  @override
  bool get supported => false;
  @override
  bool get camera => false;
  @override
  Future<ScannedReceipt?> scan({required bool fromCamera}) async => null;
}
