import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../../l10n/app_localizations.dart';
import '../../state/ledger_repository.dart';
import '../../state/settings.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  AppLocale get appLocale => Localizations.localeOf(this).languageCode == 'en' ? AppLocale.en : AppLocale.vi;

  void toast(String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
  }
}

/// Màn rộng (máy tính/tablet ngang): điều hướng bên trái, nội dung giới hạn chiều rộng.
const wideBreakpoint = 840.0;
const contentMaxWidth = 960.0;

/// Định dạng ngày theo quy ước DD/MM/YYYY.
String formatDate(CivilDate d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year.toString().padLeft(4, '0')}';

/// Tiêu đề nhóm ngày trong danh sách: "Hôm nay", "Hôm qua" hoặc "Thứ Hai, 17/11/2026".
String dayHeader(BuildContext context, CivilDate d, CivilDate today) {
  if (d == today) return context.l10n.today;
  if (d == today.addDays(-1)) return context.l10n.yesterday;
  final weekday = DateFormat.EEEE(Localizations.localeOf(context).languageCode)
      .format(DateTime(d.year, d.month, d.day));
  return '${weekday[0].toUpperCase()}${weekday.substring(1)}, ${formatDate(d)}';
}

CivilDate todayCivil() => CivilDate.fromDateTime(DateTime.now());

/// Số tiền có tôn trọng chế độ "Ẩn số dư". Màu luôn đi kèm dấu +/- (không truyền đạt chỉ bằng màu).
class MoneyText extends ConsumerWidget {
  const MoneyText(this.money, {super.key, this.style, this.signed = false, this.colored = false, this.textAlign});
  final Money money;
  final TextStyle? style;
  final bool signed;
  final bool colored;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hide = ref.watch(settingsProvider.select((s) => s.hideBalances));
    final p = context.palette;
    if (hide) {
      return Semantics(
        label: context.l10n.hiddenAmount,
        excludeSemantics: true,
        child: Text('••••••', style: style, textAlign: textAlign),
      );
    }
    final color = !colored || money.isZero ? null : (money.isNegative ? p.danger : p.success);
    return Text(
      formatMoney(money, locale: context.appLocale, plusSign: signed),
      style: (style ?? const TextStyle()).copyWith(color: color, fontFeatures: const [FontFeature.tabularFigures()]),
      textAlign: textAlign,
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.body, this.action});
  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(QtSpace.s8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(child: Icon(icon, size: 48, color: p.textMuted)),
              const SizedBox(height: QtSpace.s4),
              Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: QtSpace.s2),
              Text(
                body,
                style: TextStyle(color: p.textSecondary),
                textAlign: TextAlign.center,
              ),
              if (action != null) ...[const SizedBox(height: QtSpace.s6), action!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Bọc nội dung trang: giới hạn chiều rộng trên màn lớn.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: contentMaxWidth),
      child: child,
    ),
  );
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String message,
  String? confirmLabel,
  String? title,
  bool destructive = true,
}) async {
  final p = context.palette;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: title == null ? null : Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.l10n.actionCancel)),
        FilledButton(
          style: destructive ? FilledButton.styleFrom(backgroundColor: p.danger, foregroundColor: p.onStatus) : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel ?? ctx.l10n.actionDelete),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Thông điệp cho [LedgerException]; lỗi khác ⇒ câu chung, KHÔNG in chi tiết (có thể chứa dữ liệu D3).
String errorMessage(BuildContext context, Object error) {
  final l = context.l10n;
  if (error is LedgerException) {
    return switch (error.code) {
      'nameRequired' => l.errNameRequired,
      'currencyLocked' => l.errCurrencyLocked,
      'walletHasTxns' => l.errWalletHasTxns,
      'parentMissing' => l.errParentMissing,
      'twoLevelsOnly' => l.errTwoLevelsOnly,
      'kindMismatch' => l.errKindMismatch,
      'walletMissing' => l.errWalletMissing,
      'sameWallet' => l.errSameWallet,
      'receivedRequired' => l.errReceivedRequired,
      'amountPositive' => l.txnAmountPositive,
      'alertRange' => l.errAlertRange,
      'dateRange' => l.errDateRange,
      'sameCurrency' => l.errSameCurrency,
      'rateInvalid' => l.errRateInvalid,
      'remindRange' => l.errRemindRange,
      'notFound' => l.errNotFound,
      'walletLocked' => l.errWalletLocked,
      'readOnly' => l.errReadOnly,
      'ownerOnly' => l.errOwnerOnly,
      _ => l.errGeneric,
    };
  }
  if (error is MoneyOverflowException || error is FormatException) return l.txnAmountInvalid;
  return l.errGeneric;
}

