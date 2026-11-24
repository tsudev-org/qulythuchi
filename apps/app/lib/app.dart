import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart' show listEquals;
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'domain/txn_filter.dart';
import 'l10n/app_localizations.dart';
import 'pro/pro_controller.dart';
import 'services/reminders.dart';
import 'state/auto_import_controller.dart';
import 'state/capture_providers.dart';
import 'state/providers.dart';
import 'state/settings.dart';
import 'state/sync_controller.dart';
import 'theme/app_theme.dart';
import 'ui/account/account_page.dart';
import 'ui/auto_import/auto_import_page.dart';
import 'ui/categories/categories_page.dart';
import 'ui/data/data_page.dart';
import 'ui/debts/debt_form_page.dart';
import 'ui/debts/debts_page.dart';
import 'ui/events/event_form_page.dart';
import 'ui/events/events_page.dart';
import 'ui/income/income_page.dart';
import 'ui/income/income_plan_form_page.dart';
import 'ui/lock/lock_page.dart';
import 'ui/more/more_page.dart';
import 'ui/onboarding/onboarding.dart';
import 'ui/overview/overview_page.dart';
import 'ui/payment/qr_pay_page.dart';
import 'ui/plan/budget_form_page.dart';
import 'ui/plan/goal_form_page.dart';
import 'ui/plan/plan_page.dart';
import 'ui/pro/pro_page.dart';
import 'ui/pro/pro_prompts.dart';
import 'ui/rates/rates_page.dart';
import 'ui/recurring/recurring_form_page.dart';
import 'ui/recurring/recurring_page.dart';
import 'ui/reports/reports_page.dart';
import 'ui/settings/settings_page.dart';
import 'ui/shell.dart';
import 'ui/tax/tax_page.dart';
import 'ui/transactions/txn_form_page.dart';
import 'ui/transactions/txn_list_page.dart';
import 'ui/wallets/join_wallet_page.dart';
import 'ui/wallets/shared_wallet_page.dart';
import 'ui/wallets/wallet_form_page.dart';
import 'ui/wallets/wallets_page.dart';
import 'ui/widgets/brand.dart';

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
      // Liên kết mời `…/app/#/moi/<mã>` (ADR-0015): mã nằm sau # nên không tới máy chủ.
      GoRoute(
        path: '/moi/:code',
        redirect: (_, s) => Uri(path: '/wallets/join', queryParameters: {'code': s.pathParameters['code']}).toString(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => ProPromptHost(child: AppShell(shell: shell)),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/overview', builder: (_, _) => const OverviewPage())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transactions',
                builder: (_, s) => TxnListPage(initialFilter: TxnFilter.fromQuery(s.uri.queryParameters)),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (_, s) => TxnFormPage(
                      initialKind: s.uri.queryParameters['kind'],
                      initialGoalId: s.uri.queryParameters['goal'],
                      initialAmount: int.tryParse(s.uri.queryParameters['amount'] ?? ''),
                      initialNote: s.uri.queryParameters['note'],
                      initialPayee: s.uri.queryParameters['payee'],
                      initialIncomePlanId: s.uri.queryParameters['plan'],
                      initialCurrency: s.uri.queryParameters['cur'],
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
                    path: 'join',
                    builder: (_, s) => JoinWalletPage(initialCode: s.uri.queryParameters['code']),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (_, s) => WalletFormPage(walletId: s.pathParameters['id']),
                    routes: [
                      GoRoute(
                        path: 'members',
                        builder: (_, s) => SharedWalletPage(walletId: s.pathParameters['id']!),
                      ),
                    ],
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
                  GoRoute(path: 'account', builder: (_, _) => const AccountPage()),
                  GoRoute(path: 'pro', builder: (_, _) => const ProPage()),
                  GoRoute(path: 'rates', builder: (_, _) => const RatesPage()),
                  GoRoute(path: 'reports', builder: (_, _) => const ReportsPage()),
                  GoRoute(path: 'data', builder: (_, _) => const DataPage()),
                  GoRoute(path: 'auto-import', builder: (_, _) => const AutoImportPage()),
                  GoRoute(path: 'tax', builder: (_, _) => const TaxPage()),
                  GoRoute(path: 'qr', builder: (_, _) => const QrPayPage()),
                  GoRoute(
                    path: 'income',
                    builder: (_, _) => const IncomePage(),
                    routes: [
                      GoRoute(path: 'new', builder: (_, _) => const IncomePlanFormPage()),
                      GoRoute(
                        path: ':id',
                        builder: (_, s) => IncomePlanFormPage(planId: s.pathParameters['id']),
                      ),
                    ],
                  ),
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
  StreamSubscription<void>? _quickLinks;
  DateTime? _hiddenAt;
  bool _obscured = false;

  @override
  void initState() {
    super.initState();
    _quickLinks = ref.read(quickLinksListenerProvider)((mode) {
      ref.read(pendingQuickEntryProvider.notifier).request(mode);
      ref.read(routerProvider).go('/overview');
    });
    _lifecycle = AppLifecycleListener(
      onInactive: () => setState(() => _obscured = true),
      onHide: () => _hiddenAt ??= DateTime.now(),
      onShow: _onShow,
      onResume: () {
        _onShow();
        ref.read(syncProvider.notifier).onResume();
        // Quay lại app: làm mới quyền lợi ⇒ màn chính hỏi nhắc gia hạn (7.6 tự lọc "lần mở mới" ≥ 30 phút).
        unawaited(ref.read(proProvider.notifier).refresh());
        unawaited(ref.read(autoImportProvider.notifier).pull());
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
    if (!settings.billReminders && !settings.taxReminders) {
      if (_lastReminders.isNotEmpty) {
        _lastReminders = const [];
        await scheduler.cancelAll();
      }
      return;
    }
    if (ref.read(sessionProvider) != SessionStatus.unlocked) return;
    final times = reminderTimes(
      ref.read(ledgerProvider),
      DateTime.now(),
      bills: settings.billReminders,
      tax: settings.taxReminders,
    );
    if (listEquals(times, _lastReminders)) return;
    _lastReminders = times;
    final l = lookupAppLocalizations(settings.locale ?? resolveAppLocale(PlatformDispatcher.instance.locale));
    await scheduler.replaceAll(times, title: l.notifBillTitle, body: l.notifBillBody);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    unawaited(_quickLinks?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(routerProvider);
    ref.listen(ledgerProvider, (_, _) => _syncReminders());
    // Giữ bộ điều khiển đồng bộ sống suốt vòng đời app (nó tự nghe mở khóa/sửa dữ liệu).
    ref.listen(syncProvider, (_, _) {});
    // Quyền lợi Pro + bộ điều khiển nhắc gia hạn sống suốt tiến trình (một controller, nối vòng đời app).
    ref.listen(proProvider, (_, _) {});
    ref.listen(proRenewalControllerProvider, (_, _) {});
    // Bộ tự nhập (thông báo ngân hàng) tự lấy hàng chờ khi mở khóa.
    ref.listen(autoImportProvider, (_, _) {});
    ref.listen(settingsProvider.select((s) => s.billReminders), (_, _) => _syncReminders());
    ref.listen(settingsProvider.select((s) => s.taxReminders), (_, _) => _syncReminders());
    return MaterialApp.router(
      onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: settings.theme.mode,
      locale: settings.locale,
      localeResolutionCallback: (device, _) => resolveAppLocale(device),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        // ignore: deprecated_member_use
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        // ignore: deprecated_member_use
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
                child: const Center(child: BrandLogo(size: 64)),
              ),
            ),
        ],
      ),
    );
  }
}
