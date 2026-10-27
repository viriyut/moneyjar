import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firstapp/screen/home.dart';
import 'package:firstapp/screen/notification.dart';
import 'package:flutter/material.dart';
import 'transaction_model.dart';

class CategoryScreen extends StatefulWidget {
  final Function(TransactionModel)? onAddTransaction;

  /// เรียกตอนกดปุ่มย้อนกลับ (ตอนอยู่หน้าแรกของ Category)
  /// ใช้ตอนหน้านี้ถูกเปิดเป็นแท็บใน bottom nav เพื่อสลับกลับไปแท็บ "หน้าหลัก"
  /// ถ้าไม่ส่งมา (เช่นตอนเปิดจากปุ่ม + ในหน้าธุรกรรม) จะ fallback ไปใช้ Navigator.pop ตามปกติ
  final VoidCallback? onBack;

  const CategoryScreen({super.key, this.onAddTransaction, this.onBack});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  int _viewMode = 0; // 0 = หน้าเลือกประเภท, 1 = รายจ่าย, 2 = รายรับ, 3 = เงินออม
  int _expenseTab = 0; // 0 = จำเป็น, 1 = ส่วนตัว

  // 📌 รายการหมวดเป็น static เพื่อให้ทุกสำเนาของหน้านี้ (แท็บล่าง + หน้าที่เปิดจากปุ่ม +)
  // ใช้รายการชุดเดียวกัน หมวดที่เพิ่มจากที่ไหนก็เห็นทั้งสองที่
  // 📌 ชื่อหมวดหมู่ต้องมีคำสำคัญที่ตรงกับ kEssentialKeywords / kPersonalKeywords ใน home.dart
  // ไม่งั้นรายการจะไม่ถูกนับเข้างบของกลุ่มนั้น
  static final List<Map<String, dynamic>> _needsCategories = [
    {'name': 'ค่าอาหาร/เครื่องดื่ม', 'icon': Icons.restaurant_menu},
    {'name': 'ค่าผ่อนบ้าน/ค่าเช่า', 'icon': Icons.home_outlined},
    {'name': 'ค่าน้ำ-ไฟ-เน็ต', 'icon': Icons.receipt_long_outlined},
    {'name': 'ค่าผ่อนรถ', 'icon': Icons.directions_car_outlined},
    {'name': 'ค่าเดินทาง', 'icon': Icons.directions_bus},
    {'name': 'ค่าประกัน', 'icon': Icons.verified_user_outlined},
    {'name': 'ค่ารักษา/ยา', 'icon': Icons.medical_services_outlined},
    {'name': 'ค่าของใช้จำเป็น', 'icon': Icons.shopping_bag_outlined},
    {'name': 'ค่าบัตรเครดิต', 'icon': Icons.credit_card_outlined},
    {'name': 'เพิ่มเติม', 'icon': Icons.add},
  ];

  static final List<Map<String, dynamic>> _wantsCategories = [
    {'name': 'เครื่องดื่ม/ขนม', 'icon': Icons.local_cafe_outlined},
    {'name': 'ช้อปปิ้ง', 'icon': Icons.checkroom_outlined},
    {'name': 'ความบันเทิง', 'icon': Icons.confirmation_number_outlined},
    {'name': 'ท่องเที่ยว', 'icon': Icons.flight_takeoff_outlined},
    {'name': 'ทำบุญ', 'icon': Icons.volunteer_activism_outlined},
    {'name': 'สัตว์เลี้ยง', 'icon': Icons.pets},
    {'name': 'ของขวัญ', 'icon': Icons.card_giftcard},
    {'name': 'เพิ่มเติม', 'icon': Icons.add},
  ];

