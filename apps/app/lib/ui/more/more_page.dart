import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/common.dart';

/// Mục "Thêm": các công cụ ít dùng hằng ngày.
class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final items = [
      (Icons.payments_outlined, l.incomeTitle, '/more/income'),
      (Icons.qr_code_scanner, l.qrTitle, '/more/qr'),
      (Icons.account_balance_outlined, l.taxTitle, '/more/tax'),
      (Icons.insights_outlined, l.navReports, '/more/reports'),
      (Icons.event_repeat_outlined, l.moreRecurring, '/more/recurring'),
      (Icons.handshake_outlined, l.moreDebts, '/more/debts'),
      (Icons.luggage_outlined, l.moreEvents, '/more/events'),
      (Icons.category_outlined, l.navCategories, '/more/categories'),
      (Icons.currency_exchange, l.moreRates, '/more/rates'),
      (Icons.cloud_sync_outlined, l.syncTitle, '/more/account'),
      (Icons.workspace_premium_outlined, l.proMenu, '/more/pro'),
      (Icons.auto_awesome_outlined, l.moreAutoImport, '/more/auto-import'),
      (Icons.import_export, l.dataTitle, '/more/data'),
      (Icons.settings_outlined, l.navSettings, '/more/settings'),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.navMore)),
      body: PageBody(
        child: ListView(
          children: [
            for (final (icon, label, path) in items)
              ListTile(
                leading: Icon(icon),
                title: Text(label),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(path),
              ),
          ],
        ),
      ),
    );
  }
}
