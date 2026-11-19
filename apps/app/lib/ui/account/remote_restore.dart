import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../../state/sync_controller.dart';
import '../../sync/api_client.dart';
import '../../theme/tokens.g.dart';
import '../widgets/auth_widgets.dart' show yieldFrame;
import '../widgets/common.dart';
import 'account_page.dart' show syncErrorText;

/// Màn chào trên thiết bị mới: đăng nhập tsudev ⇒ máy chủ có tài khoản mã hóa ⇒ mở bằng mật khẩu/24 từ ⇒ đồng bộ về.
/// Trả true nếu máy chủ CHƯA có tài khoản (người gọi chuyển sang bước tạo mật khẩu; lần đồng bộ đầu sẽ đẩy lên).
Future<bool> signInAndRestoreFlow(BuildContext context, WidgetRef ref, {String? provider}) async {
  final l = context.l10n;
  final sync = ref.read(syncProvider.notifier);
  final err = await sync.signIn(provider: provider);
  if (!context.mounted) return false;
  if (err != null) {
    context.toast(syncErrorText(l, err));
    return false;
  }
  final RemoteAccount? remote;
  try {
    remote = await sync.fetchRemoteAccount();
  } on ApiException catch (e) {
    if (context.mounted) context.toast(syncErrorText(l, e.code));
    return false;
  }
  if (!context.mounted) return false;
  if (remote == null) {
    context.toast(l.syncNoRemoteAccount);
    return true;
  }
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _UnlockRemoteDialog(remote: remote!),
  );
  return false;
}

class _UnlockRemoteDialog extends ConsumerStatefulWidget {
  const _UnlockRemoteDialog({required this.remote});
  final RemoteAccount remote;

  @override
  ConsumerState<_UnlockRemoteDialog> createState() => _UnlockRemoteDialogState();
}

class _UnlockRemoteDialogState extends ConsumerState<_UnlockRemoteDialog> {
  final _input = TextEditingController();
  bool _useWords = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    await yieldFrame();
    try {
      final text = _input.text;
      await ref
          .read(syncProvider.notifier)
          .adoptRemote(
            widget.remote,
            password: _useWords ? null : text,
            words: _useWords ? text.trim().toLowerCase().split(RegExp(r'\s+')) : null,
          );
      _input.clear();
      if (mounted) Navigator.pop(context);
    } on FormatException {
      if (mounted) setState(() => _error = l.syncRemoteInvalid);
    } on RecoveryPhraseException {
      if (mounted) setState(() => _error = l.restoreInvalid);
    } on Object {
      if (mounted) setState(() => _error = _useWords ? l.restoreInvalid : l.passwordWrong);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.syncUnlockRemoteTitle),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.syncUnlockRemoteBody),
            const SizedBox(height: QtSpace.s3),
            TextField(
              controller: _input,
              obscureText: !_useWords,
              autofocus: true,
              minLines: _useWords ? 3 : 1,
              maxLines: _useWords ? 4 : 1,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: _useWords ? l.restoreWordsLabel : l.passwordLabel,
                errorText: _error,
              ),
              onSubmitted: _busy || _useWords ? null : (_) => _submit(),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _useWords,
              title: Text(l.restoreUseRecovery),
              onChanged: (v) => setState(() {
                _useWords = v ?? false;
                _input.clear();
                _error = null;
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy
              ? null
              : () async {
                  await ref.read(syncProvider.notifier).signOut();
                  if (context.mounted) Navigator.pop(context);
                },
          child: Text(l.actionCancel),
        ),
        FilledButton(onPressed: _busy ? null : _submit, child: Text(_busy ? l.working : l.actionContinue)),
      ],
    );
  }
}