  static final List<Map<String, dynamic>> _incomeCategories = [
    {'name': 'เงินเดือน', 'icon': Icons.payments_outlined},
    {'name': 'พาร์ทไทม์/ฟรีแลนซ์', 'icon': Icons.work_outline},
    {'name': 'เงินปันผล', 'icon': Icons.trending_up},
    {'name': 'เงินรางวัล', 'icon': Icons.emoji_events_outlined},
    {'name': 'ของขวัญ', 'icon': Icons.card_giftcard},
    {'name': 'เพิ่มเติม', 'icon': Icons.add},
  ];

  // 📌 หมวดเงินออม (แยกเป็นประเภทของตัวเอง ไม่รวมในรายรับ/รายจ่าย)
  // ชื่อต้องมีคำใน kSavingsKeywords (เงินออม/ลงทุน/กองทุน/ออม) ระบบถึงจะนับเป็นเงินออม
  static final List<Map<String, dynamic>> _savingsCategories = [
    {'name': 'เงินออม', 'icon': Icons.savings_outlined},
    {'name': 'ลงทุน', 'icon': Icons.trending_up},
    {'name': 'กองทุน', 'icon': Icons.account_balance_outlined},
    {'name': 'เพิ่มเติม', 'icon': Icons.add},
  ];

  // ============================================================
  // 📌 เก็บหมวดที่ผู้ใช้เพิ่มเองไว้ใน Firestore (users/{uid}.customCategories)
  //    เก็บเฉพาะชื่อหมวด แยกตามกลุ่ม: needs / wants / income / savings
  //    โหลดครั้งเดียวต่อบัญชี (ทุกสำเนาของหน้านี้รอผลโหลดชุดเดียวกัน)
  // ============================================================
  static String? _loadedUid; // บัญชีที่โหลดหมวดไว้แล้ว (เปลี่ยนบัญชี -> โหลดใหม่)
  static Future<void>? _loadFuture;

  @override
  void initState() {
    super.initState();
    _ensureLoaded();
  }

