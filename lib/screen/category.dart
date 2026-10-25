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
  int _viewMode = 0; // 0 = หน้าเลือกประเภท, 1 = รายจ่าย, 2 = รายรับ
  int _expenseTab = 0; // 0 = จำเป็น, 1 = ส่วนตัว

  // 📌 ชื่อหมวดหมู่ต้องมีคำสำคัญที่ตรงกับ kEssentialKeywords / kPersonalKeywords ใน home.dart
  // ไม่งั้นรายการจะไม่ถูกนับเข้างบของกลุ่มนั้น
  final List<Map<String, dynamic>> _needsCategories = [
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

  final List<Map<String, dynamic>> _wantsCategories = [
    {'name': 'เครื่องดื่ม/ขนม', 'icon': Icons.local_cafe_outlined},
    {'name': 'ช้อปปิ้ง', 'icon': Icons.checkroom_outlined},
    {'name': 'ความบันเทิง', 'icon': Icons.confirmation_number_outlined},
    {'name': 'ท่องเที่ยว', 'icon': Icons.flight_takeoff_outlined},
    {'name': 'ทำบุญ', 'icon': Icons.volunteer_activism_outlined},
    {'name': 'สัตว์เลี้ยง', 'icon': Icons.pets},
    {'name': 'ของขวัญ', 'icon': Icons.card_giftcard},
    {'name': 'เพิ่มเติม', 'icon': Icons.add},
  ];

  final List<Map<String, dynamic>> _incomeCategories = [
    {'name': 'เงินเดือน', 'icon': Icons.payments_outlined},
    {'name': 'พาร์ทไทม์/ฟรีแลนซ์', 'icon': Icons.work_outline},
    {'name': 'เงินปันผล', 'icon': Icons.trending_up},
    {'name': 'เงินรางวัล', 'icon': Icons.emoji_events_outlined},
    {'name': 'ของขวัญ', 'icon': Icons.card_giftcard},
    {'name': 'เพิ่มเติม', 'icon': Icons.add},
  ];

  // 📌 หมวดเงินออม (แยกเป็นประเภทของตัวเอง ไม่รวมในรายรับ/รายจ่าย)
  // ชื่อต้องมีคำใน kSavingsKeywords (เงินออม/ลงทุน/กองทุน/ออม) ระบบถึงจะนับเป็นเงินออม
  final List<Map<String, dynamic>> _savingsCategories = [
    {'name': 'เงินออม', 'icon': Icons.savings_outlined},
    {'name': 'ลงทุน', 'icon': Icons.trending_up},
    {'name': 'กองทุน', 'icon': Icons.account_balance_outlined},
    {'name': 'เพิ่มเติม', 'icon': Icons.add},
  ];

  // 📌 ป๊อปอัปเพิ่มหมวดหมู่ใหม่เมื่อกดปุ่ม "เพิ่มเติม"
  void _showAddNewCategoryDialog(List<Map<String, dynamic>> categoryList) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'เพิ่มหมวดหมู่ใหม่',
                  style: TextStyle(
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
                    filled: true,
                    fillColor: const Color(0xFFE8F5E9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
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
                          if (nameController.text.trim().isNotEmpty) {
                            setState(() {
                              // แทรกรายการใหม่ก่อนไอคอน "เพิ่มเติม"
                              var newName = nameController.text.trim();
                              // หมวดเงินออมที่ตั้งเอง ต้องมีคำว่า "ออม" ไม่งั้นระบบจะไม่นับเป็นเงินออม
                              if (identical(categoryList, _savingsCategories) &&
                                  !kSavingsKeywords.any(
                                    (kw) => newName.contains(kw),
                                  )) {
                                newName = '$newName (ออม)';
                              }
                              categoryList.insert(categoryList.length - 1, {
                                'name': newName,
                                'icon': Icons.category_outlined,
                              });
                            });
                            Navigator.pop(ctx);
                          }
                        },
                        child: const Text(
                          'ตกลง',
                          style: TextStyle(color: Color(0xFF1E3323)),
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
                      hintText: 'รายละเอียด (ไม่บังคับ) เช่น ข้าวเหนียวหมูปิ้ง',
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
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
      ),
      itemBuilder: (context, index) {
        final item = categories[index];
        return InkWell(
          onTap: () {
            if (item['name'] == 'เพิ่มเติม') {
              _showAddNewCategoryDialog(categories);
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
          child: Column(
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
    );
  }
}