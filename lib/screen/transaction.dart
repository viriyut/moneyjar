import 'package:flutter/material.dart';
import 'package:firstapp/screen/transaction_model.dart';
import 'package:firstapp/screen/home.dart'
    show kEssentialKeywords, kPersonalKeywords, kSavingsKeywords;
import 'package:firstapp/screen/notification.dart';
import 'category.dart';

class TransactionScreen extends StatefulWidget {
  final List<Map<String, dynamic>> transactions;
  final Function(TransactionModel) onAddTransaction;
  /// ลบรายการ (ส่งตัวรายการที่ต้องการลบเข้ามา)
  final Function(Map<String, dynamic> item)? onDeleteTransaction;

  /// แก้ไขจำนวนเงินของรายการ
  final Function(Map<String, dynamic> item, double newAmount)?
      onEditTransaction;

  /// เรียกตอนกดปุ่มย้อนกลับ ใช้สำหรับสลับกลับไปแท็บ "หน้าหลัก"
  /// (ถ้าไม่ส่งมา จะ fallback ไปใช้ Navigator.pop ตามปกติ)
  final VoidCallback? onBack;

  const TransactionScreen({
    super.key,
    required this.transactions,
    required this.onAddTransaction,
    this.onDeleteTransaction,
    this.onEditTransaction,
    this.onBack,
  });

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  // 📌 คำนวณรายรับจาก widget.transactions
  double get totalIncome => widget.transactions
      .where((t) => t['isIncome'] == true)
      .fold(0.0, (sum, item) => sum + ((item['amount'] as num).toDouble()));

  // 📌 คำนวณรายจ่ายจาก widget.transactions
  double get totalExpense => widget.transactions
      .where((t) => t['isIncome'] == false)
      .fold(0.0, (sum, item) => sum + ((item['amount'] as num).toDouble()));

  // 📌 จำนวนครั้งที่จ่ายเงินทั้งหมด
  int get expenseCount =>
      widget.transactions.where((t) => t['isIncome'] == false).length;

