import 'dart:convert';
import 'dart:io';

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:qulythuchi/l10n/app_localizations.dart';
import 'package:qulythuchi/pro/channel.dart';
import 'package:qulythuchi/pro/pro_block.dart';
import 'package:qulythuchi/pro/pro_controller.dart';
import 'package:qulythuchi/pro/purchases.dart';
import 'package:qulythuchi/state/sync_controller.dart';
import 'package:qulythuchi/ui/pro/pro_page.dart';
import 'package:qulythuchi/ui/pro/pro_prompts.dart';
import 'package:tsudev_ui/tsudev_ui.dart';

import 'fake_sync_server.dart';
import 'helpers.dart';
import 'support/jws_fixture.dart';
import 'sync_test.dart' show cashOf, device, spend;

/// T7 app + PRO2 phần app (ADR-0019): PRODUCT_POLICY 7.5 (nguyên văn), 7.6 (6 test bắt buộc), 7.3, 402 `reason`,
/// kênh phát hành (bản Play không dẫn ra web), mã cài đặt.

// ------------------------------------------------------------------ Khung test

/// Quyền lợi giả: test đặt thẳng [EntitlementState] (từ JWS ký thật bằng khoá thử) rồi "làm mới xong".
class FakePro extends ProController {
  @override
  ProState build() => const ProState();

  void emit(EntitlementState ent, {ServerPro? server}) =>
      state = ProState(ent: ent, server: server, checks: state.checks + 1);
}

/// Cửa hàng giả: ghi lại mọi lượt mua (để chứng minh bản Play đi IAP, không ra web).
class FakeStore implements StorePurchases {
  final bought = <(String, String)>[];
  Map<String, String> price = {
    PlayIds.pro: '499.000 ₫',
    'ung_ho_20k': '20.000 ₫',
    'ung_ho_50k': '50.000 ₫',
    'ung_ho_100k': '100.000 ₫',
    'ung_ho_200k': '200.000 ₫',
  };
  @override
  Future<Map<String, String>> prices() async => price;
  @override
  Future<PurchaseOutcome> buy(String productId, {required String accountId}) async {
    bought.add((productId, accountId));
    return PurchaseOutcome.pending;
  }

  @override
  void start(ReceiptVerifier verify) {}
}

final class Clock {
  Clock(this.now);
  DateTime now;
  DateTime call() => now;
}

/// JWS thật (ES256, khoá thử) ⇒ [EntitlementState] qua đúng `EntitlementsRepository` của `tsudev_ui`.
Future<EntitlementState> stateOf(
  Clock clock, {
  DateTime? proUntil,
  int devices = 1,
  String badge = 'none',
  DateTime? iat,
}) async {
  final jws = signerA.sign(claims(iat: iat ?? clock.now, proUntil: proUntil, devices: devices, badge: badge));
  final repo = EntitlementsRepository(
    verifier: testVerifier(),
    store: InMemoryKeyValueStore(),
    fetchJws: () async => jws,
    clock: clock.call,
  );
  return repo.refresh();
}

typedef Host = ({FakePro pro, InMemoryKeyValueStore store, FakeStore shop});

Future<Host> pumpHost(
  WidgetTester tester,
  Clock clock, {
  DistChannel channel = DistChannel.direct,
  Locale? locale,
}) async {
  final store = InMemoryKeyValueStore();
  final shop = FakeStore();
  late FakePro pro;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tsuStoreProvider.overrideWithValue(store),
        proClockProvider.overrideWithValue(clock.call),
        proPromptsEnabledProvider.overrideWithValue(true),
        distChannelProvider.overrideWithValue(channel),
        storePurchasesProvider.overrideWithValue(shop),
        proProvider.overrideWith(() => pro = FakePro()),
      ],
      child: MaterialApp(
        locale: locale ?? const Locale('vi'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          // ignore: deprecated_member_use
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          // ignore: deprecated_member_use
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ProPromptHost(child: Scaffold(body: Text('màn chính'))),
      ),
    ),
  );
  await tester.pump();
  return (pro: pro, store: store, shop: shop);
}

const reminderTitle = 'Gia hạn TsuDEV Pro';
const expiredTitle = 'TsuDEV Pro đã hết hạn';

