import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firstapp/screen/financial_overview.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firstapp/screen/profile_screen.dart';
import 'package:firstapp/screen/category.dart';
import 'package:firstapp/screen/transaction.dart';
import 'package:firstapp/screen/transaction_model.dart';

// 📌 นำเข้าไฟล์ Notification และ NotificationService
import 'package:firstapp/screen/notification.dart';
import 'package:firstapp/services/app_setting.dart';
import 'package:firstapp/services/notification_service.dart';

// ============================================================
// 📌 Keyword กลาง ใช้ร่วมกันทั้งไฟล์ (ทั้ง Notification และ Progress bar)
// ห้ามประกาศ list คำสำคัญซ้ำที่อื่นอีก มิเช่นนั้นจะเกิดปัญหา
// คำนวณยอดไม่ตรงกันระหว่างสองจุดเหมือนที่เคยเกิดขึ้น
// ============================================================
const List<String> kEssentialKeywords = [
  'อาหาร',
  'เดินทาง',
  'หนี้',
  'เรียน',
  'ห้อง',
  'ที่อยู่',
  'จำเป็น',
  'การศึกษา',
  'ยา',
  'น้ำ',
  'ไฟ',
  'บ้าน',
  'พยาบาล',
];

const List<String> kPersonalKeywords = [
  'คาเฟ่',
  'ชาไข่มุก',
  'ช้อปปิ้ง',
  'ความบันเทิง',
  'ท่องเที่ยว',
  'ส่วนตัว',
  'เกม',
  'สัตว์เลี้ยง',
];

const List<String> kSavingsKeywords = ['เงินออม', 'ลงทุน', 'กองทุน', 'ออม'];

// ============================================================
// 📌 ไอคอนที่ใช้ในหมวดหมู่ทั้งหมด (ต้องเป็น const เพื่อให้ build release ตัดไอคอนที่ไม่ใช้ออกได้)
// ถ้าเพิ่มไอคอนหมวดหมู่ใหม่ใน category.dart ให้เพิ่มในลิสต์นี้ด้วย
// ไม่งั้นรายการที่โหลดจาก Firestore จะแสดงเป็นไอคอนทั่วไปแทน
// ============================================================
final Map<int, IconData> _knownIcons = {
  for (final icon in const <IconData>[
    Icons.restaurant_menu,
    Icons.home_outlined,
    Icons.directions_bus,
    Icons.medical_services_outlined,
    Icons.shopping_bag_outlined,
    Icons.credit_card_outlined,
    Icons.local_cafe_outlined,
    Icons.checkroom_outlined,
    Icons.confirmation_number_outlined,
    Icons.flight_takeoff_outlined,
    Icons.pets,
    Icons.card_giftcard,
    Icons.payments_outlined,
    Icons.savings_outlined,
    Icons.category_outlined,
    Icons.add,
  ])
    icon.codePoint: icon,
};

