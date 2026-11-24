// ADR-0021: chạy ENGINE OCR THẬT của desktop (Windows.Media.Ocr / Vision / Tesseract hệ thống) trên CI.
// Vẽ một hóa đơn bằng font Inter đóng gói, nhận dạng, rồi đưa qua bộ đọc hóa đơn của lõi như app làm.
//   flutter test integration_test/desktop_ocr_test.dart -d windows|macos|linux
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:qulythuchi/services/desktop_ocr.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

Future<Uint8List> _receiptPng() async {
  const lines = ['CUA HANG MINH AN', 'Ca phe sua 2 x 30.000', 'TONG CONG 125.000'];
  const w = 1400.0, lineH = 110.0;
  final rec = ui.PictureRecorder();
  final c = Canvas(rec)..drawRect(const Rect.fromLTWH(0, 0, w, lineH * 3 + 80), Paint()..color = Colors.white);
  for (var i = 0; i < lines.length; i++) {
    final tp = TextPainter(
      text: TextSpan(
        text: lines[i],
        style: const TextStyle(fontFamily: 'Inter', fontSize: 64, color: Colors.black),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(60, 40 + i * lineH));
  }
  final img = await rec.endRecording().toImage(w.toInt(), (lineH * 3 + 80).toInt());
  final png = await img.toByteData(format: ui.ImageByteFormat.png);
  return png!.buffer.asUint8List();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('OCR desktop thật đọc được tổng tiền hóa đơn', (t) async {
    await t.pumpWidget(const MaterialApp(home: SizedBox()));
    final engine = createDesktopOcrEngine();
    expect(engine.available, isTrue, reason: 'máy CI phải có engine OCR (Linux: tesseract-ocr)');
    final png = await t.runAsync(_receiptPng);
    final text = (await t.runAsync(() => engine.recognize(png!)))!;
    // In ra để ghi vào ADR-0021 (văn bản thử, không phải dữ liệu người dùng).
    debugPrint('OCR_TEXT<<<\n$text\n>>>');
    expect(parseReceiptText(text).total, 125000, reason: text);
  });
}
