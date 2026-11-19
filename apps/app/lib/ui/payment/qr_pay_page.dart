import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr/qr.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../state/providers.dart';
import '../../state/settings.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../widgets/amount_field.dart';
import '../widgets/common.dart';

/// Camera quét QR có trên Android, iOS, macOS. Web (CSP chặn thư viện ZXing từ CDN) và Windows/Linux: dán nội dung.
bool get cameraScanSupported =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS);

const _kConsent = 'vietqrLinkConsent';
const _kApp = 'vietqrBankApp';

/// QR thanh toán: quét mã của người nhận ⇒ xem chi tiết, mở app ngân hàng, ghi khoản chi; hoặc tạo mã nhận tiền.
class QrPayPage extends ConsumerStatefulWidget {
  const QrPayPage({super.key});

  @override
  ConsumerState<QrPayPage> createState() => _QrPayPageState();
}

class _QrPayPageState extends ConsumerState<QrPayPage> {
  PaymentQr? _qr;
  String? _error;
  final _paste = TextEditingController();
  MobileScannerController? _scanner;

  @override
  void initState() {
    super.initState();
    if (cameraScanSupported) {
      _scanner = MobileScannerController(
        formats: const [BarcodeFormat.qrCode],
        detectionSpeed: DetectionSpeed.noDuplicates,
      );
    }
  }

  @override
  void dispose() {
    _paste.dispose();
    _scanner?.dispose();
    super.dispose();
  }

  void _read(String raw) {
    final l = context.l10n;
    try {
      final q = PaymentQr.parse(raw);
      setState(() {
        _qr = q;
        _error = null;
      });
      _scanner?.stop();
    } on PaymentQrException catch (e) {
      setState(() {
        _qr = null;
        _error = switch (e.code) {
          'bad_crc' => l.qrErrCrc,
          'not_emv' => l.qrErrNotPayment,
          _ => l.qrErrInvalid,
        };
      });
    }
  }

  Future<void> _pasteClipboard() async {
    final d = await Clipboard.getData(Clipboard.kTextPlain);
    final t = d?.text?.trim() ?? '';
    if (t.isEmpty) return;
    _paste.text = t;
    _read(t);
  }

  void _reset() {
    setState(() {
      _qr = null;
      _error = null;
      _paste.clear();
    });
    _scanner?.start();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.qrTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l.qrTabPay, icon: const Icon(Icons.qr_code_scanner)),
              Tab(text: l.qrTabReceive, icon: const Icon(Icons.qr_code_2)),
            ],
          ),
        ),
        body: PageBody(
          child: TabBarView(
            children: [
              ListView(padding: const EdgeInsets.all(QtSpace.s4), children: _payChildren(context)),
              const _ReceiveTab(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _payChildren(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    final q = _qr;
    if (q != null) return [_QrResult(qr: q, onReset: _reset)];
    return [
      Text(l.qrPayIntro, style: TextStyle(color: p.textSecondary)),
      const SizedBox(height: QtSpace.s4),
      if (_scanner != null)
        Center(
          // Khung quét không vượt 360 dp: màn rộng (máy tính bảng, macOS) vẫn thấy ô dán ngay bên dưới.
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(QtRadius.lg),
                child: MobileScanner(
                  controller: _scanner,
                  onDetect: (capture) {
                    final raw = capture.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
                    if (raw != null) _read(raw);
                  },
                  errorBuilder: (context, error) => Center(
                    child: Padding(padding: const EdgeInsets.all(QtSpace.s4), child: Text(l.qrCameraError)),
                  ),
                ),
              ),
            ),
          ),
        )
      else
        Card(
          child: Padding(
            padding: const EdgeInsets.all(QtSpace.s4),
            child: Text(l.qrNoCamera, style: TextStyle(color: p.textSecondary)),
          ),
        ),
      const SizedBox(height: QtSpace.s4),
      TextField(
        key: const Key('qr.paste'),
        controller: _paste,
        minLines: 2,
        maxLines: 4,
        decoration: InputDecoration(
          labelText: l.qrPasteLabel,
          suffixIcon: IconButton(tooltip: l.qrPaste, icon: const Icon(Icons.content_paste), onPressed: _pasteClipboard),
        ),
        onSubmitted: _read,
      ),
      const SizedBox(height: QtSpace.s2),
      FilledButton(key: const Key('qr.read'), onPressed: () => _read(_paste.text), child: Text(l.qrRead)),
      if (_error != null) ...[
        const SizedBox(height: QtSpace.s3),
        Text(
          _error!,
          key: const Key('qr.error'),
          style: TextStyle(color: p.danger),
        ),
      ],
    ];
  }
}

class _QrResult extends ConsumerWidget {
  const _QrResult({required this.qr, required this.onReset});
  final PaymentQr qr;
  final VoidCallback onReset;

  void _copy(BuildContext context, String value) {
    Clipboard.setData(ClipboardData(text: value));
    context.toast(context.l10n.copied);
  }

