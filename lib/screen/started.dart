import 'package:firstapp/screen/login.dart';
import 'package:firstapp/screen/register.dart';
import 'package:flutter/material.dart';

class StartedScreen extends StatelessWidget {
  const StartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA2E0B2), // พื้นหลังเขียวส่วนบน เหมือนหน้าอื่นในแอป
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ---------- ส่วนบน: โลโก้ ----------
            Expanded(
              child: Center(
                child: Container(
                  width: 210,
                  height: 210,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      "assets/images/mj e logo.png",
                      fit: BoxFit.cover,
                      // กันแอปพังถ้าหาไฟล์รูปไม่เจอ (เช่น ยังไม่ได้ประกาศ assets ใน pubspec.yaml)
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.savings_outlined,
                        size: 100,
                        color: Color(0xFF1E3323),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ---------- ส่วนล่าง: การ์ดขาวโค้งมน ----------
            Container(
              width: double.infinity,
              // 📌 บวกพื้นที่แถบปุ่มระบบของมือถือ (padding.bottom) ไม่ให้บังปุ่มด้านล่าง
              padding: EdgeInsets.fromLTRB(
                28,
                32,
                28,
                40 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "MoneyJar",
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3323),
                    ),
                  ),

                  const SizedBox(height: 28),

                  /// ปุ่มเข้าสู่ระบบ
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA2E0B2),
                        foregroundColor: const Color(0xFF1E3323),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "เข้าสู่ระบบ",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  /// ปุ่มสร้างบัญชีใหม่
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE4F5E6),
                        foregroundColor: const Color(0xFF1E3323),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "สร้างบัญชีใหม่",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}