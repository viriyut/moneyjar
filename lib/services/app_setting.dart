import 'package:flutter/foundation.dart';

/// 📌 สถานะเปิด/ปิดการแจ้งเตือนของแอป ใช้ร่วมกันทุกหน้า
/// - หน้าตั้งค่าเป็นคนเปลี่ยนค่า (และบันทึกลง Firestore)
/// - หน้าหลักอ่านค่านี้ก่อนยิงแจ้งเตือนทุกครั้ง
final ValueNotifier<bool> notificationsEnabledNotifier =
    ValueNotifier<bool>(true);