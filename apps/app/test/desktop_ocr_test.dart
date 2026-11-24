// ADR-0021: OCR desktop. Engine thật chạy ở integration_test/desktop_ocr_test.dart trên CI Windows/macOS/Linux; ở đây
// kiểm phần Dart: chọn ngôn ngữ, đối số Tesseract (không shell, đường dẫn tuyệt đối, ảnh qua stdin), hết giờ, trần ảnh.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulythuchi/services/capture.dart';
import 'package:qulythuchi/services/desktop_ocr.dart';

final class _FakeProcess implements Process {
  _FakeProcess(String out, {int code = 0, bool hang = false})
    : _code = hang ? Completer<int>().future : Future.value(code),
      stdout = Stream.value(utf8.encode(out));
  final Future<int> _code;
  final stdinBytes = BytesBuilder();
  bool killed = false;

  @override
  final Stream<List<int>> stdout;
  @override
  Stream<List<int>> get stderr => const Stream.empty();
  @override
  late final IOSink stdin = IOSink(_Collect(stdinBytes));
  @override
  Future<int> get exitCode => _code;
  @override
  int get pid => 1;
  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) => killed = true;
}

final class _Collect implements StreamConsumer<List<int>> {
  _Collect(this.b);
  final BytesBuilder b;
  @override
  Future<void> addStream(Stream<List<int>> s) => s.forEach(b.add);
  @override
  Future<void> close() async {}
}

void main() {
  test('chọn ngôn ngữ Tesseract: vie+eng > vie > eng > bất kỳ (trừ osd)', () {
    expect(TesseractOcrEngine.pickLanguages(['eng', 'osd', 'vie']), 'vie+eng');
    expect(TesseractOcrEngine.pickLanguages(['vie']), 'vie');
    expect(TesseractOcrEngine.pickLanguages(['eng', 'osd']), 'eng');
    expect(TesseractOcrEngine.pickLanguages(['osd', 'fra']), 'fra');
    expect(TesseractOcrEngine.pickLanguages(['osd']), isNull);
  });

  test('Tesseract: chỉ đường dẫn tuyệt đối cố định, không có ⇒ không hỗ trợ', () {
    final none = TesseractOcrEngine(exists: (_) => false);
    expect(none.available, isFalse);
    final local = TesseractOcrEngine(exists: (p) => p == '/usr/local/bin/tesseract');
    expect(local.executable, '/usr/local/bin/tesseract');
    expect(TesseractOcrEngine().candidates.every((c) => c.startsWith('/')), isTrue);
  });

  test('Tesseract: ảnh qua stdin, đối số cố định, trả văn bản', () async {
    final calls = <List<String>>[];
    final procs = <_FakeProcess>[];
    final e = TesseractOcrEngine(
      exists: (p) => p == '/usr/bin/tesseract',
      start: (exe, args) async {
        expect(exe, '/usr/bin/tesseract');
        calls.add(args);
        final p = args.first == '--list-langs'
            ? _FakeProcess(
                'List of available languages in "/usr/share/tesseract-ocr/5/tessdata/" (3):\neng\nosd\nvie\n',
              )
            : _FakeProcess('CUA HANG A\nTONG CONG 125.000\n');
        procs.add(p);
        return p;
      },
    );
    final img = Uint8List.fromList([1, 2, 3, 4]);
    expect(await e.recognize(img), contains('TONG CONG 125.000'));
    expect(calls, [
      ['--list-langs'],
      ['stdin', 'stdout', '-l', 'vie+eng', '--psm', '4'],
    ]);
    expect(procs.last.stdinBytes.takeBytes(), img);
    // Danh sách ngôn ngữ được đệm.
    await e.recognize(img);
    expect(calls.where((c) => c.first == '--list-langs'), hasLength(1));
  });

  test('Tesseract: không có ngôn ngữ ⇒ OcrUnavailable; mã thoát ≠ 0 ⇒ lỗi', () async {
    final noLang = TesseractOcrEngine(exists: (_) => true, start: (_, _) async => _FakeProcess('List:\nosd\n'));
    await expectLater(noLang.recognize(Uint8List(1)), throwsA(isA<OcrUnavailable>()));

    var n = 0;
    final bad = TesseractOcrEngine(
      exists: (_) => true,
      start: (_, _) async => n++ == 0 ? _FakeProcess('List:\neng\n') : _FakeProcess('', code: 1),
    );
    await expectLater(bad.recognize(Uint8List(1)), throwsA(isA<StateError>()));
  });

  test('Tesseract: quá thời gian ⇒ giết tiến trình', () async {
    late _FakeProcess hung;
    var n = 0;
    final e = TesseractOcrEngine(
      exists: (_) => true,
      timeout: const Duration(milliseconds: 50),
      start: (_, _) async => n++ == 0 ? _FakeProcess('List:\neng\n') : hung = _FakeProcess('', hang: true),
    );
    await expectLater(e.recognize(Uint8List(1)), throwsA(isA<TimeoutException>()));
    expect(hung.killed, isTrue);
  });

  group('DesktopReceiptScanner', () {
    final engine = _Engine();
    test('không camera, hủy chọn ⇒ null, không gọi engine', () async {
      final s = DesktopReceiptScanner(engine, pick: () async => null);
      expect(s.camera, isFalse);
      expect(s.supported, isTrue);
      expect(await s.scan(fromCamera: true), isNull);
      expect(engine.calls, 0);
    });

    test('ảnh hợp lệ ⇒ văn bản từ engine', () async {
      final img = Uint8List.fromList(List.filled(100, 7));
      final s = DesktopReceiptScanner(engine, pick: () async => XFile.fromData(img, mimeType: 'image/png'));
      final r = await s.scan(fromCamera: false);
      expect(r!.text, 'TONG CONG 125.000');
      expect(r.mimeType, 'image/png');
      expect(r.imageBytes, img);
    });

    test('ảnh > 25 MiB bị từ chối trước khi đọc/nhận dạng', () async {
      final before = engine.calls;
      final big = Uint8List(maxReceiptImageBytes + 1);
      final s = DesktopReceiptScanner(engine, pick: () async => XFile.fromData(big));
      await expectLater(s.scan(fromCamera: false), throwsA(isA<FormatException>()));
      expect(engine.calls, before);
    });

    test('engine không dùng được ⇒ nút ẩn', () {
      expect(DesktopReceiptScanner(TesseractOcrEngine(exists: (_) => false)).supported, isFalse);
    });
  });
}

final class _Engine implements OcrEngine {
  int calls = 0;
  @override
  bool get available => true;
  @override
  Future<String> recognize(Uint8List image) async {
    calls++;
    return 'TONG CONG 125.000';
  }
}
