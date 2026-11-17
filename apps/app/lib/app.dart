import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'l10n/app_localizations.dart';
import 'services/reminders.dart';
import 'state/providers.dart';
import 'state/settings.dart';
import 'theme/app_theme.dart';
import 'ui/categories/categories_page.dart';
import 'ui/debts/debt_form_page.dart';
import 'ui/debts/debts_page.dart';
import 'ui/events/event_form_page.dart';
import 'ui/events/events_page.dart';
import 'ui/lock/lock_page.dart';
import 'ui/more/more_page.dart';
import 'ui/onboarding/onboarding.dart';
import 'ui/overview/overview_page.dart';
import 'ui/plan/budget_form_page.dart';
import 'ui/plan/goal_form_page.dart';
import 'ui/plan/plan_page.dart';
import 'ui/rates/rates_page.dart';
import 'ui/recurring/recurring_form_page.dart';
import 'ui/recurring/recurring_page.dart';
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
                    builder: (_, s) => TxnFormPage(
                      initialKind: s.uri.queryParameters['kind'],
                      initialGoalId: s.uri.queryParameters['goal'],
                    ),
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
                path: '/plan',
                builder: (_, _) => const PlanPage(),
                routes: [
                  GoRoute(path: 'budgets/new', builder: (_, _) => const BudgetFormPage()),
                  GoRoute(
                    path: 'budgets/:id',
                    builder: (_, s) => BudgetFormPage(budgetId: s.pathParameters['id']),
                  ),
                  GoRoute(path: 'goals/new', builder: (_, _) => const GoalFormPage()),
                  GoRoute(
                    path: 'goals/:id',
                    builder: (_, s) => GoalFormPage(goalId: s.pathParameters['id']),
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
            routes: [
              GoRoute(
                path: '/more',
                builder: (_, _) => const MorePage(),
                routes: [
                  GoRoute(path: 'categories', builder: (_, _) => const CategoriesPage()),
                  GoRoute(path: 'settings', builder: (_, _) => const SettingsPage()),
                  GoRoute(path: 'rates', builder: (_, _) => const RatesPage()),
                  GoRoute(
                    path: 'recurring',
                    builder: (_, _) => const RecurringPage(),
                    routes: [
                      GoRoute(path: 'new', builder: (_, _) => const RecurringFormPage()),
                      GoRoute(
                        path: ':id',
                        builder: (_, s) => RecurringFormPage(recurringId: s.pathParameters['id']),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'debts',
                    builder: (_, _) => const DebtsPage(),
                    routes: [
                      GoRoute(path: 'new', builder: (_, _) => const DebtFormPage()),
                      GoRoute(
                        path: ':id',
                        builder: (_, s) => DebtFormPage(debtId: s.pathParameters['id']),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'events',
                    builder: (_, _) => const EventsPage(),
                    routes: [
                      GoRoute(path: 'new', builder: (_, _) => const EventFormPage()),
                      GoRoute(
                        path: ':id',
                        builder: (_, s) => EventFormPage(eventId: s.pathParameters['id']),
                      ),
                    ],
                  ),
                ],
              ),
            ],
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

  List<DateTime> _lastReminders = const [];

  /// Lên lịch lại nhắc hóa đơn khi dữ liệu đổi (chỉ khi đã mở khóa - lúc khóa dữ liệu rỗng, không được xóa lịch).
  Future<void> _syncReminders() async {
    final settings = ref.read(settingsProvider);
    final scheduler = ref.read(reminderSchedulerProvider);
    if (!scheduler.supported) return;
    if (!settings.billReminders) {
      if (_lastReminders.isNotEmpty) {
        _lastReminders = const [];
        await scheduler.cancelAll();
      }
      return;
    }
    if (ref.read(sessionProvider) != SessionStatus.unlocked) return;
    final times = reminderTimes(ref.read(ledgerProvider), DateTime.now());
    if (listEquals(times, _lastReminders)) return;
    _lastReminders = times;
    final l = lookupAppLocalizations(settings.locale ?? const Locale('vi'));
    await scheduler.replaceAll(times, title: l.notifBillTitle, body: l.notifBillBody);
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
    ref.listen(ledgerProvider, (_, _) => _syncReminders());
    ref.listen(settingsProvider.select((s) => s.billReminders), (_, _) => _syncReminders());
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
