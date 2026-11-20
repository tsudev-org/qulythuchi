import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:meta/meta.dart';

/// Lý do không nhận ảnh. Không chứa tên tệp hay nội dung (AGENTS.md B.5).
enum ImageRejectReason { tooLarge, tooManyPixels, unsupported }

final class ImageRejectedException implements Exception {
  const ImageRejectedException(this.reason);
  final ImageRejectReason reason;
  @override
  String toString() => 'ImageRejectedException(${reason.name})';
}

/// Ảnh đã làm sạch: JPEG mới mã hóa lại, không EXIF/GPS/XMP/ICC/chú thích (ADR-0017 mục 4).
@immutable
final class SanitizedImage {
  const SanitizedImage({required this.bytes, required this.width, required this.height});
  final Uint8List bytes;
  final int width;
  final int height;
  String get mime => 'image/jpeg';
}

/// Làm sạch + thu nhỏ ảnh TRƯỚC khi mã hóa. Hàm thuần, chạy được trong isolate (`compute`).
abstract final class ImageSanitizer {
  static const maxInputBytes = 25 * 1024 * 1024;
  static const maxPixels = 50 * 1000 * 1000;
  static const maxOutputBytes = 2 * 1024 * 1024;
  static const _edges = [2000, 1600, 1200];
  static const _qualities = [82, 72, 60];

  /// Ném [ImageRejectedException] khi ảnh quá lớn, quá nhiều điểm ảnh hoặc không đọc được.
  static SanitizedImage sanitize(Uint8List input) {
    if (input.length > maxInputBytes) throw const ImageRejectedException(ImageRejectReason.tooLarge);
    final decoder = img.findDecoderForData(input);
    if (decoder == null) throw const ImageRejectedException(ImageRejectReason.unsupported);
    // Đọc kích thước khai TRƯỚC khi giải mã toàn ảnh - chặn "bom giải nén".
    img.DecodeInfo? info;
    try {
      info = decoder.startDecode(input);
    } on Object {
      info = null; // đầu tệp hỏng hoặc khai vượt trần của thư viện
    }
    if (info == null) throw const ImageRejectedException(ImageRejectReason.unsupported);
    if (info.width <= 0 || info.height <= 0) throw const ImageRejectedException(ImageRejectReason.unsupported);
    if (info.width * info.height > maxPixels) throw const ImageRejectedException(ImageRejectReason.tooManyPixels);
    img.Image? decoded;
    try {
      decoded = decoder.decode(input, frame: 0);
    } on Object {
      decoded = null;
    }
    if (decoded == null) throw const ImageRejectedException(ImageRejectReason.unsupported);
    // Xoay theo EXIF Orientation rồi mới bỏ EXIF (không thì ảnh dọc thành ngang).
    final upright = img.bakeOrientation(decoded);
    Uint8List? out;
    var w = upright.width;
    var h = upright.height;
    for (final edge in _edges) {
      final scaled = _fit(upright, edge);
      _strip(scaled);
      w = scaled.width;
      h = scaled.height;
      for (final q in _qualities) {
        out = img.encodeJpg(scaled, quality: q);
        if (out.length <= maxOutputBytes) return SanitizedImage(bytes: out, width: w, height: h);
      }
    }
    if (out == null || out.length > maxOutputBytes) throw const ImageRejectedException(ImageRejectReason.tooLarge);
    return SanitizedImage(bytes: out, width: w, height: h);
  }

  static img.Image _fit(img.Image src, int edge) {
    final long = src.width > src.height ? src.width : src.height;
    if (long <= edge) return img.Image.from(src);
    return src.width >= src.height
        ? img.copyResize(src, width: edge, interpolation: img.Interpolation.average)
        : img.copyResize(src, height: edge, interpolation: img.Interpolation.average);
  }

  static void _strip(img.Image i) {
    i
      ..exif = img.ExifData()
      ..iccProfile = null
      ..textData = null;
  }
}
