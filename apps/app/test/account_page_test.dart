import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:qulythuchi/app.dart';
import 'package:qulythuchi/domain/default_categories.dart';
import 'package:qulythuchi/services/notification_bridge.dart';
import 'package:qulythuchi/services/reminders.dart';
import 'package:qulythuchi/state/auto_import_controller.dart';
import 'package:qulythuchi/state/capture_providers.dart';
import 'package:qulythuchi/state/providers.dart';
import 'package:qulythuchi/state/settings.dart';
import 'package:qulythuchi/state/sync_controller.dart';
import 'package:qulythuchi/sync/pkce.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_sync_server.dart';
import 'helpers.dart';
import 'sync_test.dart' show fakeLogin;

/// FutureBuilder chạy trên mạng giả (zone thật): chờ thật rồi bơm khung hình, không pumpAndSettle (vòng quay vô hạn).
Future<void> realSettle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('màn Tài khoản: đăng nhập ⇒ trạng thái, dung lượng, thiết bị; đăng xuất', (tester) async {
    await setSurface(tester, const Size(390, 844));
    final server = FakeSyncServer();
    final services = makeServices((await tester.runAsync(testSodium))!);
    services.vault.createAccount(testPassword);
    SharedPreferences.setMockInitialValues({'locale': 'vi'});
    final sp = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        servicesProvider.overrideWithValue(services),
        sharedPreferencesProvider.overrideWithValue(sp),
        reminderSchedulerProvider.overrideWithValue(NoopReminderScheduler()),
        notificationBridgeProvider.overrideWithValue(const NoopNotificationBridge()),
        quickLinksListenerProvider.overrideWithValue((_) => null),
        syncConfigProvider.overrideWithValue(
          SyncConfig(httpClient: server.client, login: fakeLogin('u1'), autoSync: false),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const QulyApp()));
    await settle(tester);
    container.read(sessionProvider.notifier).finishOnboarding();
    container.read(routerProvider).go('/more/account');
    await settle(tester);
    expect(find.text('Chưa bật đồng bộ'), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('signin.tsudev')));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await realSettle(tester);
    expect(find.text('Người dùng u1'), findsOneWidget);
    await tester.runAsync(() => container.read(syncProvider.notifier).syncNow());
    await realSettle(tester);
    expect(find.textContaining('Đồng bộ lần cuối'), findsOneWidget);
    expect(find.text('Thiết bị này'), findsOneWidget);
    expect(find.textContaining('bản ghi ·'), findsOneWidget);

    await scrollTo(tester, find.text('Đăng xuất'));
    await tester.tap(find.text('Đăng xuất'));
    await settle(tester);
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(FilledButton, 'Đăng xuất'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await settle(tester);
    // Danh sách giữ vị trí cuộn (đã cuộn xuống nút Đăng xuất) - cuộn lên đầu.
    await scrollTo(tester, find.text('Chưa bật đồng bộ'));
    expect(find.text('Chưa bật đồng bộ'), findsOneWidget);
    expect(find.byKey(const ValueKey('account-pro')), findsOneWidget);
    expect(container.read(syncProvider).signedIn, isFalse);
    expect(GoRouter.of(tester.element(find.byType(Scaffold).first)), isNotNull);
  });

  testWidgets('màn chào có nút đăng nhập lấy dữ liệu đã đồng bộ', (tester) async {
    final services = makeServices((await tester.runAsync(testSodium))!);
    await pumpApp(tester, services);
    expect(find.byKey(const ValueKey('tsu-sign-in-tsudev')), findsOneWidget);
    expect(DefaultCategoryLocale.values, isNotEmpty);
  });

  test('parseLoginProviders: giữ lối đã biết theo thứ tự Google/Apple/GitHub; thân hỏng ⇒ null', () {
    expect(
      parseLoginProviders({
        'providers': [
          {'id': 'github'},
          {'id': 'facebook'},
          {'id': 'apple'},
          {'id': 'google'},
        ],
      }),
      ['google', 'apple', 'github'],
    );
    expect(parseLoginProviders({'providers': <Object>[]}), isEmpty);
    expect(parseLoginProviders({'providers': 'apple'}), isNull);
    expect(parseLoginProviders(null), isNull);
    expect(fallbackLoginProviders, isNot(contains('apple')));
  });

  for (final (name, list, expected) in [
    ('IdP bật Apple ⇒ Google, Apple, GitHub', ['github', 'apple', 'google'], ['google', 'apple', 'github']),
    ('IdP chỉ bật Google ⇒ chỉ nút Google', ['google'], ['google']),
    ('máy chủ cũ (404) ⇒ dự phòng Google + GitHub, không Apple', null, ['google', 'github']),
  ]) {
    testWidgets('nút đăng nhập dựng từ danh sách IdP: $name', (tester) async {
      await setSurface(tester, const Size(390, 844));
      final server = FakeSyncServer()..idpProviders = list;
      final services = makeServices((await tester.runAsync(testSodium))!);
      services.vault.createAccount(testPassword);
      SharedPreferences.setMockInitialValues({'locale': 'vi'});
      final sp = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          servicesProvider.overrideWithValue(services),
          sharedPreferencesProvider.overrideWithValue(sp),
          reminderSchedulerProvider.overrideWithValue(NoopReminderScheduler()),
          notificationBridgeProvider.overrideWithValue(const NoopNotificationBridge()),
          quickLinksListenerProvider.overrideWithValue((_) => null),
          syncConfigProvider.overrideWithValue(
            SyncConfig(httpClient: server.client, login: fakeLogin('u1'), autoSync: false),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const QulyApp()));
      await settle(tester);
      container.read(sessionProvider.notifier).finishOnboarding();
      container.read(routerProvider).go('/more/account');
      await realSettle(tester);
      for (final id in knownLoginProviders) {
        expect(find.byKey(Key('signin.$id')), expected.contains(id) ? findsOneWidget : findsNothing, reason: id);
      }
      expect(find.byKey(const Key('signin.tsudev')), findsOneWidget);
      if (expected.contains('apple')) {
        expect(find.text('Tiếp tục với Apple'), findsOneWidget);
        final ys = [for (final id in expected) tester.getTopLeft(find.byKey(Key('signin.$id'))).dy];
        expect(ys, [...ys]..sort());
      }
    });
  }
}
