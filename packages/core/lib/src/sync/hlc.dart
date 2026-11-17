import 'package:meta/meta.dart';

/// Đồng hồ máy lệch quá xa so với dấu thời gian nhận về (có thể bị giả mạo hoặc sai giờ hệ thống).
final class ClockDriftException implements Exception {
  const ClockDriftException(this.driftMillis);
  final int driftMillis;
  @override
  String toString() => 'ClockDriftException: lệch $driftMillis ms';
}

/// Dấu thời gian logic lai (Hybrid Logical Clock): mili giây vật lý + bộ đếm + id thiết bị.
/// Chuỗi mã hóa so sánh được theo thứ tự từ điển: `<15 chữ số>-<4 hex>-<node>`.
@immutable
final class Hlc implements Comparable<Hlc> {
  Hlc(this.millis, this.counter, this.node) {
    if (millis < 0 || millis > 999999999999999) throw ArgumentError.value(millis, 'millis');
    if (counter < 0 || counter > 0xFFFF) throw ArgumentError.value(counter, 'counter');
    if (!_nodePattern.hasMatch(node)) throw ArgumentError.value(node, 'node', 'Chỉ a-z0-9, 1-16 ký tự');
  }

  static final _nodePattern = RegExp(r'^[a-z0-9]{1,16}$');
  static final _pattern = RegExp(r'^(\d{15})-([0-9a-f]{4})-([a-z0-9]{1,16})$');

  final int millis;
  final int counter;
  final String node;

  static Hlc parse(String value) {
    final m = _pattern.firstMatch(value);
    if (m == null) throw FormatException('HLC không hợp lệ', value);
    return Hlc(int.parse(m.group(1)!), int.parse(m.group(2)!, radix: 16), m.group(3)!);
  }

  @override
  String toString() => '${millis.toString().padLeft(15, '0')}-${counter.toRadixString(16).padLeft(4, '0')}-$node';

  @override
  int compareTo(Hlc other) {
    final c = millis.compareTo(other.millis);
    if (c != 0) return c;
    final d = counter.compareTo(other.counter);
    if (d != 0) return d;
    return node.compareTo(other.node);
  }

  bool operator >(Hlc other) => compareTo(other) > 0;
  bool operator <(Hlc other) => compareTo(other) < 0;

  @override
  bool operator ==(Object other) =>
      other is Hlc && other.millis == millis && other.counter == counter && other.node == node;

  @override
  int get hashCode => Object.hash(millis, counter, node);
}

/// Đồng hồ HLC của một thiết bị. Không an toàn đa luồng - mỗi isolate một đồng hồ.
final class HlcClock {
  HlcClock(this.node, {int Function()? now, this.maxDriftMillis = 5 * 60 * 1000})
    : _now = now ?? (() => DateTime.now().millisecondsSinceEpoch),
      _last = Hlc(0, 0, node);

  final String node;
  final int maxDriftMillis;
  final int Function() _now;
  Hlc _last;

  Hlc get last => _last;

  /// Dấu thời gian cho một thao tác ghi cục bộ.
  Hlc tick() {
    final physical = _now();
    if (physical > _last.millis) {
      _last = Hlc(physical, 0, node);
    } else {
      _last = _bump(_last.millis, _last.counter);
    }
    return _last;
  }

  /// Cập nhật đồng hồ khi nhận dấu thời gian từ thiết bị khác.
  void receive(Hlc remote) {
    final physical = _now();
    if (remote.millis - physical > maxDriftMillis) {
      throw ClockDriftException(remote.millis - physical);
    }
    final maxMillis = [physical, _last.millis, remote.millis].reduce((a, b) => a > b ? a : b);
    if (maxMillis == _last.millis && maxMillis == remote.millis) {
      _last = _bump(maxMillis, _last.counter > remote.counter ? _last.counter : remote.counter);
    } else if (maxMillis == _last.millis) {
      _last = _bump(maxMillis, _last.counter);
    } else if (maxMillis == remote.millis) {
      _last = _bump(maxMillis, remote.counter);
    } else {
      _last = Hlc(maxMillis, 0, node);
    }
  }

  Hlc _bump(int millis, int counter) {
    if (counter >= 0xFFFF) return Hlc(millis + 1, 0, node);
    return Hlc(millis, counter + 1, node);
  }
}
