import 'pkce.dart';

/// Kết quả lượt đăng nhập: mã + tham số PKCE để đổi lấy token.
typedef LoginOutcome = ({LoginCallback callback, LoginRequest request, String platform});

Future<LoginOutcome> runSystemBrowserLogin(Uri server, {required String doneHtml}) =>
    throw UnsupportedError('Nền tảng không hỗ trợ');

/// Web: chuyển cả trang sang `/auth/web/start` (cookie phiên); không trả về.
Future<void> startWebLogin(Uri server) => throw UnsupportedError('Chỉ web');
