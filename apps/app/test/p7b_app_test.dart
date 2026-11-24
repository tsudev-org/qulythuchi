import 'dart:convert';
import 'dart:typed_data';

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:qulythuchi/attachments/attachment_picker.dart';
import 'package:qulythuchi/attachments/attachments_section.dart';
import 'package:qulythuchi/domain/default_categories.dart';
import 'package:qulythuchi/state/ledger_repository.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';

import 'helpers.dart';

final class _FakePicker implements AttachmentPicker {
  @override
  bool get supportsCamera => false;
  @override
  Future<Uint8List?> pick(AttachmentSource source) async => Uint8List.fromList(utf8.encode('anh-goc-co-exif'));
}

// PNG 1x1 hợp lệ - để Image.memory giải mã được trong test.
final _png = base64.decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

void main() {
  for (final (name, size) in [('điện thoại', Size(390, 844)), ('máy tính', Size(1280, 800))]) {
    testWidgets('Ảnh hóa đơn: thêm (đã làm sạch), xem, xóa ($name)', (tester) async {
      final sodium = await tester.runAsync(testSodium);
      final services = makeServices(sodium!);
      services.vault.createAccount(testPassword);
      final repo = LedgerRepository(services.store, services.vault)..seedDefaultCategories(DefaultCategoryLocale.vi);
      final w = repo.saveWallet(
        Wallet(id: repo.newId(), name: 'Tiền mặt', type: WalletType.cash, currency: Currency.vnd),
      );
      final t = repo.saveTxn(
        Txn(id: repo.newId(), walletId: w.id, kind: TxnKind.expense, amount: 50000, date: CivilDate(2026, 11, 20)),
      );
      final seen = <String>[];
      await setSurface(tester, size);
      await pumpApp(
        tester,
        services,
        extra: [
          attachmentPickerProvider.overrideWithValue(_FakePicker()),
          imageSanitizerProvider.overrideWithValue((raw) async {
            seen.add(utf8.decode(raw));
            return SanitizedImage(bytes: _png, width: 1, height: 1);
          }),
        ],
      );
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/transactions/${t.id}');
      await settle(tester);
      await tapVisible(tester, find.text('Thêm ảnh'));
      expect(seen, ['anh-goc-co-exif'], reason: 'ảnh gốc luôn qua bộ làm sạch');
      final atts = repo..load();
      expect(atts.attachmentsOf(t.id), hasLength(1));
      expect(find.textContaining('xóa vị trí GPS'), findsOneWidget);

      await tapVisible(tester, find.descendant(of: find.byType(AttachmentsSection), matching: find.byType(Image)).last);
      expect(find.text('Ảnh hóa đơn'), findsWidgets);
      await tester.tap(find.byTooltip('Xóa ảnh'));
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Xóa ảnh'));
      await settle(tester);
      expect((repo..load()).attachmentsOf(t.id), isEmpty);
      expect(tester.takeException(), isNull);
    });
  }
}
