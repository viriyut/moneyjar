import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firstapp/firebase_options.dart';
import 'package:firstapp/screen/home.dart';
import 'package:firstapp/screen/started.dart';
import 'package:flutter/material.dart';
import 'package:firstapp/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ต้อง initialize Firebase ก่อนสิ่งอื่นใด
  // ถ้าพลาด ให้แอปยังเปิดขึ้นมาได้ (ไม่ค้างหน้าเปิดแอป) แล้วค่อยดู error ใน log
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  // 📌 เปิดแอปก่อนเสมอ แล้วค่อยตั้งแจ้งเตือนทีหลัง
  // เดิมตั้งแจ้งเตือนก่อน runApp ถ้า error แอปจะค้างหน้าเปิดแอปตลอด
  runApp(const MyApp());
  _setupNotifications();
}

Future<void> _setupNotifications() async {
  try {
    await NotificationService.init();
    await NotificationService.scheduleDaily9AMNotification();
  } catch (e) {
    // แจ้งเตือนพัง ไม่ควรทำให้ทั้งแอปใช้ไม่ได้
    debugPrint('Notification setup failed: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoneyJar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Kanit',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AuthGate(),
    );
  }
}

/// 📌 เช็คตอนเปิดแอปว่าเคยล็อกอินค้างไว้ไหม
/// - ล็อกอินอยู่ -> เข้าหน้าหลักเลย (ไม่ต้องล็อกอินใหม่ทุกครั้ง)
/// - ยังไม่ล็อกอิน -> ไปหน้าเริ่มต้น
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // ถ้า Firebase เริ่มต้นไม่สำเร็จ ให้ไปหน้าเริ่มต้นตามปกติ (ไม่เรียก FirebaseAuth)
    if (Firebase.apps.isEmpty) return const StartedScreen();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFA2E0B2),
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3323)),
              ),
            ),
          );
        }
        if (snapshot.hasData) return const HomeScreen();
        return const StartedScreen();
      },
    );
  }
}