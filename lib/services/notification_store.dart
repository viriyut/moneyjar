// lib/services/notification_store.dart
class NotificationStore {
  static final List<Map<String, String>> history = [];

  static void addNotification({
    required String title,
    required String body,
    String type = 'reminder',
  }) {
    // 📌 เช็คว่าถ้ามีข้อความ title และ body นี้อยู่ในประวัติแล้ว จะไม่แอดเพิ่มเด็ดขาด
    bool isDuplicate = history.any((item) => item['title'] == title && item['body'] == body);
    if (isDuplicate) {
      return; 
    }

    final now = DateTime.now();
    final timeStr =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} - ${_getMonthName(now.month)} ${now.day}";

    history.insert(0, {
      'title': title,
      'body': body,
      'time': timeStr,
      'type': type,
    });
  }

  static String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}