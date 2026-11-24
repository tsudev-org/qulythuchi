// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import '../../state/ledger_repository.dart';
import '../../theme/app_theme.dart';
import '../widgets/common.dart';

/// Một dòng giao dịch. Số tiền có dấu +/- và màu (màu không đứng một mình).
class TxnTile extends StatelessWidget {
  const TxnTile({super.key, required this.txn, required this.data, this.showDate = false});
  final Txn txn;
  final LedgerData data;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    final wallet = data.wallet(txn.walletId);
    final cat = data.category(txn.categoryId);
    final parent = cat?.parentId == null ? null : data.category(cat!.parentId);
    final String title;
    final IconData icon;
    switch (txn.kind) {
      case TxnKind.transferOut:
        title = l.txnTransferTo(data.wallet(txn.counterWalletId)?.name ?? '?');
        icon = Icons.north_east;
      case TxnKind.transferIn:
        title = l.txnTransferFrom(data.wallet(txn.counterWalletId)?.name ?? '?');
        icon = Icons.south_west;
      case TxnKind.adjustment:
        title = l.txnAdjustment;
        icon = Icons.tune;
      case TxnKind.expense || TxnKind.income:
        title = cat == null
            // Giao dịch từ định kỳ/sổ nợ thường không có danh mục: tên khoản (ghi chú) dễ nhận hơn "Chưa phân loại".
            ? ((txn.note?.isNotEmpty ?? false) ? txn.note! : l.uncategorized)
            : (parent == null ? cat.name : '${parent.name} › ${cat.name}');
        icon = categoryIcon(cat?.icon ?? parent?.icon);
    }
    final subtitleParts = [
      if (txn.pending) l.pendingLabel,
      if (showDate) formatDate(txn.date),
      wallet?.name ?? '?',
      if (txn.note != null && txn.note!.isNotEmpty && txn.note != title) txn.note!,
    ];
    final currency = wallet?.currency ?? Currency.vnd;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: p.bgSubtle,
        foregroundColor: txn.pending ? p.warning : p.textSecondary,
        child: Icon(txn.pending ? Icons.hourglass_top : icon, size: 20),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitleParts.join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: MoneyText(
        // Giao dịch chờ: balanceEffect = 0 (chưa tính số dư) nhưng vẫn phải hiện số tiền thật.
        Money(
          txn.pending
              ? switch (txn.kind) {
                  TxnKind.income || TxnKind.transferIn || TxnKind.adjustment => txn.amount,
                  TxnKind.expense => -txn.amount,
                  TxnKind.transferOut => -(txn.amount + txn.fee),
                }
              : txn.balanceEffect,
          currency,
        ),
        signed: true,
        colored: txn.kind == TxnKind.income || txn.kind == TxnKind.expense || txn.kind == TxnKind.adjustment,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      onTap: () => context.go('/transactions/${txn.id}'),
    );
  }
}
