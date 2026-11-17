import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';

import 'loopback_login.dart';
import 'pkce.dart';

typedef LoginOutcome = ({LoginCallback callback, LoginRequest request, String platform});

String get _platform => Platform.isAndroid
    ? 'android'
    : Platform.isIOS
    ? 'ios'
    : Platform.isMacOS
    ? 'macos'
    : Platform.isWindows
    ? 'windows'
    : 'linux';

/// Mở trang đăng nhập bằng TRÌNH DUYỆT HỆ THỐNG (không WebView - ADR-0003) và chờ mã quay về:
/// di động qua `com.tsudev.qulythuchi:/auth/callback`, máy tính qua vòng lặp 127.0.0.1.
Future<LoginOutcome> runSystemBrowserLogin(Uri server, {required String doneHtml}) async {
  if (Platform.isAndroid || Platform.isIOS) return _mobile(server);
  final loop = await LoopbackLogin.start();
  if (!await launchUrl(loop.request.startUrl(server), mode: LaunchMode.externalApplication)) {
    await loop.close();
    return (callback: const LoginCallback.failed('no_browser'), request: loop.request, platform: _platform);
  }
  return (callback: await loop.wait(doneHtml: doneHtml), request: loop.request, platform: _platform);
}

Future<LoginOutcome> _mobile(Uri server) async {
  final req = LoginRequest.create(mobileRedirectUri);
  final done = Completer<LoginCallback>();
  final sub = AppLinks().uriLinkStream.listen((uri) {
    if ('${uri.scheme}:${uri.path}' != mobileRedirectUri || done.isCompleted) return;
    final cb = req.parseCallback(uri);
    if (cb != null) done.complete(cb);
  });
  try {
    if (!await launchUrl(req.startUrl(server), mode: LaunchMode.externalApplication)) {
      return (callback: const LoginCallback.failed('no_browser'), request: req, platform: _platform);
    }
    final cb = await done.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () => const LoginCallback.failed('timeout'),
    );
    return (callback: cb, request: req, platform: _platform);
  } finally {
    await sub.cancel();
  }
}

Future<void> startWebLogin(Uri server) => throw UnsupportedError('Chỉ web');
