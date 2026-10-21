import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:firstapp/services/notification_store.dart'; // 📌 import สโตร์กลาง

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // id ของแจ้งเตือนรายวัน (ใช้ตอนตั้งเวลาและตอนยกเลิก ต้องเป็นเลขเดียวกัน)
  static const int _dailyReminderId = 100;

  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(initializationSettings);

    _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // 📌 ฟังก์ชันยิงแจ้งเตือนทันที
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    // 💡 เช็คประเภท warning สำหรับเปลี่ยนสีไอคอนในหน้าแอป
    String type = 'reminder';
    if (title.contains('เกิน') || title.contains('เตือน') || title.contains('🚨') || title.contains('⚠️')) {
      type = 'warning';
    }

    // 💡 1. บันทึกลง NotificationStore สำหรับแสดงในหน้าแอป
    NotificationStore.addNotification(
      title: title,
      body: body,
      type: type,
    );

    // 💡 2. ส่ง Push Notification เข้าเครื่องโทรศัพท์
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'finance_tracker_channel',
      'แจ้งเตือนการเงิน',
      channelDescription: 'แจ้งเตือนรายรับ-รายจ่ายและงบประมาณ',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );
  }

  // 📌 ฟังก์ชันตั้งเวลาเตือนบันทึกรายรับ-รายจ่าย ทุกวันตอน 10:00 น.
  static Future<void> scheduleDaily9AMNotification() async {
    const String title = 'อย่าลืม !';
    const String body =
        'วันนี้คุณยังไม่ได้เพิ่มรายรับ-รายจ่ายเลย อย่าลืมเพิ่มรายรับ - รายจ่ายด้วยล่ะ !!!';

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_reminder_channel_v2',
        'เตือนบันทึกประจำวัน',
        channelDescription: 'แจ้งเตือนให้บันทึกรายรับ-รายจ่ายทุกวันตอน 9 โมงเช้า',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    Future<void> schedule(AndroidScheduleMode mode) {
      return _notificationsPlugin.zonedSchedule(
        _dailyReminderId,
        title,
        body,
        _nextInstanceOfNineAM(),
        details,
        androidScheduleMode: mode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }

    try {
      await schedule(AndroidScheduleMode.exactAllowWhileIdle);
    } catch (_) {
      // Android 12+ อาจไม่อนุญาตให้ตั้งเวลาแบบเป๊ะ (exact alarm) ถอยไปใช้แบบประมาณเวลาแทน
      await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  // 📌 ยกเลิกแจ้งเตือนรายวัน (ใช้ตอนผู้ใช้ปิดสวิตช์แจ้งเตือนในหน้าตั้งค่า)
  static Future<void> cancelDailyReminder() async {
    await _notificationsPlugin.cancel(_dailyReminderId);
  }

  // 📌 เปิด/ปิดแจ้งเตือนรายวันตามสวิตช์ในหน้าตั้งค่า
  static Future<void> setDailyReminderEnabled(bool enabled) async {
    if (enabled) {
      await scheduleDaily9AMNotification();
    } else {
      await cancelDailyReminder();
    }
  }

  static tz.TZDateTime _nextInstanceOfNineAM() {
    return tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1));
  }
}