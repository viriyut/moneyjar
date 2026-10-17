import 'package:flutter/material.dart';
import 'package:firstapp/screen/notification.dart';

class SearchScreen extends StatefulWidget {
  /// รายการธุรกรรมทั้งหมด ส่งมาจาก HomeScreen (เหมือนหน้าธุรกรรม/ภาพรวมการเงิน)
  final List<Map<String, dynamic>> transactions;

  /// เรียกตอนกดปุ่มย้อนกลับ (ถ้าไม่ส่งมา จะ fallback ไปใช้ Navigator.pop ตามปกติ)
  final VoidCallback? onBack;

  const SearchScreen({super.key, this.transactions = const [], this.onBack});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const List<String> _thaiMonthShort = [
    'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
  ];

  static const List<String> _thaiMonthFull = [
    'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
    'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
  ];

  bool? _selectedIsIncome; // null = ทั้งหมด, true = รายรับ, false = รายจ่าย
  DateTime? _selectedDate; // null = ทุกวัน

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // 📌 ผลลัพธ์คำนวณสดจากตัวกรองปัจจุบัน เปลี่ยนประเภท/วันที่แล้วอัปเดตทันที ไม่ต้องกดค้นหา
  List<Map<String, dynamic>> get _results {
    return widget.transactions.where((tx) {
      final matchesType =
          _selectedIsIncome == null || tx['isIncome'] == _selectedIsIncome;
      final DateTime? txDate = tx['dateTime'] as DateTime?;
      final matchesDate = _selectedDate == null ||
          (txDate != null && _isSameDay(txDate, _selectedDate!));
      return matchesType && matchesDate;
    }).toList();
  }

  Future<void> _pickDate() async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => _ThaiDatePickerDialog(
        initialMonth: _selectedDate ?? DateTime.now(),
        selected: _selectedDate,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String _formatDateField(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')} /${_thaiMonthShort[d.month - 1]}/${d.year}';
  }

  String _formatResultDateTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute - ${dt.day} ${_thaiMonthFull[dt.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return Scaffold(
      backgroundColor: const Color(0xFFA2E0B2),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ---------- Header ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Center(
                      child: Text(
                        'ค้นหา',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3323),
                          height: 1.2,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      child: GestureDetector(
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
                    ),
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
            ),
            const SizedBox(height: 14),

            // ---------- การ์ดขาวด้านล่าง ----------
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 📌 ประเภท
                      const Text(
                        'ประเภท',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E3323),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF7EE),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            _buildTypePill(
                              label: 'ทั้งหมด',
                              selected: _selectedIsIncome == null,
                              onTap: () =>
                                  setState(() => _selectedIsIncome = null),
                            ),
                            _buildTypePill(
                              label: 'รายรับ',
                              selected: _selectedIsIncome == true,
                              onTap: () =>
                                  setState(() => _selectedIsIncome = true),
                            ),
                            _buildTypePill(
                              label: 'รายจ่าย',
                              selected: _selectedIsIncome == false,
                              onTap: () =>
                                  setState(() => _selectedIsIncome = false),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 📌 วันที่
                      const Text(
                        'วันที่',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E3323),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF7EE),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedDate == null
                                      ? 'ทุกวัน'
                                      : _formatDateField(_selectedDate!),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _selectedDate == null
                                        ? Colors.grey
                                        : const Color(0xFF1E3323),
                                  ),
                                ),
                              ),
                              if (_selectedDate != null) ...[
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedDate = null),
                                  child: const Icon(
                                    Icons.close,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
                              Container(
                                width: 26,
                                height: 26,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF73D193),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.calendar_today,
                                  size: 13,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 📌 ผลลัพธ์ (อัปเดตทันทีตามประเภท/วันที่ที่เลือก)
                      Text(
                        'รายการ (${results.length})',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3323),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (results.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'ไม่พบรายการที่ตรงกับเงื่อนไข',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ),
                        )
                      else
                        ...results.map(_buildResultTile),
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

  // ---------- ปุ่ม pill เลือกประเภท (ทั้งหมด/รายรับ/รายจ่าย) ----------
  Widget _buildTypePill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF73D193) : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : const Color(0xFF1E3323),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- แถวผลลัพธ์ 1 รายการ (สไตล์เดียวกับหน้าธุรกรรม) ----------
  Widget _buildResultTile(Map<String, dynamic> item) {
    final double amount = (item['amount'] as num).toDouble();
    final bool isIncome = item['isIncome'] == true;
    final DateTime dt = item['dateTime'] as DateTime? ?? DateTime.now();

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
                  _formatResultDateTime(dt),
                  style: const TextStyle(fontSize: 12, color: Colors.blueAccent),
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
// 📌 ปฏิทินเลือกวันภาษาไทย (ไม่ต้องตั้งค่า localization เพิ่มในโปรเจกต์)
// ============================================================
class _ThaiDatePickerDialog extends StatefulWidget {
  final DateTime initialMonth;
  final DateTime? selected;

  const _ThaiDatePickerDialog({required this.initialMonth, this.selected});

  @override
  State<_ThaiDatePickerDialog> createState() => _ThaiDatePickerDialogState();
}

class _ThaiDatePickerDialogState extends State<_ThaiDatePickerDialog> {
  static const List<String> _monthsFull = [
    'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
    'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
  ];
  static const List<String> _weekDays = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'];

  late DateTime _month; // วันที่ 1 ของเดือนที่กำลังดู

  @override
  void initState() {
    super.initState();
    _month = DateTime(widget.initialMonth.year, widget.initialMonth.month, 1);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta, 1);
    });
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final int daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final int leadingBlanks = _month.weekday - 1; // จันทร์ = 1
    final DateTime today = DateTime.now();

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // เดือน / ปี + ลูกศรเลื่อนเดือน
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Color(0xFF1E3323)),
                  onPressed: () => _shiftMonth(-1),
                ),
                Expanded(
                  child: Text(
                    '${_monthsFull[_month.month - 1]} ${_month.year}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3323),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Color(0xFF1E3323)),
                  onPressed: () => _shiftMonth(1),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // หัวตารางวัน
            Row(
              children: _weekDays
                  .map(
                    (d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),

            // ตารางวันที่
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: leadingBlanks + daysInMonth,
              itemBuilder: (context, index) {
                if (index < leadingBlanks) return const SizedBox.shrink();

                final int day = index - leadingBlanks + 1;
                final DateTime date = DateTime(_month.year, _month.month, day);
                final bool isSelected =
                    widget.selected != null && _isSameDay(date, widget.selected!);
                final bool isToday = _isSameDay(date, today);

                return GestureDetector(
                  onTap: () => Navigator.pop(context, date),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF73D193)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isToday && !isSelected
                          ? Border.all(color: const Color(0xFF73D193), width: 1.5)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected || isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF1E3323),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'ยกเลิก',
                  style: TextStyle(
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
  }
}