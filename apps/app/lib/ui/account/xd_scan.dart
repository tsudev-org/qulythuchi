import 'package:flutter/foundation.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:tsudev_ui/tsudev_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../widgets/common.dart';

/// Đ1 "Quét để đăng nhập" chỉ có ở điện thoại (camera sau); máy tính dùng Đ2 ở trang đăng nhập tsudev.com.
bool get xdScanSupported =>
    !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

/// Kết quả đọc một mã QR khi đăng nhập chéo thiết bị (tsudev-standards CROSS_DEVICE_LOGIN v1.1.0, ADR-0023).
sealed class XdScan {
  const XdScan();

  /// Kiểm bằng [TsuXdLink.parse] (T9: chỉ `https://tsudev.com/x/<id>?f=k|d#<bí mật>`; sai ⇒ KHÔNG mở liên kết).
  static XdScan classify(String raw) {
    final link = TsuXdLink.parse(raw);
    if (link == null) return const XdNotTsudev();
    return switch (link.flow) {
      // Đ1: máy đã đăng nhập hiện QR, app này là thiết bị mới ⇒ mở /x/<id> trong trình duyệt hệ thống.
      TsuXdFlow.push => XdSignIn(link.uri),
      // Đ2: vai XÁC NHẬN trong app chờ QR2b (IdP chưa nhận access token cho scan/approve) ⇒ hướng sang trình duyệt.
      TsuXdFlow.pull => const XdApproveElsewhere(),
    };
  }
}

class XdNotTsudev extends XdScan {
  const XdNotTsudev();
}

class XdApproveElsewhere extends XdScan {
  const XdApproveElsewhere();
}

class XdSignIn extends XdScan {
  const XdSignIn(this.uri);
  final Uri uri;
}

/// Đ1 trọn luồng: quét ⇒ mở trang `/x/<id>` trong trình duyệt hệ thống (trang đó lo "Đúng tài khoản của tôi" + mã khớp,
/// T3/T4) ⇒ người dùng quay lại bấm Tiếp tục ⇒ [signIn] chạy OIDC + PKCE như thường trong CÙNG trình duyệt, tsudev.com
/// đã có phiên nên trả mã ngay. QR chỉ cho phiên tài khoản: khoá E2EE vẫn mở bằng mật khẩu/24 từ như cũ (ADR-0023).
Future<void> scanToSignIn(
  BuildContext context,
  Future<void> Function() signIn, {
  @visibleForTesting Future<bool> Function(Uri uri)? openBrowser,
  @visibleForTesting Future<Uri?> Function(BuildContext context)? scan,
}) async {
  final uri = await (scan ?? (c) => Navigator.of(c).push<Uri>(MaterialPageRoute(builder: (_) => const XdScanPage())))(
    context,
  );
  if (uri == null || !context.mounted) return;
  final l = context.l10n;
  final opened = await (openBrowser ?? (u) => launchUrl(u, mode: LaunchMode.externalApplication))(uri);
  if (!context.mounted) return;
  if (!opened) {
    context.toast(l.xdBrowserFailed);
    return;
  }
  final go = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(l.xdContinueTitle),
      content: Text(l.xdContinueBody),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.actionCancel)),
        FilledButton(key: const Key('xd.continue'), onPressed: () => Navigator.pop(c, true), child: Text(l.xdContinue)),
      ],
    ),
  );
  if (go == true && context.mounted) await signIn();
}

/// Màn quét: quyền camera xin lúc mở màn này (người dùng vừa bấm "Quét để đăng nhập"), không lúc mở app.
/// Trả [Uri] trang `/x/<id>` khi gặp mã Đ1 hợp lệ; mã sai chỉ báo, không mở gì. Không chụp/lưu ảnh.
class XdScanPage extends StatefulWidget {
  const XdScanPage({super.key});

  @override
  State<XdScanPage> createState() => _XdScanPageState();
}

class _XdScanPageState extends State<XdScanPage> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  String? _notice;
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    final l = context.l10n;
    for (final raw in capture.barcodes.map((b) => b.rawValue).whereType<String>()) {
      switch (XdScan.classify(raw)) {
        case XdSignIn(:final uri):
          _done = true;
          Navigator.of(context).pop(uri);
          return;
        case XdApproveElsewhere():
          setState(() => _notice = l.xdApproveElsewhere);
        case XdNotTsudev():
          setState(() => _notice = l.xdNotTsudev);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(title: Text(l.xdScanTitle)),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error) => Center(
                child: Padding(padding: const EdgeInsets.all(QtSpace.s6), child: Text(l.qrCameraError)),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            color: p.bgSurface,
            padding: const EdgeInsets.all(QtSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.xdScanHint),
                if (_notice != null) ...[
                  const SizedBox(height: QtSpace.s2),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _notice!,
                      key: const Key('xd.notice'),
                      style: TextStyle(color: p.danger, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
