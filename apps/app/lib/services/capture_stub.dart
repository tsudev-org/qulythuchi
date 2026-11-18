import 'capture.dart';

// Web: không có OCR/giọng nói trên máy (Web Speech API gửi âm thanh lên máy chủ của trình duyệt - không dùng).
VoiceInput createVoiceInput() => const NoVoiceInput();
ReceiptScanner createReceiptScanner() => const NoReceiptScanner();
