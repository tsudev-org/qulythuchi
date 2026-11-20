import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../../domain/default_categories.dart';
import '../../security/vault.dart';
import '../../state/providers.dart';
import '../../theme/app_theme.dart';
import '../account/remote_restore.dart';
import '../data/data_page.dart' show restoreFromBackupFlow;
import '../widgets/auth_widgets.dart';
import '../widgets/common.dart';
import '../widgets/sign_in_buttons.dart';

enum _Step { welcome, password, words, verify, pin }

/// Khởi tạo lần đầu: tạo khóa cục bộ (ADR-0002), ghi 24 từ, xác nhận 3 từ ngẫu nhiên, đặt PIN (nếu có kho bí mật).
class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  _Step _step = _Step.welcome;
  List<String>? _words;

  void _finish() => ref.read(sessionProvider.notifier).finishOnboarding();

  @override
  Widget build(BuildContext context) {
    final quick = ref.read(servicesProvider).vault.quickUnlockSupported;
    return switch (_step) {
      _Step.welcome => _Welcome(
        onStart: () => setState(() => _step = _Step.password),
        onSyncSignIn: (provider) async {
          if (await signInAndRestoreFlow(context, ref, provider: provider) && mounted) {
            setState(() => _step = _Step.password);
          }
        },
      ),
      _Step.password => _CreatePassword(
        onBack: () => setState(() => _step = _Step.welcome),
        onCreated: (words) => setState(() {
          _words = words;
          _step = _Step.words;
        }),
      ),
      _Step.words => _ShowWords(words: _words!, onNext: () => setState(() => _step = _Step.verify)),
      _Step.verify => _VerifyWords(
        words: _words!,
        onBack: () => setState(() => _step = _Step.words),
        onVerified: () {
          setState(() {
            _words = null; // bỏ 24 từ khỏi bộ nhớ của giao diện
            _step = _Step.pin;
          });
          if (!quick) _finish();
        },
      ),
      _Step.pin => _SetPin(onDone: _finish),
    };
  }
}

class _Welcome extends ConsumerWidget {
  const _Welcome({required this.onStart, required this.onSyncSignIn});
  final VoidCallback onStart;
  final Future<void> Function(String? provider) onSyncSignIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return AuthScaffold(
      title: l.welcomeTitle,
      body: l.welcomeBody,
      children: [
        Text(l.syncWelcomeSignIn, style: Theme.of(context).textTheme.titleSmall, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        SignInButtons(onSignIn: onSyncSignIn),
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(l.signInOr)),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const Key('welcome.guest'),
          onPressed: onStart,
          icon: const Icon(Icons.person_outline),
          label: Text(l.welcomeGuest),
        ),
        const SizedBox(height: 4),
        Text(
          l.welcomeGuestNote,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.palette.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => restoreFromBackupFlow(context, ref),
          icon: const Icon(Icons.restore),
          label: Text(l.restoreFromBackup),
        ),
      ],
    );
  }
}

class _CreatePassword extends ConsumerStatefulWidget {
  const _CreatePassword({required this.onCreated, required this.onBack});
  final ValueChanged<List<String>> onCreated;
  final VoidCallback onBack;

  @override
  ConsumerState<_CreatePassword> createState() => _CreatePasswordState();
}

class _CreatePasswordState extends ConsumerState<_CreatePassword> {
  final _form = GlobalKey<FormState>();
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _pw.dispose();
    _pw2.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() => _busy = true);
    await yieldFrame();
    if (!mounted) return;
    try {
      final locale = context.appLocale == AppLocale.en ? DefaultCategoryLocale.en : DefaultCategoryLocale.vi;
      final words = ref.read(sessionProvider.notifier).createAccount(_pw.text, locale);
      _pw.clear();
      _pw2.clear();
      widget.onCreated(words);
    } on Object catch (e) {
      if (mounted) context.toast(errorMessage(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AuthScaffold(
      title: l.setupPasswordTitle,
      body: l.setupPasswordBody,
      leading: BackButton(onPressed: _busy ? null : widget.onBack),
      children: [
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              children: [
                PasswordField(
                  controller: _pw,
                  label: l.passwordLabel,
                  autofocus: true,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (v) =>
                      KeyHierarchy.normalizePassword(v ?? '').runes.length < KeyHierarchy.minPasswordLength
                      ? l.passwordTooShort(KeyHierarchy.minPasswordLength)
                      : null,
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _pw2,
                  label: l.passwordConfirmLabel,
                  validator: (v) => v != _pw.text ? l.passwordMismatch : null,
                  onSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(width: 12),
                    Text(l.working),
                  ],
                )
              : Text(l.actionContinue),
        ),
      ],
    );
  }
}

class _ShowWords extends StatefulWidget {
  const _ShowWords({required this.words, required this.onNext});
  final List<String> words;
  final VoidCallback onNext;

  @override
  State<_ShowWords> createState() => _ShowWordsState();
}

