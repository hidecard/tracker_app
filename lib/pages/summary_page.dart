import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/glass_card.dart';
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
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildDateSelector(years),
            const SizedBox(height: 8),
            _buildStatsRow(balance),
            const SizedBox(height: 12),
            Expanded(child: _buildTransactionsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  hintText: 'Search category, note or date',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Color(0xFF0077B6)),
                ),
                onChanged: (_) => calculateTotals(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GlassCard(
            padding: const EdgeInsets.all(8),
            child: ToggleButtons(
              isSelected: [mode == 'day', mode == 'month'],
              onPressed: (i) {
                setState(() => mode = i == 0 ? 'day' : 'month');
                calculateTotals();
              },
              borderRadius: BorderRadius.circular(8),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 36),
              children: const [
                Icon(Icons.calendar_today, size: 18),
                Icon(Icons.calendar_month, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(List<String> years) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          if (mode == 'day') ...[
            Expanded(
              child: GlassCard(
                onTap: _pickDate,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Color(0xFF0077B6),
                      size: 20,
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
          ] else ...[
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedYear,
                    isExpanded: true,
                    dropdownColor: const Color(0xFFE0F7FA),
                    items: years
                        .map(
                          (y) => DropdownMenuItem(
                            value: y,
                            child: Text(
                              y,
                              style: const TextStyle(color: Color(0xFF0077B6)),
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
            const SizedBox(width: 8),
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedMonth,
                    isExpanded: true,
                    dropdownColor: const Color(0xFFE0F7FA),
                    items: List.generate(
                      12,
                      (i) => DropdownMenuItem(
                        value: (i + 1).toString(),
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(color: Color(0xFF0077B6)),
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
      ),
    );
  }

  Widget _buildStatsRow(double balance) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _buildStatCard('Income', formatMMK(totalIncome), Colors.green[700]!),
          const SizedBox(width: 8),
          _buildStatCard('Expense', formatMMK(totalExpense), Colors.red[700]!),
          const SizedBox(width: 8),
          _buildStatCard('Saved', formatMMK(totalSaved), Colors.blue[700]!),
          const SizedBox(width: 8),
          _buildStatCard(
            'Balance',
            formatMMK(balance),
            balance >= 0 ? Colors.green[700]! : Colors.red[700]!,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey[700], fontSize: 10),
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

  Widget _buildTransactionsList() {
    if (isLoading) return const LoadingIndicator();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: filteredItems().length,
      itemBuilder: (context, idx) {
        var item = filteredItems()[idx];
        bool isIncome = item['type'] == 'income';
        bool isSave = item['type'] == 'save';
        return _buildTransactionItem(item, isIncome, isSave);
      },
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
        ? Colors.blue[700]!
        : (isIncome ? Colors.green[700]! : Colors.red[700]!);
    IconData icon = isSave
        ? Icons.savings
        : (isIncome ? Icons.arrow_downward : Icons.arrow_upward);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSave
                    ? Colors.blue[50]
                    : (isIncome ? Colors.green[50] : Colors.red[50]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['category'] ?? (isSave ? 'Save' : ''),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0077B6),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    item['date'] ?? '',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : '-'}${formatMMK(amountValue)}',
              style: TextStyle(
                color: iconColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
