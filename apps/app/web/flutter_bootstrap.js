{{flutter_js}}
{{flutter_build_config}}

// Không đăng ký service worker: Flutter đã ngừng hỗ trợ cách nạp này, và bản lưu đệm offline-first làm người dùng kẹt
// ở bản cũ. CanvasKit tự phục vụ (build --no-web-resources-cdn); CSP ở <meta> của index.html.
_flutter.loader.load();