class _ShowWordsState extends State<_ShowWords> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    return AuthScaffold(
      title: l.recoveryTitle,
      body: l.recoveryBody,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.bgSurface,
            border: Border.all(color: p.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth >= 400 ? 3 : 2;
              final itemWidth = (c.maxWidth - (cols - 1) * 8) / cols;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < widget.words.length; i++)
                    SizedBox(
                      width: itemWidth,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${i + 1}. ',
                              style: TextStyle(color: p.textSecondary),
                            ),
                            TextSpan(
                              text: widget.words[i],
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          value: _confirmed,
          onChanged: (v) => setState(() => _confirmed = v ?? false),
          title: Text(l.recoveryConfirmCheck),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: _confirmed ? widget.onNext : null, child: Text(l.actionContinue)),
      ],
    );
  }
}

class _VerifyWords extends StatefulWidget {
  const _VerifyWords({required this.words, required this.onVerified, required this.onBack});
  final List<String> words;
  final VoidCallback onVerified;
  final VoidCallback onBack;

  @override
  State<_VerifyWords> createState() => _VerifyWordsState();
}

class _VerifyWordsState extends State<_VerifyWords> {
  late final List<int> _positions;
  late final Map<int, List<String>> _choices;
  final Map<int, String> _picked = {};
  bool _wrong = false;

  @override
  void initState() {
    super.initState();
    final rnd = Random.secure();
    final idx = List<int>.generate(widget.words.length, (i) => i)..shuffle(rnd);
    _positions = idx.take(3).toList()..sort();
    _choices = {
      for (final pos in _positions)
        pos: ({
          widget.words[pos],
          ...(List.of(widget.words)..shuffle(rnd)).where((w) => w != widget.words[pos]).take(3),
        }.toList()..shuffle(rnd)),
    };
  }

  void _check() {
    final ok = _positions.every((p) => _picked[p] == widget.words[p]);
    if (ok) {
      widget.onVerified();
    } else {
      setState(() {
        _wrong = true;
        _picked.clear();
      });
      SemanticsService.sendAnnouncement(View.of(context), context.l10n.recoveryVerifyWrong, Directionality.of(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AuthScaffold(
      title: l.recoveryVerifyTitle,
      body: l.recoveryVerifyBody,
      leading: BackButton(onPressed: widget.onBack),
      children: [
        for (final pos in _positions) ...[
          Text(l.recoveryWordN(pos + 1), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final w in _choices[pos]!)
                ChoiceChip(
                  label: Text(w),
                  selected: _picked[pos] == w,
                  onSelected: (_) => setState(() {
                    _picked[pos] = w;
                    _wrong = false;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (_wrong)
          Row(
            children: [
              Icon(Icons.error_outline, color: context.palette.danger),
              const SizedBox(width: 8),
              Expanded(
                child: Text(l.recoveryVerifyWrong, style: TextStyle(color: context.palette.danger)),
              ),
            ],
          ),
        const SizedBox(height: 16),
        FilledButton(onPressed: _picked.length == _positions.length ? _check : null, child: Text(l.actionContinue)),
      ],
    );
  }
}

class _SetPin extends ConsumerStatefulWidget {
  const _SetPin({required this.onDone});
  final VoidCallback onDone;

  @override
  ConsumerState<_SetPin> createState() => _SetPinState();
}

class _SetPinState extends ConsumerState<_SetPin> {
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AuthScaffold(
      title: l.pinSetupTitle,
      body: l.pinSetupBody,
      children: [
        PinForm(onSaved: widget.onDone),
        const SizedBox(height: 8),
        TextButton(onPressed: widget.onDone, child: Text(l.pinSkip)),
      ],
    );
  }
}

/// Biểu mẫu đặt PIN (dùng cả trong Cài đặt).
class PinForm extends ConsumerStatefulWidget {
  const PinForm({super.key, required this.onSaved});
  final VoidCallback onSaved;

  @override
  ConsumerState<PinForm> createState() => _PinFormState();
}

class _PinFormState extends ConsumerState<PinForm> {
  final _form = GlobalKey<FormState>();
  final _pin = TextEditingController();
  final _pin2 = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _pin.dispose();
    _pin2.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() => _busy = true);
    await yieldFrame();
    try {
      await ref.read(servicesProvider).vault.setPin(_pin.text);
      widget.onSaved();
    } on Object catch (e) {
      if (mounted) context.toast(errorMessage(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PasswordField(
            controller: _pin,
            label: l.pinLabel,
            digitsOnly: true,
            autofocus: true,
            validator: (v) => PinPolicy.isValidPin(v ?? '') ? null : l.pinInvalid,
          ),
          const SizedBox(height: 16),
          PasswordField(
            controller: _pin2,
            label: l.pinConfirmLabel,
            digitsOnly: true,
            validator: (v) => v != _pin.text ? l.pinMismatch : null,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _busy ? null : _save, child: Text(_busy ? l.working : l.actionSave)),
        ],
      ),
    );
  }
}
