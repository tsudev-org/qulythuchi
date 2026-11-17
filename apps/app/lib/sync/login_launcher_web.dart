import 'package:url_launcher/url_launcher.dart';

import 'pkce.dart';

typedef LoginOutcome = ({LoginCallback callback, LoginRequest request, String platform});

Future<LoginOutcome> runSystemBrowserLogin(Uri server, {required String doneHtml}) =>
    throw UnsupportedError('Web dùng startWebLogin');

/// Web (cùng gốc `qulythuchi.tsudev.com/app/`): máy chủ đặt cookie `__Host-qt_session` rồi quay lại `/app/`.
Future<void> startWebLogin(Uri server) async {
  await launchUrl(
    Uri(path: '/auth/web/start', queryParameters: {'return_to': '/app/'}),
    webOnlyWindowName: '_self',
  );
}
