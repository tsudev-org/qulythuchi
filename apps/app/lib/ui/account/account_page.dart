import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../state/sync_controller.dart';
import '../../sync/api_client.dart';
import '../../sync/sync_engine.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../data/data_page.dart' show saveBytes;
import '../widgets/common.dart';
import '../widgets/sign_in_buttons.dart';

/// Thông điệp cho mã lỗi đồng bộ/đăng nhập. KHÔNG in chi tiết lỗi (có thể chứa dữ liệu).
String syncErrorText(AppLocalizations l, String? code) => switch (code) {
  null => '',
  ApiException.network || 'timeout' => l.syncErrNetwork,
  ApiException.tlsPin => l.syncErrTls,
  'device_revoked' || 'invalid_grant' || ApiException.signedOut || 'unauthenticated' => l.syncErrSignedOut,
  'access_denied' => l.syncErrDenied,
  'no_browser' => l.syncErrNoBrowser,
  'rate_limited' => l.syncErrRateLimited,
  'otherUser' => l.syncBlockOtherUser,
  _ => l.syncErrGeneric,
};

String syncBlockText(AppLocalizations l, SyncBlock b) => switch (b) {
  SyncBlock.differentAccount => l.syncBlockDifferentAccount,
  SyncBlock.identityChanged => l.syncBlockIdentityChanged,
  SyncBlock.rollback => l.syncBlockRollback,
  SyncBlock.pendingDeletion => l.syncBlockPendingDeletion,
  SyncBlock.otherUser => l.syncBlockOtherUser,
};

String _two(int v) => v.toString().padLeft(2, '0');
String formatDateTime(DateTime t) {
  final x = t.toLocal();
  return '${_two(x.hour)}:${_two(x.minute)} ${_two(x.day)}/${_two(x.month)}/${x.year}';
}

