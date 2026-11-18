import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/capture.dart';
import '../services/capture_platform.dart';
import '../services/quick_links.dart';

/// Nhận dạng giọng nói (ghi đè trong test).
final voiceInputProvider = Provider<VoiceInput>((ref) => createVoiceInput());

/// Quét hóa đơn bằng OCR trên máy (ghi đè trong test).
final receiptScannerProvider = Provider<ReceiptScanner>((ref) => createReceiptScanner());

/// Bộ nghe liên kết ghi nhanh (widget/lối tắt) - ghi đè trong test (flutter test giả lập Android, không có plugin).
final quickLinksListenerProvider = Provider<QuickLinksListener>((ref) => listenQuickLinks);

/// Ghi nhanh được yêu cầu từ ngoài app (widget màn hình chính, lối tắt) - mở khi đã vào app và mở khóa.
final pendingQuickEntryProvider = NotifierProvider<PendingQuickEntry, String?>(PendingQuickEntry.new);

final class PendingQuickEntry extends Notifier<String?> {
  @override
  String? build() => null;

  /// [mode]: `type`, `voice`, `scan`.
  void request(String mode) => state = const {'type', 'voice', 'scan'}.contains(mode) ? mode : 'type';
  String? take() {
    final m = state;
    state = null;
    return m;
  }
}
