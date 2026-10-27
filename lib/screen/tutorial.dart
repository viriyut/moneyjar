import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firstapp/screen/home.dart';
import 'package:flutter/material.dart';

/// 📌 หน้าแนะนำวิธีใช้งานแอป (แสดงอัตโนมัติครั้งแรก และเปิดดูซ้ำได้จากหน้าตั้งค่า)
class TutorialScreen extends StatefulWidget {
  /// true = เปิดตอนสมัครสมาชิกใหม่ (จบแล้วไปหน้า Home)
  /// false = เปิดดูซ้ำจากหน้าตั้งค่า (จบแล้วย้อนกลับ)
  final bool isFirstTime;

  const TutorialScreen({super.key, this.isFirstTime = false});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialSlide {
  final IconData icon;
  final String title;
  final String body;
  const _TutorialSlide(this.icon, this.title, this.body);
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const List<_TutorialSlide> _slides = [
    _TutorialSlide(
      Icons.savings_outlined,
      'ยินดีต้อนรับสู่ MoneyJar',
      'แอปบันทึกรายรับ-รายจ่ายและวางแผนการเงินของคุณ\nมาเริ่มใช้งานกันเลย',
    ),
    _TutorialSlide(
      Icons.pie_chart_outline,
      'ตั้งค่าหน้าหลัก & งบประมาณ',
      'ที่หน้าหลัก สามารถกดปุ่มแก้ไข (มุมขวาบนของกราฟวงกลม)\n'
          'เพื่อปรับแต่งสัดส่วนการเงินและแก้ไขงบประมาณเริ่มต้นได้\n'
          '(โดยระบบเริ่มต้นให้ที่ 10,000 บาท สามารถปรับได้ตามใจชอบ)',
    ),
    _TutorialSlide(
      Icons.view_week_outlined,
      'กระปุกการเงิน 3 ส่วน',
      'หน้าหลักจะแบ่งการจัดสรรเงินเป็น 3 ส่วน ได้แก่:\n\n'
          '🔴 ค่าใช้จ่ายจำเป็น: สำหรับค่าใช้จ่ายพื้นฐาน\n'
          '🟡 ค่าใช้จ่ายส่วนตัว: สำหรับความบันเทิง/ช้อปปิ้ง\n'
          '🔵 เงินออม: เงินที่กันไว้เพื่อเป้าหมายออมเงิน\n\n'
          'แถบจะแสดงความคืบหน้าการใช้จ่ายตามสัดส่วนที่ตั้งไว้ โดยระบบจะแจ้งเตือนอัตโนมัติเมื่อใช้จ่าย/ออมเงินถึง 50%, 70% และ 100%\n'
          '(การแจ้งเตือนสามารถเปิด/ปิดได้ภายในตั้งค่า)',
    ),
    _TutorialSlide(
      Icons.layers_outlined,
      'เพิ่มรายการ',
      'ไปที่แท็บ "หมวดหมู่" (ไอคอนที่ 4 ในแถบด้านล่าง)\n'
          'เลือกเพิ่มรายรับ/รายจ่าย หรือเงินออม เลือกหมวดหมู่ ใส่จำนวนเงิน\n'
          'และสามารถพิมพ์รายละเอียดได้เล็กน้อย',
    ),
    _TutorialSlide(
      Icons.category_outlined,
      'ประเภทของรายการ',
      'รายรับ: เงินเดือน, งานพาร์ทไทม์/ฟรีแลนซ์, เงินปันผล, เงินรางวัล\n\n'
          'ค่าใช้จ่ายจำเป็น: อาหาร, ผ่อนบ้าน/ค่าเช่า, น้ำ-ไฟ-เน็ต, ผ่อนรถ, '
          'เดินทาง, ประกัน, รักษาพยาบาล, ของใช้จำเป็น\n\n'
          'ค่าใช้จ่ายส่วนตัว: ความบันเทิง, ทำบุญ, ท่องเที่ยว\n\n'
          'เงินออมจะแยกคิดต่างหาก ไม่รวมเป็นรายรับ',
    ),
    _TutorialSlide(
      Icons.swap_horiz_outlined,
      'แก้ไข / ลบรายการ',
      'ที่แท็บ "ธุรกรรม" แตะรายการเพื่อแก้ไขจำนวนเงินและรายละเอียด\n'
          'ปัดรายการไปทางซ้ายเพื่อลบ',
    ),
    _TutorialSlide(
      Icons.analytics_outlined,
      'ดูภาพรวมการเงิน',
      '📊 แท็บกราฟ: แสดงรายรับ รายจ่าย และเงินออม แยกรายวัน/เดือน/ปี\n\n'
          '🔍 หน้าค้นหา: สามรถเลือกหารายการธุรกรรมในแต่ละหมวดหมู่ย้อนหลังได้อย่างรวดเร็ว\n\n'
          '📅 หน้าปฏิทิน: เลือกดูสรุปยอดรายรับ-รายจ่ายย้อนหลังในแต่ละวันโดยสามารถเลือกได้สูงสุดเต็มเดือน',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// จบ Tutorial: ถ้าเปิดตอนสมัครใหม่ -> จดว่าดูแล้ว แล้วไปหน้า Home และล้าง stack
  /// ถ้าเปิดดูซ้ำจากหน้าตั้งค่า -> ย้อนกลับตามปกติ
  void _finish() {
    if (widget.isFirstTime) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        // ไม่ใช้ await เพื่อไม่ให้ค้างตอนเน็ตหลุด (Firestore จะเก็บไว้ในเครื่องแล้วซิงค์ทีหลัง)
        FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set({'tutorialSeen': true}, SetOptions(merge: true))
            .catchError((_) {});
      }
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _next() {
    if (_page >= _slides.length - 1) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLast = _page == _slides.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFA2E0B2),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ปุ่มข้าม
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text(
                    'ข้าม',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3323),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: _controller,
                        itemCount: _slides.length,
                        onPageChanged: (i) => setState(() => _page = i),
                        itemBuilder: (context, i) {
                          final slide = _slides[i];
                          return SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(28, 40, 28, 16),
                            child: Column(
                              children: [
                                Container(
                                  width: 110,
                                  height: 110,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFD7F5DC),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(i == 0 ? 18.0 : 0),
                                    child: i == 0
                                        // 📌 สไลด์แรกแสดงรูปโลโก้แอป
                                        ? Image.asset(
                                            'assets/images/mj e logo.png',
                                            fit: BoxFit.contain,
                                          )
                                        // 📌 สไลด์อื่นๆ แสดง IconData
                                        : Icon(
                                            slide.icon,
                                            size: 54,
                                            color: const Color(0xFF1E3323),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                Text(
                                  slide.title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E3323),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  slide.body,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.5,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // จุดบอกหน้า
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_slides.length, (i) {
                        final active = i == _page;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: active ? 20 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: active
                                ? const Color(0xFF73D193)
                                : const Color(0xFFD8D8D8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),

                    // ปุ่มถัดไป / เริ่มใช้งาน
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        28,
                        20,
                        28,
                        24 + MediaQuery.of(context).padding.bottom,
                      ),
                      child: SizedBox(
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
                          onPressed: _next,
                          child: Text(
                            isLast ? 'เริ่มใช้งาน' : 'ถัดไป',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}