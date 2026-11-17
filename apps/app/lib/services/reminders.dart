import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:qulythuchi_core/qulythuchi_core.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../state/ledger_repository.dart';

/// Giờ nhắc trong ngày (giờ địa phương).
const reminderHour = 9;
const reminderHorizonDays = 60;
const maxReminders = 30;

/// Thời điểm cần nhắc hóa đơn và hạn trả nợ trong [reminderHorizonDays] ngày tới (đã sắp, bỏ thời điểm đã qua, không trùng).
/// Hàm thuần - test được không cần nền tảng.
List<DateTime> reminderTimes(LedgerData data, DateTime now) {
  final today = CivilDate.fromDateTime(now);
  final horizon = today.addDays(reminderHorizonDays);
  final out = <DateTime>{};
  for (final r in data.recurrings) {
    if (!r.isBill || r.paused) continue;
    final from = r.generatedThrough?.addDays(1) ?? r.rule.start;
    final start = from > today ? from : today;
    if (start > horizon) continue;
    for (final due in r.rule.occurrences(DateRange(start, horizon))) {
      final day = due.addDays(-r.remindDaysBefore);
      final at = DateTime(day.year, day.month, day.day, reminderHour);
      if (at.isAfter(now)) out.add(at);
    }
  }
  // Hạn trả nợ: nhắc trước 1 ngày, chỉ khoản còn mở và chưa trả hết.
  for (final d in data.debts) {
    if (d.closed || d.dueDate == null || d.dueDate! < today || d.dueDate! > horizon) continue;
    final w = data.wallet(d.walletId);
    if (w == null || Ledger.debtStatus(d, w, data.txns).settled) continue;
    final day = d.dueDate!.addDays(-1);
    final at = DateTime(day.year, day.month, day.day, reminderHour);
    if (at.isAfter(now)) out.add(at);
  }
  final list = out.toList()..sort();
  return list.length > maxReminders ? list.sublist(0, maxReminders) : list;
}

/// Lên lịch thông báo hệ thống. Nội dung CHUNG CHUNG (không tên, không số tiền) - không lộ D3 trên màn khóa.
abstract interface class ReminderScheduler {
  bool get supported;
  Future<bool> requestPermission();
  Future<void> replaceAll(List<DateTime> times, {required String title, required String body});
  Future<void> cancelAll();
}

final class NoopReminderScheduler implements ReminderScheduler {
  final List<DateTime> scheduled = [];

  @override
  bool get supported => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> replaceAll(List<DateTime> times, {required String title, required String body}) async {
    scheduled
      ..clear()
      ..addAll(times);
  }

  @override
  Future<void> cancelAll() async => scheduled.clear();
}

/// Android, iOS, macOS (Linux/Windows/web của plugin không hỗ trợ lên lịch đủ tin cậy).
final class LocalNotificationScheduler implements ReminderScheduler {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static bool get platformSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  @override
  bool get supported => platformSupported;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'bills',
      'Hóa đơn / Bills',
      importance: Importance.defaultImportance,
      visibility: NotificationVisibility.private,
    ),
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
  );

  Future<void> _init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: darwin,
        macOS: darwin,
      ),
    );
    _ready = true;
  }

  @override
  Future<bool> requestPermission() async {
    if (!supported) return false;
    await _init();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) return await android.requestNotificationsPermission() ?? false;
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) return await ios.requestPermissions(alert: true, sound: true) ?? false;
    final mac = _plugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();
    if (mac != null) return await mac.requestPermissions(alert: true, sound: true) ?? false;
    return false;
  }

  @override
  Future<void> replaceAll(List<DateTime> times, {required String title, required String body}) async {
    if (!supported) return;
    await _init();
    await _plugin.cancelAll();
    for (var i = 0; i < times.length; i++) {
      await _plugin.zonedSchedule(
        id: i + 1,
        // Đổi giờ địa phương sang thời điểm UTC tuyệt đối: không cần biết tên múi giờ.
        scheduledDate: tz.TZDateTime.from(times[i], tz.UTC),
        notificationDetails: _details,
        // Không xin quyền báo thức chính xác: nhắc hóa đơn lệch vài phút không sao.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: title,
        body: body,
      );
    }
  }

  @override
  Future<void> cancelAll() async {
    if (!supported) return;
    await _init();
    await _plugin.cancelAll();
  }
}
