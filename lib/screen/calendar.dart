import 'package:flutter/material.dart';
import 'package:firstapp/screen/notification.dart';

class CalendarPage extends StatefulWidget {
  final List<Map<String, dynamic>> transactions;

  /// เรียกตอนกดปุ่มย้อนกลับ (ถ้าไม่ส่งมา จะ fallback ไปใช้ Navigator.pop ตามปกติ)
  final VoidCallback? onBack;

  const CalendarPage({
    Key? key,
    this.transactions = const [],
    this.onBack,
  }) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  // เก็บเป็นวันที่ 1 ของเดือนที่กำลังดูอยู่
  late DateTime _currentDate;
  Set<int> _selectedDays = {};

  static const List<String> _thaiMonthsShort = [
    'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
  ];

  static const List<String> _thaiMonthsFull = [
    'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
    'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentDate = DateTime(now.year, now.month, 1);
    _selectedDays = _defaultSelection(now.year, now.month);
  }

  // เดือนปัจจุบัน -> เลือกวันนี้, เดือนอื่น -> เลือกทั้งเดือน
  Set<int> _defaultSelection(int year, int month) {
    final now = DateTime.now();
    if (year == now.year && month == now.month) return {now.day};
    final days = DateTime(year, month + 1, 0).day;
    return Set.from(List.generate(days, (i) => i + 1));
  }

  void _changeMonthYear(int year, int month) {
    setState(() {
      _currentDate = DateTime(year, month, 1);
      _selectedDays = _defaultSelection(year, month);
    });
  }

  // จำนวนวันในเดือนที่กำลังดู
  int get _daysInMonth =>
      DateTime(_currentDate.year, _currentDate.month + 1, 0).day;

  // กรองรายการธุรกรรมจริงตามวันที่เลือก
  List<Map<String, dynamic>> get _filteredTransactions {
    return widget.transactions.where((item) {
      final dt = item['dateTime'] as DateTime?;
      if (dt == null) return false;
      return _selectedDays.contains(dt.day) &&
          dt.month == _currentDate.month &&
          dt.year == _currentDate.year;
    }).toList();
  }

  // ปุ่มสลับเลือกทั้งเดือน / ยกเลิกทั้งหมด
  void _toggleSelectAllDays() {
    final totalDays = _daysInMonth;
    setState(() {
      if (_selectedDays.length == totalDays) {
        _selectedDays = {};
      } else {
        _selectedDays = Set.from(List.generate(totalDays, (i) => i + 1));
      }
    });
  }

  String _formatDateTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute - ${dt.day} ${_thaiMonthsFull[dt.month - 1]}';
  }

  // ป๊อปอัปเลือกเดือน/ปี
  void _showOptionSheet({
    required String title,
    required List<String> labels,
    required int selectedIndex,
    required ValueChanged<int> onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3323),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: List.generate(labels.length, (i) {
                  final selected = i == selectedIndex;
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      onSelect(i);
                    },
                    child: Container(
                      width: 76,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF73D193)
                            : const Color(0xFFEAF7EE),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color:
                              selected ? Colors.white : const Color(0xFF1E3323),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  void _pickMonth() {
    _showOptionSheet(
      title: 'เลือกเดือน',
      labels: _thaiMonthsShort,
      selectedIndex: _currentDate.month - 1,
      onSelect: (i) => _changeMonthYear(_currentDate.year, i + 1),
    );
  }

  void _pickYear() {
    final nowYear = DateTime.now().year;
    final years = List.generate(7, (i) => nowYear - 5 + i);
    _showOptionSheet(
      title: 'เลือกปี',
      labels: years.map((y) => '$y').toList(),
      selectedIndex: years.indexOf(_currentDate.year),
      onSelect: (i) => _changeMonthYear(years[i], _currentDate.month),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredTransactions;
    final totalDays = _daysInMonth;

    return Scaffold(
      backgroundColor: const Color(0xFFA2E0B2),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ---------- Header (มาตรฐานเดียวกับหน้าอื่น) ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Center(
                      child: Text(
                        'ปฏิทิน',
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
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // แถบเลือกเดือน / ปี
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: _pickMonth,
                            child: Row(
                              children: [
                                Text(
                                  _thaiMonthsShort[_currentDate.month - 1],
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF73D193),
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Color(0xFF73D193),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: _toggleSelectAllDays,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Text(
                                _selectedDays.length == totalDays
                                    ? 'ยกเลิกทั้งหมด'
                                    : 'เลือกทั้งเดือน',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3323),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _pickYear,
                            child: Row(
                              children: [
                                Text(
                                  '${_currentDate.year}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF73D193),
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Color(0xFF73D193),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ตารางปฏิทิน
                      _buildCalendarGrid(totalDays),
                      const SizedBox(height: 20),

                      // แถบบอกจำนวนวัน
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA2E0B2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'รายการ (${_selectedDays.length} วัน)',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3323),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // รายการธุรกรรม
                      if (filteredItems.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'ไม่มีรายการในวันที่เลือก',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        )
                      else
                        ...filteredItems.map(_buildTransactionItem),
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

  // ---------- ตารางปฏิทิน ----------
  Widget _buildCalendarGrid(int totalDays) {
    const daysOfWeek = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'];

    // วันที่ 1 ของเดือนตรงกับวันอะไร (จันทร์ = 1) -> เว้นช่องว่างนำหน้าให้ตรงวันจริง
    final int leadingBlanks =
        DateTime(_currentDate.year, _currentDate.month, 1).weekday - 1;

    return Column(
      children: [
        Row(
          children: daysOfWeek
              .map(
                (day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
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
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: leadingBlanks + totalDays,
          itemBuilder: (context, index) {
            if (index < leadingBlanks) return const SizedBox.shrink();

            final int dayNumber = index - leadingBlanks + 1;
            final bool isSelected = _selectedDays.contains(dayNumber);

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedDays.remove(dayNumber);
                  } else {
                    _selectedDays.add(dayNumber);
                  }
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFC7ECCB)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$dayNumber',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: const Color(0xFF1E3323),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ---------- แถวรายการธุรกรรม (สไตล์เดียวกับหน้าธุรกรรม) ----------
  Widget _buildTransactionItem(Map<String, dynamic> item) {
    final bool isIncome = item['isIncome'] == true;
    final double amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
    final DateTime dt = item['dateTime'] as DateTime? ?? DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: (item['iconBgColor'] as Color?) ?? Colors.grey,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              (item['icon'] as IconData?) ?? Icons.category,
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
                  (item['title'] as String?) ?? 'ไม่มีชื่อรายการ',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3323),
                  ),
                ),
                if ((item['note'] as String?)?.isNotEmpty ?? false)
                  Text(
                    item['note'] as String,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  _formatDateTime(dt),
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
              color:
                  isIncome ? const Color(0xFF2E7D32) : const Color(0xFFEF5350),
            ),
          ),
        ],
      ),
    );
  }
}