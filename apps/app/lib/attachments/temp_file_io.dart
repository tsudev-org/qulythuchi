import 'dart:io';

/// Xóa bản sao tạm `image_picker` để trong bộ nhớ đệm app (ảnh gốc CÒN EXIF/GPS - không giữ lại).
/// CHỈ gọi trên Android/iOS: ở đó picker luôn chép ảnh vào thư mục đệm của app. Trên desktop đường dẫn là tệp gốc
/// của người dùng - không bao giờ xóa.
Future<void> deleteTempFile(String path) async {
  try {
    await File(path).delete();
  } on Object {
    // Hệ điều hành đã dọn.
  }
}
