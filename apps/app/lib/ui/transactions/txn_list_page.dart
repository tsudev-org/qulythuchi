import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../../domain/vn_search.dart';
import '../../state/ledger_repository.dart';
import '../../state/providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../widgets/common.dart';
import 'txn_tile.dart';

/// Số ký tự tối thiểu để lọc và thời gian chờ gõ (SEARCH_AND_FILTER.md).
const minQueryLength = 2;
const searchDebounce = Duration(milliseconds: 350);

class TxnListPage extends ConsumerStatefulWidget {
  const TxnListPage({super.key});

  @override
  ConsumerState<TxnListPage> createState() => _TxnListPageState();
}

class _TxnListPageState extends ConsumerState<TxnListPage> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(searchDebounce, () {
      if (mounted) setState(() => _query = v.trim().length >= minQueryLength ? v.trim() : '');
    });
  }

  bool _matches(Txn t, LedgerData data) {
    if (_query.isEmpty) return true;
    final cat = data.category(t.categoryId);
    final parent = cat?.parentId == null ? null : data.category(cat!.parentId);
    final hay = [
      t.note,
      t.payee,
      cat?.name,
      parent?.name,
      data.wallet(t.walletId)?.name,
      data.wallet(t.counterWalletId)?.name,
      ...t.tags,
      formatMoney(Money(t.amount.abs(), data.wallet(t.walletId)?.currency ?? Currency.vnd), withSymbol: false),
    ].whereType<String>().join(' ');
    return matchesVi(hay, _query);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    final data = ref.watch(ledgerProvider);
    final txns = data.txns.where((t) => _matches(t, data)).toList();
    final today = todayCivil();

    // Nhóm theo ngày (danh sách đã sắp mới nhất trước).
    final groups = <(CivilDate, List<Txn>)>[];
    for (final t in txns) {
      if (groups.isEmpty || groups.last.$1 != t.date) groups.add((t.date, []));
      groups.last.$2.add(t);
    }
    final hasWallets = data.wallets.any((w) => !w.archived);

    return Scaffold(
      appBar: AppBar(title: Text(l.navTransactions)),
      floatingActionButton: hasWallets
          ? FloatingActionButton(
              tooltip: l.txnNew,
              onPressed: () => context.go('/transactions/new'),
              child: const Icon(Icons.add),
            )
          : null,
      body: PageBody(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(QtSpace.s4, 0, QtSpace.s4, QtSpace.s2),
              child: TextField(
                controller: _search,
                onChanged: _onChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: l.searchLabel,
                  hintText: l.searchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: l.actionCancel,
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _search.clear();
                            _debounce?.cancel();
                            setState(() => _query = '');
                          },
                        ),
                ),
              ),
            ),
            Expanded(
              child: txns.isEmpty
                  ? (_query.isNotEmpty
                        ? Semantics(liveRegion: true, child: Center(child: Text(l.noResults)))
                        : EmptyState(icon: Icons.receipt_long_outlined, title: l.emptyTxnsTitle, body: l.emptyTxnsBody))
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: groups.length,
                      itemBuilder: (context, i) {
                        final (date, items) = groups[i];
                        final totals = <Currency, int>{};
                        for (final t in items) {
                          if (t.kind == TxnKind.transferIn || t.kind == TxnKind.transferOut) continue;
                          final cur = data.wallet(t.walletId)?.currency ?? Currency.vnd;
                          totals[cur] = (totals[cur] ?? 0) + t.balanceEffect;
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              color: p.bgSubtle,
                              padding: const EdgeInsets.symmetric(horizontal: QtSpace.s4, vertical: QtSpace.s2),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Semantics(
                                      header: true,
                                      child: Text(
                                        dayHeader(context, date, today),
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                  for (final e in totals.entries)
                                    Padding(
                                      padding: const EdgeInsets.only(left: QtSpace.s2),
                                      child: MoneyText(Money(e.value, e.key), signed: true, colored: true),
                                    ),
                                ],
                              ),
                            ),
                            for (final t in items) TxnTile(txn: t, data: data),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
