import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firstapp/screen/calendar.dart';
import 'package:firstapp/screen/home.dart' show kSavingsKeywords;
import 'package:firstapp/screen/searching.dart';
import 'package:firstapp/screen/notification.dart';

class FinancialOverviewPage extends StatefulWidget {
  /// รายการธุรกรรมทั้งหมด ส่งมาจาก HomeScreen
  /// แต่ละ item ต้องมี key: 'amount' (double), 'isIncome' (bool), 'dateTime' (DateTime)
  final List<Map<String, dynamic>> transactions;

  /// เรียกตอนกดปุ่มย้อนกลับ ใช้สำหรับสลับกลับไปแท็บ "หน้าหลัก"
  /// (ถ้าไม่ส่งมา จะ fallback ไปใช้ Navigator.pop ตามปกติ)
  final VoidCallback? onBack;

  const FinancialOverviewPage({
    Key? key,
    this.transactions = const [],
    this.onBack,
  }) : super(key: key);

  @override
  State<FinancialOverviewPage> createState() => _FinancialOverviewPageState();
}

class _FinancialOverviewPageState extends State<FinancialOverviewPage> {
  // 0: รายวัน, 1: รายเดือน, 2: รายปี, 3: ทั้งหมด
  int _selectedPeriodIndex = 1;

  // 📌 ใช้เฉพาะตอนแท็บ "รายปี": เลื่อนดูทีละกลุ่ม 4 เดือน (ม.ค.-เม.ย. / พ.ค.-ส.ค. / ก.ย.-ธ.ค.)
  late final PageController _quarterPageController;
  int _yearQuarterIndex = (DateTime.now().month - 1) ~/ 4;

  @override
  void initState() {
    super.initState();
    _quarterPageController = PageController(initialPage: _yearQuarterIndex);
  }

  @override
  void dispose() {
    _quarterPageController.dispose();
    super.dispose();
  }

  final List<String> _periods = ["รายวัน", "รายเดือน", "รายปี", "ทั้งหมด"];

  static const List<String> _thaiMonthShort = [
    "ม.ค.", "ก.พ.", "มี.ค.", "เม.ย.", "พ.ค.", "มิ.ย.",
    "ก.ค.", "ส.ค.", "ก.ย.", "ต.ค.", "พ.ย.", "ธ.ค.",
  ];

  static const List<String> _thaiWeekdayShort = [
    "จ.", "อ.", "พ.", "พฤ.", "ศ.", "ส.", "อา.",
  ];

  // ---------------- ยอดคงเหลือ (จากธุรกรรมทั้งหมด) ----------------
  double get _totalBalance {
    double total = 0.0;
    for (final tx in widget.transactions) {
      if (_isSavingTx(tx)) continue; // เงินออมไม่นับรวมในยอดคงเหลือ
      final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
      if (tx['isIncome'] == true) {
        total += amount;
      } else {
        total -= amount;
      }
    }
    return total;
  }

  // 📌 รายการเงินออม (หมวด เงินออม/ลงทุน/กองทุน) แยกออกจากรายรับ ไม่รวมเป็นรายรับในกราฟ
  bool _isSavingTx(Map<String, dynamic> tx) {
    final title = tx['title'] as String? ?? '';
    return kSavingsKeywords.any((kw) => title.contains(kw));
  }

  DateTime? _dateOf(Map<String, dynamic> tx) {
    final d = tx['dateTime'];
    if (d is DateTime) return d;
    return null;
  }

  /// รวมข้อมูลกราฟ ({x: index, income, expense}) ตามช่วงที่เลือก
  _PeriodResult _buildPeriodResult() {
    final now = DateTime.now();
    switch (_selectedPeriodIndex) {
      case 0: // รายวัน: 7 วันล่าสุด (จ.-อา. ของสัปดาห์นี้)
        return _buildDaily(now);
      case 1: // รายเดือน: แบ่งเป็นสัปดาห์ที่ 1-5 ของเดือนนี้
        return _buildMonthly(now);
      case 2: // รายปี: แบ่งเป็นเดือน ม.ค.-ธ.ค. ของปีนี้
        return _buildYearly(now);
      case 3: // ทั้งหมด: แบ่งเป็นปี
      default:
        return _buildAllTime();
    }
  }