  // 📌 สรุปรายจ่ายแยกเป็นกลุ่มใหญ่: จำเป็น / ส่วนตัว / เงินออม / อื่นๆ
  //    ใช้ keyword ชุดเดียวกับหน้าหลัก (kEssentialKeywords ฯลฯ) เพื่อให้ผลตรงกันทั้งแอป
  //    คืนค่าเป็น list เรียงจากกลุ่มที่จ่ายเยอะสุดไปน้อยสุด (ซ่อนกลุ่มที่ไม่มีรายการ)
  List<Map<String, dynamic>> get expenseByGroup {
    final Map<String, Map<String, dynamic>> groups = {
      'จำเป็น': {
        'label': 'ค่าใช้จ่ายจำเป็น',
        'count': 0,
        'total': 0.0,
        'color': const Color(0xFFEE4E4E),
        'icon': Icons.shopping_basket_outlined,
      },
      'ส่วนตัว': {
        'label': 'ค่าใช้จ่ายส่วนตัว',
        'count': 0,
        'total': 0.0,
        'color': const Color(0xFFF5BD55),
        'icon': Icons.sentiment_satisfied_alt_outlined,
      },
      'เงินออม': {
        'label': 'เงินออม',
        'count': 0,
        'total': 0.0,
        'color': const Color(0xFF3B97FF),
        'icon': Icons.savings_outlined,
      },
      'อื่นๆ': {
        'label': 'อื่นๆ',
        'count': 0,
        'total': 0.0,
        'color': const Color(0xFF9AA5B1),
        'icon': Icons.category_outlined,
      },
    };

    for (final tx in widget.transactions) {
      if (tx['isIncome'] == true) continue;
      final String title = tx['title'] as String? ?? '';
      final double amount = (tx['amount'] as num).toDouble();

      final String key;
      if (kEssentialKeywords.any((kw) => title.contains(kw))) {
        key = 'จำเป็น';
      } else if (kPersonalKeywords.any((kw) => title.contains(kw))) {
        key = 'ส่วนตัว';
      } else if (kSavingsKeywords.any((kw) => title.contains(kw))) {
        key = 'เงินออม';
      } else {
        key = 'อื่นๆ';
      }

      groups[key]!['count'] = (groups[key]!['count'] as int) + 1;
      groups[key]!['total'] = (groups[key]!['total'] as double) + amount;
    }

    final result = groups.entries
        .map((e) => {'title': e.key, ...e.value})
        .where((g) => (g['count'] as int) > 0)
        .toList();
    result.sort(
      (a, b) => (b['total'] as double).compareTo(a['total'] as double),
    );
    return result;
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'มกราคม',
      'กุมภาพันธ์',
      'มีนาคม',
      'เมษายน',
      'พฤษภาคม',
      'มิถุนายน',
      'กรกฎาคม',
      'สิงหาคม',
      'กันยายน',
      'ตุลาคม',
      'พฤศจิกายน',
      'ธันวาคม',
    ];
    String hour = dt.hour.toString().padLeft(2, '0');
    String minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute - ${dt.day} ${months[dt.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA2E0B2),
      body: Stack(
        children: [
          Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Column(
                    children: [
                      // 📌 Header ด้านบน
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (widget.onBack != null) {
                                widget.onBack!();
                              } else if (Navigator.canPop(context)) {
                                Navigator.pop(context);
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
                              'ธุรกรรม',
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
                      const SizedBox(height: 12),
                      
                      // 📌 สรุปยอดคงเหลือ
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'ยอดคงเหลือ',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(totalIncome - totalExpense).toStringAsFixed(2)} THB',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3323),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // 📌 สรุปรายรับ-รายจ่าย
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              'รายรับ',
                              '+${totalIncome.toStringAsFixed(2)} THB',
                              Icons.north_east,
                              const Color(0xFFA2E0B2),
                              const Color(0xFF1E3323),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              'รายจ่าย',
                              '-${totalExpense.toStringAsFixed(2)} THB',
                              Icons.south_east,
                              const Color(0xFFFFCDD2),
                              const Color(0xFFE57373),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              
              // 📌 รายการธุรกรรม
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3FAF4),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(35),
                      topRight: Radius.circular(35),
                    ),
                  ),
                  child: widget.transactions.isEmpty
                      ? const Center(
                          child: Text(
                            'ยังไม่มีรายการ กด + ด้านล่างเพื่อเพิ่ม',
                            style: TextStyle(color: Colors.grey, fontSize: 15),
                          ),
                        )
                      : ListView(
                          physics: const BouncingScrollPhysics(),
                          children: [
                            // 📌 การ์ดสรุปรายจ่าย (จ่ายไปกี่ครั้ง / จ่ายอะไรบ้าง)
                            if (expenseCount > 0) _buildExpenseSummaryCard(),

                            // 📌 หัวข้อรายการทั้งหมด
                            const Padding(
                              padding: EdgeInsets.only(top: 4, bottom: 2),
                              child: Text(
                                'รายการทั้งหมด',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3323),
                                ),
                              ),
                            ),
                            if (widget.onEditTransaction != null ||
                                widget.onDeleteTransaction != null)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 4),
                                child: Text(
                                  'แตะที่รายการเพื่อแก้ไข · ปัดซ้ายเพื่อลบ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),

                            // 📌 รายการธุรกรรมทีละรายการ
                            ...List.generate(widget.transactions.length, (
                              index,
                            ) {
                              final item = widget.transactions[index];
                              final Widget tile = GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: widget.onEditTransaction == null
                                    ? null
                                    : () => _showEditDialog(item),
                                child: _buildTransactionTile(item),
                              );
                              if (widget.onDeleteTransaction != null) {
                                return Dismissible(
                                  key: ObjectKey(item),
                                  direction: DismissDirection.endToStart,
                                  confirmDismiss: (_) => _confirmDelete(item),
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                  onDismissed: (direction) {
                                    widget.onDeleteTransaction!(item);
                                  },
                                  child: tile,
                                );
                              }
                              return tile;
                            }),
                          ],
                        ),
                ),
              ),
            ],
          ),

          // 📌 ปุ่ม FloatingActionButton (+)
          Positioned(
            bottom: 16,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: const Color(0xFF1E3323),
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () async {
                final result = await Navigator.push<TransactionModel>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CategoryScreen(),
                  ),
                );

                if (result != null) {
                  widget.onAddTransaction(result);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String amount,
    IconData icon,
    Color iconBg,
    Color amountColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: amountColor),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    amount,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: amountColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- การ์ดสรุปรายจ่าย: จ่ายไปกี่ครั้ง / แยกกลุ่มจำเป็น-ส่วนตัว ----------
  Widget _buildExpenseSummaryCard() {
    final groups = expenseByGroup;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // หัวข้อ + จำนวนครั้งรวม
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFFDE8E8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: Color(0xFFEE4E4E),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'สรุปรายจ่าย',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3323),
                      ),
                    ),
                    Text(
                      'คุณใช้จ่ายไปแล้ว $expenseCount รายการ',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFEFEFEF)),
          const SizedBox(height: 10),

          // รายการแยกตามกลุ่ม: จำเป็น / ส่วนตัว / เงินออม / อื่นๆ
          ...groups.map((g) {
            final double total = g['total'] as double;
            final int count = g['count'] as int;
            final Color color = g['color'] as Color;
            final double maxTotal = groups.first['total'] as double;
            final double ratio = maxTotal > 0 ? (total / maxTotal) : 0.0;
            final double avgPerItem = count > 0 ? (total / count) : 0.0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      g['icon'] as IconData,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                g['label'] as String,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E3323),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3FAF4),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$count รายการ',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E3323),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '-${total.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        // 📌 ค่าเฉลี่ยต่อรายการของกลุ่มนี้ เช่น "เฉลี่ยรายการละ 85.50 THB"
                        Text(
                          'เฉลี่ยรายการละ ${avgPerItem.toStringAsFixed(2)} THB',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 5),
                        // หลอดเปรียบเทียบสัดส่วนการใช้จ่ายของแต่ละกลุ่ม
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 5,
                            backgroundColor: const Color(0xFFF0F0F0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              color.withOpacity(0.55),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 📌 หน้าต่างยืนยันก่อนลบ (คืน true ถ้ายืนยัน)
  Future<bool> _confirmDelete(Map<String, dynamic> item) async {
    final title = item['title'] as String? ?? 'รายการนี้';
    final result = await showDialog<bool>(
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
                'ลบรายการ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3323),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ต้องการลบ "$title" ใช่ไหม?\nลบแล้วกู้คืนไม่ได้',
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
    return result ?? false;
  }

  // 📌 หน้าต่างแก้ไขจำนวนเงิน (มีปุ่มลบรายการด้วย)
  Future<void> _showEditDialog(Map<String, dynamic> item) async {
    final result = await showDialog<_EditResult>(
      context: context,
      builder: (_) => _EditAmountDialog(
        title: item['title'] as String? ?? 'รายการ',
        initialAmount: (item['amount'] as num).toDouble(),
        canDelete: widget.onDeleteTransaction != null,
      ),
    );
    if (result == null || !mounted) return;

    if (result.delete) {
      if (await _confirmDelete(item)) {
        widget.onDeleteTransaction?.call(item);
      }
    } else if (result.amount != null) {
      widget.onEditTransaction?.call(item, result.amount!);
    }
  }

  Widget _buildTransactionTile(Map<String, dynamic> item) {
    final double amount = (item['amount'] as num).toDouble();
    final bool isIncome = item['isIncome'] == true;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: item['iconBgColor'] as Color? ?? Colors.grey,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              item['icon'] as IconData? ?? Icons.category,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] as String? ?? 'ไม่มีชื่อรายการ',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3323),
                  ),
                ),
                Text(
                  _formatDateTime(item['dateTime'] as DateTime? ?? DateTime.now()),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${amount.toStringAsFixed(2)} THB',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isIncome ? const Color(0xFF2E7D32) : const Color(0xFFEF5350),
            ),
          ),
        ],
      ),
    );
  }
}


