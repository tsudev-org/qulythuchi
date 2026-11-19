import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../../state/providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../widgets/common.dart';

class WalletsPage extends ConsumerStatefulWidget {
  const WalletsPage({super.key});

  @override
  ConsumerState<WalletsPage> createState() => _WalletsPageState();
}

class _WalletsPageState extends ConsumerState<WalletsPage> {
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    final data = ref.watch(ledgerProvider);
    final wallets = data.wallets.where((w) => _showArchived || !w.archived).toList();
    final hasArchived = data.wallets.any((w) => w.archived);
    final totals = data.totals();

    return Scaffold(
      appBar: AppBar(title: Text(l.navWallets)),
      floatingActionButton: FloatingActionButton(
        tooltip: l.walletNew,
        onPressed: () => context.go('/wallets/new'),
        child: const Icon(Icons.add),
      ),
      body: PageBody(
        child: data.wallets.isEmpty
            ? EmptyState(
                icon: Icons.account_balance_wallet_outlined,
                title: l.emptyWalletsTitle,
                body: l.emptyWalletsBody,
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(QtSpace.s4, 0, QtSpace.s4, 96),
                children: [
                  Card(
                    child: ListTile(
                      title: Text(l.overviewTotal, style: TextStyle(color: p.textSecondary)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final m in totals.values)
                            MoneyText(m, style: const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: QtSpace.s4),
                  Card(
                    child: Column(
                      children: [
                        for (final w in wallets)
                          ListTile(
                            leading: Icon(walletTypeIcon(w.type)),
                            title: Text(w.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                              [
                                walletTypeLabel(l, w.type),
                                w.currency.code,
                                if (w.archived) l.walletArchivedBadge,
                              ].join(' · '),
                            ),
                            trailing: MoneyText(data.balance(w), style: const TextStyle(fontWeight: FontWeight.w600)),
                            onTap: () => context.go('/wallets/${w.id}'),
                          ),
                      ],
                    ),
                  ),
                  if (hasArchived)
                    SwitchListTile(
                      value: _showArchived,
                      onChanged: (v) => setState(() => _showArchived = v),
                      title: Text(l.showArchived),
                    ),
                ],
              ),
      ),
    );
  }
}

/// Dùng chung: tiền tệ cho phép chọn khi tạo ví.
List<Currency> get selectableCurrencies => Currency.all;
