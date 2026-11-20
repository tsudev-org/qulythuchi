import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart' show Currency, Money, formatMoney;
import 'package:tsudev_ui/tsudev_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../pro/channel.dart';
import '../../pro/pro_controller.dart';
import '../../pro/purchases.dart';
import '../../state/sync_controller.dart';
import '../../theme/tokens.g.dart';
import '../widgets/common.dart';

/// Ngày theo PRODUCT_POLICY 7.6: vi ⇒ DD/MM/YYYY theo giờ máy; en ⇒ "November 27, 2026".
String proDate(BuildContext context, DateTime t) => formatProRenewalDate(t.toLocal(), Localizations.localeOf(context));

/// Câu trạng thái Pro (dùng ở màn Pro và Tài khoản).
String proStatusText(AppLocalizations l, BuildContext context, ProState s, DateTime now) {
  final until = s.ent.entitlement?.proUntil;
  if (until == null) return l.proStatusFree;
  return until.isAfter(now.toUtc())
      ? l.proStatusActive(proDate(context, until))
      : l.proStatusExpired(proDate(context, until));
}

String purchaseOutcomeText(AppLocalizations l, PurchaseOutcome o) => switch (o) {
  PurchaseOutcome.verified => l.proOutcomeVerified,
  PurchaseOutcome.pending => l.proOutcomePending,
  PurchaseOutcome.invalid => l.proOutcomeInvalid,
  PurchaseOutcome.unavailable => l.proStoreUnavailable,
  PurchaseOutcome.cancelled || PurchaseOutcome.error => l.proOutcomeError,
};

/// Màn TsuDEV Pro + Ủng hộ (PRODUCT_POLICY 3.3, 4.3, 7.2, 7.5; ADR-0019 mục 6).
///
/// - Chỉ MỘT lựa chọn Pro: 1 năm, không tự gia hạn; điều khoản 7.5 nguyên văn đứng TRƯỚC nút mua.
/// - Bản Play: chỉ Play Billing (giá cửa hàng trả về) - không có liên kết thanh toán/ủng hộ ra web.
/// - Bản App Store: chưa có IAP ⇒ không có nút mua, không có liên kết ra web.
/// - Bản ngoài cửa hàng: mở `tsudev.com/pro?app=qulythuchi` / `tsudev.com/ung-ho?app=qulythuchi`.
class ProPage extends ConsumerStatefulWidget {
  const ProPage({super.key});

  @override
  ConsumerState<ProPage> createState() => _ProPageState();
}

