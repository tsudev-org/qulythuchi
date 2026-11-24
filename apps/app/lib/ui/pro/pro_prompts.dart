import 'dart:async';

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tsudev_ui/tsudev_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../pro/channel.dart';
import '../../pro/pro_controller.dart';
import '../../pro/purchases.dart';
import '../widgets/common.dart';
import 'pro_page.dart';

/// Mốc báo trước khi xoá bản sao đám mây (PRODUCT_POLICY 7.2: 30 và 7 ngày trước). null = không báo.
int? cloudPurgeMilestone(DateTime? serverDataUntil, DateTime now) {
  if (serverDataUntil == null) return null;
  final left = serverDataUntil.difference(now.toUtc());
  if (left <= Duration.zero) return null;
  if (left <= const Duration(days: 7)) return 7;
  if (left <= const Duration(days: 30)) return 30;
  return null;
}

/// Đang có ô nhập liệu giữ tiêu điểm ⇒ không chen hộp thoại (như `tsudev_ui`).
bool _isEditingText() {
  final ctx = FocusManager.instance.primaryFocus?.context;
  if (ctx == null || !ctx.mounted) return false;
  return ctx.widget is EditableText || ctx.findAncestorWidgetOfExactType<EditableText>() != null;
}

/// Khoá cục bộ: mốc đã báo, dạng `<server_data_until giây Unix>:<30|7>` (mỗi mốc một lần).
const cloudPurgeNotifiedKey = 'qlt.pro_purge.notified';

/// "Gia hạn" theo kênh (PRODUCT_POLICY 7.6 + 7.3): Play ⇒ IAP gói `nam`; App Store (chưa có IAP) ⇒ màn Pro trong
/// app; ngoài cửa hàng ⇒ `tsudev.com/pro?app=qulythuchi`. Bản cửa hàng KHÔNG BAO GIỜ mở trang thanh toán web.
void renewPro(BuildContext context, WidgetRef ref) {
  switch (ref.read(distChannelProvider)) {
    case DistChannel.play:
      final messenger = ScaffoldMessenger.maybeOf(context);
      final l = context.l10n;
      unawaited(
        ref.read(proProvider.notifier).buy(PlayIds.pro).then((o) {
          if (o == PurchaseOutcome.unavailable) {
            if (context.mounted) unawaited(context.push('/more/pro'));
          } else if (o != PurchaseOutcome.cancelled) {
            messenger?.showSnackBar(SnackBar(content: Text(purchaseOutcomeText(l, o))));
          }
        }),
      );
    case DistChannel.appStore:
      unawaited(context.push('/more/pro'));
    case DistChannel.direct:
      unawaited(launchUrl(proWebUrl(tsudevClientId), mode: LaunchMode.externalApplication));
  }
}

/// Bọc màn chính: sau mỗi lần làm mới quyền lợi (mở app, mở khoá, quay lại) hỏi lần lượt - nhắc gia hạn / báo hết kỳ
/// (7.6, `tsudev_ui`), báo trước xoá bản sao đám mây (7.2), thông báo nhiều thiết bị (7.3, `tsudev_ui`). Tối đa MỘT hộp
/// thoại mỗi lượt; đóng được, không chặn; không chen khi đang nhập liệu.
class ProPromptHost extends ConsumerStatefulWidget {
  const ProPromptHost({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<ProPromptHost> createState() => _ProPromptHostState();
}

class _ProPromptHostState extends ConsumerState<ProPromptHost> {
  bool _running = false;

  @override
  void initState() {
    super.initState();
    // Lượt làm mới đã xong trước khi màn chính dựng (mở khoá nhanh) ⇒ vẫn hỏi một lần.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(proProvider).checks > 0) unawaited(_prompt());
    });
  }

  Future<void> _prompt() async {
    if (_running || !mounted || !ref.read(proPromptsEnabledProvider)) return;
    _running = true;
    try {
      final s = ref.read(proProvider);
      final shown = await maybeShowProRenewal(
        context,
        controller: ref.read(proRenewalControllerProvider),
        state: s.ent,
        onRenew: () => renewPro(context, ref),
        hasCloudSync: true,
      );
      if (shown != null || !mounted) return;
      if (await _maybePurgeNotice(s)) return;
      if (!mounted) return;
      final channel = ref.read(distChannelProvider);
      await maybeShowProNotice(
        context,
        controller: ref.read(proNoticeControllerProvider),
        state: s.ent,
        onSeePro: () => channel.isStore
            ? unawaited(context.push('/more/pro'))
            : unawaited(launchUrl(proWebUrl(tsudevClientId), mode: LaunchMode.externalApplication)),
        onBackupToFile: () => unawaited(context.push('/more/data')),
      );
    } on Object {
      // Lời nhắc không bao giờ làm hỏng màn chính.
    } finally {
      _running = false;
    }
  }

  Future<bool> _maybePurgeNotice(ProState s) async {
    final now = ref.read(proClockProvider)();
    final until = s.server?.serverDataUntil;
    if (s.isPro(now)) return false;
    final m = cloudPurgeMilestone(until, now);
    if (m == null) return false;
    final store = ref.read(tsuStoreProvider);
    final tag = '${until!.millisecondsSinceEpoch ~/ 1000}:$m';
    if (await store.read(cloudPurgeNotifiedKey) == tag || !mounted) return false;
    if (_isEditingText()) return false;
    await store.write(cloudPurgeNotifiedKey, tag);
    if (!mounted) return true;
    final l = context.l10n;
    final days = (until.difference(now.toUtc()).inMilliseconds / Duration.millisecondsPerDay).ceil();
    final renew = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.proPurgeTitle),
        scrollable: true,
        content: Text(l.proPurgeBody(days < 1 ? 1 : days, proDate(c, until))),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(false), child: Text(l.proClose)),
          FilledButton(onPressed: () => Navigator.of(c).pop(true), child: Text(l.proRenew)),
        ],
      ),
    );
    if (renew == true && mounted) renewPro(context, ref);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(proProvider.select((s) => s.checks), (_, _) => unawaited(_prompt()));
    return widget.child;
  }
}
