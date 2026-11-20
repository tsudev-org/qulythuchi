import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import 'purchases.dart';

/// Google Play Billing cho bản `TSU_CHANNEL=play` (ADR-0019 mục 4).
///
/// - Pro: thuê bao `tsudev_pro`, CHỈ gói cơ sở trả trước `nam` (bỏ qua mọi gói/ưu đãi khác nếu lỡ tạo).
/// - Ủng hộ: tiêu hao `ung_ho_*`, không tự tiêu thụ - chỉ tiêu thụ sau khi tsudev.com xác minh.
/// - App KHÔNG tự tin biên nhận: chỉ hoàn tất (acknowledge/consume) sau khi máy chủ trả `verified`. Chưa xác minh được
///   ⇒ để nguyên, Play giao lại ở lần mở sau (quá 3 ngày không acknowledge ⇒ Play tự hoàn tiền: không ai mất tiền).
final class PlayPurchases implements StorePurchases {
  PlayPurchases([InAppPurchase? iap]) : _iap = iap ?? InAppPurchase.instance;

  final InAppPurchase _iap;
  final Map<String, ProductDetails> _details = {};
  final Map<String, Completer<PurchaseOutcome>> _waiting = {};
  StreamSubscription<List<PurchaseDetails>>? _sub;
  ReceiptVerifier? _verify;

  @override
  void start(ReceiptVerifier verify) {
    _verify = verify;
    _sub ??= _iap.purchaseStream.listen(_onUpdates, onError: (_) {});
  }

  @override
  Future<Map<String, String>> prices() async {
    if (!await _iap.isAvailable()) return const {};
    final res = await _iap.queryProductDetails(PlayIds.all);
    _details.clear();
    for (final d in res.productDetails) {
      if (d is GooglePlayProductDetails && d.id == PlayIds.pro) {
        final i = d.subscriptionIndex;
        final offer = i == null ? null : d.productDetails.subscriptionOfferDetails?[i];
        // Chỉ gói cơ sở `nam` (không phải ưu đãi gắn trên nó).
        if (offer == null || offer.basePlanId != PlayIds.proBasePlan || offer.offerId != null) continue;
      }
      _details[d.id] = d;
    }
    return {for (final e in _details.entries) e.key: e.value.price};
  }

  @override
  Future<PurchaseOutcome> buy(String productId, {required String accountId}) async {
    if (_details[productId] == null) await prices();
    final d = _details[productId];
    if (d == null) return PurchaseOutcome.unavailable;
    final param = GooglePlayPurchaseParam(
      productDetails: d,
      applicationUserName: accountId,
      offerToken: d is GooglePlayProductDetails ? d.offerToken : null,
    );
    final done = _waiting[productId] = Completer<PurchaseOutcome>();
    final started = productId == PlayIds.pro
        ? await _iap.buyNonConsumable(purchaseParam: param)
        : await _iap.buyConsumable(purchaseParam: param, autoConsume: false);
    if (!started) {
      _waiting.remove(productId);
      return PurchaseOutcome.error;
    }
    return done.future.timeout(const Duration(minutes: 10), onTimeout: () => PurchaseOutcome.pending);
  }

  Future<void> _onUpdates(List<PurchaseDetails> updates) async {
    for (final p in updates) {
      final outcome = await _handle(p);
      _waiting.remove(p.productID)?.complete(outcome);
    }
  }

  Future<PurchaseOutcome> _handle(PurchaseDetails p) async {
    switch (p.status) {
      case PurchaseStatus.pending:
        return PurchaseOutcome.pending;
      case PurchaseStatus.canceled:
        return PurchaseOutcome.cancelled;
      case PurchaseStatus.error:
        return PurchaseOutcome.error;
      case PurchaseStatus.purchased || PurchaseStatus.restored:
        if (!PlayIds.all.contains(p.productID)) return PurchaseOutcome.invalid;
        final verify = _verify;
        if (verify == null) return PurchaseOutcome.pending;
        final outcome = await verify(p.productID, p.verificationData.serverVerificationData);
        if (outcome != PurchaseOutcome.verified) return outcome;
        try {
          if (PlayIds.donations.contains(p.productID)) {
            await _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>().consumePurchase(p);
          } else if (p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }
        } on Object {
          // tsudev.com đã acknowledge phía máy chủ; lần mở sau Play giao lại thì xác minh lại (trùng ⇒ bỏ qua).
        }
        return PurchaseOutcome.verified;
    }
  }
}
