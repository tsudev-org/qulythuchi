import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../../services/notification_bridge.dart';
import '../../state/auto_import_controller.dart';
import '../../state/capture_providers.dart';
import '../../state/providers.dart';
import '../../theme/tokens.g.dart';
import '../quick_entry/quick_entry_sheet.dart';
import '../widgets/common.dart';
import 'email_inbox_section.dart';

/// Màn "Tự nhập": ghi nhanh, thông báo ngân hàng (Android), sao kê, email chuyển tiếp.
class AutoImportPage extends ConsumerStatefulWidget {
  const AutoImportPage({super.key});

  @override
  ConsumerState<AutoImportPage> createState() => _AutoImportPageState();
}

class _AutoImportPageState extends ConsumerState<AutoImportPage> with WidgetsBindingObserver {
  bool? _permission;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    // Quay lại từ màn cài đặt quyền của hệ thống.
    if (s == AppLifecycleState.resumed) _checkPermission();
  }

  Future<void> _checkPermission() async {
    final bridge = ref.read(notificationBridgeProvider);
    if (!bridge.supported) return;
    final ok = await bridge.isEnabled();
    if (mounted) setState(() => _permission = ok);
  }

  Future<void> _toggleNotifications(bool v) async {
    final l = context.l10n;
    final c = ref.read(autoImportProvider.notifier);
    if (v) {
      final ok = await confirmDialog(
        context,
        message: l.bankNotifDisclosure,
        confirmLabel: l.bankNotifDisclosureOk,
        destructive: false,
      );
      if (!ok) return;
    }
    await c.setNotifications(v);
    if (v && _permission != true) await ref.read(notificationBridgeProvider).openSettings();
  }

  Future<void> _addApp() async {
    final l = context.l10n;
    final apps = await ref.read(notificationBridgeProvider).installedApps();
    if (!mounted) return;
    final chosen = ref.read(autoImportProvider).settings.apps;
    final known = [
      for (final a in apps)
        if (knownBankApps.containsKey(a.packageName) && !chosen.containsKey(a.packageName)) a,
    ];
    final others = [
      for (final a in apps)
        if (!knownBankApps.containsKey(a.packageName) && !chosen.containsKey(a.packageName)) a,
    ];
    final picked = await showDialog<InstalledApp>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.bankNotifPickApp),
        children: [
          if (known.isNotEmpty) Padding(padding: const EdgeInsets.all(QtSpace.s3), child: Text(l.bankNotifKnownApps)),
          for (final a in [...known, ...others])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, a),
              child: Text(a.label.isEmpty ? a.packageName : a.label),
            ),
        ],
      ),
    );
    if (picked == null || !mounted) return;
    final wallets = ref.read(ledgerProvider).wallets.where((w) => !w.archived).toList();
    final def =
        wallets.where((w) => w.type == WalletType.bank || w.type == WalletType.ewallet).firstOrNull ??
        wallets.firstOrNull;
    if (def == null) {
      context.toast(l.importNeedWallet);
      return;
    }
    await ref.read(autoImportProvider.notifier).setApp(picked.packageName, def.id);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final st = ref.watch(autoImportProvider);
    final s = st.settings;
    final data = ref.watch(ledgerProvider);
    final bridge = ref.watch(notificationBridgeProvider);
    final wallets = data.wallets.where((w) => !w.archived).toList();
    final voice = ref.watch(voiceInputProvider);
    final scanner = ref.watch(receiptScannerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.autoImportTitle)),
      body: PageBody(
        child: ListView(
          padding: const EdgeInsets.all(QtSpace.s4),
          children: [
            _Card(
              title: l.quickTitle,
              children: [
                Text(l.quickExplain),
                Wrap(
                  spacing: QtSpace.s2,
                  runSpacing: QtSpace.s2,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => showQuickEntry(context),
                      icon: const Icon(Icons.edit_note),
                      label: Text(l.quickTitle),
                    ),
                    if (voice.supported)
                      FilledButton.tonalIcon(
                        onPressed: () => showQuickEntry(context, mode: QuickEntryMode.voice),
                        icon: const Icon(Icons.mic_none),
                        label: Text(l.voiceStart),
                      ),
                    if (scanner.supported)
                      FilledButton.tonalIcon(
                        onPressed: () => showQuickEntry(context, mode: QuickEntryMode.scan),
                        icon: const Icon(Icons.document_scanner_outlined),
                        label: Text(l.scanReceipt),
                      ),
                  ],
                ),
                if (!voice.supported) Text(scanner.supported ? l.voiceMobileOnly : l.captureMobileOnly),
                if (scanner.supported && !scanner.camera) Text(l.scanDesktopHint),
                if (!scanner.supported && !kIsWeb && defaultTargetPlatform == TargetPlatform.linux)
                  Text(l.scanLinuxNeedsTesseract),
              ],
            ),
            _Card(
              title: l.bankNotifTitle,
              children: [
                if (!bridge.supported)
                  Text(l.bankNotifAndroidOnly)
                else ...[
                  Text(l.bankNotifExplain),
                  SwitchListTile(
                    key: const Key('notif.enable'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.bankNotifEnable),
                    value: s.notifications,
                    onChanged: _toggleNotifications,
                  ),
                  if (s.notifications) ...[
                    if (_permission == false)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.warning_amber_outlined),
                        title: Text(l.bankNotifNoPermission),
                        trailing: TextButton(onPressed: bridge.openSettings, child: Text(l.bankNotifGrant)),
                      ),
                    for (final e in s.apps.entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: QtSpace.s2),
                        child: Row(
                          children: [
                            Expanded(child: Text(knownBankApps[e.key] ?? e.key, overflow: TextOverflow.ellipsis)),
                            const SizedBox(width: QtSpace.s2),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: data.wallet(e.value) == null ? null : e.value,
                                isExpanded: true,
                                decoration: InputDecoration(labelText: l.txnWallet),
                                items: [
                                  for (final w in wallets)
                                    DropdownMenuItem(
                                      value: w.id,
                                      child: Text(w.name, overflow: TextOverflow.ellipsis),
                                    ),
                                ],
                                onChanged: (v) => ref.read(autoImportProvider.notifier).setApp(e.key, v),
                              ),
                            ),
                            IconButton(
                              tooltip: l.actionDelete,
                              onPressed: () => ref.read(autoImportProvider.notifier).setApp(e.key, null),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: _addApp,
                      icon: const Icon(Icons.add),
                      label: Text(l.bankNotifAddApp),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l.autoConfirm),
                      subtitle: Text(l.autoConfirmHint),
                      value: s.autoConfirm,
                      onChanged: (v) => ref.read(autoImportProvider.notifier).setAutoConfirm(v),
                    ),
                    if (st.lastRun != null) Text(l.bankNotifLastRun(st.lastAdded, st.lastIgnored)),
                  ],
                ],
              ],
            ),
            _Card(
              title: l.statementTitle,
              children: [
                Text(l.statementExplain),
                OutlinedButton.icon(
                  onPressed: () => context.go('/more/data'),
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text(l.statementOpen),
                ),
              ],
            ),
            const EmailInboxSection(),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: QtSpace.s4),
    child: Padding(
      padding: const EdgeInsets.all(QtSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: QtSpace.s3,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          ...children,
        ],
      ),
    ),
  );
}
