import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firstapp/screen/home.dart';
import 'package:firstapp/screen/login.dart';
import 'package:firstapp/screen/notification.dart';
import 'package:flutter/material.dart';
import 'package:firstapp/screen/edit_profile_screen.dart';
import 'package:firstapp/screen/setting.dart';

class ProfileScreen extends StatelessWidget {
  /// เรียกตอนกดปุ่มย้อนกลับ ใช้สลับกลับไปแท็บ "หน้าหลัก" โดยไม่ล้าง state ทิ้ง
  /// (ถ้าไม่ส่งมา จะ fallback ไปสร้าง HomeScreen ใหม่ตามโค้ดเดิม)
  final VoidCallback? onBack;

  const ProfileScreen({super.key, this.onBack});

  // 📌 Dialog หน้าต่างป๊อปอัปออกจากระบบ (สีแดง)
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ไอคอนเตือนออกจากระบบ
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFDE8E8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: Color(0xFFEE4E4E),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),

                // ข้อความหัวข้อ
                const Text(
                  'ออกจากระบบ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3323),
                  ),
                ),
                const SizedBox(height: 8),

                // ข้อความอธิบาย
                Text(
                  'คุณแน่ใจใช่ไหมว่าต้องการออกจากระบบ?',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // ปุ่มดำเนินการ (ยกเลิก / ออกจากระบบ)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFF1E3323)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          'ยกเลิก',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3323),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFFEE4E4E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.pop(ctx); // ปิด Dialog

                          // เคลียร์หน้าก่อนหน้าทั้งหมด แล้วเด้งกลับไปหน้า Login
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        child: const Text(
                          'ออกจากระบบ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3FAF4),
      body: Column(
        children: [
          // ส่วน Header + รูปโปรไฟล์
          SizedBox(
            height: 180,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 160,
                  width: double.infinity,
                  color: const Color(0xFFA2E0B2),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (onBack != null) {
                                // ✅ เปิดมาจากแท็บ bottom nav -> สลับกลับไปแท็บ "หน้าหลัก" (ไม่ล้าง state ทิ้ง)
                                onBack!();
                              } else {
                                // fallback กรณีไม่ได้ส่ง onBack มา (โค้ดเดิม)
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const HomeScreen(),
                                  ),
                                  (route) => false,
                                );
                              }
                            },
                            child: Container(
                              width: 38,
                              height: 38,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.arrow_back,
                                color: Color(0xFF1E3323),
                                size: 24,
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text(
                              'โปรไฟล์',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3323),
                                height: 1.2,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const NotificationPage(),
                                ),
                              );
                            },
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.notifications_none,
                                color: Color(0xFF1E3323),
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 135,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3FAF4),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(36),
                        topRight: Radius.circular(36),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 85,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 95,
                      height: 95,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF3FAF4),
                        border: Border.all(
                          color: const Color(0xFF1E3323),
                          width: 3.5,
                        ),
                      ),
                      // 📌 แสดงรูปโปรไฟล์ที่เลือกไว้ (ถ้ายังไม่มีให้โชว์ไอคอนเดิม)
                      child: ValueListenableBuilder<File?>(
                        valueListenable: profileImageNotifier,
                        builder: (context, file, _) {
                          if (file == null) {
                            return const Center(
                              child: Icon(
                                Icons.person,
                                size: 65,
                                color: Color(0xFF1E3323),
                              ),
                            );
                          }
                          return ClipOval(
                            child: Image.file(
                              file,
                              fit: BoxFit.cover,
                              width: 88,
                              height: 88,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // รายการเมนูด้านล่าง
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // 📌 ชื่อ/อีเมลของบัญชีที่ login อยู่ ฟังจาก Firestore แก้ชื่อแล้วอัปเดตทันที
                  _buildUserInfo(),
                  const SizedBox(height: 20),
                  _buildMenuItem(
                    icon: Icons.person_outline,
                    title: 'จัดการโปรไฟล์',
                    iconBgColor: const Color(0xFFD7F5DC),
                    iconColor: const Color(0xFF1E3323),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'ตั้งค่า',
                    iconBgColor: const Color(0xFFD7F5DC),
                    iconColor: const Color(0xFF1E3323),
                    // ✅ แก้ตรงนี้: เดิมเป็น () {} ว่างเปล่า ไม่ได้เปิดหน้า Settings เลย
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    icon: Icons.logout,
                    title: 'ออกจากระบบ',
                    iconBgColor: const Color(0xFFFDE8E8),
                    iconColor: const Color(0xFFEE4E4E),
                    isDestructive: true,
                    // 📌 เรียกฟังก์ชัน Dialog สีแดงตรงกลาง
                    onTap: () => _showLogoutDialog(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _userInfoTexts('User', 'ยังไม่ได้เข้าสู่ระบบ');
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final name = (data?['name'] as String?)?.trim();
        final email = (data?['email'] as String?) ?? user.email ?? '';
        return _userInfoTexts(
          (name == null || name.isEmpty) ? (user.displayName ?? 'User') : name,
          email,
        );
      },
    );
  }

  Widget _userInfoTexts(String name, String email) {
    return Column(
      children: [
        Text(
          name,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3323),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          email,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDestructive
                        ? const Color(0xFFEE4E4E)
                        : const Color(0xFF1E3323),
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDestructive
                    ? const Color(0xFFEE4E4E)
                    : Colors.grey[400],
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}