  Future<void> _ensureLoaded() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (_loadedUid != uid) {
      _loadedUid = uid;
      _loadFuture = _loadCustomCategories(uid);
    }
    await _loadFuture;
    if (mounted) setState(() {});
  }

  static Future<void> _loadCustomCategories(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final raw = doc.data()?['customCategories'];
      final Map<String, dynamic> saved =
          raw is Map ? Map<String, dynamic>.from(raw) : {};

      // ล้างหมวดที่เพิ่มเองของบัญชีก่อนหน้า (ถ้ามี) แล้วใส่หมวดของบัญชีนี้แทน
      void fill(List<Map<String, dynamic>> list, String key) {
        list.removeWhere((c) => c['custom'] == true);
        final names = saved[key];
        if (names is! List) return;
        for (final n in names) {
          if (n is! String || n.isEmpty) continue;
          if (list.any((c) => c['name'] == n)) continue;
          list.insert(list.length - 1, {
            'name': n,
            'icon': Icons.category_outlined,
            'custom': true,
          });
        }
      }

      fill(_needsCategories, 'needs');
      fill(_wantsCategories, 'wants');
      fill(_incomeCategories, 'income');
      fill(_savingsCategories, 'savings');
    } catch (_) {
      // โหลดไม่สำเร็จ (เช่น ไม่มีเน็ต) ให้ลองโหลดใหม่ตอนเปิดหน้านี้ครั้งหน้า
      _loadedUid = null;
    }
  }

  // บันทึกหมวดที่เพิ่มเองทั้งหมดลง Firestore (เรียกทุกครั้งที่เพิ่ม/แก้ไข/ลบ)
  Future<void> _saveCustomCategories() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // ถ้ายังโหลดหมวดเดิมไม่เสร็จ ให้รอก่อน กันเขียนทับข้อมูลเดิมด้วยรายการที่ยังไม่ครบ
    if (_loadedUid == uid) {
      await _loadFuture;
    } else {
      await _ensureLoaded();
    }
    if (_loadedUid != uid) {
      _showSnack('บันทึกหมวดหมู่ไม่สำเร็จ กรุณาตรวจสอบอินเทอร์เน็ตแล้วลองใหม่');
      return;
    }

    List<String> namesOf(List<Map<String, dynamic>> list) => list
        .where((c) => c['custom'] == true)
        .map((c) => c['name'] as String)
        .toList();

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'customCategories': {
          'needs': namesOf(_needsCategories),
          'wants': namesOf(_wantsCategories),
          'income': namesOf(_incomeCategories),
          'savings': namesOf(_savingsCategories),
        },
      }, SetOptions(merge: true));
    } catch (_) {
      _showSnack('บันทึกหมวดหมู่ไม่สำเร็จ กรุณาลองใหม่อีกครั้ง');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // 📌 หมวดที่ตั้งเอง ต้องถูกนับเข้ากลุ่มที่เพิ่มหมวดไว้ (จำเป็น / ส่วนตัว / เงินออม)
  // ถ้าชื่อที่ตั้งไม่มีคำที่ระบบรู้จักว่าอยู่กลุ่มนั้น จะเติมป้ายท้ายชื่อให้อัตโนมัติ
  // เช่น "ค่าสมาชิกยิม" ในกลุ่มส่วนตัว -> "ค่าสมาชิกยิม (ส่วนตัว)"
  // หมวดรายรับไม่ต้องจัดกลุ่ม คืนชื่อเดิม
  String _normalizeName(List<Map<String, dynamic>> categoryList, String name) {
    final String group;
    final String tag;
    if (identical(categoryList, _needsCategories)) {
      group = 'essential';
      tag = kEssentialTag;
    } else if (identical(categoryList, _wantsCategories)) {
      group = 'personal';
      tag = kPersonalTag;
    } else if (identical(categoryList, _savingsCategories)) {
      group = 'savings';
      tag = kSavingsTag;
    } else {
      return name;
    }

    if (groupOfTitle(name) == group) return name;
    return '$name $tag';
  }

  // 📌 ป๊อปอัปเพิ่มหมวดหมู่ใหม่ (กดปุ่ม "เพิ่มเติม")
  //    หรือแก้ไข/ลบหมวดหมู่ที่เพิ่มเอง (กดค้างที่หมวดนั้น) เมื่อส่ง existing เข้ามา
  void _showCategoryDialog(
    List<Map<String, dynamic>> categoryList, {
    Map<String, dynamic>? existing,
  }) {
    final TextEditingController nameController = TextEditingController(
      text: (existing?['name'] as String?) ?? '',
    );
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        existing == null ? 'เพิ่มหมวดหมู่ใหม่' : 'แก้ไขหมวดหมู่',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3323),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'ชื่อหมวดหมู่',
                          errorText: errorText,
                          filled: true,
                          fillColor: const Color(0xFFE8F5E9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (_) {
                          if (errorText != null) {
                            setDialogState(() => errorText = null);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text(
                                'ยกเลิก',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFA2E0B2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () {
                                final raw = nameController.text.trim();
                                if (raw.isEmpty) {
                                  setDialogState(
                                    () => errorText = 'กรุณากรอกชื่อหมวดหมู่',
                                  );
                                  return;
                                }

                                final newName = _normalizeName(
                                  categoryList,
                                  raw,
                                );

                                // ห้ามชื่อซ้ำกับหมวดอื่นในหน้าเดียวกัน (และห้ามใช้ชื่อ "เพิ่มเติม")
                                final bool duplicated =
                                    newName == 'เพิ่มเติม' ||
                                    categoryList.any(
                                      (c) =>
                                          !identical(c, existing) &&
                                          c['name'] == newName,
                                    );
                                if (duplicated) {
                                  setDialogState(
                                    () => errorText = 'มีหมวดหมู่ชื่อนี้อยู่แล้ว',
                                  );
                                  return;
                                }

                                setState(() {
                                  if (existing != null) {
                                    existing['name'] = newName;
                                  } else {
                                    // แทรกรายการใหม่ก่อนไอคอน "เพิ่มเติม"
                                    categoryList.insert(
                                      categoryList.length - 1,
                                      {
                                        'name': newName,
                                        'icon': Icons.category_outlined,
                                        'custom': true,
                                      },
                                    );
                                  }
                                });
                                _saveCustomCategories();
                                Navigator.pop(ctx);
                              },
                              child: Text(
                                existing == null ? 'ตกลง' : 'บันทึก',
                                style: const TextStyle(
                                  color: Color(0xFF1E3323),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // ปุ่มลบ แสดงเฉพาะตอนแก้ไขหมวดที่เพิ่มเอง
                      if (existing != null)
                        TextButton.icon(
                          onPressed: () async {
                            final ok = await _confirmDeleteCategory(
                              existing['name'] as String,
                            );
                            if (ok != true) return;
                            setState(() => categoryList.remove(existing));
                            _saveCustomCategories();
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Color(0xFFEE4E4E),
                          ),
                          label: const Text(
                            'ลบหมวดหมู่นี้',
                            style: TextStyle(color: Color(0xFFEE4E4E)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 📌 หน้าต่างยืนยันก่อนลบหมวดหมู่ (คืน true ถ้ายืนยัน)
  Future<bool?> _confirmDeleteCategory(String name) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFFDE8E8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFEE4E4E),
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'ลบหมวดหมู่',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3323),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ต้องการลบหมวด "$name" ใช่ไหม?\nรายการที่เคยบันทึกไว้จะไม่ถูกลบ',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
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
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text(
                        'ยกเลิก',
                        style: TextStyle(
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
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        'ลบ',
                        style: TextStyle(
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
      ),
    );
  }

  void _showAddAmountDialog(
    BuildContext dialogContext, {
    required String title,
    required IconData icon,
    required Color cardColor,
    required bool isIncome,
  }) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController noteController = TextEditingController();
    showDialog(
      context: dialogContext,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: cardColor,
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'บันทึก $title',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3323),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      hintText: 'กรอกจำนวนเงิน (THB)',
                      filled: true,
                      fillColor: const Color(0xFFE8F5E9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // 📌 รายละเอียดเพิ่มเติม (ไม่บังคับ)
                  TextField(
                    controller: noteController,
                    maxLength: 60,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'รายละเอียด (ไม่บังคับ)',
                      filled: true,
                      fillColor: const Color(0xFFE8F5E9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            'ยกเลิก',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cardColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            final double? amount = double.tryParse(
                              amountController.text,
                            );
                            if (amount != null && amount > 0) {
                              final newTransaction = TransactionModel(
                                title: title,
                                amount: amount,
                                dateTime: DateTime.now(),
                                icon: icon,
                                iconBgColor: cardColor,
                                isIncome: isIncome,
                                note: noteController.text.trim(),
                              );

                              Navigator.of(ctx).pop();

                              if (widget.onAddTransaction != null) {
                                widget.onAddTransaction!(newTransaction);
                              } else {
                                Navigator.of(dialogContext).pop(newTransaction);
                              }
                            }
                          },
                          child: const Text(
                            'บันทึก',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA2E0B2),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_viewMode != 0) {
                        // ยังอยู่ในหน้าย่อย (เลือกหมวดรายรับ/รายจ่าย) ให้ถอยกลับมาหน้าแรกของ Category ก่อน
                        setState(() => _viewMode = 0);
                      } else if (widget.onBack != null) {
                        // ✅ เปิดมาจากแท็บ bottom nav -> สลับกลับไปแท็บ "หน้าหลัก" (ไม่ล้าง state ทิ้ง)
                        widget.onBack!();
                      } else if (Navigator.canPop(context)) {
                        // ✅ เปิดมาจากปุ่ม + ในหน้าธุรกรรม (push flow) -> แค่ pop กลับไปหน้าธุรกรรมตามปกติ
                        Navigator.pop(context);
                      } else {
                        // fallback สุดท้ายจริงๆ กรณีไม่มีทั้ง onBack และไม่มีอะไรให้ pop
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
                  const Expanded(
                    child: Text(
                      'หมวดหมู่',
                      textAlign: TextAlign.center,
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
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFFF3FAF4),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(35),
                    topRight: Radius.circular(35),
                  ),
                ),
                child: _buildBodyContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_viewMode == 0) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionButton(
                title: 'รายรับ',
                icon: Icons.north_east,
                backgroundColor: const Color(0xFF90CAF9),
                textColor: Colors.white,
                onTap: () => setState(() => _viewMode = 2),
              ),
              const SizedBox(height: 20),
              _buildActionButton(
                title: 'รายจ่าย',
                icon: Icons.south_east,
                backgroundColor: const Color(0xFFEE4335),
                textColor: Colors.white,
                onTap: () => setState(() => _viewMode = 1),
              ),
              const SizedBox(height: 20),
              _buildActionButton(
                title: 'เงินออม',
                icon: Icons.savings_outlined,
                backgroundColor: const Color(0xFF212121),
                textColor: Colors.white,
                onTap: () => setState(() => _viewMode = 3),
              ),
            ],
          ),
        ),
      );
    } else if (_viewMode == 3) {
      return Column(
        children: [
          Expanded(
            child: _buildGridMode(
              _savingsCategories,
              const Color(0xFF212121),
              isIncome: true,
            ),
          ),
        ],
      );
    } else if (_viewMode == 1) {
      return Column(
        children: [
          _buildExpenseSubTabs(),
          const SizedBox(height: 16),
          Expanded(
            child: _buildGridMode(
              _expenseTab == 0 ? _needsCategories : _wantsCategories,
              _expenseTab == 0
                  ? const Color(0xFFEF5350)
                  : const Color(0xFFFBC02D),
              isIncome: false,
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Expanded(
            child: _buildGridMode(
              _incomeCategories,
              const Color(0xFF90CAF9),
              isIncome: true,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 220,
        height: 120,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: textColor, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: textColor, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseSubTabs() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _expenseTab = 0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _expenseTab == 0
                    ? const Color(0xFFEF5350)
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  'ค่าใช้จ่ายจำเป็น',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _expenseTab == 0 ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _expenseTab = 1),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _expenseTab == 1
                    ? const Color(0xFFFBC02D)
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  'ค่าใช้จ่ายส่วนตัว',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _expenseTab == 1 ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridMode(
    List<Map<String, dynamic>> categories,
    Color cardColor, {
    required bool isIncome,
  }) {
    final bool hasCustom = categories.any((c) => c['custom'] == true);

    return Column(
      children: [
        // 📌 คำใบ้วิธีแก้ไข/ลบ แสดงเมื่อมีหมวดที่เพิ่มเองอยู่ในหน้านี้
        if (hasCustom)
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              'กดค้างที่หมวดที่มีไอคอนดินสอ เพื่อแก้ไขหรือลบ',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        Expanded(
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 20,
            ),
            itemBuilder: (context, index) {
              final item = categories[index];
              final bool isCustom = item['custom'] == true;
              return InkWell(
                onTap: () {
                  if (item['name'] == 'เพิ่มเติม') {
                    _showCategoryDialog(categories);
                  } else {
                    _showAddAmountDialog(
                      context,
                      title: item['name'],
                      icon: item['icon'],
                      cardColor: cardColor,
                      isIncome: isIncome,
                    );
                  }
                },
                // 📌 กดค้างเพื่อแก้ไข/ลบ (เฉพาะหมวดที่ผู้ใช้เพิ่มเอง)
                onLongPress: isCustom
                    ? () => _showCategoryDialog(categories, existing: item)
                    : null,
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 65,
                          height: 65,
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        if (isCustom)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFE0E0E0),
                                ),
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 12,
                                color: Color(0xFF1E3323),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['name'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}