/// Tài khoản TsuDEV + đồng bộ: đăng nhập/đăng xuất, trạng thái, thiết bị, dung lượng, xuất, xóa tài khoản.
class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  bool _busy = false;
  Future<_ServerInfo>? _info;

  @override
  void initState() {
    super.initState();
    if (ref.read(syncProvider).signedIn) _info = _loadInfo();
  }

  Future<_ServerInfo> _loadInfo() async {
    final c = ref.read(syncProvider.notifier);
    final results = await Future.wait([c.me(), c.usage(), c.devices()]);
    return _ServerInfo(
      me: results[0] as Map<String, Object?>,
      usage: results[1] as Map<String, Object?>,
      devices: results[2] as List<Map<String, Object?>>,
    );
  }

  void _reload() {
    final next = _loadInfo();
    setState(() {
      _info = next;
    });
  }

  Future<void> _guard(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on ApiException catch (e) {
      if (mounted) context.toast(syncErrorText(context.l10n, e.code));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signIn([String? provider]) => _guard(() async {
    final err = await ref.read(syncProvider.notifier).signIn(provider: provider);
    if (!mounted) return;
    if (err != null) {
      context.toast(syncErrorText(context.l10n, err));
    } else if (ref.read(syncProvider).signedIn) {
      _reload();
    }
  });

  Future<void> _signOut() async {
    final l = context.l10n;
    if (!await confirmDialog(context, message: l.syncSignOutConfirm, confirmLabel: l.syncSignOut, destructive: false)) {
      return;
    }
    await _guard(() async {
      await ref.read(syncProvider.notifier).signOut();
      if (mounted) setState(() => _info = null);
    });
  }

  Future<void> _revoke(Map<String, Object?> d) async {
    final l = context.l10n;
    if (!await confirmDialog(context, message: l.syncRevokeConfirm(d['name']! as String), confirmLabel: l.syncRevoke)) {
      return;
    }
    await _guard(() async {
      await ref.read(syncProvider.notifier).revokeDevice(d['id']! as String);
      if (mounted) _reload();
    });
  }

  Future<void> _export() async {
    final l = context.l10n;
    await _guard(() async {
      final bytes = await ref.read(syncProvider.notifier).exportServerData();
      final ok = await saveBytes('qulythuchi-may-chu', 'json', bytes, MimeType.json);
      if (mounted && ok) context.toast(l.syncExportDone);
    });
  }

  Future<void> _deleteAccount() async {
    final l = context.l10n;
    if (!await confirmDialog(context, message: l.syncDeleteConfirm, confirmLabel: l.syncDeleteAccount)) return;
    await _guard(() async {
      await ref.read(syncProvider.notifier).requestDeletion();
      if (mounted) _reload();
    });
  }

  Future<void> _cancelDeletion() => _guard(() async {
    await ref.read(syncProvider.notifier).cancelDeletion();
    if (mounted) _reload();
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = ref.watch(syncProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.syncTitle)),
      body: PageBody(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: QtSpace.s2),
          children: s.signedIn ? _signedIn(context, s) : _signedOut(context, s),
        ),
      ),
    );
  }

  List<Widget> _signedOut(BuildContext context, SyncState s) {
    final l = context.l10n;
    return [
      ListTile(
        leading: const Icon(Icons.cloud_off_outlined),
        title: Text(l.syncSignedOutTitle),
        subtitle: Text(l.syncSignedOutBody),
      ),
      if (s.error != null) ListTile(leading: const Icon(Icons.info_outline), title: Text(syncErrorText(l, s.error))),
      Padding(
        padding: const EdgeInsets.all(QtSpace.s4),
        child: SignInButtons(busy: _busy, onSignIn: _signIn),
      ),
      ListTile(leading: const Icon(Icons.person_outline), title: Text(l.guestModeNote)),
      ListTile(leading: const Icon(Icons.shield_outlined), title: Text(l.syncE2eeNote)),
    ];
  }

  List<Widget> _signedIn(BuildContext context, SyncState s) {
    final l = context.l10n;
    final p = s.profile;
    final status = switch (s.phase) {
      SyncPhase.syncing => l.syncStatusSyncing,
      SyncPhase.blocked => syncBlockText(l, s.block!),
      SyncPhase.error => syncErrorText(l, s.error),
      _ => s.lastSyncAt == null ? l.syncStatusNever : l.syncStatusLast(formatDateTime(s.lastSyncAt!)),
    };
    return [
      ListTile(
        leading: const Icon(Icons.account_circle_outlined),
        title: Text(p?.displayName ?? ''),
        subtitle: p?.email == null ? null : Text(p!.email!),
      ),
      ListTile(
        leading: Icon(switch (s.phase) {
          SyncPhase.syncing => Icons.sync,
          SyncPhase.blocked => Icons.gpp_maybe_outlined,
          SyncPhase.error => Icons.sync_problem_outlined,
          _ => Icons.cloud_done_outlined,
        }),
        title: Text(status),
        subtitle: Text(
          [
            if (s.pending > 0) l.syncPending(s.pending),
            if (s.quotaFull) l.syncQuotaFull,
            if (s.rejected > 0 && !s.quotaFull) l.syncRejected(s.rejected),
            if (s.filesPending > 0) l.attFilesPending(s.filesPending),
            if (s.filesBlocked) l.attProBlocked,
          ].join(' · '),
        ),
        trailing: TextButton(
          onPressed: s.phase == SyncPhase.syncing ? null : () => ref.read(syncProvider.notifier).syncNow(),
          child: Text(l.syncNow),
        ),
      ),
      FutureBuilder<_ServerInfo>(
        future: _info,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.all(QtSpace.s4),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snap.hasError || snap.data == null) {
            final e = snap.error;
            return ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(syncErrorText(l, e is ApiException ? e.code : 'x')),
              trailing: TextButton(onPressed: _reload, child: Text(l.syncRetry)),
            );
          }
          return _serverSection(context, snap.data!);
        },
      ),
      const Divider(),
      ListTile(
        leading: const Icon(Icons.logout),
        title: Text(l.syncSignOut),
        subtitle: Text(l.syncSignOutBody),
        onTap: _busy ? null : _signOut,
      ),
    ];
  }

  Widget _serverSection(BuildContext context, _ServerInfo info) {
    final l = context.l10n;
    final rec = info.usage['records']! as Map;
    final files = info.usage['files']! as Map;
    String mb(Object? b) => ((b! as num) / (1024 * 1024)).toStringAsFixed(1);
    final deletion = info.me['deletion'] as Map?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (deletion != null)
          ListTile(
            leading: Icon(Icons.warning_amber_outlined, color: context.palette.danger),
            title: Text(l.syncDeletionPending(deletion['days_remaining']! as int)),
            trailing: TextButton(onPressed: _busy ? null : _cancelDeletion, child: Text(l.syncDeletionCancel)),
          ),
        ListTile(
          leading: const Icon(Icons.storage_outlined),
          title: Text(l.syncUsage),
          subtitle: Text(
            l.syncUsageDetail(
              rec['count']! as int,
              mb(rec['bytes']),
              mb(rec['quota_bytes']),
              mb(files['bytes']),
              mb(files['quota_bytes']),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(QtSpace.s4, QtSpace.s3, QtSpace.s4, 0),
          child: Text(l.syncDevices, style: Theme.of(context).textTheme.titleSmall),
        ),
        for (final d in info.devices)
          ListTile(
            leading: Icon(switch (d['platform']) {
              'android' || 'ios' => Icons.smartphone,
              'web' => Icons.language,
              _ => Icons.computer,
            }),
            title: Text(d['name']! as String),
            subtitle: Text(
              d['current'] == true
                  ? l.syncThisDevice
                  : l.syncLastSeen(formatDateTime(DateTime.parse(d['last_seen_at']! as String))),
            ),
            trailing: d['current'] == true
                ? null
                : IconButton(
                    tooltip: l.syncRevoke,
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: _busy ? null : () => _revoke(d),
                  ),
          ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.download_outlined),
          title: Text(l.syncExport),
          subtitle: Text(l.syncExportBody),
          onTap: _busy ? null : _export,
        ),
        if (deletion == null)
          ListTile(
            leading: Icon(Icons.delete_forever_outlined, color: context.palette.danger),
            title: Text(l.syncDeleteAccount),
            subtitle: Text(l.syncDeleteBody),
            onTap: _busy ? null : _deleteAccount,
          ),
      ],
    );
  }
}

final class _ServerInfo {
  const _ServerInfo({required this.me, required this.usage, required this.devices});
  final Map<String, Object?> me;
  final Map<String, Object?> usage;
  final List<Map<String, Object?>> devices;
}
