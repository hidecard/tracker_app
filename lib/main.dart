import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF87CEEB),
        scaffoldBackgroundColor: const Color(0xFFE0F7FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF87CEEB),
          brightness: Brightness.light,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String url =
      "https://script.google.com/macros/s/AKfycby0elRrVVqSKwHQgJXYx44eP6D0W-BtLypq1zl-ev0rqDUXzqBzkIBN1Wxsi0aVK_9ImA/exec";

  List data = [];
  String selectedMonth = DateTime.now().month.toString();
  String selectedYear = DateTime.now().year.toString();

  double totalIncome = 0;
  double totalExpense = 0;

  bool isLoading = false;
  String? error;

  final List<String> monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String formatMMK(double amount) {
    return '${amount.toStringAsFixed(0)}MMK';
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        data = jsonDecode(response.body);
        data.sort((a, b) {
          try {
            return b['date'].toString().compareTo(a['date'].toString());
          } catch (_) {
            return 0;
          }
        });
        calculateTotals();
      } else {
        error = 'Server returned ${response.statusCode}';
      }
    } catch (e) {
      error = 'Failed to fetch data';
    }
    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
  }

  void calculateTotals() {
    totalIncome = 0;
    totalExpense = 0;

    for (var item in data) {
      DateTime? date;
      try {
        date = DateTime.parse(item['date'] ?? '');
      } catch (_) {
        continue;
      }
      if (date.month.toString() == selectedMonth &&
          date.year.toString() == selectedYear) {
        String typeVal = item['type']?.toString() ?? '';
        if (typeVal == 'income') {
          totalIncome +=
              double.tryParse(item['amount']?.toString() ?? '0') ?? 0;
        } else {
          totalExpense +=
              double.tryParse(item['amount']?.toString() ?? '0') ?? 0;
        }
      }
    }
  }

  Widget _buildGlassCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.3),
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF87CEEB).withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(16), child: child),
    );
  }

  Widget _buildStatCard(String label, double value, Color color) {
    return Expanded(
      child: _buildGlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatMMK(value),
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, double> getCategoryTotals() {
    Map<String, double> result = {};
    for (var item in data) {
      DateTime date;
      try {
        date = DateTime.parse(item['date'] ?? '');
      } catch (_) {
        continue;
      }

      String typeVal = item['type']?.toString() ?? '';
      if (date.month.toString() == selectedMonth &&
          date.year.toString() == selectedYear &&
          typeVal == "expense") {
        String cat = item['category']?.toString() ?? 'Unknown';
        double amt = double.tryParse(item['amount']?.toString() ?? '0') ?? 0;
        result[cat] = (result[cat] ?? 0) + amt;
      }
    }
    return result;
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF87CEEB),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> addTransaction(Map body) async {
    await http.post(Uri.parse(url), body: jsonEncode(body));
    if (!mounted) return;
    loadData();
    showMessage('Added');
  }

  Future<void> updateTransaction(Map body) async {
    await http.put(Uri.parse(url), body: jsonEncode(body));
    if (!mounted) return;
    loadData();
    showMessage('Updated');
  }

  Future<void> deleteTransaction(String id) async {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
          'Are you sure you want to delete this transaction?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await http.delete(Uri.parse("$url?id=$id"));
              if (!mounted) return;
              loadData();
              showMessage('Deleted');
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void showDialogForm({Map? item}) {
    final TextEditingController amount = TextEditingController(
      text: item?['amount']?.toString(),
    );
    final TextEditingController note = TextEditingController(
      text: item?['note']?.toString(),
    );

    String type = item?['type']?.toString() ?? "income";
    String category = item?['category']?.toString() ?? "Food";

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: _buildGlassCard(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  item == null ? "Add Transaction" : "Edit Transaction",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0077B6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: "income", child: Text("Income")),
                      DropdownMenuItem(
                        value: "expense",
                        child: Text("Expense"),
                      ),
                    ],
                    onChanged: (v) {
                      type = v!;
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items:
                        [
                              "Food",
                              "Rent",
                              "Bill",
                              "Shopping",
                              "Transport",
                              "Entertainment",
                              "Health",
                            ]
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                    onChanged: (v) {
                      category = v!;
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextFormField(
                    controller: amount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Amount (MMK)",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextFormField(
                    controller: note,
                    decoration: const InputDecoration(
                      labelText: "Note",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF87CEEB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          if (formKey.currentState?.validate() ?? false) {
                            Map body = {
                              "id": item?['id'],
                              "date": DateTime.now().toString().substring(
                                0,
                                10,
                              ),
                              "type": type,
                              "category": category,
                              "amount": amount.text,
                              "note": note.text,
                            };
                            if (item == null) {
                              addTransaction(body);
                            } else {
                              updateTransaction(body);
                            }
                            Navigator.pop(context);
                          }
                        },
                        child: const Text("Save"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double balance = totalIncome - totalExpense;
    Map<String, double> categoryTotals = getCategoryTotals();

    int currentYear = DateTime.now().year;
    List<String> years = List.generate(
      5,
      (index) => (currentYear - 2 + index).toString(),
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2), Color(0xFF80DEEA)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildGlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF87CEEB).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet,
                                color: Color(0xFF0077B6),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                "Money Tracker",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0077B6),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Year and Month Selector
                        Row(
                          children: [
                            Expanded(
                              child: _buildGlassCard(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedYear,
                                    isExpanded: true,
                                    icon: const Icon(
                                      Icons.calendar_today,
                                      color: Color(0xFF0077B6),
                                      size: 18,
                                    ),
                                    dropdownColor: const Color(0xFFE0F7FA),
                                    borderRadius: BorderRadius.circular(12),
                                    items: years
                                        .map(
                                          (year) => DropdownMenuItem(
                                            value: year,
                                            child: Text(
                                              year,
                                              style: const TextStyle(
                                                color: Color(0xFF0077B6),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      selectedYear = value!;
                                      calculateTotals();
                                      setState(() {});
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: _buildGlassCard(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedMonth,
                                    isExpanded: true,
                                    icon: const Icon(
                                      Icons.arrow_drop_down,
                                      color: Color(0xFF0077B6),
                                    ),
                                    dropdownColor: const Color(0xFFE0F7FA),
                                    borderRadius: BorderRadius.circular(12),
                                    items: List.generate(
                                      12,
                                      (index) => DropdownMenuItem(
                                        value: (index + 1).toString(),
                                        child: Text(
                                          monthNames[index],
                                          style: const TextStyle(
                                            color: Color(0xFF0077B6),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                    onChanged: (value) {
                                      selectedMonth = value!;
                                      calculateTotals();
                                      setState(() {});
                                    },
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
              ),

              // Stats Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildStatCard('Income', totalIncome, Colors.green[700]!),
                    const SizedBox(width: 8),
                    _buildStatCard('Expense', totalExpense, Colors.red[700]!),
                    const SizedBox(width: 8),
                    _buildStatCard(
                      'Balance',
                      balance,
                      balance >= 0 ? Colors.green[700]! : Colors.red[700]!,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Pie Chart
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildGlassCard(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    height: 180,
                    child: categoryTotals.isEmpty
                        ? const Center(
                            child: Text(
                              'No expenses',
                              style: TextStyle(color: Color(0xFF0077B6)),
                            ),
                          )
                        : PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 35,
                              sections: categoryTotals.entries
                                  .map(
                                    (e) => PieChartSectionData(
                                      value: e.value,
                                      title: e.key,
                                      color: _getCategoryColor(e.key),
                                      radius: 45,
                                      titleStyle: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Transactions Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text(
                      'Transactions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0077B6),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF87CEEB).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${data.length}',
                        style: const TextStyle(
                          color: Color(0xFF0077B6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Transactions List
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF87CEEB),
                        ),
                      )
                    : error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 40,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: loadData,
                              child: const Text("Retry"),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          var item = data[index];
                          String typeVal = item['type']?.toString() ?? '';
                          bool isIncome = typeVal == 'income';
                          String categoryText =
                              item['category']?.toString() ?? '';
                          String dateText = item['date']?.toString() ?? '';
                          double amountValue =
                              double.tryParse(
                                item['amount']?.toString() ?? '0',
                              ) ??
                              0;
                          String itemId = item['id']?.toString() ?? '';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildGlassCard(
                              padding: EdgeInsets.zero,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isIncome
                                        ? Colors.green.withOpacity(0.2)
                                        : Colors.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    isIncome
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    color: isIncome
                                        ? Colors.green[700]
                                        : Colors.red[700],
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  categoryText,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0077B6),
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  dateText,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${isIncome ? '+' : '-'}${formatMMK(amountValue)}',
                                      style: TextStyle(
                                        color: isIncome
                                            ? Colors.green[700]
                                            : Colors.red[700],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    // Edit Button
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Color(0xFF0077B6),
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        showDialogForm(item: item);
                                      },
                                    ),
                                    // Delete Button
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        deleteTransaction(itemId);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF87CEEB), Color(0xFF00B4DB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF87CEEB).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => showDialogForm(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'Food': const Color(0xFFFF6B6B),
      'Rent': const Color(0xFF4ECDC4),
      'Bill': const Color(0xFFFFE66D),
      'Shopping': const Color(0xFF95E1D3),
      'Transport': const Color(0xFFDDA0DD),
      'Entertainment': const Color(0xFF98D8C8),
      'Health': const Color(0xFFF7DC6F),
      'Unknown': const Color(0xFFBDC3C7),
    };
    return colors[category] ?? colors['Unknown']!;
  }
}
