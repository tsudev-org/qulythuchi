import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulythuchi/state/providers.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import 'helpers.dart';

Future<void> _onboard(WidgetTester tester, AppServices services) async {
  expect(find.text('Chào mừng tới Quly Thu Chi'), findsOneWidget);
  await scrollTo(tester, find.byKey(const ValueKey('tsu-sign-in-guest')));
  await tester.tap(find.byKey(const ValueKey('tsu-sign-in-guest')));
  await settle(tester);

  // Mật khẩu ngắn bị chặn.
  await tester.enterText(textField('Mật khẩu mã hóa'), 'ngan');
  await tester.tap(find.text('Tiếp tục'));
  await settle(tester);
  expect(find.text('Cần ít nhất 10 ký tự'), findsOneWidget);

  await tester.enterText(textField('Mật khẩu mã hóa'), testPassword);
  await tester.enterText(textField('Nhập lại mật khẩu'), testPassword);
  await tester.tap(find.text('Tiếp tục'));
  await settle(tester);

  // Đọc 24 từ trên màn hình.
  final words = <String>[
    for (final t in tester.widgetList<Text>(find.byType(Text)))
      if (RegExp(r'^\d+\. ([a-z]+)$').firstMatch(t.data ?? t.textSpan?.toPlainText() ?? '') case final m?) m.group(1)!,
  ];
  expect(words, hasLength(24));
  final continueBtn = find.widgetWithText(FilledButton, 'Tiếp tục');
  expect(tester.widget<FilledButton>(continueBtn).onPressed, isNull, reason: 'phải tích xác nhận đã chép');
  await tester.ensureVisible(find.byType(CheckboxListTile));
  await tester.tap(find.byType(CheckboxListTile));
  await tester.pump();
  expect(tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value, isTrue);
  await tester.ensureVisible(continueBtn);
  await tester.tap(continueBtn);
  await settle(tester);

  // Chọn đúng từ cho 3 vị trí được hỏi (mỗi nhóm có một Wrap chip riêng).
  expect(find.text('Xác nhận từ khôi phục'), findsOneWidget);
  final wraps = find.byWidgetPredicate((w) => w is Wrap && w.children.isNotEmpty && w.children.first is ChoiceChip);
  final positions = RegExp(r'Từ thứ (\d+)')
      .allMatches(tester.widgetList<Text>(find.textContaining('Từ thứ')).map((t) => t.data).join(' '))
      .map((m) => int.parse(m.group(1)!))
      .toList();
  expect(positions, hasLength(3));
  for (var g = 0; g < 3; g++) {
    final chip = find.descendant(of: wraps.at(g), matching: find.widgetWithText(ChoiceChip, words[positions[g] - 1]));
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pump();
  }
  await tester.tap(find.widgetWithText(FilledButton, 'Tiếp tục'));
  await settle(tester);

  // Bước PIN (thiết bị có kho bí mật) - bỏ qua.
  expect(find.text('Đặt PIN mở nhanh'), findsOneWidget);
  await tester.tap(find.text('Để sau'));
  await settle(tester);
  expect(services.vault.isUnlocked, isTrue);
}

void main() {
  for (final (name, size) in [('điện thoại', const Size(360, 800)), ('máy tính', const Size(1280, 800))]) {
    testWidgets('khởi tạo → ví → giao dịch ($name)', (tester) async {
      final sodium = await tester.runAsync(testSodium);
      final services = makeServices(sodium!);
      await setSurface(tester, size);
      await pumpApp(tester, services);
      await _onboard(tester, services);

      expect(find.text('Chưa có ví nào'), findsOneWidget);
      if (size.width >= 840) {
        expect(find.byType(NavigationRail), findsOneWidget);
      } else {
        expect(find.byType(NavigationBar), findsOneWidget);
      }

      await tester.tap(find.text('Ví mới'));
      await settle(tester);
      await tester.enterText(textField('Tên ví'), 'Tiền mặt');
      await tester.enterText(textField('Số dư ban đầu'), '1.500.000');
      await tester.tap(find.widgetWithText(FilledButton, 'Lưu'));
      await settle(tester);

      // Thêm khoản chi bằng máy tính trong ô số tiền.
      await tester.tap(find.byIcon(Icons.receipt_long_outlined).first);
      await settle(tester);
      await tester.tap(find.byTooltip('Giao dịch mới'));
      await settle(tester);
      await tester.enterText(find.byKey(const Key('amount')), '50.000+25.000x2');
      await tester.pump();
      expect(find.textContaining('= 100.000'), findsOneWidget);
      await tester.enterText(textField('Ghi chú'), 'Phở bò');
      // Form có thêm mục Ảnh hóa đơn (P7b) ⇒ nút Lưu có thể nằm dưới màn hình điện thoại.
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Lưu'));

      expect(find.text('Hôm nay'), findsOneWidget);
      expect(find.textContaining('Phở bò'), findsOneWidget);
      expect(find.textContaining('-100.000'), findsWidgets);

      final wallets = services.store.allRecords();
      expect(wallets.length, greaterThan(28)); // 36 danh mục + ví + giao dịch, tất cả đã niêm phong
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('màn khóa: sai mật khẩu báo lỗi, đúng thì mở; bật ẩn số dư', (tester) async {
    final sodium = await tester.runAsync(testSodium);
    final services = makeServices(sodium!);
    services.vault.createAccount(testPassword);
    services.vault.lock();
    await setSurface(tester, const Size(360, 800));
    await pumpApp(tester, services, prefs: {'locale': 'vi', 'hideBalances': true});

    expect(find.text('Đã khóa'), findsOneWidget);
    await tester.enterText(textField('Mật khẩu mã hóa'), 'sai-mat-khau-123');
    await tester.tap(find.widgetWithText(FilledButton, 'Mở khóa'));
    await settle(tester);
    expect(find.text('Mật khẩu không đúng'), findsOneWidget);

    await tester.enterText(textField('Mật khẩu mã hóa'), testPassword);
    await tester.tap(find.widgetWithText(FilledButton, 'Mở khóa'));
    await settle(tester);
    expect(find.text('Tổng quan'), findsWidgets);
    expect(find.textContaining('₫'), findsNothing);
  });

  testWidgets('tiếng Anh + giao diện sáng hiển thị đúng', (tester) async {
    final sodium = await tester.runAsync(testSodium);
    await setSurface(tester, const Size(360, 800));
    await pumpApp(tester, makeServices(sodium!), prefs: {'locale': 'en', 'theme': 'light'});
    expect(find.text('Welcome to Quly Thu Chi'), findsOneWidget);
    expect(Theme.of(tester.element(find.byKey(const ValueKey('tsu-sign-in-tsudev')))).brightness, Brightness.light);
    expect(Currency.vnd.code, 'VND');
  });
}
