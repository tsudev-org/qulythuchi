import 'dart:async';

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../../domain/reports.dart';
import '../../domain/txn_filter.dart';
import '../../domain/vn_search.dart';
import '../../state/ledger_repository.dart';
import '../../state/providers.dart';
import '../../state/settings.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../widgets/common.dart';
import 'filter_dialog.dart';
import 'txn_tile.dart';

/// Số ký tự tối thiểu để lọc và thời gian chờ gõ (SEARCH_AND_FILTER.md).
const minQueryLength = 2;
const searchDebounce = Duration(milliseconds: 350);

class TxnListPage extends ConsumerStatefulWidget {
  const TxnListPage({super.key, this.initialFilter = TxnFilter.empty});

  /// Bộ lọc mở sẵn (ví dụ từ Báo cáo → chạm một danh mục).
  final TxnFilter initialFilter;

  @override
  ConsumerState<TxnListPage> createState() => _TxnListPageState();
}

class _TxnListPageState extends ConsumerState<TxnListPage> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '';
  late TxnFilter _filter = widget.initialFilter;

  @override
  void didUpdateWidget(TxnListPage old) {
    super.didUpdateWidget(old);
    if (old.initialFilter != widget.initialFilter) _filter = widget.initialFilter;
  }

  Future<void> _openFilter() async {
    final f = await showDialog<TxnFilter>(
      context: context,
      builder: (_) => FilterDialog(initial: _filter),
    );
    if (f != null && mounted) setState(() => _filter = f);
  }

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
    final reports = Reports(data, Currency.of(ref.watch(settingsProvider.select((s) => s.baseCurrency))));
    final txns = data.txns.where((t) => _filter.matches(t, data, reports) && _matches(t, data)).toList();
    final today = todayCivil();

    // Nhóm theo ngày (danh sách đã sắp mới nhất trước).
    final groups = <(CivilDate, List<Txn>)>[];
    for (final t in txns) {
      if (groups.isEmpty || groups.last.$1 != t.date) groups.add((t.date, []));
      groups.last.$2.add(t);
    }
    final hasWallets = data.wallets.any((w) => !w.archived);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.navTransactions),
        actions: [
          IconButton(
            tooltip: l.filterTitle,
            onPressed: _openFilter,
            icon: Badge(
              isLabelVisible: !_filter.isEmpty,
              label: Text('${_filter.activeCount}'),
              child: const Icon(Icons.filter_list),
            ),
          ),
        ],
      ),
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
              padding: const EdgeInsets.fromLTRB(QtSpace.s4, QtSpace.s2, QtSpace.s4, QtSpace.s2),
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
            if (data.savedFilters.isNotEmpty || !_filter.isEmpty)
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: QtSpace.s4),
                  children: [
                    if (!_filter.isEmpty) ...[
                      InputChip(
                        label: Text(l.filterActive(_filter.activeCount)),
                        onDeleted: () => setState(() => _filter = TxnFilter.empty),
                        deleteButtonTooltipMessage: l.filterClear,
                      ),
                      const SizedBox(width: QtSpace.s2),
                    ],
                    for (final f in data.savedFilters) ...[
                      ChoiceChip(
                        label: Text(f.name),
                        selected: _filter == f.filter,
                        onSelected: (on) => setState(() => _filter = on ? f.filter : TxnFilter.empty),
                      ),
                      const SizedBox(width: QtSpace.s2),
                    ],
                  ],
                ),
              ),
            if (!_filter.isEmpty || _query.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(QtSpace.s4, 0, QtSpace.s4, QtSpace.s1),
                child: Semantics(
                  liveRegion: true,
                  child: Text(l.filterResultCount(txns.length), style: TextStyle(color: p.textSecondary)),
                ),
              ),
            Expanded(
              child: txns.isEmpty
                  ? ((_query.isNotEmpty || !_filter.isEmpty)
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
