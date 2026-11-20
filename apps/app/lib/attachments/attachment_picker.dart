import 'dart:typed_data';

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:image_picker/image_picker.dart';

import 'temp_file_stub.dart' if (dart.library.io) 'temp_file_io.dart';

enum AttachmentSource { camera, gallery }

/// Lấy byte ảnh do người dùng chọn. KHÔNG trả tên tệp (không lưu tên gốc - ADR-0017 mục 4).
abstract interface class AttachmentPicker {
  bool get supportsCamera;
  Future<Uint8List?> pick(AttachmentSource source);
}

final class ImagePickerAttachmentPicker implements AttachmentPicker {
  final _picker = ImagePicker();

  @override
  bool get supportsCamera =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<Uint8List?> pick(AttachmentSource source) async {
    final x = await _picker.pickImage(
      source: source == AttachmentSource.camera ? ImageSource.camera : ImageSource.gallery,
      // Thu nhỏ sơ bộ bằng mã gốc cho nhanh; làm sạch thật (bỏ EXIF/GPS) vẫn do ImageSanitizer.
      maxWidth: 2400,
      maxHeight: 2400,
      imageQuality: 92,
      requestFullMetadata: false,
    );
    if (x == null) return null;
    try {
      return await x.readAsBytes();
    } finally {
      if (supportsCamera) await deleteTempFile(x.path); // supportsCamera = Android/iOS
    }
  }
}