IconData _iconFromCodePoint(int? codePoint) {
  if (codePoint == null) return Icons.category_outlined;
  return _knownIcons[codePoint] ?? Icons.category_outlined;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // 📌 ไม่ใช่ final แล้ว เพราะจะถูกแทนที่ด้วยข้อมูลสดจาก Firestore ทุกครั้งที่มีการเปลี่ยนแปลง
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoadingTransactions = true;

  // 📌 ตัวแปรตั้งค่า งบรวม และ สัดส่วน % (ค่าเริ่มต้น ใช้ตอนยังโหลดจาก Firestore ไม่เสร็จ)
  double _totalBudget = 10000.0;
  double _essentialPct = 50.0; // ค่าใช้จ่ายจำเป็น
  double _personalPct = 30.0; // ค่าใช้จ่ายส่วนตัว
  double _savingsPct = 20.0; // เงินออม

  StreamSubscription<QuerySnapshot>? _transactionsSub;
  StreamSubscription<DocumentSnapshot>? _userDocSub;

  // uid ของผู้ใช้ที่ login อยู่ตอนนี้ (null ถ้าไม่ได้ login)
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _listenToUserData();
  }

  @override
  void dispose() {
    _transactionsSub?.cancel();
    _userDocSub?.cancel();
    super.dispose();
  }

  // 📌 เริ่มฟังข้อมูลธุรกรรม + งบประมาณของบัญชีที่ login อยู่ตอนนี้ (ตาม uid)
  void _listenToUserData() {
    final uid = _uid;
    if (uid == null) {
      // ยังไม่ได้ login ไม่ต้องดึงข้อมูลอะไร
      _isLoadingTransactions = false;
      return;
    }

    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

    // ฟังรายการธุรกรรมของบัญชีนี้ เรียงล่าสุดก่อน
    _transactionsSub = userDoc
        .collection('transactions')
        .orderBy('dateTime', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        final loaded = snapshot.docs
            .map((doc) => _decodeTransaction(doc.id, doc.data()))
            .toList();
        if (!mounted) return;
        setState(() {
          _transactions = loaded;
          _isLoadingTransactions = false;
        });
      },
      onError: (e) {
        // ถ้าอ่านไม่ได้ (เช่น security rules ไม่อนุญาต) อย่าให้ค้างที่หน้าโหลดตลอด
        if (!mounted) return;
        setState(() => _isLoadingTransactions = false);
      },
    );

    // ฟังงบประมาณของบัญชีนี้ (ถ้ายังไม่เคยตั้งค่าไว้ จะใช้ค่าเริ่มต้นด้านบนไปก่อน)
    _userDocSub = userDoc.snapshots().listen((doc) {
      final data = doc.data();
      if (data == null || !mounted) return;
      // สถานะเปิด/ปิดแจ้งเตือนที่ผู้ใช้ตั้งไว้ (ถ้ายังไม่เคยตั้ง = เปิด)
      final notificationsEnabled = data['notificationsEnabled'] as bool? ?? true;
      notificationsEnabledNotifier.value = notificationsEnabled;
      // main.dart ตั้งแจ้งเตือนรายวันไว้ทุกครั้งที่เปิดแอป ถ้าผู้ใช้ปิดไว้ให้ยกเลิกทิ้ง
      if (!notificationsEnabled) {
        NotificationService.cancelDailyReminder();
      }
      setState(() {
        _totalBudget = (data['totalBudget'] as num?)?.toDouble() ?? _totalBudget;
        _essentialPct = (data['essentialPct'] as num?)?.toDouble() ?? _essentialPct;
        _personalPct = (data['personalPct'] as num?)?.toDouble() ?? _personalPct;
        _savingsPct = (data['savingsPct'] as num?)?.toDouble() ?? _savingsPct;
      });
    });
  }

  // 📌 แปลงข้อมูลดิบจาก Firestore กลับเป็นรูปแบบที่หน้าจออื่นในแอปใช้อยู่
  // (ต้องแปลง icon/สีกลับเป็น IconData/Color เพราะ Firestore เก็บได้แค่ตัวเลข/ข้อความ)
  Map<String, dynamic> _decodeTransaction(String id, Map<String, dynamic> data) {
    return {
      'id': id,
      'title': data['title'] as String? ?? 'ไม่มีชื่อรายการ',
      'amount': (data['amount'] as num?)?.toDouble() ?? 0.0,
      'isIncome': data['isIncome'] as bool? ?? false,
      'dateTime': data['dateTime'] is Timestamp
          ? (data['dateTime'] as Timestamp).toDate()
          : DateTime.now(),
      'icon': _iconFromCodePoint(data['iconCodePoint'] as int?),
      'iconBgColor': Color(data['iconColorValue'] as int? ?? Colors.grey.toARGB32()),
    };
  }

  double get _totalBalance {
    double total = 0.0;
    for (var tx in _transactions) {
      if (tx['isIncome'] == true) {
        total += (tx['amount'] as double);
      } else {
        total -= (tx['amount'] as double);
      }
    }
    return total;
  }

  // 📌 ฟังก์ชันคำนวณยอดใช้จ่ายตาม Keyword (ใช้สำหรับเช็คเงื่อนไขยิง Notification)
  double _calculateSpentForGroup(List<String> keywords) {
    return _transactions
        .where(
          (tx) =>
              tx['isIncome'] == false &&
              keywords.any((kw) => (tx['title'] as String).contains(kw)),
        )
        .fold(0.0, (sum, tx) => sum + (tx['amount'] as double));
  }

  // 📌 ฟังก์ชันบันทึกข้อมูลและสลับไปหน้า Transaction (Index 2) พร้อมระบบแจ้งเตือนทุกหมวดหมู่
  // 📌 สลับกลับไปแท็บ "หน้าหลัก" ใช้กับปุ่มย้อนกลับของหน้าอื่นๆ ในแท็บ
  void _goToHome() {
    setState(() {
      _currentIndex = 0;
    });
  }

  // 📌 ยิงแจ้งเตือน เฉพาะตอนที่ผู้ใช้เปิดการแจ้งเตือนไว้ในหน้าตั้งค่า
  void _notify({required int id, required String title, required String body}) {
    if (!notificationsEnabledNotifier.value) return;
    NotificationService.showNotification(id: id, title: title, body: body);
  }

  // 📌 เขียนธุรกรรมลง Firestore (ถ้าไม่ได้ login จะข้ามไป)
  Future<void> _saveTransactionToFirestore(
    TransactionModel tx,
    String? id,
  ) async {
    final uid = _uid;
    if (uid == null || id == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .doc(id)
          .set({
        'title': tx.title,
        'amount': tx.amount,
        'isIncome': tx.isIncome,
        'dateTime': tx.dateTime,
        'iconCodePoint': tx.icon.codePoint,
        'iconFontFamily': tx.icon.fontFamily ?? 'MaterialIcons',
        'iconColorValue': tx.iconBgColor.toARGB32(),
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกรายการไปยังเซิร์ฟเวอร์ไม่สำเร็จ')),
      );
    }
  }

  // 📌 ลบรายการ: เอาออกจากหน้าจอทันที แล้วลบเอกสารใน Firestore
  Future<void> _deleteTransaction(Map<String, dynamic> item) async {
    setState(() => _transactions.remove(item));

    final uid = _uid;
    final id = item['id'] as String?;
    if (uid == null || id == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .doc(id)
          .delete();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบรายการบนเซิร์ฟเวอร์ไม่สำเร็จ')),
      );
    }
  }

  // 📌 แก้ไขจำนวนเงินของรายการ: อัปเดตหน้าจอทันที แล้วอัปเดตเอกสารใน Firestore
  Future<void> _updateTransactionAmount(
    Map<String, dynamic> item,
    double newAmount,
  ) async {
    final oldAmount = item['amount'];
    setState(() => item['amount'] = newAmount);

    final uid = _uid;
    final id = item['id'] as String?;
    if (uid == null || id == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .doc(id)
          .update({'amount': newAmount});
    } catch (e) {
      if (!mounted) return;
      setState(() => item['amount'] = oldAmount); // คืนค่าเดิมถ้าบันทึกไม่สำเร็จ
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('แก้ไขรายการบนเซิร์ฟเวอร์ไม่สำเร็จ')),
      );
    }
  }

  void _addTransactionFromModel(TransactionModel tx) {
    // สร้างรหัสเอกสารล่วงหน้า เพื่อให้รายการที่เพิ่งเพิ่มลบ/แก้ไขได้ทันที
    final uid = _uid;
    final String? newId = uid == null
        ? null
        : FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('transactions')
            .doc()
            .id;

    setState(() {
      _transactions.insert(0, {
        'id': newId,
        'title': tx.title,
        'amount': tx.amount,
        'dateTime': tx.dateTime,
        'icon': tx.icon,
        'iconBgColor': tx.iconBgColor,
        'isIncome': tx.isIncome,
      });
      _currentIndex = 2; // สลับไปหน้า Transaction ทันทีหลังบันทึก
    });

    // 📌 บันทึกลง Firestore จริง ผูกกับบัญชีที่ login อยู่ (uid)
    _saveTransactionToFirestore(tx, newId);

    // ========================================================
    // 🔔 1. แจ้งเตือน: ค่าใช้จ่ายจำเป็น (50%, 70%, 100%)
    // ========================================================
    final double essentialBudget = _totalBudget * (_essentialPct / 100);
    if (essentialBudget > 0) {
      final double currentEssentialSpent = _calculateSpentForGroup(
        kEssentialKeywords,
      );
      // หายอดก่อนหน้ารายการนี้ (ถ้ารายการนี้ตรงกับหมวดจำเป็น ให้ลบออกก่อนเช็ค)
      final bool isEssentialTx = kEssentialKeywords.any(
        (kw) => tx.title.contains(kw),
      );
      final double previousEssentialSpent = isEssentialTx
          ? (currentEssentialSpent - tx.amount)
          : currentEssentialSpent;

      final double currentProgress = currentEssentialSpent / essentialBudget;
      final double previousProgress = previousEssentialSpent / essentialBudget;

      if (currentProgress >= 1.0 && previousProgress < 1.0) {
        _notify(
          id: 101,
          title: '🚨 งบค่าใช้จ่ายจำเป็นถึงขีดจำกัด!',
          body:
              'คุณใช้จ่ายค่าใช้จ่ายจำเป็นครบ 100% แล้ว (${currentEssentialSpent.toStringAsFixed(0)} THB)',
        );
      } else if (currentProgress >= 0.7 && previousProgress < 0.7) {
        _notify(
          id: 102,
          title: '⚠️ เตือนค่าใช้จ่ายจำเป็น',
          body:
              'คุณใช้จ่ายไป  ${(currentProgress * 100).toStringAsFixed(0)}% แล้ว',
        );
      } else if (currentProgress >= 0.5 && previousProgress < 0.5) {
        _notify(
          id: 103,
          title: '📢 แจ้งเตือนค่าใช้จ่ายจำเป็น',
          body:
              'คุณใช้จ่ายค่าใช้จ่ายจำเป็นไปครึ่งหนึ่งแล้ว (${(currentProgress * 100).toStringAsFixed(0)}%)',
        );
      }
    }

    // ========================================================
    // 🔔 2. แจ้งเตือน: ค่าใช้จ่ายส่วนตัว (50%, 70%, 100%)
    // ========================================================
    final double personalBudget = _totalBudget * (_personalPct / 100);
    if (personalBudget > 0) {
      final double currentPersonalSpent = _calculateSpentForGroup(
        kPersonalKeywords,
      );
      final bool isPersonalTx = kPersonalKeywords.any(
        (kw) => tx.title.contains(kw),
      );
      final double previousPersonalSpent = isPersonalTx
          ? (currentPersonalSpent - tx.amount)
          : currentPersonalSpent;

      final double currentProgress = currentPersonalSpent / personalBudget;
      final double previousProgress = previousPersonalSpent / personalBudget;

      if (currentProgress >= 1.0 && previousProgress < 1.0) {
        _notify(
          id: 201,
          title: '🚨 งบค่าใช้จ่ายส่วนตัวถึงขีดจำกัด!',
          body:
              'คุณใช้จ่ายส่วนตัวครบ 100% แล้ว (${currentPersonalSpent.toStringAsFixed(0)}/${personalBudget.toStringAsFixed(0)} THB)',
        );
      } else if (currentProgress >= 0.7 && previousProgress < 0.7) {
        _notify(
          id: 202,
          title: '⚠️ เตือนค่าใช้จ่ายส่วนตัว',
          body:
              'คุณใช้จ่ายส่วนตัวถึง ${(currentProgress * 100).toStringAsFixed(0)}% แล้ว ระวังงบบานปลาย!',
        );
      } else if (currentProgress >= 0.5 && previousProgress < 0.5) {
        _notify(
          id: 203,
          title: '📢 แจ้งเตือนค่าใช้จ่ายส่วนตัว',
          body:
              'คุณใช้จ่ายส่วนตัวไปแล้ว ${(currentProgress * 100).toStringAsFixed(0)}%',
        );
      }
    }

    // ========================================================
    // 🔔 3. แจ้งเตือน: เงินออม (50%, 70%, 100%)
    // ========================================================
    final double savingsBudget = _totalBudget * (_savingsPct / 100);
    if (savingsBudget > 0) {
      final double currentSavingsSpent = _transactions
          .where(
            (t) => kSavingsKeywords.any(
              (kw) => (t['title'] as String).contains(kw),
            ),
          )
          .fold(0.0, (sum, t) => sum + (t['amount'] as double));

      final bool isSavingsTx = kSavingsKeywords.any(
        (kw) => tx.title.contains(kw),
      );
      final double previousSavingsSpent = isSavingsTx
          ? (currentSavingsSpent - tx.amount)
          : currentSavingsSpent;

      final double currentProgress = currentSavingsSpent / savingsBudget;
      final double previousProgress = previousSavingsSpent / savingsBudget;

      if (currentProgress >= 1.0 && previousProgress < 1.0) {
        _notify(
          id: 301,
          title: '🎉 ยินดีด้วย!',
          body:
              'คุณออมเงินบรรลุเป้าหมาย 100% ของเดือนนี้แล้ว! (${currentSavingsSpent.toStringAsFixed(0)} THB)',
        );
      } else if (currentProgress >= 0.7 && previousProgress < 0.7) {
        _notify(
          id: 302,
          title: '💪 อีกนิดเดียว!',
          body:
              'คุณออมเงินไปแล้ว ${(currentProgress * 100).toStringAsFixed(0)}% ใกล้ถึงเป้าหมายแล้ว!',
        );
      } else if (currentProgress >= 0.5 && previousProgress < 0.5) {
        _notify(
          id: 303,
          title: '🌱 มาได้ครึ่งทางแล้ว',
          body:
              'คุณออมเงินได้แล้ว ${(currentProgress * 100).toStringAsFixed(0)}% ของเป้าหมาย',
        );
      }
    }
  }

  // 📌 ป๊อปอัปแก้ไขงบประมาณรวม และ ปรับ Slider %
  void _showEditBudgetDialog() {
    final budgetController = TextEditingController(
      text: _totalBudget.toStringAsFixed(0),
    );
    double tempEssential = _essentialPct;
    double tempPersonal = _personalPct;
    double tempSavings = _savingsPct;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            double totalPct = tempEssential + tempPersonal + tempSavings;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "ตั้งค่าแผนการเงิน",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3323),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "งบประมาณตั้งต้น (THB)",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: budgetController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "เช่น 10000",
                        filled: true,
                        fillColor: const Color(0xFFF3FAF4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "ปรับสัดส่วน (%)",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          "รวม: ${totalPct.toStringAsFixed(0)}%",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: totalPct == 100 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Slider จำเป็น
                    _buildDialogSlider(
                      label: "จำเป็น",
                      val: tempEssential,
                      color: const Color(0xFFEE4E4E),
                      onChanged: (v) => setModalState(() => tempEssential = v),
                    ),
                    // Slider ส่วนตัว
                    _buildDialogSlider(
                      label: "ส่วนตัว",
                      val: tempPersonal,
                      color: const Color(0xFFF5BD55),
                      onChanged: (v) => setModalState(() => tempPersonal = v),
                    ),
                    // Slider เงินออม
                    _buildDialogSlider(
                      label: "เงินออม",
                      val: tempSavings,
                      color: const Color(0xFF3B97FF),
                      onChanged: (v) => setModalState(() => tempSavings = v),
                    ),

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA2E0B2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          final newTotalBudget =
                              double.tryParse(budgetController.text) ??
                                  _totalBudget;
                          setState(() {
                            _totalBudget = newTotalBudget;
                            _essentialPct = tempEssential;
                            _personalPct = tempPersonal;
                            _savingsPct = tempSavings;
                          });

                          // 📌 บันทึกแผนการเงินลง Firestore ผูกกับบัญชีที่ login อยู่
                          final uid = _uid;
                          if (uid != null) {
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .set({
                              'totalBudget': newTotalBudget,
                              'essentialPct': tempEssential,
                              'personalPct': tempPersonal,
                              'savingsPct': tempSavings,
                            }, SetOptions(merge: true));
                          }

                          Navigator.pop(context);
                        },
                        child: const Text(
                          "บันทึกแผนการเงิน",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3323),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDialogSlider({
    required String label,
    required double val,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13)),
            Text(
              "${val.toStringAsFixed(0)}%",
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        Slider(
          value: val,
          min: 0,
          max: 100,
          divisions: 20,
          activeColor: color,
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeContent(
        transactions: _transactions,
        totalBalance: _totalBalance,
        totalBudget: _totalBudget,
        essentialPct: _essentialPct,
        personalPct: _personalPct,
        savingsPct: _savingsPct,
        onEditBudget: _showEditBudgetDialog,
      ),
      // ✅ แก้ตรงนี้: ส่ง _transactions เข้าไปให้ FinancialOverviewPage (เดิมเป็น const FinancialOverviewPage() ไม่มีข้อมูล)
      FinancialOverviewPage(transactions: _transactions, onBack: _goToHome),
      TransactionScreen(
        transactions: _transactions,
        onAddTransaction: _addTransactionFromModel,
        onDeleteTransaction: _deleteTransaction,
        onEditTransaction: _updateTransactionAmount,
        onBack: _goToHome,
      ),
      CategoryScreen(onAddTransaction: _addTransactionFromModel, onBack: _goToHome),
      ProfileScreen(onBack: _goToHome),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFA2E0B2),
      body: _isLoadingTransactions
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3323)),
              ),
            )
          : IndexedStack(index: _currentIndex, children: screens),
      // 📌 SafeArea (เฉพาะด้านล่าง) กันแถบปุ่มระบบของมือถือไม่ให้ทับแถบเมนู
      // สีพื้นอยู่ที่ Container นอกสุด จึงยังต่อเนื่องไปถึงขอบล่างของจอ
      bottomNavigationBar: Container(
        color: const Color(0xFFF3FAF4),
        child: SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8, top: 2),
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFD7F5DC),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_outlined, 0),
                _buildNavItem(Icons.analytics_outlined, 1),
                _buildNavItem(Icons.swap_horiz_outlined, 2),
                _buildNavItem(Icons.layers_outlined, 3),
                _buildNavItem(Icons.person_outline, 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFA2E0B2) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF1E3323), size: 26),
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final double totalBalance;
  final double totalBudget;
  final double essentialPct;
  final double personalPct;
  final double savingsPct;
  final VoidCallback onEditBudget;

  const HomeContent({
    super.key,
    required this.transactions,
    required this.totalBalance,
    required this.totalBudget,
    required this.essentialPct,
    required this.personalPct,
    required this.savingsPct,
    required this.onEditBudget,
  });

  // 📌 ฟังก์ชันแยกคำนวณยอดเงินที่จ่ายไปตามกลุ่มหมวดหมู่
  double _calculateSpentForGroup(List<String> keywords) {
    return transactions
        .where(
          (tx) =>
              tx['isIncome'] == false &&
              keywords.any((kw) => (tx['title'] as String).contains(kw)),
        )
        .fold(0.0, (sum, tx) => sum + (tx['amount'] as double));
  }

  @override
  Widget build(BuildContext context) {
    // 📌 1. คำนวณยอดเงินเป้าหมายของแต่ละกลุ่ม
    final double essentialBudget = totalBudget * (essentialPct / 100);
    final double personalBudget = totalBudget * (personalPct / 100);
    final double savingsBudget = totalBudget * (savingsPct / 100);

    // 📌 2. คำนวณยอดที่ใช้จ่ายไปจริงในแต่ละกลุ่ม
    final double essentialSpent = _calculateSpentForGroup(kEssentialKeywords);
    final double personalSpent = _calculateSpentForGroup(kPersonalKeywords);
    final double savingsSpent = transactions
        .where(
          (tx) => kSavingsKeywords.any(
            (kw) => (tx['title'] as String).contains(kw),
          ),
        )
        .fold(0.0, (sum, tx) => sum + (tx['amount'] as double));

    // 📌 3. คำนวณสัดส่วนสำหรับ Progress Bar (0.0 ถึง 1.0)
    final double essentialProgress = essentialBudget > 0
        ? (essentialSpent / essentialBudget)
        : 0.0;
    final double personalProgress = personalBudget > 0
        ? (personalSpent / personalBudget)
        : 0.0;
    final double savingsProgress = savingsBudget > 0
        ? (savingsSpent / savingsBudget)
        : 0.0;

    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Column(
              children: [
                SizedBox(
                  height: 40,
                  child: Stack(
                    children: [
                      const Center(
                        child: Text(
                          "หน้าหลัก",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3323),
                            height: 1.2,
                          ),
                        ),
                      ),

                      // 📌 ปุ่มกระดิ่ง เปิดไปที่ NotificationPage
                      Positioned(
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotificationPage(),
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
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.north_east, size: 14, color: Color(0xFF1E3323)),
                    SizedBox(width: 4),
                    Text(
                      "ยอดคงเหลือ",
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1E3323),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  "${totalBalance.toStringAsFixed(2)} THB",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3323),
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
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
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "แผนการเงินของฉัน",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3323),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 📌 กราฟ PieChart + ปุ่มกดแก้ไขงบ
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDFF6DE),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Stack(
                      children: [
                        PieChart(
                          PieChartData(
                            centerSpaceRadius: 0,
                            sectionsSpace: 2,
                            borderData: FlBorderData(show: false),
                            sections: [
                              PieChartSectionData(
                                value: essentialPct,
                                color: const Color(0xFFEE4E4E),
                                radius: 80,
                                title: "${essentialPct.toStringAsFixed(0)}%",
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              PieChartSectionData(
                                value: personalPct,
                                color: const Color(0xFFF5BD55),
                                radius: 80,
                                title: "${personalPct.toStringAsFixed(0)}%",
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              PieChartSectionData(
                                value: savingsPct,
                                color: const Color(0xFF3B97FF),
                                radius: 80,
                                title: "${savingsPct.toStringAsFixed(0)}%",
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: onEditBudget,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFFA2E0B2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit_note,
                                color: Color(0xFF1E3323),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: onEditBudget,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2F3E4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        "แก้ไขงบรวม (${totalBudget.toStringAsFixed(0)} THB)",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4A6B50),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 📌 1. หลอด Progress ค่าใช้จ่ายจำเป็น
                  _buildBudgetItem(
                    dotColor: const Color(0xFFEE4E4E),
                    title:
                        "ค่าใช้จ่ายจำเป็น ${essentialPct.toStringAsFixed(0)}%",
                    badgeBgColor: const Color.fromARGB(255, 238, 164, 164),
                    progressColor: const Color(0xFFEE4E4E),
                    percentValue: essentialProgress,
                    badgeText:
                        "คุณใช้จ่ายไป ${essentialSpent.toStringAsFixed(0)} / ${essentialBudget.toStringAsFixed(0)} THB",
                    subIcon: essentialProgress >= 1.0
                        ? Icons.warning_amber_rounded
                        : Icons.error_outline,
                    subText:
                        "คิดเป็น ${(essentialProgress * 100).toStringAsFixed(0)}% ของค่าใช้จ่ายจำเป็น",
                  ),
                  const SizedBox(height: 12),

                  // 📌 2. หลอด Progress ค่าใช้จ่ายส่วนตัว
                  _buildBudgetItem(
                    dotColor: const Color(0xFFF5BD55),
                    title:
                        "ค่าใช้จ่ายส่วนตัว ${personalPct.toStringAsFixed(0)}%",
                    badgeBgColor: const Color.fromARGB(255, 240, 227, 198),
                    progressColor: const Color(0xFFFFE0A3),
                    percentValue: personalProgress,
                    badgeText:
                        "คุณใช้จ่ายไป ${personalSpent.toStringAsFixed(0)} / ${personalBudget.toStringAsFixed(0)} THB",
                    subIcon: personalProgress >= 1.0
                        ? Icons.warning_amber_rounded
                        : Icons.error_outline,
                    subText:
                        "คิดเป็น ${(personalProgress * 100).toStringAsFixed(0)}% ของค่าใช้จ่ายส่วนตัว",
                  ),
                  const SizedBox(height: 12),

                  // 📌 3. หลอด Progress เงินออม
                  _buildBudgetItem(
                    dotColor: const Color(0xFF3B97FF),
                    title: "เงินออม ${savingsPct.toStringAsFixed(0)}%",
                    badgeBgColor: const Color(0xFFEBF4FF),
                    progressColor: const Color(0xFF3B97FF),
                    percentValue: savingsProgress,
                    badgeText:
                        "เป้าหมายเดือนนี้ ${savingsSpent.toStringAsFixed(0)} / ${savingsBudget.toStringAsFixed(0)} THB",
                    showAddButton: false,
                    subIcon: savingsProgress >= 1.0
                        ? Icons.check_circle_outline
                        : Icons.savings_outlined,
                    subText: savingsProgress >= 1.0
                        ? "ยินดีด้วยคุณสำเร็จ 100% ของเป้าหมายเดือนนี้แล้ว"
                        : "ออมไปแล้ว ${(savingsProgress * 100).toStringAsFixed(0)}% ของเป้าหมาย",
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetItem({
    required Color dotColor,
    required String title,
    required Color badgeBgColor,
    required Color progressColor,
    required double percentValue,
    required String badgeText,
    bool showAddButton = false,
    required IconData subIcon,
    required String subText,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3323),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: double.infinity,
            height: 46,
            color: badgeBgColor,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: percentValue.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: progressColor,
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: showAddButton ? 48 : 16,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      badgeText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF1E3323),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                if (showAddButton)
                  Positioned(
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(255, 237, 239, 237),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 18,
                        color: Color(0xFF1E3323),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(subIcon, size: 14, color: Colors.black54),
            const SizedBox(width: 4),
            Text(
              subText,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}