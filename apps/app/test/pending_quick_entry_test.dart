// ADR-0012 mục 11 / ADR-0022: liên kết ghi nhanh từ widget/lối tắt chỉ mang chế độ mở; giá trị lạ ⇒ `type`.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qulythuchi/state/capture_providers.dart';

void main() {
  test('chỉ nhận type|voice|scan, giá trị lạ ⇒ type, take() lấy một lần', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final p = c.read(pendingQuickEntryProvider.notifier);
    for (final (input, want) in [('voice', 'voice'), ('scan', 'scan'), ('type', 'type'), ('x', 'type'), ('', 'type')]) {
      p.request(input);
      expect(p.take(), want);
      expect(p.take(), isNull);
    }
  });
}