Future<void> emit(WidgetTester tester, Host h, EntitlementState s, {ServerPro? server}) async {
  h.pro.emit(s, server: server);
  await tester.pumpAndSettle();
}

Future<void> close(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

/// Lấy đoạn nguyên văn trong PRODUCT_POLICY.md (gộp xuống dòng + thụt lề thành một dấu cách).
String policyQuote(String after) {
  final md = File('../../.standards/docs/PRODUCT_POLICY.md').readAsStringSync();
  final start = md.indexOf(after);
  expect(start, greaterThanOrEqualTo(0), reason: 'không thấy "$after" trong PRODUCT_POLICY.md');
  final from = start + after.length;
  final end = md.indexOf('"', from);
  return md.substring(from, end).replaceAll(RegExp(r'\s*\n\s*(- )?'), ' ').trim();
}

void main() {
  // ---------------------------------------------------------------- 7.5 nguyên văn

  group('PRODUCT_POLICY 7.5 - điều khoản nguyên văn', () {
    test('vi và en khớp từng chữ với .standards (thay {giá}/{price})', () {
      final vi = lookupAppLocalizations(const Locale('vi'));
      final en = lookupAppLocalizations(const Locale('en'));
      expect(vi.proTerms('{giá}'), policyQuote('nguyên văn (vi): "'));
      expect(en.proTerms('{price}'), policyQuote('(en): "'));
    });

    test('không còn gói tháng / "tự gia hạn" / "huỷ bất cứ lúc nào" trong chuỗi và mã', () {
      for (final f in ['lib/l10n/app_vi.arb', 'lib/l10n/app_en.arb']) {
        final arb = (jsonDecode(File(f).readAsStringSync()) as Map).cast<String, Object?>();
        final t = [
          for (final e in arb.entries)
            if (e.key.startsWith('pro') || e.key.startsWith('donate')) e.value,
        ].join('\n').toLowerCase();
        for (final bad in [
          '49.000',
          '/tháng',
          'thang',
          'per month',
          'monthly',
          'cancel anytime',
          'huỷ bất cứ',
          'hủy bất cứ',
        ]) {
          expect(t.contains(bad), isFalse, reason: '$f chứa "$bad"');
        }
        expect(RegExp(r'(?<!không )tự gia hạn').hasMatch(t), isFalse, reason: f);
        expect(RegExp(r'(?<!not )renews? automatically').hasMatch(t), isFalse, reason: f);
      }
      expect(PlayIds.all, {'tsudev_pro', 'ung_ho_20k', 'ung_ho_50k', 'ung_ho_100k', 'ung_ho_200k'});
      expect(PlayIds.proBasePlan, 'nam');
    });
  });

  // ---------------------------------------------------------------- 7.6 - 6 test bắt buộc

  group('PRODUCT_POLICY 7.6 - nhắc gia hạn + báo hết kỳ (tsudev_ui ProRenewal*)', () {
    final t0 = DateTime.utc(2026, 11, 20, 3);

    testWidgets('1. còn 8 ngày ⇒ không nhắc', (tester) async {
      final clock = Clock(t0);
      final h = await pumpHost(tester, clock);
      await emit(tester, h, await stateOf(clock, proUntil: t0.add(const Duration(days: 8))));
      expect(find.text(reminderTitle), findsNothing);
    });

    testWidgets('2. còn 7 ngày ⇒ nhắc, nội dung nguyên văn, ngày DD/MM/YYYY', (tester) async {
      final clock = Clock(t0);
      final h = await pumpHost(tester, clock);
      final until = t0.add(const Duration(days: 7));
      await emit(tester, h, await stateOf(clock, proUntil: until));
      expect(find.text(reminderTitle), findsOneWidget);
      expect(
        find.text(
          ProRenewalStrings.reminderVi.body(days: 7, date: formatProRenewalDate(until.toLocal(), const Locale('vi'))),
        ),
        findsOneWidget,
      );
      expect(find.text('Gia hạn'), findsOneWidget);
      await close(tester, 'Để sau');
      expect(find.text(reminderTitle), findsNothing);
    });

    testWidgets('3. mở app 2 lần trong 7 ngày cuối ⇒ nhắc 2 lần; quay lại sau < 30 phút ⇒ không nhắc lại', (
      tester,
    ) async {
      final clock = Clock(t0);
      final h = await pumpHost(tester, clock);
      final until = t0.add(const Duration(days: 5));
      final renewal = ProviderScope.containerOf(tester.element(find.text('màn chính')))
          .read(proRenewalControllerProvider);
      await emit(tester, h, await stateOf(clock, proUntil: until));
      expect(find.text(reminderTitle), findsOneWidget);
      await close(tester, 'Để sau');

      // Quay lại sau 10 phút ở nền: cùng lần mở ⇒ không nhắc.
      renewal.handleAppLifecycleState(AppLifecycleState.paused);
      clock.now = clock.now.add(const Duration(minutes: 10));
      renewal.handleAppLifecycleState(AppLifecycleState.resumed);
      await emit(tester, h, await stateOf(clock, proUntil: until));
      expect(find.text(reminderTitle), findsNothing);

      // Quay lại sau 31 phút ⇒ lần mở mới ⇒ nhắc lần 2.
      renewal.handleAppLifecycleState(AppLifecycleState.paused);
      clock.now = clock.now.add(const Duration(minutes: 31));
      renewal.handleAppLifecycleState(AppLifecycleState.resumed);
      await emit(tester, h, await stateOf(clock, proUntil: until));
      expect(find.text(reminderTitle), findsOneWidget);
    });

    testWidgets('4. hết hạn ⇒ báo hết kỳ đúng một lần (kèm ngày xoá = pro_until + 90 ngày); mở lại ⇒ không báo', (
      tester,
    ) async {
      final clock = Clock(t0);
      final h = await pumpHost(tester, clock);
      final until = t0.add(const Duration(days: 20));
      await emit(tester, h, await stateOf(clock, proUntil: until)); // thiết bị thấy Pro còn hạn
      expect(find.byType(AlertDialog), findsNothing);

      clock.now = until.add(const Duration(hours: 1));
      await emit(tester, h, await stateOf(clock, proUntil: until));
      expect(find.text(expiredTitle), findsOneWidget);
      final del = formatProRenewalDate(until.add(const Duration(days: 90)).toLocal(), const Locale('vi'));
      expect(find.text(ProRenewalStrings.expiredVi.body(date: del)), findsOneWidget);
      expect(h.store.snapshot[ProRenewalPolicy.notifiedUntilKey], '${until.millisecondsSinceEpoch ~/ 1000}');
      await close(tester, 'Đóng');

      await emit(tester, h, await stateOf(clock, proUntil: until));
      expect(find.text(expiredTitle), findsNothing);
    });

    testWidgets('5. gia hạn (JWS mới, pro_until xa hơn) ⇒ thôi nhắc; lần hết kỳ sau báo lại', (tester) async {
      final clock = Clock(t0);
      final h = await pumpHost(tester, clock);
      final renewal = ProviderScope.containerOf(tester.element(find.text('màn chính')))
          .read(proRenewalControllerProvider);
      final first = t0.add(const Duration(days: 3));
      await emit(tester, h, await stateOf(clock, proUntil: first));
      expect(find.text(reminderTitle), findsOneWidget);
      await close(tester, 'Để sau');

      // Gia hạn trên web: JWS mới cộng 1 năm ⇒ lần mở sau không nhắc.
      final second = first.add(const Duration(days: 365));
      renewal.handleAppLifecycleState(AppLifecycleState.paused);
      clock.now = clock.now.add(const Duration(hours: 2));
      renewal.handleAppLifecycleState(AppLifecycleState.resumed);
      await emit(tester, h, await stateOf(clock, proUntil: second));
      expect(find.byType(AlertDialog), findsNothing);

      // Kỳ mới cũng hết ⇒ báo hết kỳ lại (khoá theo từng giá trị pro_until).
      clock.now = second.add(const Duration(days: 1));
      await emit(tester, h, await stateOf(clock, proUntil: second));
      expect(find.text(expiredTitle), findsOneWidget);
    });

    testWidgets('6. ngoại tuyến với JWS đệm đã hết hạn ⇒ không nhắc, không lỗi', (tester) async {
      final clock = Clock(t0);
      final h = await pumpHost(tester, clock);
      final until = t0.add(const Duration(days: 3));
      final store = InMemoryKeyValueStore({
        EntitlementsRepository.cacheKey: signerA.sign(
          claims(iat: t0.subtract(const Duration(days: 8)), proUntil: until),
        ),
      });
      final repo = EntitlementsRepository(
        verifier: testVerifier(),
        store: store,
        fetchJws: () async => throw const SocketException('ngoại tuyến'),
        clock: clock.call,
      );
      final offline = await repo.refresh();
      expect(offline.entitlement, isNull);
      await emit(tester, h, offline);
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('bản Play: "Gia hạn" mở Play Billing gói tsudev_pro với obfuscatedAccountId - không ra web', (
      tester,
    ) async {
      final clock = Clock(t0);
      final h = await pumpHost(tester, clock, channel: DistChannel.play);
      await emit(tester, h, await stateOf(clock, proUntil: t0.add(const Duration(days: 2))));
      await close(tester, 'Gia hạn');
      expect(h.shop.bought, [(PlayIds.pro, obfuscatedAccountId('user-018f'))]);
    });

    testWidgets('tiếng Anh: nội dung nguyên văn en', (tester) async {
      final clock = Clock(t0);
      final h = await pumpHost(tester, clock, locale: const Locale('en'));
      await emit(tester, h, await stateOf(clock, proUntil: t0.add(const Duration(days: 1))));
      expect(find.text('Renew TsuDEV Pro'), findsOneWidget);
      expect(find.text('Later'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------- 7.3 + 7.2 qua màn chính

  group('Thông báo khác ở màn chính', () {
    final t0 = DateTime.utc(2026, 11, 20, 3);

    testWidgets('7.3: miễn phí + 2 thiết bị ⇒ hiện; có Pro ⇒ không (5 ca đầy đủ ở test của tsudev_ui)', (tester) async {
      final clock = Clock(t0);
      final h = await pumpHost(tester, clock);
      await emit(tester, h, await stateOf(clock, proUntil: t0.add(const Duration(days: 100)), devices: 3));
      expect(find.text('Dữ liệu chỉ lưu trên thiết bị này'), findsNothing);
      await emit(tester, h, await stateOf(clock, devices: 2));
      expect(find.text('Dữ liệu chỉ lưu trên thiết bị này'), findsOneWidget);
    });

    test('7.2: mốc báo trước xoá bản sao đám mây 30 và 7 ngày', () {
      final until = t0.add(const Duration(days: 40));
      expect(cloudPurgeMilestone(until, t0), isNull);
      expect(cloudPurgeMilestone(until, until.subtract(const Duration(days: 30))), 30);
      expect(cloudPurgeMilestone(until, until.subtract(const Duration(days: 8))), 30);
      expect(cloudPurgeMilestone(until, until.subtract(const Duration(days: 7))), 7);
      expect(cloudPurgeMilestone(until, until.add(const Duration(seconds: 1))), isNull);
      expect(cloudPurgeMilestone(null, t0), isNull);
    });

    testWidgets('7.2: hết Pro, còn 25 ngày tới mốc xoá ⇒ báo một lần cho mốc 30', (tester) async {
      final clock = Clock(t0);
      final h = await pumpHost(tester, clock);
      final server = ServerPro(
        enforce: true,
        status: 'ok',
        canSync: false,
        serverDataUntil: t0.add(const Duration(days: 25)),
      );
      await emit(tester, h, await stateOf(clock), server: server);
      expect(find.text('Bản sao đám mây sắp bị xoá'), findsOneWidget);
      await close(tester, 'Đóng');
      await emit(tester, h, await stateOf(clock), server: server);
      expect(find.text('Bản sao đám mây sắp bị xoá'), findsNothing);
    });
  });

  // ---------------------------------------------------------------- Kênh phát hành, định danh

  group('Kênh phát hành và định danh', () {
    test('mặc định an toàn: Android ⇒ Play, iOS ⇒ App Store, web/desktop ⇒ ngoài cửa hàng; cờ thắng mặc định', () {
      expect(DistChannel.resolve(raw: '', web: false, platform: TargetPlatform.android), DistChannel.play);
      expect(DistChannel.resolve(raw: '', web: false, platform: TargetPlatform.iOS), DistChannel.appStore);
      expect(DistChannel.resolve(raw: '', web: true, platform: TargetPlatform.android), DistChannel.direct);
      expect(DistChannel.resolve(raw: '', web: false, platform: TargetPlatform.linux), DistChannel.direct);
      expect(DistChannel.resolve(raw: 'direct', web: false, platform: TargetPlatform.android), DistChannel.direct);
      expect(DistChannel.resolve(raw: 'play', web: false, platform: TargetPlatform.windows), DistChannel.play);
    });

    test('obfuscatedAccountId = base64url(SHA-256("tsudev-pro|" + sub)), 43 ký tự', () {
      // python3 -c "import hashlib,base64;print(base64.urlsafe_b64encode(hashlib.sha256(b'tsudev-pro|user-018f').digest()).rstrip(b'='))"
      final id = obfuscatedAccountId('user-018f');
      expect(id.length, 43);
      expect(id, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
      expect(id, isNot(obfuscatedAccountId('user-018g')));
    });

    test('402 reason: lạ/thiếu ⇒ no_pro; gộp: reauth > no_pro > owner_no_pro', () {
      expect(ProBlock.parse('reauth'), ProBlock.reauth);
      expect(ProBlock.parse('owner_no_pro'), ProBlock.ownerNoPro);
      expect(ProBlock.parse(null), ProBlock.noPro);
      expect(ProBlock.parse('lạ'), ProBlock.noPro);
      expect(ProBlock.worst(ProBlock.ownerNoPro, ProBlock.reauth), ProBlock.reauth);
      expect(ProBlock.worst(ProBlock.ownerNoPro, ProBlock.noPro), ProBlock.noPro);
      expect(ProBlock.worst(null, ProBlock.ownerNoPro), ProBlock.ownerNoPro);
    });

    test('ServerPro đọc đúng /me/entitlements; thiếu trường ⇒ cho đồng bộ (máy chủ tự kiểm)', () {
      final s = ServerPro.fromJson({
        'enforce': true,
        'status': 'reauth',
        'can_sync': false,
        'server_data_until': '2027-02-18T00:00:00.000Z',
      });
      expect(s.needsReauth, isTrue);
      expect(s.canSync, isFalse);
      expect(s.serverDataUntil, DateTime.utc(2027, 2, 18));
      expect(ServerPro.fromJson(const {}).canSync, isTrue);
    });
  });

  // ---------------------------------------------------------------- 402 khi đồng bộ

  group('Đồng bộ gặp 402 (ADR-0019 mục 5)', () {
    late FakeSyncServer server;
    setUp(() => server = FakeSyncServer());

    for (final (reason, block) in [
      ('no_pro', ProBlock.noPro),
      ('reauth', ProBlock.reauth),
      ('owner_no_pro', ProBlock.ownerNoPro),
    ]) {
      test('reason=$reason ⇒ $block, không lỗi, bản ghi giữ chờ trên máy, vẫn kéo', () async {
        final a = await device(server, 'u-$reason');
        spend(a, cashOf(a), 12000);
        expect(await a.sync.signIn(), isNull);
        server.pushProReason = reason;
        await a.sync.syncNow();
        expect(a.state.phase, SyncPhase.idle);
        expect(a.state.proBlock, block);
        expect(a.state.pending, greaterThan(0));
        expect(server.paths, contains('GET /api/v1/sync/pull'));

        server.pushProReason = null;
        await a.sync.syncNow();
        expect(a.state.proBlock, isNull);
        expect(a.state.pending, 0);
      });
    }

    test('can_sync=false ⇒ KHÔNG gọi đẩy (miễn phí không gửi dữ liệu lên mạng); mọi lượt gửi mã cài đặt', () async {
      final a = await device(server, 'u-free');
      spend(a, cashOf(a), 12000);
      server.entitlements = {'enforce': true, 'status': 'ok', 'pro': false, 'can_sync': false, 'jws': null};
      expect(await a.sync.signIn(), isNull);
      await a.c.read(proProvider.notifier).refresh();
      expect(a.c.read(proProvider).canSync, isFalse);
      server.paths.clear();
      await a.sync.syncNow();
      expect(server.paths.where((p) => p.contains('/push')), isEmpty);
      expect(a.state.proBlock, ProBlock.noPro);
      expect(server.lastInstallation, matches(RegExp(r'^[A-Za-z0-9_-]{22}$')));
      expect(server.lastPlatform, isNotNull);
    });
  });

  // ---------------------------------------------------------------- Màn Pro theo kênh

  group('Màn Pro / Ủng hộ (PRODUCT_POLICY 3.3, 4.3, 7.5)', () {
    Future<FakeStore> openPro(WidgetTester tester, DistChannel channel, Size size) async {
      await setSurface(tester, size);
      final sodium = await tester.runAsync(testSodium);
      final services = makeServices(sodium!);
      services.vault.createAccount(testPassword);
      final shop = FakeStore();
      await pumpApp(
        tester,
        services,
        extra: [
          distChannelProvider.overrideWithValue(channel),
          storePurchasesProvider.overrideWithValue(channel == DistChannel.play ? shop : null),
        ],
      );
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/more/pro');
      await settle(tester);
      expect(find.byType(ProPage), findsOneWidget);
      expect(tester.takeException(), isNull);
      return shop;
    }

    for (final (name, size) in [('điện thoại', Size(390, 844)), ('máy tính', Size(1280, 800))]) {
      testWidgets('ngoài cửa hàng: 490.000 ₫, điều khoản TRƯỚC nút mua, có trang Ủng hộ web ($name)', (tester) async {
        await openPro(tester, DistChannel.direct, size);
        final terms = find.byKey(const ValueKey('pro-terms'));
        final buy = find.byKey(const ValueKey('pro-buy'));
        expect(terms, findsOneWidget);
        expect((tester.widget(terms) as Text).data, contains('490.000'));
        // Bộ định dạng tiền dùng dấu cách không ngắt trước "₫".
        expect(
          (tester.widget(terms) as Text).data!.replaceAll('\u00a0', ' '),
          startsWith('TsuDEV Pro 490.000 ₫ cho 1 năm, KHÔNG tự gia hạn.'),
        );
        expect(tester.getTopLeft(terms).dy, lessThan(tester.getTopLeft(buy).dy));
        await scrollTo(tester, find.byKey(const ValueKey('donate-web')));
        expect(find.byKey(const ValueKey('donate-web')), findsOneWidget);
      });
    }

    testWidgets('bản Play: giá cửa hàng, KHÔNG có liên kết web; chưa đăng nhập ⇒ nút mua tắt + mời đăng nhập', (
      tester,
    ) async {
      await openPro(tester, DistChannel.play, const Size(390, 844));
      final terms = find.byKey(const ValueKey('pro-terms'));
      expect((tester.widget(terms) as Text).data, startsWith('TsuDEV Pro 499.000 ₫ cho 1 năm'));
      expect(find.text('Mua trên tsudev.com'), findsNothing);
      expect(find.byKey(const ValueKey('donate-web')), findsNothing);
      expect(tester.widget<FilledButton>(find.byKey(const ValueKey('pro-buy'))).onPressed, isNull);
      expect(find.text('Đăng nhập tài khoản TsuDEV để mua Pro hoặc ủng hộ.'), findsWidgets);
      await scrollTo(tester, find.byKey(const ValueKey('donate-ung_ho_200k')));
      expect(find.byKey(const ValueKey('donate-ung_ho_200k')), findsOneWidget);
    });

    testWidgets('bản App Store: không nút mua, không liên kết web, không mục Ủng hộ', (tester) async {
      await openPro(tester, DistChannel.appStore, const Size(390, 844));
      expect(find.byKey(const ValueKey('pro-buy')), findsNothing);
      expect(find.byKey(const ValueKey('pro-terms')), findsNothing);
      expect(find.byKey(const ValueKey('donate-web')), findsNothing);
      expect(find.text('Ủng hộ TsuDEV'), findsNothing);
    });
  });
}
