import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../../state/sync_controller.dart';
import '../../sync/shared_wallets.dart';
import '../../theme/tokens.g.dart';
import '../widgets/common.dart';
import 'shared_wallet_page.dart' show roleLabel, sharingErrorText;

/// Nhận lời mời vào ví chung bằng mã/liên kết (P9, ADR-0015).
class JoinWalletPage extends ConsumerStatefulWidget {
  const JoinWalletPage({super.key, this.initialCode});
  final String? initialCode;

  @override
  ConsumerState<JoinWalletPage> createState() => _JoinWalletPageState();
}

class _JoinWalletPageState extends ConsumerState<JoinWalletPage> {
  final _code = TextEditingController();
  InvitePreview? _preview;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _code.text = widget.initialCode ?? '';
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on Object catch (e) {
      if (mounted) context.toast(sharingErrorText(context.l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _lookUp() async {
    final code = InviteCode.parse(_code.text);
    if (code == null) {
      context.toast(context.l10n.joinInvalidCode);
      return;
    }
    await _run(() async {
      final p = await ref.read(syncProvider.notifier).previewInvite(code);
      if (mounted) setState(() => _preview = p);
    });
  }

  Future<void> _accept() => _run(() async {
    await ref.read(syncProvider.notifier).acceptInvite(_preview!);
    if (!mounted) return;
    context.toast(context.l10n.joinSent);
    setState(() {
      _preview = null;
      _code.clear();
    });
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final signedIn = ref.watch(syncProvider.select((s) => s.signedIn));
    final pending = ref.watch(sharedWalletsProvider.select((s) => s.overview?.pending ?? const <PendingJoin>[]));
    final p = _preview;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.joinTitle),
        bottom: _busy
            ? const PreferredSize(preferredSize: Size.fromHeight(2), child: LinearProgressIndicator(minHeight: 2))
            : null,
      ),
      body: PageBody(
        child: ListView(
          padding: const EdgeInsets.all(QtSpace.s4),
          children: [
            if (!signedIn) ...[
              Text(l.shareNeedSignIn),
              const SizedBox(height: QtSpace.s4),
              OutlinedButton(onPressed: () => context.go('/more/account'), child: Text(l.shareGoSignIn)),
            ] else ...[
              TextField(
                key: const Key('join.code'),
                controller: _code,
                minLines: 1,
                maxLines: 3,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(labelText: l.joinCodeLabel),
                onSubmitted: (_) => _lookUp(),
              ),
              const SizedBox(height: QtSpace.s4),
              FilledButton(
                key: const Key('join.preview'),
                onPressed: _busy ? null : _lookUp,
                child: Text(l.joinPreview),
              ),
              if (p != null) ...[
                const SizedBox(height: QtSpace.s6),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(QtSpace.s4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.joinFrom(p.ownerName ?? l.joinOwnerUnknown),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: QtSpace.s2),
                        Text(l.joinRole(roleLabel(l, p.role))),
                        const SizedBox(height: QtSpace.s2),
                        Text(l.shareIntro),
                        const SizedBox(height: QtSpace.s4),
                        if (p.state == 'accepted')
                          Text(l.joinAlreadyAccepted)
                        else if (p.state == 'own')
                          Text(l.shareErrInviteOwn)
                        else if (p.state == 'taken')
                          Text(l.shareErrInviteTaken)
                        else
                          FilledButton(
                            key: const Key('join.accept'),
                            onPressed: _busy ? null : _accept,
                            child: Text(l.joinAccept),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              if (pending.isNotEmpty) ...[
                const SizedBox(height: QtSpace.s6),
                Text(l.joinPending, style: Theme.of(context).textTheme.titleSmall),
                for (final j in pending)
                  ListTile(
                    leading: const Icon(Icons.hourglass_empty),
                    title: Text(l.joinFrom(j.ownerName ?? l.joinOwnerUnknown)),
                    subtitle: Text(roleLabel(l, j.role)),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
