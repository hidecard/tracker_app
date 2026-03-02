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
  // TODO: replace with your actual Web App URL
  final String url =
      "https://script.google.com/macros/s/AKfycby0elRrVVqSKwHQgJXYx44eP6D0W-BtLypq1zl-ev0rqDUXzqBzkIBN1Wxsi0aVK_9ImA/exec";

  List data = [];
  String selectedMonth = DateTime.now().month.toString();

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
      if (date.month.toString() == selectedMonth) {
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

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.25),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF87CEEB).withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(20), child: child),
    );
  }

  Widget _buildStatCard(String label, double value, Color color) {
    return Expanded(
      child: _buildGlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value.toStringAsFixed(2),
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
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
      if (date.month.toString() == selectedMonth && typeVal == "expense") {
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
    await http.delete(Uri.parse("$url?id=$id"));
    if (!mounted) return;
    loadData();
    showMessage('Deleted');
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    item == null ? "Add Transaction" : "Edit Transaction",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0077B6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "income",
                          child: Text("Income"),
                        ),
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
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: category,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
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
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                      onChanged: (v) {
                        category = v!;
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextFormField(
                      controller: amount,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Amount",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextFormField(
                      controller: note,
                      decoration: const InputDecoration(
                        labelText: "Note",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF87CEEB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double balance = totalIncome - totalExpense;
    Map<String, double> categoryTotals = getCategoryTotals();

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
              // App Bar with Glass Effect
              _buildGlassCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet,
                        color: Color(0xFF0077B6),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Money Tracker",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0077B6),
                          ),
                        ),
                      ),
                      // Month Selector with Calendar Icon
                      _buildGlassCard(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedMonth,
                              icon: const Icon(
                                Icons.calendar_month,
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
                ),
              ),
              const SizedBox(height: 16),

              // Stats Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildStatCard('Income', totalIncome, Colors.green[700]!),
                    const SizedBox(width: 12),
                    _buildStatCard('Expense', totalExpense, Colors.red[700]!),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      'Balance',
                      balance,
                      balance >= 0 ? Colors.green[700]! : Colors.red[700]!,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Pie Chart
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildGlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      height: 200,
                      child: categoryTotals.isEmpty
                          ? const Center(
                              child: Text(
                                'No expenses this month',
                                style: TextStyle(
                                  color: Color(0xFF0077B6),
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                                sections: categoryTotals.entries
                                    .map(
                                      (e) => PieChartSectionData(
                                        value: e.value,
                                        title: e.key,
                                        color: _getCategoryColor(e.key),
                                        radius: 50,
                                        titleStyle: const TextStyle(
                                          fontSize: 12,
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
              ),

              // Transactions Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Transactions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0077B6),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF87CEEB).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${data.length} items',
                        style: const TextStyle(
                          color: Color(0xFF0077B6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

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
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
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
                          String amountText = item['amount']?.toString() ?? '';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildGlassCard(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isIncome
                                        ? Colors.green.withOpacity(0.2)
                                        : Colors.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isIncome
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    color: isIncome
                                        ? Colors.green[700]
                                        : Colors.red[700],
                                  ),
                                ),
                                title: Text(
                                  categoryText,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0077B6),
                                  ),
                                ),
                                subtitle: Text(
                                  dateText,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${isIncome ? '+' : '-'}$amountText',
                                      style: TextStyle(
                                        color: isIncome
                                            ? Colors.green[700]
                                            : Colors.red[700],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    PopupMenuButton<String>(
                                      icon: const Icon(
                                        Icons.more_vert,
                                        color: Color(0xFF0077B6),
                                      ),
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.edit,
                                                color: Color(0xFF0077B6),
                                              ),
                                              SizedBox(width: 8),
                                              Text('Edit'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Delete',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          showDialogForm(item: item);
                                        } else if (value == 'delete') {
                                          deleteTransaction(
                                            item['id'].toString(),
                                          );
                                        }
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
              blurRadius: 15,
              offset: const Offset(0, 8),
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
