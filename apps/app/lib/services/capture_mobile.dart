import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'capture.dart';

bool get mobileCaptureSupported =>
    !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

/// Nhận dạng giọng nói qua `speech_to_text`. Lượt đầu luôn đòi nhận dạng TRÊN MÁY (`onDevice`); máy không có gói
/// ngôn ngữ ngoại tuyến ⇒ [VoiceStatus.needsConsent], chỉ dùng dịch vụ HĐH khi người dùng đồng ý (ADR-0006).
final class MobileVoiceInput implements VoiceInput {
  final _stt = SpeechToText();
  bool? _ready;
  void Function(SpeechRecognitionError)? _onError;
  void Function(String)? _onStatus;

  @override
  bool get supported => mobileCaptureSupported;

  Future<bool> _init() async =>
      _ready ??= await _stt.initialize(onError: (e) => _onError?.call(e), onStatus: (s) => _onStatus?.call(s));

  @override
  Future<VoiceResult> listen({required String localeId, required bool allowOsService}) async {
    final bool ok;
    try {
      ok = await _init();
    } on Object {
      _ready = null;
      return const VoiceResult(VoiceStatus.unavailable);
    }
    if (!ok) {
      _ready = null;
      return VoiceResult(await _stt.hasPermission ? VoiceStatus.unavailable : VoiceStatus.denied);
    }
    final done = Completer<VoiceResult>();
    var words = '';
    _onError = (e) {
      if (done.isCompleted) return;
      final msg = e.errorMsg;
      if (msg.contains('permission')) {
        done.complete(const VoiceResult(VoiceStatus.denied));
      } else if (msg == 'error_no_match' || msg == 'error_speech_timeout') {
        done.complete(const VoiceResult(VoiceStatus.cancelled));
      } else if (!allowOsService) {
        // Không có bộ nhận dạng ngoại tuyến cho ngôn ngữ này (hoặc cần mạng) ⇒ hỏi người dùng.
        done.complete(const VoiceResult(VoiceStatus.needsConsent));
      } else {
        done.complete(const VoiceResult(VoiceStatus.unavailable));
      }
    };
    _onStatus = (s) {
      if ((s == SpeechToText.doneStatus || s == SpeechToText.notListeningStatus) && words.isNotEmpty) {
        if (!done.isCompleted) done.complete(VoiceResult(VoiceStatus.ok, words));
      }
    };
    try {
      await _stt.listen(
        listenOptions: SpeechListenOptions(
          localeId: localeId.replaceAll('-', '_'),
          listenFor: const Duration(seconds: 20),
          pauseFor: const Duration(seconds: 3),
          onDevice: !allowOsService,
          partialResults: false,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
        ),
        onResult: (r) {
          words = r.recognizedWords;
          if (r.finalResult && !done.isCompleted) done.complete(VoiceResult(VoiceStatus.ok, words));
        },
      );
    } on Object {
      if (!done.isCompleted) {
        done.complete(VoiceResult(allowOsService ? VoiceStatus.unavailable : VoiceStatus.needsConsent));
      }
    }
    return done.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () => words.isEmpty ? const VoiceResult(VoiceStatus.cancelled) : VoiceResult(VoiceStatus.ok, words),
    );
  }

  @override
  Future<void> stop() => _stt.stop();
}

/// Chụp/chọn ảnh hóa đơn rồi nhận dạng chữ bằng Google ML Kit (mô hình chữ Latinh đóng gói sẵn, chạy trên máy -
/// ảnh không rời thiết bị). Tệp ảnh tạm trong bộ nhớ đệm của app bị xóa ngay sau khi đọc.
final class MlKitReceiptScanner implements ReceiptScanner {
  final _picker = ImagePicker();

  @override
  bool get supported => mobileCaptureSupported;

  @override
  Future<ScannedReceipt?> scan({required bool fromCamera}) async {
    final x = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 85,
      requestFullMetadata: false,
    );
    if (x == null) return null;
    final recognizer = TextRecognizer();
    try {
      final r = await recognizer.processImage(InputImage.fromFilePath(x.path));
      final bytes = await x.readAsBytes();
      return ScannedReceipt(text: r.text, imageBytes: bytes, mimeType: x.mimeType ?? 'image/jpeg');
    } finally {
      await recognizer.close();
      try {
        await File(x.path).delete();
      } on Object {
        // Tệp đã bị HĐH dọn.
      }
    }
  }
}

VoiceInput createVoiceInput() => mobileCaptureSupported ? MobileVoiceInput() : const NoVoiceInput();
ReceiptScanner createReceiptScanner() => mobileCaptureSupported ? MlKitReceiptScanner() : const NoReceiptScanner();
