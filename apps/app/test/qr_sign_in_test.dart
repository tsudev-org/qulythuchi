import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulythuchi/l10n/app_localizations.dart';
import 'package:qulythuchi/ui/account/xd_scan.dart';

import 'helpers.dart';

// QR3 (CROSS_DEVICE_LOGIN v1.1.0, ADR-0023): bộ quét chỉ mở đúng mã Đ1 của tsudev; màn chào theo 13.2 + 13.4.
const _id = 'AbCdEfGhIjKlMnOpQrStUv'; // 22 ký tự
const _k = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQ'; // 43 ký tự

void main() {
  group('XdScan.classify', () {
    test('Đ1 (f=d) hợp lệ ⇒ mở đúng URL đã quét', () {
      final r = XdScan.classify('https://tsudev.com/x/$_id?f=d#$_k');
      expect(r, isA<XdSignIn>());
      expect((r as XdSignIn).uri.toString(), 'https://tsudev.com/x/$_id?f=d#$_k');
    });

    test('Đ2 (f=k) ⇒ không mở, hướng sang máy đã đăng nhập (vai xác nhận chờ QR2b)', () {
      expect(XdScan.classify('https://tsudev.com/x/$_id?f=k#$_k'), isA<XdApproveElsewhere>());
    });

    test('T9: tên miền giả, http, cổng, userinfo, đường dẫn lạ, thiếu bí mật ⇒ "không phải của tsudev"', () {
      for (final raw in [
        'https://tsudev.com.evil.io/x/$_id?f=d#$_k',
        'https://evil.io/x/$_id?f=d#$_k',
        'http://tsudev.com/x/$_id?f=d#$_k',
        'https://tsudev.com:8443/x/$_id?f=d#$_k',
        'https://a@tsudev.com/x/$_id?f=d#$_k',
        'https://tsudev.com/y/$_id?f=d#$_k',
        'https://tsudev.com/x/$_id?f=d',
        'https://tsudev.com/x/$_id?f=d&next=evil#$_k',
        '00020101021138570010A000000727', // QR thanh toán VietQR
        '',
      ]) {
        expect(XdScan.classify(raw), isA<XdNotTsudev>(), reason: raw);
      }
    });
  });

  group('scanToSignIn', () {
    Future<BuildContext> host(WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SizedBox()),
        ),
      );
      return tester.element(find.byType(SizedBox));
    }

    testWidgets('quét ⇒ mở trình duyệt ⇒ Tiếp tục ⇒ đăng nhập OIDC', (tester) async {
      final ctx = await host(tester);
      final opened = <Uri>[];
      var signedIn = 0;
      final uri = Uri.parse('https://tsudev.com/x/$_id?f=d#$_k');
      final done = scanToSignIn(
        ctx,
        () async => signedIn++,
        scan: (_) async => uri,
        openBrowser: (u) async {
          opened.add(u);
          return true;
        },
      );
      await tester.pumpAndSettle();
      expect(opened, [uri]);
      expect(find.textContaining('24 từ khôi phục'), findsOneWidget, reason: 'nói rõ QR không mở khoá dữ liệu');
      await tester.tap(find.byKey(const Key('xd.continue')));
      await tester.pumpAndSettle();
      await done;
      expect(signedIn, 1);
    });

    testWidgets('huỷ quét / trình duyệt không mở / bấm Huỷ ⇒ không đăng nhập', (tester) async {
      final ctx = await host(tester);
      var signedIn = 0;
      await scanToSignIn(ctx, () async => signedIn++, scan: (_) async => null, openBrowser: (_) async => true);
      final uri = Uri.parse('https://tsudev.com/x/$_id?f=d#$_k');
      await scanToSignIn(ctx, () async => signedIn++, scan: (_) async => uri, openBrowser: (_) async => false);
      await tester.pumpAndSettle();
      final f = scanToSignIn(ctx, () async => signedIn++, scan: (_) async => uri, openBrowser: (_) async => true);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      await f;
      expect(signedIn, 0);
    });
  });

  group('màn chào TsuSignInScreen', () {
    testWidgets(
      'ô đồng ý không tích sẵn; bấm lối vào khi chưa tích ⇒ bảng "Đồng ý và tiếp tục"; khách không cần tích',
      (tester) async {
        final sodium = await tester.runAsync(testSodium);
        await setSurface(tester, const Size(400, 900));
        await pumpApp(tester, makeServices(sodium!));
        expect(find.text('Chào mừng tới Quly Thu Chi'), findsOneWidget);
        final consent = tester.widget<CheckboxListTile>(find.byKey(const ValueKey('tsu-sign-in-consent')));
        expect(consent.value, isFalse);
        for (final id in ['google', 'github', 'tsudev']) {
          expect(find.byKey(ValueKey('tsu-sign-in-$id')), findsOneWidget, reason: id);
        }
        // flutter test giả lập Android ⇒ có "Quét để đăng nhập".
        await scrollTo(tester, find.byKey(const ValueKey('tsu-sign-in-scan')));
        await scrollTo(tester, find.byKey(const Key('welcome.restore')));
        await tester.drag(find.byType(Scrollable).first, const Offset(0, 2000));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('tsu-sign-in-tsudev')));
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsOneWidget);
        await tester.tap(find.byType(TextButton).last); // Huỷ
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsNothing);

        await scrollTo(tester, find.byKey(const ValueKey('tsu-sign-in-guest')));
        await tester.tap(find.byKey(const ValueKey('tsu-sign-in-guest')));
        await settle(tester);
        expect(find.text('Mật khẩu mã hóa'), findsWidgets);
      },
    );

    testWidgets('chế độ Tối dựng được, không lỗi', (tester) async {
      final sodium = await tester.runAsync(testSodium);
      await setSurface(tester, const Size(400, 900));
      await pumpApp(tester, makeServices(sodium!), prefs: {'locale': 'en', 'theme': 'dark'});
      expect(find.text('Welcome to Quly Thu Chi'), findsOneWidget);
      expect(Theme.of(tester.element(find.byKey(const ValueKey('tsu-sign-in-tsudev')))).brightness, Brightness.dark);
      expect(tester.takeException(), isNull);
    });
  });
}
