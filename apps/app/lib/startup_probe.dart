// Đo khởi động desktop trên CI (LANGUAGE_SELECTION 5.1: tới cửa sổ dùng được ≤ 1 giây) - tool/do_khoi_dong.py.
export 'startup_probe_stub.dart' if (dart.library.io) 'startup_probe_io.dart';
