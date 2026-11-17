import 'dart:convert';
import 'dart:math';

import 'package:qulythuchi_core/qulythuchi_core.dart';
import 'package:test/test.dart';

const id1 = '0f8fad5b-d9cb-469f-a165-70867728950e';
const w1 = '7c9e6679-7425-40de-944b-e07fc1f90ae7';

void main() {
  group('Hlc', () {
    test('chuỗi so sánh được theo thứ tự từ điển và đọc lại được', () {
      final a = Hlc(1731830000000, 1, 'deva');
      final b = Hlc(1731830000000, 2, 'deva');
      final c = Hlc(1731830000001, 0, 'devb');
      expect(a < b && b < c, isTrue);
      expect(a.toString().compareTo(b.toString()) < 0, isTrue);
      expect(b.toString().compareTo(c.toString()) < 0, isTrue);
      expect(Hlc.parse(c.toString()), c);
      expect(() => Hlc.parse('xyz'), throwsFormatException);
      expect(() => Hlc(0, 0, 'BAD'), throwsArgumentError);
    });

    test('tick tăng đơn điệu kể cả khi đồng hồ đứng hoặc lùi', () {
      var now = 1000;
      final clock = HlcClock('a', now: () => now);
      final t1 = clock.tick();
      final t2 = clock.tick();
      now = 500; // đồng hồ hệ thống lùi
      final t3 = clock.tick();
      expect(t1 < t2 && t2 < t3, isTrue);
      now = 2000;
      expect(clock.tick().millis, 2000);
    });

    test('receive vượt dấu từ xa và chặn lệch giờ quá lớn', () {
      var now = 1000;
      final clock = HlcClock('a', now: () => now);
      clock.receive(Hlc(5000, 3, 'b'));
      expect(clock.tick() > Hlc(5000, 3, 'b'), isTrue);
      expect(() => clock.receive(Hlc(now + 10 * 60 * 1000, 0, 'b')), throwsA(isA<ClockDriftException>()));
      now = 9000;
      clock.receive(Hlc(100, 0, 'b'));
      expect(clock.last.millis, 9000);
    });
  });

  group('SyncRecord', () {
    test('hợp nhất theo trường: giao hoán, kết hợp, lũy đẳng (ngẫu nhiên)', () {
      final rnd = Random(42);
      for (var round = 0; round < 200; round++) {
        final replicas = <SyncRecord>[];
        for (var r = 0; r < 3; r++) {
          final clock = HlcClock('n$r', now: () => 1000 + rnd.nextInt(50));
          var rec = SyncRecord(id: id1, type: 'txn', walletId: w1);
          for (var k = 0; k < 5; k++) {
            rec = rec.set('f${rnd.nextInt(4)}', rnd.nextInt(100), clock);
          }
          replicas.add(rec);
        }
        final [a, b, c] = replicas;
        String bytes(SyncRecord x) => utf8.decode(x.toBytes());
        expect(bytes(a.merge(b)), bytes(b.merge(a)));
        expect(bytes(a.merge(b).merge(c)), bytes(a.merge(b.merge(c))));
        expect(bytes(a.merge(a)), bytes(a));
      }
    });

    test('ghi sau thắng và bia mộ', () {
      final ca = HlcClock('a', now: () => 1000);
      final cb = HlcClock('b', now: () => 2000);
      final base = SyncRecord(id: id1, type: 'txn', walletId: w1).set('amount', 5, ca);
      final edited = base.set('amount', 7, cb);
      final deleted = base.markDeleted(ca);
      final merged = edited.merge(deleted);
      expect(merged['amount'], 7);
      expect(merged.isDeleted, isTrue);
      expect(merged.values.containsKey(SyncRecord.deletedField), isFalse);
    });

    test('tuần tự hóa chuẩn tắc, đọc lại đúng, từ chối dữ liệu hỏng', () {
      final clock = HlcClock('a', now: () => 1000);
      final rec = SyncRecord(id: id1, type: 'txn', walletId: w1).setAll({
        'b': 'x',
        'a': [1, 2],
        'n': null,
      }, clock);
      final again = SyncRecord.fromBytes(rec.toBytes());
      expect(again.toBytes(), rec.toBytes());
      expect(again.maxHlc, rec.maxHlc);
      expect(() => SyncRecord.fromBytes(utf8.encode('{"v":2}')), throwsFormatException);
      expect(
        () => SyncRecord.fromBytes(utf8.encode('{"v":1,"id":5,"t":"txn","w":null,"f":{}}')),
        throwsFormatException,
      );
      expect(
        () => SyncRecord.fromBytes(
          utf8.encode('{"v":1,"id":"$id1","t":"txn","w":null,"f":{"a":[1.5,"000000000001000-0000-a"]}}'),
        ),
        throwsFormatException,
      );
      expect(() => SyncRecord.fromBytes(utf8.encode('not json')), throwsFormatException);
      expect(() => rec.set('a', 1.5, clock), throwsArgumentError);
      expect(() => rec.set('bad name', 1, clock), throwsArgumentError);
      expect(() => SyncRecord(id: 'X', type: 'txn', walletId: null), throwsArgumentError);
      expect(() => rec.merge(SyncRecord(id: id1, type: 'wallet', walletId: w1)), throwsArgumentError);
    });

    test('canonicalJson sắp khóa, chặn kiểu lạ', () {
      expect(
        canonicalJson({
          'b': 1,
          'a': {'d': true, 'c': null},
        }),
        '{"a":{"c":null,"d":true},"b":1}',
      );
      expect(canonicalJson('Việt "x"'), '"Việt \\"x\\""');
      expect(() => canonicalJson(DateTime(2026)), throwsArgumentError);
    });
  });
}