  _PeriodResult _buildDaily(DateTime now) {
    // หาวันจันทร์ของสัปดาห์นี้
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final days = List.generate(
      7,
      (i) => DateTime(monday.year, monday.month, monday.day + i),
    );

    final incomeByDay = List<double>.filled(7, 0.0);
    final expenseByDay = List<double>.filled(7, 0.0);
    final savingByDay = List<double>.filled(7, 0.0);

    for (final tx in widget.transactions) {
      final d = _dateOf(tx);
      if (d == null) continue;
      final dayOnly = DateTime(d.year, d.month, d.day);
      final idx = days.indexWhere((day) => day == dayOnly);
      if (idx == -1) continue;
      final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
      if (_isSavingTx(tx)) {
        savingByDay[idx] += amount;
      } else if (tx['isIncome'] == true) {
        incomeByDay[idx] += amount;
      } else {
        expenseByDay[idx] += amount;
      }
    }

    return _PeriodResult(
      labels: _thaiWeekdayShort,
      income: incomeByDay,
      expense: expenseByDay,
      saving: savingByDay,
    );
  }

  _PeriodResult _buildMonthly(DateTime now) {
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final weekCount = ((daysInMonth - 1) ~/ 7) + 1; // ปกติ 4-5 สัปดาห์

    final incomeByWeek = List<double>.filled(weekCount, 0.0);
    final expenseByWeek = List<double>.filled(weekCount, 0.0);
    final savingByWeek = List<double>.filled(weekCount, 0.0);

    for (final tx in widget.transactions) {
      final d = _dateOf(tx);
      if (d == null) continue;
      if (d.year != now.year || d.month != now.month) continue;
      final weekIdx = ((d.day - 1) ~/ 7).clamp(0, weekCount - 1);
      final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
      if (_isSavingTx(tx)) {
        savingByWeek[weekIdx] += amount;
      } else if (tx['isIncome'] == true) {
        incomeByWeek[weekIdx] += amount;
      } else {
        expenseByWeek[weekIdx] += amount;
      }
    }

    final labels = List.generate(weekCount, (i) => "สัปดาห์ที่ ${i + 1}");

    return _PeriodResult(
      labels: labels,
      income: incomeByWeek,
      expense: expenseByWeek,
      saving: savingByWeek,
    );
  }

  _PeriodResult _buildYearly(DateTime now) {
    final incomeByMonth = List<double>.filled(12, 0.0);
    final expenseByMonth = List<double>.filled(12, 0.0);
    final savingByMonth = List<double>.filled(12, 0.0);

    for (final tx in widget.transactions) {
      final d = _dateOf(tx);
      if (d == null) continue;
      if (d.year != now.year) continue;
      final idx = d.month - 1;
      final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
      if (_isSavingTx(tx)) {
        savingByMonth[idx] += amount;
      } else if (tx['isIncome'] == true) {
        incomeByMonth[idx] += amount;
      } else {
        expenseByMonth[idx] += amount;
      }
    }

    // คืนค่าครบทั้ง 12 เดือนเสมอ (เดือนที่ยังไม่ถึงจะเป็น 0)
    // เพื่อให้แบ่งเป็นไตรมาสและเลื่อนดูล่วงหน้าได้ครบ 4 ไตรมาส
    return _PeriodResult(
      labels: _thaiMonthShort,
      income: incomeByMonth,
      expense: expenseByMonth,
      saving: savingByMonth,
    );
  }

  _PeriodResult _buildAllTime() {
    if (widget.transactions.isEmpty) {
      final year = DateTime.now().year.toString();
      return _PeriodResult(
        labels: [year],
        income: [0.0],
        expense: [0.0],
        saving: [0.0],
      );
    }

    final years = <int>{};
    for (final tx in widget.transactions) {
      final d = _dateOf(tx);
      if (d != null) years.add(d.year);
    }
    final sortedYears = years.toList()..sort();

    final incomeByYear = List<double>.filled(sortedYears.length, 0.0);
    final expenseByYear = List<double>.filled(sortedYears.length, 0.0);
    final savingByYear = List<double>.filled(sortedYears.length, 0.0);

    for (final tx in widget.transactions) {
      final d = _dateOf(tx);
      if (d == null) continue;
      final idx = sortedYears.indexOf(d.year);
      if (idx == -1) continue;
      final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
      if (_isSavingTx(tx)) {
        savingByYear[idx] += amount;
      } else if (tx['isIncome'] == true) {
        incomeByYear[idx] += amount;
      } else {
        expenseByYear[idx] += amount;
      }
    }

    return _PeriodResult(
      labels: sortedYears.map((y) => y.toString()).toList(),
      income: incomeByYear,
      expense: expenseByYear,
      saving: savingByYear,
    );
  }

