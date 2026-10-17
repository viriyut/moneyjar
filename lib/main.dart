import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // 📌 เพิ่ม import นี้
import 'firebase_options.dart'; // 📌 เพิ่ม import ไฟล์คอนฟิกที่ flutterfire configure สร้างให้
import 'package:firstapp/screen/started.dart';
import 'package:firstapp/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 📌 เรียกใช้งาน Firebase เป็นอันดับแรก
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // การตั้งค่าแจ้งเตือนเดิมของคุณ
  await NotificationService.init();
  await NotificationService.scheduleDaily9AMNotification();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        fontFamily: 'Kanit',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: StartedScreen(),
    );
  }
}