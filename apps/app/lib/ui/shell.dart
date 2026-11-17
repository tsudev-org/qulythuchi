import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'widgets/common.dart';

/// Khung điều hướng: thanh dưới trên điện thoại, thanh bên trên màn rộng.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  void _go(int i) => shell.goBranch(i, initialLocation: i == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final items = [
      (Icons.dashboard_outlined, Icons.dashboard, l.navOverview),
      (Icons.receipt_long_outlined, Icons.receipt_long, l.navTransactions),
      (Icons.savings_outlined, Icons.savings, l.navPlan),
      (Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, l.navWallets),
      (Icons.more_horiz, Icons.more_horiz, l.navMore),
    ];
    final wide = MediaQuery.sizeOf(context).width >= wideBreakpoint;
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: MediaQuery.sizeOf(context).width >= 1200,
              selectedIndex: shell.currentIndex,
              onDestinationSelected: _go,
              labelType: MediaQuery.sizeOf(context).width >= 1200 ? null : NavigationRailLabelType.all,
              destinations: [
                for (final (icon, selected, label) in items)
                  NavigationRailDestination(icon: Icon(icon), selectedIcon: Icon(selected), label: Text(label)),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: ScaffoldMessenger(child: shell)),
          ],
        ),
      );
    }
    return Scaffold(
      // Messenger riêng: thông báo gắn vào Scaffold của trang (có FAB) nên tự nâng lên trên nút +.
      body: ScaffoldMessenger(child: shell),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: _go,
        destinations: [
          for (final (icon, selected, label) in items)
            NavigationDestination(icon: Icon(icon), selectedIcon: Icon(selected), label: label),
        ],
      ),
    );
  }
}
