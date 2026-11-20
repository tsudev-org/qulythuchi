import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../security/vault.dart';
import '../../state/providers.dart';
import '../../state/settings.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../onboarding/onboarding.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';

/// Phiên bản sản phẩm theo khuôn `YY.M.DDNN` (phiếu 20261117-V1); khớp `version` trong pubspec.yaml.
const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '26.11.1701');

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool? _bioAvailable;

  Vault get _vault => ref.read(servicesProvider).vault;

  @override
  void initState() {
    super.initState();
    if (_vault.quickUnlockSupported) _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    try {
      final auth = LocalAuthentication();
      final ok = await auth.isDeviceSupported() && await auth.canCheckBiometrics;
      if (mounted) setState(() => _bioAvailable = ok);
    } on Object {
      if (mounted) setState(() => _bioAvailable = false);
    }
  }

  Future<void> _setPin() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.pinSetupTitle),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(ctx.l10n.pinSetupBody),
                const SizedBox(height: QtSpace.s4),
                PinForm(onSaved: () => Navigator.pop(ctx)),
              ],
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.l10n.actionCancel))],
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _disablePin() async {
    await _vault.disablePin();
    if (mounted) setState(() {});
  }

  Future<void> _toggleBiometric(bool on) async {
    final l = context.l10n;
    try {
      if (on) {
        final ok = await LocalAuthentication().authenticate(localizedReason: l.biometricReason, biometricOnly: true);
        if (!ok) return;
        await _vault.enableBiometric();
      } else {
        _vault.disableBiometric();
      }
    } on Object catch (e) {
      if (mounted) context.toast(errorMessage(context, e));
    }
    if (mounted) setState(() {});
  }

  Future<void> _changePassword() async {
    final changed = await showDialog<bool>(context: context, builder: (_) => const _ChangePasswordDialog());
    if (changed == true && mounted) context.toast(context.l10n.settingsPasswordChanged);
  }

  Future<void> _newRecovery() async {
    final l = context.l10n;
    if (!await confirmDialog(context, message: l.settingsNewRecoveryConfirm, confirmLabel: l.actionContinue)) return;
    if (!mounted) return;
    final words = _vault.rotateRecovery();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.recoveryTitle),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ctx.l10n.recoveryBody),
                const SizedBox(height: QtSpace.s4),
                Wrap(
                  spacing: QtSpace.s3,
                  runSpacing: QtSpace.s2,
                  children: [
                    for (var i = 0; i < words.length; i++)
                      SizedBox(
                        width: 130,
                        child: Text('${i + 1}. ${words[i]}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.l10n.actionDone))],
      ),
    );
  }

  Future<void> _wipe() async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => ControllerScope(
        count: 1,
        builder: (ctx, cs) => StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l.settingsResetConfirm),
                const SizedBox(height: QtSpace.s4),
                TextField(
                  controller: cs[0],
                  autofocus: true,
                  decoration: InputDecoration(labelText: l.settingsResetTypeHint),
                  onChanged: (_) => setLocal(() {}),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.actionCancel)),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: ctx.palette.danger,
                  foregroundColor: ctx.palette.onStatus,
                ),
                onPressed: cs[0].text.trim().toUpperCase() == l.settingsResetWord
                    ? () => Navigator.pop(ctx, true)
                    : null,
                child: Text(l.actionDelete),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok == true) await ref.read(sessionProvider.notifier).wipe();
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(QtSpace.s4, QtSpace.s6, QtSpace.s4, QtSpace.s2),
    child: Semantics(header: true, child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final vault = _vault;
    final pinOn = vault.pinEnabled;

    return Scaffold(
      appBar: AppBar(title: Text(l.navSettings)),
      body: PageBody(
        child: ListView(
          padding: const EdgeInsets.only(bottom: QtSpace.s12),
          children: [
            _section(l.settingsAppearance),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: QtSpace.s4),
              child: SegmentedButton<ThemeChoice>(
                segments: [
                  ButtonSegment(
                    value: ThemeChoice.light,
                    label: Text(l.themeLight),
                    icon: const Icon(Icons.light_mode),
                  ),
                  ButtonSegment(value: ThemeChoice.dark, label: Text(l.themeDark), icon: const Icon(Icons.dark_mode)),
                  ButtonSegment(
                    value: ThemeChoice.system,
                    label: Text(l.themeSystem),
                    icon: const Icon(Icons.brightness_auto),
                  ),
                ],
                selected: {settings.theme},
                showSelectedIcon: false,
                onSelectionChanged: (s) => notifier.setTheme(s.first),
              ),
            ),
            const SizedBox(height: QtSpace.s4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: QtSpace.s4),
              child: DropdownButtonFormField<String?>(
                initialValue: settings.localeCode,
                decoration: InputDecoration(labelText: l.settingsLanguage),
                items: [
                  DropdownMenuItem(value: null, child: Text(l.settingsLanguageSystem)),
                  const DropdownMenuItem(value: 'vi', child: Text('Tiếng Việt')),
                  const DropdownMenuItem(value: 'en', child: Text('English')),
                ],
                onChanged: notifier.setLocale,
              ),
            ),
            SwitchListTile(
              key: const Key('settings.carry'),
              value: settings.carryOverBalance,
              onChanged: notifier.setCarryOverBalance,
              title: Text(l.settingsCarryOver),
              subtitle: Text(l.settingsCarryOverSub),
              secondary: const Icon(Icons.redo),
            ),
            _section(l.settingsPrivacy),
            SwitchListTile(
              value: settings.hideBalances,
              onChanged: notifier.setHideBalances,
              title: Text(l.settingsHideBalance),
              subtitle: Text(l.settingsHideBalanceSub),
              secondary: const Icon(Icons.visibility_off_outlined),
            ),
            if (vault.quickUnlockSupported) ...[
              ListTile(
                leading: const Icon(Icons.pin_outlined),
                title: Text(l.settingsPin),
                subtitle: Text(pinOn ? l.settingsPinOn : l.settingsPinOff),
                trailing: Wrap(
                  spacing: QtSpace.s2,
                  children: [
                    TextButton(onPressed: _setPin, child: Text(pinOn ? l.settingsPinChange : l.actionAdd)),
                    if (pinOn)
                      TextButton(
                        onPressed: _disablePin,
                        style: TextButton.styleFrom(foregroundColor: p.danger),
                        child: Text(l.settingsPinDisable),
                      ),
                  ],
                ),
              ),
              SwitchListTile(
                value: vault.biometricEnabled,
                onChanged: (pinOn && _bioAvailable == true) ? _toggleBiometric : null,
                title: Text(l.settingsBiometric),
                subtitle: Text(_bioAvailable == false ? l.settingsBiometricUnavailable : l.settingsBiometricSub),
                secondary: const Icon(Icons.fingerprint),
              ),
            ] else
              ListTile(leading: const Icon(Icons.info_outline), title: Text(l.settingsQuickUnlockWeb)),
            if (ref.read(reminderSchedulerProvider).supported)
              SwitchListTile(
                value: settings.billReminders,
                onChanged: (v) async {
                  if (v && !await ref.read(reminderSchedulerProvider).requestPermission()) return;
                  await notifier.setBillReminders(v);
                },
                title: Text(l.settingsNotifications),
                subtitle: Text(l.settingsNotificationsSub),
                secondary: const Icon(Icons.notifications_outlined),
              ),
            if (ref.read(reminderSchedulerProvider).supported)
              SwitchListTile(
                value: settings.taxReminders,
                onChanged: (v) async {
                  if (v && !await ref.read(reminderSchedulerProvider).requestPermission()) return;
                  await notifier.setTaxReminders(v);
                },
                title: Text(l.settingsTaxReminders),
                subtitle: Text(l.settingsTaxRemindersSub),
                secondary: const Icon(Icons.event_note_outlined),
              ),
            ListTile(leading: const Icon(Icons.timer_outlined), title: Text(l.settingsAutoLock)),
            ListTile(
              leading: const Icon(Icons.password),
              title: Text(l.settingsChangePassword),
              onTap: _changePassword,
            ),
            ListTile(leading: const Icon(Icons.key_outlined), title: Text(l.settingsNewRecovery), onTap: _newRecovery),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(l.settingsLockNow),
              onTap: () => ref.read(sessionProvider.notifier).lock(),
            ),
            _section(l.settingsAbout),
            ListTile(leading: const Icon(Icons.shield_outlined), title: Text(l.settingsSecurityNote)),
            ListTile(
              leading: const BrandLogo(size: 24),
              title: Text(l.settingsVersion(appVersion)),
              subtitle: Text(l.settingsLicense),
              onTap: () => showLicensePage(
                context: context,
                applicationName: l.appTitle,
                applicationVersion: appVersion,
                applicationIcon: const BrandLogo(size: 48),
              ),
            ),
            const MakerTile(),
            const SizedBox(height: QtSpace.s4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: QtSpace.s4),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: p.danger,
                  side: BorderSide(color: p.danger),
                ),
                onPressed: _wipe,
                icon: const Icon(Icons.delete_forever_outlined),
                label: Text(l.settingsReset),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _form = GlobalKey<FormState>();
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _new2 = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _new2.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    await yieldFrame();
    try {
      ref.read(servicesProvider).vault.changePassword(_old.text, _new.text);
      if (mounted) Navigator.pop(context, true);
    } on Object {
      if (mounted) setState(() => _error = context.l10n.passwordWrong);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.settingsChangePassword),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PasswordField(
                  controller: _old,
                  label: l.settingsOldPassword,
                  autofocus: true,
                  validator: (v) => (v == null || v.isEmpty) ? l.passwordWrong : null,
                ),
                const SizedBox(height: QtSpace.s4),
                PasswordField(
                  controller: _new,
                  label: l.settingsNewPassword,
                  validator: (v) => (v ?? '').runes.length < 10 ? l.passwordTooShort(10) : null,
                ),
                const SizedBox(height: QtSpace.s4),
                PasswordField(
                  controller: _new2,
                  label: l.passwordConfirmLabel,
                  validator: (v) => v != _new.text ? l.passwordMismatch : null,
                  onSubmitted: (_) => _save(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: QtSpace.s3),
                  Text(_error!, style: TextStyle(color: context.palette.danger)),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: Text(l.actionCancel)),
        FilledButton(onPressed: _busy ? null : _save, child: Text(_busy ? l.working : l.actionSave)),
      ],
    );
  }
}