  Future<void> _openBank(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs.getBool(_kConsent) != true) {
      final ok = await confirmDialog(
        context,
        title: l.qrConsentTitle,
        message: l.qrConsentBody,
        confirmLabel: l.qrConsentOk,
        destructive: false,
      );
      if (!ok) return;
      await prefs.setBool(_kConsent, true);
    }
    if (!context.mounted) return;
    final last = prefs.getString(_kApp);
    final apps = VnBank.withApp.toList()
      ..sort((a, b) => a.shortName.toLowerCase().compareTo(b.shortName.toLowerCase()));
    final chosen = await showDialog<VnBank>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.qrChooseBankApp),
        children: [
          for (final b in [...apps.where((a) => a.appId == last), ...apps.where((a) => a.appId != last)])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, b),
              child: ListTile(
                title: Text(b.shortName),
                subtitle: b.appId == last ? Text(l.qrLastUsed) : null,
                dense: true,
              ),
            ),
        ],
      ),
    );
    if (chosen == null) return;
    await prefs.setString(_kApp, chosen.appId!);
    final uri = VietQr.bankAppLink(qr, chosen.appId!);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) context.toast(l.qrOpenFailed);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final data = ref.watch(ledgerProvider);
    final amount = qr.amount;
    final hasWalletInCurrency = amount != null && data.wallets.any((w) => !w.archived && w.currency == amount.currency);
    Widget field(String label, String? value, {bool copy = true, Key? key}) => value == null || value.isEmpty
        ? const SizedBox.shrink()
        : ListTile(
            key: key,
            contentPadding: EdgeInsets.zero,
            title: Text(
              label,
              style: TextStyle(color: p.textSecondary, fontSize: QtFontSize.sm),
            ),
            subtitle: SelectableText(value, style: text.titleSmall),
            trailing: copy
                ? IconButton(
                    tooltip: l.actionCopy,
                    icon: const Icon(Icons.copy),
                    onPressed: () => _copy(context, value),
                  )
                : null,
          );
    final bank = qr.bank;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(QtSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_schemeName(qr.scheme), style: TextStyle(color: p.textMuted)),
                if (amount != null)
                  MoneyText(amount, key: const Key('qr.amount'), style: text.headlineMedium)
                else
                  Text(l.qrNoAmount, style: TextStyle(color: p.textSecondary)),
                const SizedBox(height: QtSpace.s2),
                field(l.qrPayee, qr.merchantName, copy: false, key: const Key('qr.payee')),
                field(l.qrBank, bank == null ? qr.bankBin : '${bank.shortName} - ${bank.name}', copy: false),
                field(l.qrAccount, qr.accountNumber, key: const Key('qr.account')),
                field(l.qrMessage, qr.message, key: const Key('qr.message')),
                if (amount != null)
                  field(l.txnAmount, formatMoney(amount, locale: context.appLocale, withSymbol: false)),
                field(l.qrCity, [qr.merchantCity, qr.countryCode].whereType<String>().join(', '), copy: false),
                if (qr.isCard) Text(l.qrIsCard, style: TextStyle(color: p.textMuted)),
              ],
            ),
          ),
        ),
        const SizedBox(height: QtSpace.s4),
        if (qr.scheme == PaymentQrScheme.vietQr && qr.accountNumber != null) ...[
          FilledButton.icon(
            key: const Key('qr.openBank'),
            onPressed: () => _openBank(context, ref),
            icon: const Icon(Icons.account_balance),
            label: Text(l.qrOpenBank),
          ),
          const SizedBox(height: QtSpace.s1),
          Text(
            l.qrOpenBankNote,
            style: TextStyle(color: p.textMuted, fontSize: QtFontSize.sm),
          ),
          const SizedBox(height: QtSpace.s3),
        ] else ...[
          Text(l.qrForeignNote, style: TextStyle(color: p.textSecondary)),
          const SizedBox(height: QtSpace.s3),
        ],
        OutlinedButton.icon(
          key: const Key('qr.record'),
          onPressed: data.wallets.isEmpty
              ? null
              : () => context.go(
                  Uri(
                    path: '/transactions/new',
                    queryParameters: {
                      'kind': 'expense',
                      if (hasWalletInCurrency) 'amount': '${amount.minor}',
                      if (hasWalletInCurrency) 'cur': amount.currency.code,
                      if (qr.payeeLabel != null) 'payee': qr.payeeLabel!,
                      if (qr.message != null && qr.message!.isNotEmpty) 'note': qr.message!,
                    },
                  ).toString(),
                ),
          icon: const Icon(Icons.edit_note),
          label: Text(l.qrRecordExpense),
        ),
        const SizedBox(height: QtSpace.s2),
        TextButton.icon(
          key: const Key('qr.reset'),
          onPressed: onReset,
          icon: const Icon(Icons.refresh),
          label: Text(l.qrScanAgain),
        ),
      ],
    );
  }
}

