import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb, visibleForTesting;
import 'package:flutter/services.dart';

import 'capture.dart';

/// Nhận dạng chữ trên ảnh, chạy TRÊN MÁY (ADR-0021). Trả văn bản, mỗi dòng một dòng.
abstract interface class OcrEngine {
  bool get available;
  Future<String> recognize(Uint8List image);
}

/// Windows (`Windows.Media.Ocr`) và macOS (Vision) - mã native trong runner, kênh `com.tsudev.qulythuchi/ocr`.
final class ChannelOcrEngine implements OcrEngine {
  const ChannelOcrEngine();
  static const channel = MethodChannel('com.tsudev.qulythuchi/ocr');

  @override
  bool get available => true;

  @override
  Future<String> recognize(Uint8List image) async {
    try {
      return await channel.invokeMethod<String>('recognize', image) ?? '';
    } on PlatformException catch (e) {
      if (e.code == 'no_language') throw const OcrUnavailable('no_language');
      rethrow;
    } on MissingPluginException {
      throw const OcrUnavailable('no_engine');
    }
  }
}

/// Chạy tiến trình (thay được trong test).
typedef ProcessStarter = Future<Process> Function(String exe, List<String> args);

/// Linux: Tesseract của bản phân phối, gọi bằng đường dẫn tuyệt đối (không tra PATH), không qua shell, ảnh qua stdin.
final class TesseractOcrEngine implements OcrEngine {
  TesseractOcrEngine({
    this.candidates = const ['/usr/bin/tesseract', '/usr/local/bin/tesseract'],
    ProcessStarter? start,
    bool Function(String path)? exists,
    this.timeout = const Duration(seconds: 60),
  }) : _start = start ?? ((exe, args) => Process.start(exe, args, runInShell: false)),
       _exists = exists ?? ((p) => File(p).existsSync());

  final List<String> candidates;
  final ProcessStarter _start;
  final bool Function(String path) _exists;
  final Duration timeout;
  List<String>? _langs;

  String? get executable {
    for (final c in candidates) {
      if (_exists(c)) return c;
    }
    return null;
  }

  @override
  bool get available => executable != null;

  /// `vie+eng` khi có cả hai, rồi `vie`, `eng`, cuối cùng ngôn ngữ đầu tiên đã cài.
  @visibleForTesting
  static String? pickLanguages(List<String> installed) {
    final has = installed.toSet();
    if (has.contains('vie') && has.contains('eng')) return 'vie+eng';
    if (has.contains('vie')) return 'vie';
    if (has.contains('eng')) return 'eng';
    return installed.where((l) => l != 'osd').firstOrNull;
  }

  Future<({int code, String out})> _run(List<String> args, [Uint8List? stdinBytes]) async {
    final exe = executable;
    if (exe == null) throw const OcrUnavailable('no_engine');
    final p = await _start(exe, args);
    final out = p.stdout.transform(utf8.decoder).join();
    final err = p.stderr.drain<void>();
    if (stdinBytes != null) p.stdin.add(stdinBytes);
    await p.stdin.close();
    try {
      final code = await p.exitCode.timeout(timeout);
      await err;
      return (code: code, out: await out);
    } on TimeoutException {
      p.kill(ProcessSignal.sigkill);
      rethrow;
    }
  }

  Future<List<String>> _installed() async {
    if (_langs != null) return _langs!;
    final r = await _run(const ['--list-langs']);
    // Dòng đầu là "List of available languages in ...:".
    final langs = const LineSplitter().convert(r.out).skip(1).map((l) => l.trim()).where((l) => l.isNotEmpty);
    return _langs = langs.toList();
  }

  @override
  Future<String> recognize(Uint8List image) async {
    final lang = pickLanguages(await _installed());
    if (lang == null) throw const OcrUnavailable('no_language');
    final r = await _run(['stdin', 'stdout', '-l', lang, '--psm', '4'], image);
    if (r.code != 0) throw StateError('tesseract exit ${r.code}');
    return r.out;
  }
}

/// Chọn tệp ảnh (thay được trong test). null = người dùng hủy.
typedef ImageFilePicker = Future<XFile?> Function();

Future<XFile?> _pickImageFile() => openFile(
  acceptedTypeGroups: [
    XTypeGroup(
      label: 'images',
      extensions: [
        'jpg',
        'jpeg',
        'png',
        if (defaultTargetPlatform != TargetPlatform.linux) ...['bmp', 'webp'],
        if (defaultTargetPlatform == TargetPlatform.macOS) 'heic',
      ],
      uniformTypeIdentifiers: const ['public.jpeg', 'public.png', 'public.heic', 'org.webmproject.webp'],
    ),
  ],
);

/// Trần kích thước ảnh vào, cùng trần `ImageSanitizer` (ADR-0017).
const maxReceiptImageBytes = 25 * 1024 * 1024;

/// Desktop: chọn tệp ảnh hóa đơn rồi nhận dạng bằng engine trên máy. Ảnh chỉ nằm trong bộ nhớ, không ghi tệp tạm.
final class DesktopReceiptScanner implements ReceiptScanner {
  DesktopReceiptScanner(this.engine, {ImageFilePicker? pick}) : _pick = pick ?? _pickImageFile;
  final OcrEngine engine;
  final ImageFilePicker _pick;

  @override
  bool get supported => engine.available;

  @override
  bool get camera => false;

  @override
  Future<ScannedReceipt?> scan({required bool fromCamera}) async {
    final f = await _pick();
    if (f == null) return null;
    if (await f.length() > maxReceiptImageBytes) throw const FormatException('image too large');
    final bytes = await f.readAsBytes();
    final text = await engine.recognize(bytes);
    return ScannedReceipt(text: text, imageBytes: bytes, mimeType: f.mimeType ?? 'image/jpeg');
  }
}

bool get desktopOcrPlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux);

OcrEngine createDesktopOcrEngine() =>
    defaultTargetPlatform == TargetPlatform.linux ? TesseractOcrEngine() : const ChannelOcrEngine();