// ============================================================
// 📌 หน้าต่างแก้ไขจำนวนเงินของรายการ
// ============================================================
class _EditResult {
  final bool delete;
  final double? amount;
  const _EditResult.save(this.amount) : delete = false;
  const _EditResult.delete()
      : delete = true,
        amount = null;
}

class _EditAmountDialog extends StatefulWidget {
  final String title;
  final double initialAmount;
  final bool canDelete;

  const _EditAmountDialog({
    required this.title,
    required this.initialAmount,
    required this.canDelete,
  });

  @override
  State<_EditAmountDialog> createState() => _EditAmountDialogState();
}

class _EditAmountDialogState extends State<_EditAmountDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    final a = widget.initialAmount;
    _controller = TextEditingController(
      text: a == a.roundToDouble() ? a.toStringAsFixed(0) : a.toString(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = double.tryParse(_controller.text.trim());
    if (value == null || value <= 0) {
      setState(() => _error = 'กรุณากรอกจำนวนเงินที่มากกว่า 0');
      return;
    }
    Navigator.pop(context, _EditResult.save(value));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'แก้ไข ${widget.title}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3323),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  hintText: 'จำนวนเงิน (THB)',
                  errorText: _error,
                  filled: true,
                  fillColor: const Color(0xFFE8F5E9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
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
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _save,
                      child: const Text(
                        'บันทึก',
                        style: TextStyle(
                          color: Color(0xFF1E3323),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.canDelete)
                TextButton.icon(
                  onPressed: () =>
                      Navigator.pop(context, const _EditResult.delete()),
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Color(0xFFEE4E4E),
                  ),
                  label: const Text(
                    'ลบรายการนี้',
                    style: TextStyle(color: Color(0xFFEE4E4E)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}