String walletTypeLabel(AppLocalizations l, WalletType t) => switch (t) {
  WalletType.cash => l.walletTypeCash,
  WalletType.bank => l.walletTypeBank,
  WalletType.credit => l.walletTypeCredit,
  WalletType.ewallet => l.walletTypeEwallet,
  WalletType.saving => l.walletTypeSaving,
  WalletType.investment => l.walletTypeInvestment,
  WalletType.other => l.walletTypeOther,
};

IconData walletTypeIcon(WalletType t) => switch (t) {
  WalletType.cash => Icons.payments_outlined,
  WalletType.bank => Icons.account_balance_outlined,
  WalletType.credit => Icons.credit_card,
  WalletType.ewallet => Icons.phone_iphone,
  WalletType.saving => Icons.savings_outlined,
  WalletType.investment => Icons.trending_up,
  WalletType.other => Icons.account_balance_wallet_outlined,
};

const _categoryIcons = <String, IconData>{
  'restaurant': Icons.restaurant,
  'shopping_basket': Icons.shopping_basket_outlined,
  'ramen_dining': Icons.ramen_dining_outlined,
  'local_cafe': Icons.local_cafe_outlined,
  'home': Icons.home_outlined,
  'house': Icons.house_outlined,
  'bolt': Icons.bolt,
  'water_drop': Icons.water_drop_outlined,
  'wifi': Icons.wifi,
  'directions_car': Icons.directions_car_outlined,
  'local_gas_station': Icons.local_gas_station_outlined,
  'local_parking': Icons.local_parking,
  'local_taxi': Icons.local_taxi_outlined,
  'shopping_bag': Icons.shopping_bag_outlined,
  'checkroom': Icons.checkroom,
  'chair': Icons.chair_outlined,
  'favorite': Icons.favorite_border,
  'medical_services': Icons.medical_services_outlined,
  'health_and_safety': Icons.health_and_safety_outlined,
  'school': Icons.school_outlined,
  'movie': Icons.movie_outlined,
  'flight': Icons.flight,
  'card_giftcard': Icons.card_giftcard,
  'payments': Icons.payments_outlined,
  'emoji_events': Icons.emoji_events_outlined,
  'savings': Icons.savings_outlined,
  'percent': Icons.percent,
  'sell': Icons.sell_outlined,
  'label': Icons.label_outline,
};

/// Danh sách icon chọn được khi tạo danh mục.
List<String> get categoryIconNames => _categoryIcons.keys.toList();

IconData categoryIcon(String? name) => _categoryIcons[name] ?? Icons.label_outline;

String weekdayName(AppLocalizations l, int d) => switch (d) {
  1 => l.weekday1,
  2 => l.weekday2,
  3 => l.weekday3,
  4 => l.weekday4,
  5 => l.weekday5,
  6 => l.weekday6,
  _ => l.weekday7,
};

/// Phần trăm (phần vạn) dạng chữ, làm tròn 1 chữ số thập phân bằng số nguyên (không `double`):
/// 8000 ⇒ "80"; 9790 ⇒ "97.9" (mặc định, dạng máy đọc cho ô nhập) hoặc "97,9" khi [locale] là tiếng Việt.
String percentText(int bp, {AppLocale locale = AppLocale.en}) {
  final sign = bp < 0 ? '-' : '';
  final tenths = (bp.abs() + 5) ~/ 10;
  if (tenths % 10 == 0) return '$sign${tenths ~/ 10}';
  return '$sign${tenths ~/ 10}${locale == AppLocale.vi ? ',' : '.'}${tenths % 10}';
}

extension PercentContext on BuildContext {
  /// [percentText] theo ngôn ngữ đang hiển thị - chỉ dùng để HIỂN THỊ, không đưa vào ô nhập.
  String percent(int bp) => percentText(bp, locale: appLocale);
}