String _schemeName(PaymentQrScheme s) => switch (s) {
  PaymentQrScheme.vietQr => 'VietQR (NAPAS 247)',
  PaymentQrScheme.promptPay => 'PromptPay (TH)',
  PaymentQrScheme.payNow => 'PayNow (SG)',
  PaymentQrScheme.duitNow => 'DuitNow (MY)',
  PaymentQrScheme.qris => 'QRIS (ID)',
  PaymentQrScheme.qrPh => 'QR Ph (PH)',
  PaymentQrScheme.khqr => 'KHQR (KH)',
  PaymentQrScheme.upi => 'UPI / Bharat QR (IN)',
  PaymentQrScheme.other => 'EMVCo QR',
};

/// Tạo mã VietQR để người khác quét chuyển tiền cho mình (không lưu số tài khoản, không gọi mạng).
class _ReceiveTab extends ConsumerStatefulWidget {
  const _ReceiveTab();

  @override
  ConsumerState<_ReceiveTab> createState() => _ReceiveTabState();
}

class _ReceiveTabState extends ConsumerState<_ReceiveTab> {
  final _account = TextEditingController();
  final _amount = TextEditingController();
  final _message = TextEditingController();
  String _bin = VnBank.all.first.bin;
  String? _payload;
  String? _error;

  @override
  void dispose() {
    for (final c in [_account, _amount, _message]) {
      c.dispose();
    }
    super.dispose();
  }

  void _build() {
    final l = context.l10n;
    try {
      final amount = AmountField.tryValue(_amount.text, Currency.vnd, context.appLocale)?.minor;
      setState(() {
        _payload = VietQr.build(
          bin: _bin,
          account: _account.text.trim(),
          amount: amount == null || amount <= 0 ? null : amount,
          message: _message.text,
        );
        _error = null;
      });
    } on ArgumentError {
      setState(() {
        _payload = null;
        _error = l.qrErrAccount;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    final banks = [...VnBank.all]..sort((a, b) => a.shortName.toLowerCase().compareTo(b.shortName.toLowerCase()));
    return ListView(
      padding: const EdgeInsets.all(QtSpace.s4),
      children: [
        Text(l.qrReceiveIntro, style: TextStyle(color: p.textSecondary)),
        const SizedBox(height: QtSpace.s4),
        DropdownButtonFormField<String>(
          initialValue: _bin,
          isExpanded: true,
          decoration: InputDecoration(labelText: l.qrBank),
          items: [
            for (final b in banks)
              DropdownMenuItem(
                value: b.bin,
                child: Text('${b.shortName} · ${b.name}', overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) => setState(() => _bin = v ?? _bin),
        ),
        const SizedBox(height: QtSpace.s3),
        TextField(
          key: const Key('qr.recv.account'),
          controller: _account,
          keyboardType: TextInputType.number,
          maxLength: 19,
          decoration: InputDecoration(labelText: l.qrAccount, counterText: ''),
        ),
        const SizedBox(height: QtSpace.s3),
        TextField(
          controller: _amount,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l.qrAmountOptional, suffixText: '₫'),
        ),
        const SizedBox(height: QtSpace.s3),
        TextField(
          controller: _message,
          maxLength: 25,
          decoration: InputDecoration(labelText: l.qrMessage, helperText: l.qrMessageHelp),
        ),
        const SizedBox(height: QtSpace.s3),
        FilledButton(key: const Key('qr.recv.build'), onPressed: _build, child: Text(l.qrCreate)),
        if (_error != null) ...[const SizedBox(height: QtSpace.s3), Text(_error!, style: TextStyle(color: p.danger))],
        if (_payload != null) ...[
          const SizedBox(height: QtSpace.s4),
          Center(
            child: Container(
              key: const Key('qr.recv.image'),
              padding: const EdgeInsets.all(QtSpace.s4),
              color: Colors.white,
              child: Semantics(
                label: l.qrImageLabel,
                image: true,
                child: SizedBox(width: 240, height: 240, child: CustomPaint(painter: QrPainter(_payload!))),
              ),
            ),
          ),
          const SizedBox(height: QtSpace.s3),
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _payload!));
              context.toast(l.copied);
            },
            icon: const Icon(Icons.copy),
            label: Text(l.qrCopyContent),
          ),
        ],
      ],
    );
  }
}

/// Vẽ mã QR (đen trên nền trắng - luôn đủ tương phản cho máy quét, ở cả chế độ Tối).
class QrPainter extends CustomPainter {
  QrPainter(this.data) : _image = QrImage(QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.M));
  final String data;
  final QrImage _image;

  @override
  void paint(Canvas canvas, Size size) {
    final n = _image.moduleCount;
    final cell = size.shortestSide / n;
    final paint = Paint()..color = Colors.black;
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        if (_image.isDark(y, x)) canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell + 0.5, cell + 0.5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(QrPainter old) => old.data != data;
}
