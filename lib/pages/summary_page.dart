import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/common_components.dart';

class SummaryPage extends StatefulWidget {
  final VoidCallback? onAddPressed;

  const SummaryPage({super.key, this.onAddPressed});

  @override
  State<SummaryPage> createState() => SummaryPageState();
}

class SummaryPageState extends State<SummaryPage> {
  final String url =
      "https://script.google.com/macros/s/AKfycbx2grg3odTkT7KlCvjiUzCH80jXLsrZX2gnFDCntu2FQpW5ko4urwJkn8fd81cBOOKmpA/exec";

  List data = [];
  bool isLoading = false;
  String mode = 'month';
  DateTime selectedDate = DateTime.now();
  String selectedMonth = DateTime.now().month.toString();
  String selectedYear = DateTime.now().year.toString();
  final TextEditingController searchController = TextEditingController();

  double totalIncome = 0;
  double totalExpense = 0;
  double totalSaved = 0;

  String formatMMK(double amount) => '${amount.toStringAsFixed(0)} MMK';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List newData = jsonDecode(response.body);
        newData.sort(
          (a, b) => (b['date'] ?? '').toString().compareTo(
            (a['date'] ?? '').toString(),
          ),
        );
        if (!mounted) return;
        setState(() => data = newData);
        calculateTotals();
      }
    } catch (_) {}
    if (mounted) setState(() => isLoading = false);
  }

  void calculateTotals() {
    totalIncome = 0;
    totalExpense = 0;
    totalSaved = 0;
    for (var item in filteredItems()) {
      try {
        if (item['type'] == 'income') {
          totalIncome +=
              double.tryParse(item['amount']?.toString() ?? '0') ?? 0;
        } else if (item['type'] == 'expense') {
          totalExpense +=
              double.tryParse(item['amount']?.toString() ?? '0') ?? 0;
        } else if (item['type'] == 'save') {
          totalSaved += double.tryParse(item['amount']?.toString() ?? '0') ?? 0;
        }
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  List filteredItems() {
    String q = searchController.text.trim().toLowerCase();
    return data.where((item) {
      try {
        DateTime d = DateTime.parse(item['date'] ?? '');
        bool dateMatch = false;
        if (mode == 'month') {
          dateMatch =
              d.month.toString() == selectedMonth &&
              d.year.toString() == selectedYear;
        } else {
          dateMatch =
              d.year == selectedDate.year &&
              d.month == selectedDate.month &&
              d.day == selectedDate.day;
        }
        if (!dateMatch) return false;
        if (q.isEmpty) return true;
        String cat = (item['category'] ?? '').toString().toLowerCase();
        String note = (item['note'] ?? '').toString().toLowerCase();
        return cat.contains(q) ||
            note.contains(q) ||
            item['date'].toString().contains(q);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  Future<void> _pickDate() async {
    DateTime? d = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (d != null) {
      setState(() => selectedDate = d);
      calculateTotals();
    }
  }

  @override
  Widget build(BuildContext context) {
    double balance = totalIncome - totalExpense - totalSaved;
    int currentYear = DateTime.now().year;
    List<String> years = List.generate(
      5,
      (index) => (currentYear - 2 + index).toString(),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(years),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [_buildStatsRow(balance), const SizedBox(height: 16)],
              ),
            ),
          ),
          if (isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF0077B6)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index >= filteredItems().length) return null;
                  var item = filteredItems()[index];
                  bool isIncome = item['type'] == 'income';
                  bool isSave = item['type'] == 'save';
                  return _buildTransactionItem(item, isIncome, isSave);
                }, childCount: filteredItems().length),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(List<String> years) {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF0077B6),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const Text(
          'Summary',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF87CEEB), Color(0xFF0077B6)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                left: -20,
                bottom: 60,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(130),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSearchBar(),
              const SizedBox(height: 12),
              _buildDateSelector(years),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF0077B6)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'Search category, note or date',
                border: InputBorder.none,
              ),
              onChanged: (_) => calculateTotals(),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F9FC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildModeButton(Icons.calendar_today, 0),
                const SizedBox(width: 4),
                _buildModeButton(Icons.calendar_month, 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(IconData icon, int index) {
    bool isSelected =
        (mode == 'day' && index == 0) || (mode == 'month' && index == 1);
    return GestureDetector(
      onTap: () {
        setState(() => mode = index == 0 ? 'day' : 'month');
        calculateTotals();
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0077B6) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected ? Colors.white : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildDateSelector(List<String> years) {
    return Row(
      children: [
        if (mode == 'day')
          Expanded(
            child: GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Color(0xFF0077B6),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${selectedDate.toString().substring(0, 10)}',
                      style: const TextStyle(
                        color: Color(0xFF0077B6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedYear,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xFF0077B6),
                  ),
                  items: years
                      .map(
                        (y) => DropdownMenuItem(
                          value: y,
                          child: Text(
                            y,
                            style: const TextStyle(
                              color: Color(0xFF0077B6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() {
                    selectedYear = v!;
                    calculateTotals();
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedMonth,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xFF0077B6),
                  ),
                  items: List.generate(
                    12,
                    (i) => DropdownMenuItem(
                      value: (i + 1).toString(),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: Color(0xFF0077B6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ).toList(),
                  onChanged: (v) => setState(() {
                    selectedMonth = v!;
                    calculateTotals();
                  }),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatsRow(double balance) {
    return Row(
      children: [
        _buildStatCard('Income', formatMMK(totalIncome), Colors.green[400]!),
        const SizedBox(width: 8),
        _buildStatCard('Expense', formatMMK(totalExpense), Colors.red[400]!),
        const SizedBox(width: 8),
        _buildStatCard('Saved', formatMMK(totalSaved), Colors.blue[400]!),
        const SizedBox(width: 8),
        _buildStatCard(
          'Balance',
          formatMMK(balance),
          balance >= 0 ? Colors.green[400]! : Colors.red[400]!,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 10),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(
    Map<String, dynamic> item,
    bool isIncome,
    bool isSave,
  ) {
    double amountValue =
        double.tryParse(item['amount']?.toString() ?? '0') ?? 0;
    Color iconColor = isSave
        ? Colors.blue
        : (isIncome ? Colors.green : Colors.red);
    Color bgColor = isSave
        ? Colors.blue.withOpacity(0.1)
        : (isIncome
              ? Colors.green.withOpacity(0.1)
              : Colors.red.withOpacity(0.1));
    IconData icon = isSave
        ? Icons.savings
        : (isIncome ? Icons.arrow_downward : Icons.arrow_upward);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['category'] ?? (isSave ? 'Save' : ''),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['date'] ?? '',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : '-'}${formatMMK(amountValue)}',
              style: TextStyle(
                color: iconColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
