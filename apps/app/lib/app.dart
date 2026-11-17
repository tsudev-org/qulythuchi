import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'l10n/app_localizations.dart';
import 'state/providers.dart';
import 'state/settings.dart';
import 'theme/app_theme.dart';
import 'ui/categories/categories_page.dart';
import 'ui/lock/lock_page.dart';
import 'ui/onboarding/onboarding.dart';
import 'ui/overview/overview_page.dart';
import 'ui/settings/settings_page.dart';
import 'ui/shell.dart';
import 'ui/transactions/txn_form_page.dart';
import 'ui/transactions/txn_list_page.dart';
import 'ui/wallets/wallet_form_page.dart';
import 'ui/wallets/wallets_page.dart';

/// Thời gian ở nền tối đa trước khi tự khóa.
const autoLockAfter = Duration(seconds: 60);

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  String? redirect(BuildContext context, GoRouterState state) {
    final status = ref.read(sessionProvider);
    final loc = state.matchedLocation;
    final inSetup = loc.startsWith('/welcome');
    switch (status) {
      case SessionStatus.needsSetup:
      case SessionStatus.onboarding:
        return inSetup ? null : '/welcome';
      case SessionStatus.locked:
        return loc == '/lock' ? null : '/lock';
      case SessionStatus.unlocked:
        return (inSetup || loc == '/lock') ? '/overview' : null;
    }
  }

  return GoRouter(
    initialLocation: '/overview',
    refreshListenable: refresh,
    redirect: redirect,
    routes: [
      GoRoute(path: '/welcome', builder: (_, _) => const OnboardingFlow()),
      GoRoute(path: '/lock', builder: (_, _) => const LockPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/overview', builder: (_, _) => const OverviewPage())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transactions',
                builder: (_, _) => const TxnListPage(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (_, s) => TxnFormPage(initialKind: s.uri.queryParameters['kind']),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (_, s) => TxnFormPage(txnId: s.pathParameters['id']),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/wallets',
                builder: (_, _) => const WalletsPage(),
                routes: [
                  GoRoute(path: 'new', builder: (_, _) => const WalletFormPage()),
                  GoRoute(
                    path: ':id',
                    builder: (_, s) => WalletFormPage(walletId: s.pathParameters['id']),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/categories', builder: (_, _) => const CategoriesPage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/settings', builder: (_, _) => const SettingsPage())],
          ),
        ],
      ),
    ],
  );
});

class QulyApp extends ConsumerStatefulWidget {
  const QulyApp({super.key});

  @override
  ConsumerState<QulyApp> createState() => _QulyAppState();
}

class _QulyAppState extends ConsumerState<QulyApp> {
  late final AppLifecycleListener _lifecycle;
  DateTime? _hiddenAt;
  bool _obscured = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onInactive: () => setState(() => _obscured = true),
      onHide: () => _hiddenAt ??= DateTime.now(),
      onShow: _onShow,
      onResume: () {
        _onShow();
        setState(() => _obscured = false);
      },
    );
  }

  void _onShow() {
    final at = _hiddenAt;
    _hiddenAt = null;
    if (at != null && DateTime.now().difference(at) >= autoLockAfter) {
      ref.read(sessionProvider.notifier).lock();
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: settings.theme.mode,
      locale: settings.locale,
      localeResolutionCallback: (device, supported) {
        if (device != null && supported.any((l) => l.languageCode == device.languageCode)) {
          return Locale(device.languageCode);
        }
        return const Locale('vi');
      },
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      builder: (context, child) => Stack(
        children: [
          ?child,
          // Che nội dung khi app mất tiêu điểm (ảnh chụp đa nhiệm). Android còn có FLAG_SECURE, iOS che ở AppDelegate.
          if (_obscured)
            Positioned.fill(
              child: ColoredBox(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: const Center(child: Icon(Icons.lock_outline, size: 48)),
              ),
            ),
        ],
      ),
    );
  }
}