class _ProPageState extends ConsumerState<ProPage> {
  Map<String, String>? _prices;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final store = ref.read(storePurchasesProvider);
    if (store != null) {
      unawaited(
        store.prices().then((p) => p, onError: (_) => const <String, String>{}).then((p) {
          if (mounted) setState(() => _prices = p);
        }),
      );
    }
    unawaited(ref.read(proProvider.notifier).refresh());
  }

  Future<void> _buy(String productId) async {
    setState(() => _busy = true);
    final outcome = await ref.read(proProvider.notifier).buy(productId);
    if (!mounted) return;
    setState(() => _busy = false);
    if (outcome == PurchaseOutcome.cancelled) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(purchaseOutcomeText(context.l10n, outcome))));
  }

  Future<void> _open(Uri url) => launchUrl(url, mode: LaunchMode.externalApplication);

  Future<void> _checkAgain() async {
    setState(() => _busy = true);
    await ref.read(proProvider.notifier).refresh(force: true);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final channel = ref.watch(distChannelProvider);
    final pro = ref.watch(proProvider);
    final signedIn = ref.watch(syncProvider.select((s) => s.signedIn));
    final now = ref.watch(proClockProvider)();
    final isPro = pro.isPro(now);
    final canBuyInApp = signedIn && pro.ent.entitlement != null;
    final price = switch (channel) {
      DistChannel.play => _prices?[PlayIds.pro],
      DistChannel.direct => formatMoney(Money(proWebPriceVnd, Currency.vnd), locale: context.appLocale),
      DistChannel.appStore => null,
    };
    final dataUntil = pro.server?.serverDataUntil;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.proMenu)),
      body: ListView(
        padding: const EdgeInsets.all(QtSpace.s4),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.workspace_premium_outlined),
              title: Row(
                children: [
                  const Flexible(child: Text('TsuDEV Pro')),
                  if (pro.badge != TsuBadgeKind.none) ...[
                    const SizedBox(width: 6),
                    TsuBadge(kind: pro.badge, nameStyle: theme.textTheme.titleMedium),
                  ],
                ],
              ),
              subtitle: Text(
                [
                  proStatusText(l, context, pro, now),
                  if (dataUntil != null && !isPro) l.proServerDataUntil(proDate(context, dataUntil)),
                ].join('\n'),
              ),
            ),
          ),
          const SizedBox(height: QtSpace.s4),
          Text(l.proFeaturesTitle, style: theme.textTheme.titleMedium),
          for (final f in [l.proFeatSync, l.proFeatShared, l.proFeatAttach, l.proFeatQuota, l.proFeatOneAccount])
            ListTile(dense: true, leading: const Icon(Icons.check_circle_outline), title: Text(f)),
          const SizedBox(height: QtSpace.s2),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(QtSpace.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l.proPlanYear, style: theme.textTheme.titleMedium),
                  const SizedBox(height: QtSpace.s2),
                  ..._purchase(context, channel, price, signedIn, canBuyInApp, isPro),
                ],
              ),
            ),
          ),
          if (channel != DistChannel.appStore) ...[
            const SizedBox(height: QtSpace.s4),
            Text(l.donateTitle, style: theme.textTheme.titleMedium),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: QtSpace.s2),
              child: Text(l.donateBody),
            ),
            ..._donate(context, channel, canBuyInApp),
          ],
        ],
      ),
    );
  }

  List<Widget> _purchase(
    BuildContext context,
    DistChannel channel,
    String? price,
    bool signedIn,
    bool canBuyInApp,
    bool isPro,
  ) {
    final l = context.l10n;
    switch (channel) {
      case DistChannel.appStore:
        return [Text(l.proAppStoreSoon)];
      case DistChannel.play:
        if (_prices == null) return const [Center(child: CircularProgressIndicator())];
        if (price == null) return [Text(l.proStoreUnavailable)];
        return [
          // Điều khoản đứng TRƯỚC nút mua (PRODUCT_POLICY 3.5, 7.5).
          Text(l.proTerms(price), key: const ValueKey('pro-terms')),
          const SizedBox(height: QtSpace.s4),
          if (!canBuyInApp) ..._signInFirst(context, signedIn),
          FilledButton(
            key: const ValueKey('pro-buy'),
            onPressed: _busy || !canBuyInApp ? null : () => _buy(PlayIds.pro),
            child: Text(isPro ? l.proRenewStore : l.proBuyStore),
          ),
        ];
      case DistChannel.direct:
        return [
          Text(l.proTerms(price!), key: const ValueKey('pro-terms')),
          const SizedBox(height: QtSpace.s4),
          FilledButton.icon(
            key: const ValueKey('pro-buy'),
            onPressed: () => _open(proWebUrl(tsudevClientId)),
            icon: const Icon(Icons.open_in_new),
            label: Text(l.proBuyWeb),
          ),
          if (signedIn) TextButton(onPressed: _busy ? null : _checkAgain, child: Text(l.proCheckAgain)),
        ];
    }
  }

  List<Widget> _signInFirst(BuildContext context, bool signedIn) => [
    Text(context.l10n.proSignInFirst),
    Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton(
        onPressed: () => context.push('/more/account'),
        child: Text(signedIn ? context.l10n.proSignInAgain : context.l10n.proSignIn),
      ),
    ),
  ];

  List<Widget> _donate(BuildContext context, DistChannel channel, bool canBuyInApp) {
    final l = context.l10n;
    if (channel == DistChannel.direct) {
      return [
        OutlinedButton.icon(
          key: const ValueKey('donate-web'),
          onPressed: () => _open(donateWebUrl(tsudevClientId)),
          icon: const Icon(Icons.favorite_outline),
          label: Text(l.donateWeb),
        ),
      ];
    }
    final prices = _prices ?? const {};
    final available = [
      for (final id in PlayIds.donations)
        if (prices[id] != null) id,
    ];
    if (_prices != null && available.isEmpty) return [Text(l.proStoreUnavailable)];
    return [
      if (!canBuyInApp) Text(l.proSignInFirst),
      Wrap(
        spacing: QtSpace.s2,
        runSpacing: QtSpace.s2,
        children: [
          for (final id in available)
            OutlinedButton.icon(
              key: ValueKey('donate-$id'),
              onPressed: _busy || !canBuyInApp ? null : () => _buy(id),
              icon: const Icon(Icons.favorite_outline),
              label: Text(prices[id]!),
            ),
        ],
      ),
    ];
  }
}
