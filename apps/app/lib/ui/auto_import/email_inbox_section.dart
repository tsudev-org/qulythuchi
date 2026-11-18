import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/auto_import_controller.dart';
import '../../state/providers.dart';
import '../../state/sync_controller.dart';
import '../../theme/tokens.g.dart';
import '../widgets/common.dart';

/// Email chuyển tiếp niêm phong (ADR-0006, ADR-0012): TẮT mặc định, bật phải đọc cảnh báo đây là ngoại lệ E2EE.
class EmailInboxSection extends ConsumerStatefulWidget {
  const EmailInboxSection({super.key});

  @override
  ConsumerState<EmailInboxSection> createState() => _EmailInboxSectionState();
}

class _EmailInboxSectionState extends ConsumerState<EmailInboxSection> {
  String? _address;
  bool _loading = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _run(Future<void> Function() body) async {
    setState(() => _loading = true);
    try {
      await body();
    } on Object catch (e) {
      if (mounted) context.toast(errorMessage(context, e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _load() async {
    if (!ref.read(syncProvider).signedIn) return;
    await _run(() async {
      final a = await ref.read(autoImportProvider.notifier).emailAddress();
      if (mounted) {
        setState(() {
          _address = a;
          _loaded = true;
        });
      }
    });
  }

  Future<void> _enable() async {
    final l = context.l10n;
    final ok = await confirmDialog(
      context,
      message: l.emailDisclosure,
      confirmLabel: l.emailEnable,
      destructive: false,
    );
    if (!ok || !mounted) return;
    await _run(() async {
      final a = await ref.read(autoImportProvider.notifier).rotateEmailAddress();
      if (mounted) setState(() => _address = a);
    });
  }

  Future<void> _rotate() async {
    final l = context.l10n;
    final ok = await confirmDialog(context, message: l.emailRotateConfirm, confirmLabel: l.emailRotate);
    if (!ok || !mounted) return;
    await _run(() async {
      final a = await ref.read(autoImportProvider.notifier).rotateEmailAddress();
      if (mounted) setState(() => _address = a);
    });
  }

  Future<void> _disable() async {
    final l = context.l10n;
    final ok = await confirmDialog(context, message: l.emailDisableConfirm, confirmLabel: l.emailDisable);
    if (!ok || !mounted) return;
    await _run(() async {
      await ref.read(autoImportProvider.notifier).disableEmail();
      if (mounted) setState(() => _address = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final signedIn = ref.watch(syncProvider.select((s) => s.signedIn));
    final settings = ref.watch(autoImportProvider.select((s) => s.settings));
    final wallets = ref.watch(ledgerProvider).wallets.where((w) => !w.archived && w.currency.code == 'VND').toList();
    final walletId = wallets.any((w) => w.id == settings.emailWalletId)
        ? settings.emailWalletId
        : wallets.firstOrNull?.id;
    final address = _address;

    return Card(
      margin: const EdgeInsets.only(bottom: QtSpace.s4),
      child: Padding(
        padding: const EdgeInsets.all(QtSpace.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: QtSpace.s3,
          children: [
            Text(l.emailTitle, style: Theme.of(context).textTheme.titleMedium),
            Text(l.emailExplain),
            if (!signedIn)
              OutlinedButton(onPressed: () => context.go('/more/account'), child: Text(l.emailNeedSignIn))
            else if (_loading && !_loaded)
              const LinearProgressIndicator()
            else if (address == null)
              FilledButton.tonal(
                key: const Key('email.enable'),
                onPressed: _loading ? null : _enable,
                child: Text(l.emailEnable),
              )
            else ...[
              SelectableText(address, key: const Key('email.address')),
              Wrap(
                spacing: QtSpace.s2,
                runSpacing: QtSpace.s2,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: address));
                      if (context.mounted) context.toast(l.emailCopied);
                    },
                    icon: const Icon(Icons.copy),
                    label: Text(l.emailCopy),
                  ),
                  OutlinedButton(onPressed: _loading ? null : _rotate, child: Text(l.emailRotate)),
                  TextButton(onPressed: _loading ? null : _disable, child: Text(l.emailDisable)),
                ],
              ),
              if (wallets.isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue: walletId,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.txnWallet),
                  items: [for (final w in wallets) DropdownMenuItem(value: w.id, child: Text(w.name))],
                  onChanged: (v) {
                    if (v != null) ref.read(autoImportProvider.notifier).setEmailWallet(v);
                  },
                ),
              Text(l.emailWarning, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
