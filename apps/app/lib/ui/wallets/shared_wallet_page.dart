import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../../state/sync_controller.dart';
import '../../sync/api_client.dart';
import '../../sync/shared_wallets.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../account/account_page.dart' show formatDateTime, syncErrorText;
import '../payment/qr_pay_page.dart' show QrPainter;
import '../widgets/common.dart';

/// Gốc liên kết mời (web app). Bí mật nằm sau `#` nên không tới máy chủ khi mở liên kết.
const inviteOrigin = 'https://qulythuchi.tsudev.com';

String roleLabel(AppLocalizations l, WalletRole r) => switch (r) {
  WalletRole.owner => l.shareRoleOwner,
  WalletRole.editor => l.shareRoleEditor,
  WalletRole.viewer => l.shareRoleViewer,
};

/// Thông điệp cho lỗi ví chung. KHÔNG in chi tiết lỗi.
String sharingErrorText(AppLocalizations l, Object e) => switch (e) {
  SharingException(code: 'missingSecret') => l.shareErrMissingSecret,
  SharingException(code: 'inviteOwn') => l.shareErrInviteOwn,
  SharingException(code: 'inviteTaken') => l.shareErrInviteTaken,
  SharingException(code: 'notSignedIn') => l.shareNeedSignIn,
  SharingException() => l.errGeneric,
  ApiException(code: 'invite_gone') => l.shareErrInviteGone,
  ApiException(code: 'invite_taken') => l.shareErrInviteTaken,
  ApiException(code: 'already_member') => l.shareErrAlreadyMember,
  ApiException(code: 'no_keys') => l.shareErrNoKeys,
  ApiException(code: 'limit') => l.shareErrLimit,
  ApiException(code: 'stale_key' || 'members_changed' || 'wallet_exists') => l.shareErrStale,
  ApiException(code: 'forbidden' || 'owner_cannot_leave') => l.shareErrForbidden,
  ApiException(:final code) => syncErrorText(l, code),
  _ => l.errGeneric,
};

/// Chia sẻ ví + quản lý thành viên, lời mời, quyền (P9, ADR-0015).
class SharedWalletPage extends ConsumerStatefulWidget {
  const SharedWalletPage({super.key, required this.walletId});
  final String walletId;

  @override
  ConsumerState<SharedWalletPage> createState() => _SharedWalletPageState();
}

