// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../../security/vault.dart';
import '../../state/providers.dart';
import '../../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/common.dart';

/// Màn khóa: PIN (nếu bật), sinh trắc (nếu bật), mật khẩu mã hóa, hoặc 24 từ.
class LockPage extends ConsumerStatefulWidget {
  const LockPage({super.key, this.localAuth});

  /// Cho test thay thế.
  final LocalAuthentication? localAuth;

  @override
  ConsumerState<LockPage> createState() => _LockPageState();
}

class _LockPageState extends ConsumerState<LockPage> {
  final _form = GlobalKey<FormState>();
  final _secret = TextEditingController();
  late bool _usePin;
  bool _busy = false;
  String? _error;

  Vault get _vault => ref.read(servicesProvider).vault;

  @override
  void initState() {
    super.initState();
    _usePin = _vault.pinEnabled;
    if (_vault.biometricEnabled) WidgetsBinding.instance.addPostFrameCallback((_) => _biometric());
  }

  @override
  void dispose() {
    _secret.dispose();
    super.dispose();
  }

  Future<void> _biometric() async {
    if (_busy || !mounted) return;
    final l = context.l10n;
    final auth = widget.localAuth ?? LocalAuthentication();
    try {
      final ok = await auth.authenticate(localizedReason: l.biometricReason, biometricOnly: true);
      if (!ok || !mounted) return;
      setState(() => _busy = true);
      await ref.read(sessionProvider.notifier).unlockWithBiometric();
    } on Object {
      // Hủy, không có sinh trắc, hoặc khóa thiết bị bị thay ⇒ dùng PIN/mật khẩu.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    final l = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    await yieldFrame();
    final secret = _secret.text;
    try {
      final session = ref.read(sessionProvider.notifier);
      if (_usePin) {
        final r = await session.unlockWithPin(secret);
        if (!mounted) return;
        setState(() {
          _error = switch (r) {
            PinOk() => null,
            PinWrong(:final remaining, :final waitUntil) =>
              waitUntil == null ? l.pinWrong(remaining) : l.pinLockedOut(_time(waitUntil)),
            PinLockedOut(:final until) => l.pinLockedOut(_time(until)),
            PinDisabled() => l.pinDisabledMsg,
          };
          if (r is PinDisabled) _usePin = false;
        });
      } else {
        await session.unlockWithPassword(secret);
      }
    } on EnvelopeException {
      if (mounted) setState(() => _error = l.passwordWrong);
    } on Object catch (e) {
      if (mounted) setState(() => _error = errorMessage(context, e));
    } finally {
      _secret.clear();
      if (mounted) setState(() => _busy = false);
    }
  }

  String _time(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:'
      '${t.second.toString().padLeft(2, '0')}';

  Future<void> _recovery() async {
    final words = await showDialog<List<String>>(context: context, builder: (_) => const _RecoveryDialog());
    if (words == null || !mounted) return;
    setState(() => _busy = true);
    await yieldFrame();
    try {
      await ref.read(sessionProvider.notifier).unlockWithRecovery(words);
    } on Object {
      if (mounted) setState(() => _error = context.l10n.restoreInvalid);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    final vault = _vault;
    return AuthScaffold(
      title: l.lockTitle,
      body: l.lockBody,
      children: [
        Form(
          key: _form,
          child: PasswordField(
            key: ValueKey(_usePin),
            controller: _secret,
            label: _usePin ? l.pinLabel : l.passwordLabel,
            digitsOnly: _usePin,
            autofocus: true,
            autofillHints: _usePin ? null : const [AutofillHints.password],
            validator: (v) => (v == null || v.isEmpty) ? (_usePin ? l.pinInvalid : l.passwordWrong) : null,
            onSubmitted: (_) => _submit(),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Row(
              children: [
                Icon(Icons.error_outline, color: p.danger),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_error!, style: TextStyle(color: p.danger)),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l.unlock),
        ),
        const SizedBox(height: 8),
        if (vault.pinEnabled)
          TextButton(
            onPressed: _busy
                ? null
                : () => setState(() {
                    _usePin = !_usePin;
                    _error = null;
                    _secret.clear();
                  }),
            child: Text(_usePin ? l.unlockWithPassword : l.unlockWithPin),
          ),
        if (vault.biometricEnabled)
          OutlinedButton.icon(
            onPressed: _busy ? null : _biometric,
            icon: const Icon(Icons.fingerprint),
            label: Text(l.unlockWithBiometric),
          ),
        TextButton(onPressed: _busy ? null : _recovery, child: Text(l.unlockWithRecovery)),
      ],
    );
  }
}

class _RecoveryDialog extends StatefulWidget {
  const _RecoveryDialog();

  @override
  State<_RecoveryDialog> createState() => _RecoveryDialogState();
}

class _RecoveryDialogState extends State<_RecoveryDialog> {
  final _c = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _ok() {
    final words = _c.text.trim().toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    try {
      RecoveryPhrase.toEntropy(words);
    } on Object {
      setState(() => _error = context.l10n.restoreInvalid);
      return;
    }
    Navigator.pop(context, words);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.restoreTitle),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.restoreBody),
            const SizedBox(height: 16),
            TextField(
              controller: _c,
              minLines: 3,
              maxLines: 6,
              autocorrect: false,
              enableSuggestions: false,
              enableIMEPersonalizedLearning: false,
              decoration: InputDecoration(labelText: l.recoveryTitle, errorText: _error),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.actionCancel)),
        FilledButton(onPressed: _ok, child: Text(l.unlock)),
      ],
    );
  }
}
