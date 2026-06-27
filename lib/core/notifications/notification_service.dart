import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../db/models.dart';

/// チケット販売日・イベント前日のローカル通知を扱う。
/// サーバー不要・無料。Web では通知非対応のため安全に無視する。
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _channelId = 'oshikatsu_events';
  static const _channelName = '推し活イベント通知';
  static const _channelDesc = 'チケット販売日やイベント前のリマインド';

  Future<void> init() async {
    if (_ready || kIsWeb) return;
    try {
      tzdata.initializeTimeZones();
      // 端末のタイムゾーンが取れない環境向けに東京を既定とする。
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));
      } catch (_) {}

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      await _plugin.initialize(
        settings: const InitializationSettings(android: android, iOS: ios),
      );
      _ready = true;
    } catch (e) {
      debugPrint('NotificationService init failed: $e');
    }
  }

  Future<void> requestPermissions() async {
    if (!_ready || kIsWeb) return;
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('requestPermissions failed: $e');
    }
  }

  /// イベント id から安定した通知 id を 2 つ生成する(チケット用 / リマインド用)。
  int _ticketId(String eventId) => eventId.hashCode & 0x7ffffffe;
  int _reminderId(String eventId) => (eventId.hashCode & 0x7ffffffe) | 1;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> scheduleForEvent(EventItem e) async {
    if (!_ready || kIsWeb) return;
    final now = DateTime.now();

    // チケット販売日の通知。
    if (e.ticketSaleDate != null && e.ticketSaleDate!.isAfter(now)) {
      await _zonedSchedule(
        _ticketId(e.id),
        '🎫 チケット販売日',
        '「${e.title}」のチケット販売が始まります',
        e.ticketSaleDate!,
      );
    }

    // イベント前のリマインド通知。
    if (e.notifyBeforeDays > 0) {
      final remindAt = DateTime(
        e.dateTime.year,
        e.dateTime.month,
        e.dateTime.day - e.notifyBeforeDays,
        9, // 朝9時に通知
      );
      if (remindAt.isAfter(now)) {
        await _zonedSchedule(
          _reminderId(e.id),
          '📅 まもなく推し活',
          '「${e.title}」まであと${e.notifyBeforeDays}日です',
          remindAt,
        );
      }
    }
  }

  Future<void> _zonedSchedule(
      int id, String title, String body, DateTime when) async {
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(when, tz.local),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('zonedSchedule failed: $e');
    }
  }

  Future<void> cancelForEvent(String eventId) async {
    if (!_ready || kIsWeb) return;
    try {
      await _plugin.cancel(id: _ticketId(eventId));
      await _plugin.cancel(id: _reminderId(eventId));
    } catch (e) {
      debugPrint('cancel failed: $e');
    }
  }

  /// 予算超過などの即時通知。
  Future<void> showNow(int id, String title, String body) async {
    if (!_ready || kIsWeb) return;
    try {
      await _plugin.show(
          id: id, title: title, body: body, notificationDetails: _details);
    } catch (e) {
      debugPrint('show failed: $e');
    }
  }
}