  /// ปัดเพดานแกน Y ให้เป็นเลขกลมๆ อ่านง่าย
  double _niceMaxY(double rawMax) {
    if (rawMax <= 0) return 1000;
    final magnitude = _pow10Floor(rawMax);
    final normalized = rawMax / magnitude;
    double niceNormalized;
    if (normalized <= 1) {
      niceNormalized = 1;
    } else if (normalized <= 2) {
      niceNormalized = 2;
    } else if (normalized <= 5) {
      niceNormalized = 5;
    } else {
      niceNormalized = 10;
    }
    return niceNormalized * magnitude * 1.2; // เผื่อหัวกราฟไม่ชนขอบบนพอดี
  }

  double _pow10Floor(double value) {
    double magnitude = 1;
    while (magnitude * 10 <= value) {
      magnitude *= 10;
    }
    return magnitude;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA2E0B2),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // --- Header & App Bar (สไตล์เดียวกับหน้าหลัก) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: SizedBox(
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Center(
                      child: Text(
                        "ภาพรวมการเงิน",
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

            // --- ยอดคงเหลือ (คำนวณจากธุรกรรมจริง) ---
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
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
                    "${_totalBalance.toStringAsFixed(2)} THB",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3323),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- Card ส่วนล่าง (สีขาว) ---
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Toggle เลือกช่วงเวลา
                      _buildPeriodSegmentedControl(),

                      const SizedBox(height: 20),

                      // การ์ดแสดงกราฟ
                      _buildChartCard(),

                      const SizedBox(height: 24),

                      // สรุป รายรับ / รายจ่าย
                      _buildSummarySection(),

                      const SizedBox(height: 16),
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

  // --- Widget: ปุ่มเลือกช่วงเวลา (Segmented Control) ---
  Widget _buildPeriodSegmentedControl() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5EC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: List.generate(_periods.length, (index) {
          final isSelected = _selectedPeriodIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriodIndex = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFA2E0B2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _periods[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: const Color(0xFF1E3323),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // --- Widget: การ์ดกราฟแท่ง (ข้อมูลจริงจาก widget.transactions) ---
  Widget _buildChartCard() {
    final result = _buildPeriodResult();

    final rawMax = [
      ...result.income,
      ...result.expense,
      ...result.saving,
    ].fold<double>(0.0, (prev, v) => v > prev ? v : prev);
    final maxYValue = _niceMaxY(rawMax);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F4E8),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "รายรับ & รายจ่าย",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3323),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                    icon: const Icon(Icons.search, size: 20, color: Color(0xFF1E3323)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SearchScreen(transactions: widget.transactions),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                    icon: const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF1E3323)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CalendarPage(transactions: widget.transactions),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 📌 แท็บ "รายปี" (index 2) แสดงเป็นไตรมาสที่เลื่อนดูได้ ส่วนแท็บอื่นแสดงกราฟปกติ
          _selectedPeriodIndex == 2
              ? _buildYearlyQuarterChart(result)
              : _buildBarChart(
                  result.labels,
                  result.income,
                  result.expense,
                  result.saving,
                  maxYValue,
                ),
        ],
      ),
    );
  }

  // --- Widget: กราฟแท่ง 1 ชุด (ใช้ซ้ำได้ทั้งมุมมองปกติและมุมมองไตรมาส) ---
  Widget _buildBarChart(
    List<String> labels,
    List<double> income,
    List<double> expense,
    List<double> saving,
    double maxY,
  ) {
    final chartData = List.generate(
      labels.length,
      (i) => _makeGroupData(i, income[i], expense[i], saving[i]),
    );

    return SizedBox(
      height: 150,
      child: labels.isEmpty
          ? const Center(
              child: Text(
                "ยังไม่มีข้อมูลในช่วงนี้",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            )
          : BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        if (value >= 1000) {
                          return Text(
                            "${(value / 1000).toStringAsFixed(0)}k",
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          );
                        }
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(
                              labels[index],
                              style: const TextStyle(fontSize: 10, color: Color(0xFF1E3323)),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.black.withOpacity(0.05),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: chartData,
              ),
            ),
    );
  }

  // --- Widget: กราฟรายปีแบบแบ่งกลุ่มละ 4 เดือน เลื่อนซ้าย-ขวาดูได้ ---
  Widget _buildYearlyQuarterChart(_PeriodResult result) {
    const int groupSize = 4; // เดือนต่อกลุ่ม -> ทั้งปีมี 3 กลุ่มพอดี (12/4)
    // จำนวนกลุ่มที่ถึงแล้ว คำนวณจากวันที่ปัจจุบันจริง (ค่าคงที่ ไม่เปลี่ยนตามหน้าที่เลื่อนดูอยู่)
    final int quarterCount = (DateTime.now().month - 1) ~/ groupSize + 1;

    return SizedBox(
      height: 150,
      child: PageView.builder(
        controller: _quarterPageController,
        itemCount: quarterCount,
        onPageChanged: (i) => setState(() => _yearQuarterIndex = i),
        itemBuilder: (context, qIndex) {
          final start = qIndex * groupSize;
          final qLabels = result.labels.sublist(start, start + groupSize);
          final qIncome = result.income.sublist(start, start + groupSize);
          final qExpense = result.expense.sublist(start, start + groupSize);
          final qSaving = result.saving.sublist(start, start + groupSize);
          final rawMax = [
            ...qIncome,
            ...qExpense,
            ...qSaving,
          ].fold<double>(0.0, (prev, v) => v > prev ? v : prev);
          final maxY = _niceMaxY(rawMax);
          return _buildBarChart(qLabels, qIncome, qExpense, qSaving, maxY);
        },
      ),
    );
  }

  // ฟังก์ชันสร้างแท่ง (เขียว = รายรับ, แดง = รายจ่าย, น้ำเงิน = เงินออม)
  BarChartGroupData _makeGroupData(
    int x,
    double income,
    double expense,
    double saving,
  ) {
    return BarChartGroupData(
      x: x,
      barRods: [
        if (income > 0)
          BarChartRodData(
            toY: income,
            color: const Color(0xFF73D193),
            width: 6,
            borderRadius: BorderRadius.circular(4),
          ),
        if (expense > 0)
          BarChartRodData(
            toY: expense,
            color: const Color(0xFFE55345),
            width: 6,
            borderRadius: BorderRadius.circular(4),
          ),
        if (saving > 0)
          BarChartRodData(
            toY: saving,
            color: const Color(0xFF3B97FF),
            width: 6,
            borderRadius: BorderRadius.circular(4),
          ),
      ],
    );
  }

  // --- Widget: สรุปยอด รายรับ / รายจ่าย (รวมตามช่วงที่เลือกจากข้อมูลจริง) ---
  Widget _buildSummarySection() {
    final result = _buildPeriodResult();
    final totalIncome = result.income.fold<double>(0.0, (a, b) => a + b);
    final totalExpense = result.expense.fold<double>(0.0, (a, b) => a + b);
    final totalSaving = result.saving.fold<double>(0.0, (a, b) => a + b);

    final incomeText = "${totalIncome.toStringAsFixed(2)} THB";
    final expenseText = "${totalExpense.toStringAsFixed(2)} THB";
    final savingText = "${totalSaving.toStringAsFixed(2)} THB";

    return Row(
      children: [
        // รายรับ
        Expanded(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5EC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.north_east, color: Color(0xFF73D193), size: 20),
              ),
              const SizedBox(height: 6),
              const Text("รายรับ", style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(
                incomeText,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ),

        // รายจ่าย
        Expanded(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE8E8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.south_east, color: Color(0xFFE55345), size: 20),
              ),
              const SizedBox(height: 6),
              const Text("รายจ่าย", style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(
                expenseText,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ),

        // เงินออม (แยกจากรายรับ)
        Expanded(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF4FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.savings_outlined, color: Color(0xFF3B97FF), size: 20),
              ),
              const SizedBox(height: 6),
              const Text("เงินออม", style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  savingText,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// โครงสร้างข้อมูลกราฟที่แปลงแล้วสำหรับแต่ละช่วงเวลา
class _PeriodResult {
  final List<String> labels;
  final List<double> income;
  final List<double> expense;
  final List<double> saving; // เงินออม (แยกจากรายรับ)

  const _PeriodResult({
    required this.labels,
    required this.income,
    required this.expense,
    required this.saving,
  });
}