class _SharedWalletPageState extends ConsumerState<SharedWalletPage> {
  bool _busy = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(syncProvider).signedIn && ref.read(ledgerProvider).isShared(widget.walletId)) {
        _run(() => ref.read(syncProvider.notifier).refreshShared(), onError: () => _loadFailed = true);
      }
    });
  }

  SyncController get _sync => ref.read(syncProvider.notifier);

  Future<void> _run(Future<void> Function() action, {String? done, void Function()? onError}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _loadFailed = false;
    });
    try {
      await action();
      if (mounted && done != null) context.toast(done);
    } on Object catch (e) {
      onError?.call();
      if (mounted) context.toast(sharingErrorText(context.l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _invite() async {
    final l = context.l10n;
    final role = await showDialog<WalletRole>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.shareInviteRoleTitle),
        children: [
          for (final r in [WalletRole.editor, WalletRole.viewer])
            SimpleDialogOption(
              key: Key('share.role.${r.name}'),
              onPressed: () => Navigator.pop(ctx, r),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(r == WalletRole.editor ? Icons.edit_outlined : Icons.visibility_outlined),
                title: Text(roleLabel(l, r)),
                subtitle: Text(r == WalletRole.editor ? l.shareRoleEditorHint : l.shareRoleViewerHint),
              ),
            ),
        ],
      ),
    );
    if (role == null || !mounted) return;
    InviteCode? code;
    await _run(() async => code = await _sync.createInvite(widget.walletId, role));
    if (code != null && mounted) await _showCode(code!);
  }

  Future<void> _showCode(InviteCode code) {
    final l = context.l10n;
    final link = code.link(inviteOrigin);
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.shareInviteCodeTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.shareInviteCodeBody),
              const SizedBox(height: QtSpace.s4),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(QtSpace.s2),
                child: SizedBox(width: 200, height: 200, child: CustomPaint(painter: QrPainter(link))),
              ),
              const SizedBox(height: QtSpace.s4),
              SelectableText(code.encode(), key: const Key('share.code'), style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: link));
              if (ctx.mounted) ctx.toast(l.shareCopied);
            },
            child: Text(l.shareCopyLink),
          ),
          FilledButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code.encode()));
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) context.toast(l.shareCopied);
            },
            child: Text(l.shareCopyCode),
          ),
        ],
      ),
    );
  }

  Future<void> _remove(WalletMember m) async {
    final l = context.l10n;
    if (!await confirmDialog(
      context,
      message: l.shareRemoveConfirm(m.displayName ?? m.email ?? '?'),
      confirmLabel: l.shareRemove,
    )) {
      return;
    }
    await _run(() => _sync.removeMember(widget.walletId, m.userId), done: l.shareRemoved);
  }

  Future<void> _leave(String name) async {
    final l = context.l10n;
    if (!await confirmDialog(context, message: l.shareLeaveConfirm(name), confirmLabel: l.shareLeave)) return;
    await _run(() => _sync.leaveWallet(widget.walletId), done: l.shareLeft);
    if (mounted && !ref.read(ledgerProvider).isShared(widget.walletId)) context.go('/wallets');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    final data = ref.watch(ledgerProvider);
    final signedIn = ref.watch(syncProvider.select((s) => s.signedIn));
    final shared = ref.watch(sharedWalletsProvider);
    final wallet = data.wallet(widget.walletId);
    final info = shared.overview?.wallet(widget.walletId);
    final isShared = data.isShared(widget.walletId);
    final vault = ref.read(servicesProvider).vault;
    final myId = ref.watch(syncProvider.select((s) => s.profile?.userId));

    Widget body;
    if (!signedIn) {
      body = _Message(
        icon: Icons.cloud_off_outlined,
        text: l.shareNeedSignIn,
        action: OutlinedButton(onPressed: () => context.go('/more/account'), child: Text(l.shareGoSignIn)),
      );
    } else if (!isShared) {
      body = _Message(
        icon: Icons.group_outlined,
        text: l.shareIntro,
        action: FilledButton.icon(
          key: const Key('share.start'),
          onPressed: _busy || wallet == null ? null : () => _run(() => _sync.shareWallet(widget.walletId)),
          icon: const Icon(Icons.group_add_outlined),
          label: Text(l.shareStart),
        ),
      );
    } else if (info == null) {
      body = _busy && !_loadFailed
          ? const Center(child: CircularProgressIndicator())
          : _Message(
              icon: Icons.sync_problem_outlined,
              text: l.shareNotLoaded,
              action: OutlinedButton(
                onPressed: () => _run(() => _sync.refreshShared(), onError: () => _loadFailed = true),
                child: Text(l.shareRetry),
              ),
            );
    } else {
      final owner = info.role == WalletRole.owner;
      body = ListView(
        padding: const EdgeInsets.fromLTRB(QtSpace.s4, 0, QtSpace.s4, 96),
        children: [
          if (shared.badInvites > 0 && owner)
            Card(
              color: p.bgSubtle,
              child: ListTile(
                leading: Icon(Icons.gpp_maybe_outlined, color: p.warning),
                title: Text(l.shareBadInvites(shared.badInvites)),
              ),
            ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: Text(l.shareYourRole(roleLabel(l, info.role))),
              subtitle: Text(l.shareMySafetyCode(vault.safetyCode)),
            ),
          ),
          const SizedBox(height: QtSpace.s4),
          _Header(l.shareMembers),
          Card(
            child: Column(
              children: [
                for (final m in info.members)
                  ListTile(
                    key: Key('share.member.${m.userId}'),
                    leading: CircleAvatar(child: Text(_initial(m))),
                    title: Text(
                      m.userId == myId ? '${m.displayName ?? m.email ?? '?'} (${l.shareYou})' : m.displayName ?? '?',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      [
                        roleLabel(l, m.role),
                        ?m.email,
                        if (m.kemPublicKey != null && m.boxPublicKey != null && m.userId != myId)
                          l.shareSafetyCode(vault.sharing.safetyCode(m.kemPublicKey!, m.boxPublicKey!)),
                      ].join(' · '),
                    ),
                    trailing: owner && m.role != WalletRole.owner
                        ? PopupMenuButton<String>(
                            key: Key('share.menu.${m.userId}'),
                            enabled: !_busy,
                            onSelected: (v) => switch (v) {
                              'remove' => _remove(m),
                              _ => _run(() => _sync.changeRole(widget.walletId, m.userId, WalletRole.fromName(v)!)),
                            },
                            itemBuilder: (_) => [
                              for (final r in [WalletRole.editor, WalletRole.viewer])
                                if (r != m.role)
                                  PopupMenuItem(value: r.name, child: Text(l.shareChangeTo(roleLabel(l, r)))),
                              PopupMenuItem(
                                value: 'remove',
                                child: Text(l.shareRemove, style: TextStyle(color: p.danger)),
                              ),
                            ],
                          )
                        : null,
                  ),
              ],
            ),
          ),
          if (owner && info.invites.isNotEmpty) ...[
            const SizedBox(height: QtSpace.s4),
            _Header(l.shareInvites),
            Card(
              child: Column(
                children: [
                  for (final i in info.invites)
                    ListTile(
                      leading: const Icon(Icons.mail_outline),
                      title: Text(roleLabel(l, i.role)),
                      subtitle: Text(
                        i.accepted == null
                            ? '${l.shareInviteWaiting} · ${formatDateTime(i.expiresAt)}'
                            : l.shareInviteAccepted(i.accepted!.displayName ?? i.accepted!.email ?? '?'),
                      ),
                      trailing: IconButton(
                        tooltip: l.shareInviteCancel,
                        icon: const Icon(Icons.close),
                        onPressed: _busy ? null : () => _run(() => _sync.cancelInvite(widget.walletId, i.inviteId)),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: QtSpace.s6),
          if (owner)
            FilledButton.icon(
              key: const Key('share.invite'),
              onPressed: _busy ? null : _invite,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: Text(l.shareInvite),
            )
          else
            OutlinedButton.icon(
              key: const Key('share.leave'),
              style: OutlinedButton.styleFrom(foregroundColor: p.danger),
              onPressed: _busy ? null : () => _leave(wallet?.name ?? ''),
              icon: const Icon(Icons.logout),
              label: Text(l.shareLeave),
            ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          wallet == null ? l.shareTitle : '${l.shareTitle} · ${wallet.name}',
          overflow: TextOverflow.ellipsis,
        ),
        bottom: _busy
            ? const PreferredSize(preferredSize: Size.fromHeight(2), child: LinearProgressIndicator(minHeight: 2))
            : null,
      ),
      body: PageBody(child: body),
    );
  }

  static String _initial(WalletMember m) {
    final s = (m.displayName ?? m.email ?? '?').trim();
    return s.isEmpty ? '?' : s.characters.first.toUpperCase();
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(QtSpace.s2, 0, QtSpace.s2, QtSpace.s2),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, required this.action});
  final IconData icon;
  final String text;
  final Widget action;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(QtSpace.s6),
    children: [
      Icon(icon, size: 48, color: context.palette.textSecondary),
      const SizedBox(height: QtSpace.s4),
      Text(text, textAlign: TextAlign.center),
      const SizedBox(height: QtSpace.s6),
      Center(child: action),
    ],
  );
}
