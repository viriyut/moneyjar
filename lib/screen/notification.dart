import 'package:flutter/material.dart';
import 'package:firstapp/services/notification_store.dart'; // 📌 นำเข้าไฟล์ Store (ปรับ path ตามจริง)

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 📌 ดึงรายการจาก NotificationStore
    final notifications = NotificationStore.history;

    return Scaffold(
      backgroundColor: const Color(0xFFA2E0B2), // สีเขียวตรงกับหน้าหลัก
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header ด้านบน
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                height: 40,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFF1E3323),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const Center(
                      child: Text(
                        "การแจ้งเตือน",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3323),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // เนื้อหาหลักสีขาว ยืดลงมาล่างสุด
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3FAF4),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: notifications.isEmpty
                    ? const Center(
                        child: Text(
                          "ยังไม่มีรายการแจ้งเตือน",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "รายการล่าสุด",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3323),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: notifications.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(
                                    color: Colors.black12,
                                    height: 24,
                                  ),
                              itemBuilder: (context, index) {
                                final item = notifications[index];
                                final isWarning = item['type'] == 'warning';

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ไอคอนแจ้งเตือน
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: isWarning
                                            ? const Color(0xFFEE4E4E)
                                            : const Color(0xFFA2E0B2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        isWarning
                                            ? Icons.error_outline
                                            : Icons.check_circle_outline,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // ข้อความ
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['title'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E3323),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item['body'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black87,
                                              height: 1.3,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              item['time'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.blueAccent,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
