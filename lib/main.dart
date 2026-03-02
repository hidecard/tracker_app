import 'dart:async';
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
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // keys allow us to reach into the tab states so that the "add" button
  // (either from the bottom nav or an app bar) can delegate to the
  // currently visible page.
  final GlobalKey<_HomeTabState> _homeKey = GlobalKey<_HomeTabState>();
  final GlobalKey<TransactionsTabState> _transactionsKey =
      GlobalKey<TransactionsTabState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [HomeTab(key: _homeKey), TransactionsTab(key: _transactionsKey)];
  }

  void setCurrentIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      extendBody: true,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF87CEEB).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.4),
                  Colors.white.withOpacity(0.3),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: BackdropFilter(
              filter: ColorFilter.mode(
                Colors.white.withOpacity(0.1),
                BlendMode.srcOver,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
                    _buildNavItem(
                      1,
                      Icons.receipt_long_outlined,
                      Icons.receipt_long,
                      'Transactions',
                    ),
                    _buildCenterAddButton(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setCurrentIndex(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? const Color(0xFF87CEEB).withOpacity(0.4)
              : Colors.transparent,
          border: isSelected
              ? Border.all(color: Colors.white.withOpacity(0.5), width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? const Color(0xFF0077B6) : Colors.grey[600],
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF0077B6),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCenterAddButton(BuildContext context) {
    return GestureDetector(
      onTap: _showAddFormFromNav,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF87CEEB),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF87CEEB).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  /// Forward the add request to the active tab.  With only two pages the
  /// index will be either home (0) or transactions (1); anything else simply
  /// shows the home form.
  void _showAddFormFromNav() {
    if (_currentIndex == 1) {
      _transactionsKey.currentState?.showAddForm();
    } else {
      // default to home
      _homeKey.currentState?.showAddForm();
    }
  }
}

// ==================== HOME TAB ====================
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final String url =
      "https://script.google.com/macros/s/AKfycbx2grg3odTkT7KlCvjiUzCH80jXLsrZX2gnFDCntu2FQpW5ko4urwJkn8fd81cBOOKmpA/exec";

  List data = [];
  List cachedData = [];
  String selectedMonth = DateTime.now().month.toString();
  String selectedYear = DateTime.now().year.toString();

  double totalIncome = 0;
  double totalExpense = 0;

  bool isLoading = false;
  bool isRefreshing = false;
  String? error;
  Timer? _autoRefreshTimer;

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

  String formatMMK(double amount) => '${amount.toStringAsFixed(0)}MMK';

  void showMessage(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : const Color(0xFF87CEEB),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> deleteTransaction(String id) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'id': id, 'action': 'delete'}),
      );
      if (response.statusCode == 200) {
        loadData();
        showMessage('Transaction deleted successfully');
      }
    } catch (_) {}
  }

  Future<void> updateTransaction(Map body) async {
    try {
      body['action'] = 'update';
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        loadData();
        showMessage('Transaction updated successfully');
      }
    } catch (_) {}
  }

  Future<void> addTransaction(Map body) async {
    body['action'] = 'add';
    try {
      body['action'] = 'add';
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 302) {
        loadData();
        showMessage('Transaction added successfully');
      } else {
        showMessage('Failed to add transaction', isError: true);
      }
    } catch (e) {
      showMessage('Error: ${e.toString()}', isError: true);
    }
  }

  void showTransactionDetail(Map<String, dynamic> item) {
    String typeVal = item['type']?.toString() ?? '';
    bool isIncome = typeVal == 'income';
    String categoryText = item['category']?.toString() ?? '';
    String dateText = item['date']?.toString() ?? '';
    String noteText = item['note']?.toString() ?? '';
    double amountValue =
        double.tryParse(item['amount']?.toString() ?? '0') ?? 0;
    String itemId = item['id']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isIncome ? Colors.green[50] : Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                color: isIncome ? Colors.green[700] : Colors.red[700],
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              categoryText,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0077B6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${isIncome ? '+' : '-'}${formatMMK(amountValue)}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isIncome ? Colors.green[700] : Colors.red[700],
              ),
            ),
            const SizedBox(height: 20),
            _buildDetailRow(Icons.calendar_today, 'Date', dateText),
            _buildDetailRow(Icons.category, 'Category', categoryText),
            _buildDetailRow(
              Icons.attach_money,
              'Type',
              isIncome ? 'Income' : 'Expense',
            ),
            _buildDetailRow(
              Icons.note,
              'Note',
              noteText.isEmpty ? 'No note' : noteText,
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF87CEEB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        showEditForm(item);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        showDeleteConfirmation(itemId);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF87CEEB)),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: Colors.grey[600])),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Color(0xFF0077B6),
            ),
          ),
        ],
      ),
    );
  }

  void showDeleteConfirmation(String id) {
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
            onPressed: () {
              Navigator.pop(ctx);
              deleteTransaction(id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void showEditForm(Map<String, dynamic> item) {
    final TextEditingController amountController = TextEditingController(
      text: item['amount']?.toString() ?? '',
    );
    final TextEditingController noteController = TextEditingController(
      text: item['note']?.toString() ?? '',
    );
    String selectedType = item['type']?.toString() ?? 'expense';
    String selectedCategory = item['category']?.toString() ?? 'Food';
    String itemId = item['id']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: _buildGlassCard(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Edit Transaction",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0077B6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButton<String>(
                      value: selectedType,
                      isExpanded: true,
                      underline: const SizedBox(),
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
                      onChanged: (v) => setDialogState(() => selectedType = v!),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      underline: const SizedBox(),
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
                      onChanged: (v) =>
                          setDialogState(() => selectedCategory = v!),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Amount (MMK)",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: "Note",
                        border: InputBorder.none,
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
                            if (amountController.text.isEmpty) {
                              showMessage('Please enter amount', isError: true);
                              return;
                            }
                            Map body = {
                              "id": itemId,
                              "date":
                                  item['date']?.toString() ??
                                  DateTime.now().toString().substring(0, 10),
                              "type": selectedType,
                              "category": selectedCategory,
                              "amount": amountController.text,
                              "note": noteController.text,
                            };
                            Navigator.pop(ctx);
                            updateTransaction(body);
                          },
                          child: const Text("Update"),
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

  void initState() {
    super.initState();
    loadData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshDataInBackground(),
    );
  }

  Future<void> _refreshDataInBackground() async {
    if (!mounted) return;
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200 && mounted) {
        List newData = jsonDecode(response.body);
        newData.sort(
          (a, b) => (b['date'] ?? '').toString().compareTo(
            (a['date'] ?? '').toString(),
          ),
        );
        setState(() {
          data = newData;
          cachedData = List.from(newData);
          error = null;
        });
        calculateTotals();
      }
    } catch (_) {}
  }

  Future<void> loadData() async {
    if (!mounted) return;
    if (cachedData.isNotEmpty) {
      data = List.from(cachedData);
      calculateTotals();
      setState(() => isLoading = false);
    } else {
      setState(() {
        isLoading = true;
        error = null;
      });
    }

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        List newData = jsonDecode(response.body);
        newData.sort(
          (a, b) => (b['date'] ?? '').toString().compareTo(
            (a['date'] ?? '').toString(),
          ),
        );
        if (!mounted) return;
        setState(() {
          data = newData;
          cachedData = List.from(newData);
          error = null;
        });
        calculateTotals();
      }
    } catch (e) {
      if (mounted) setState(() => error = 'Failed to fetch data');
    }
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _pullToRefresh() async {
    if (!mounted) return;
    setState(() => isRefreshing = true);
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        List newData = jsonDecode(response.body);
        newData.sort(
          (a, b) => (b['date'] ?? '').toString().compareTo(
            (a['date'] ?? '').toString(),
          ),
        );
        if (!mounted) return;
        setState(() {
          data = newData;
          cachedData = List.from(newData);
          error = null;
        });
        calculateTotals();
      }
    } catch (_) {}
    if (mounted) setState(() => isRefreshing = false);
  }

  void calculateTotals() {
    totalIncome = 0;
    totalExpense = 0;
    for (var item in data) {
      try {
        DateTime date = DateTime.parse(item['date'] ?? '');
        if (date.month.toString() == selectedMonth &&
            date.year.toString() == selectedYear) {
          if (item['type'] == 'income') {
            totalIncome +=
                double.tryParse(item['amount']?.toString() ?? '0') ?? 0;
          } else {
            totalExpense +=
                double.tryParse(item['amount']?.toString() ?? '0') ?? 0;
          }
        }
      } catch (_) {}
    }
  }

  /// Show the add transaction dialog; needed so that the main screen can
  /// delegate to this tab via a global key.
  void showAddForm() {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController noteController = TextEditingController();
    String selectedType = 'expense';
    String selectedCategory = 'Food';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: _buildGlassCard(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Add Transaction",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0077B6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButton<String>(
                      value: selectedType,
                      isExpanded: true,
                      underline: const SizedBox(),
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
                      onChanged: (v) => setDialogState(() => selectedType = v!),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: "Food", child: Text("Food")),
                        DropdownMenuItem(value: "Rent", child: Text("Rent")),
                        DropdownMenuItem(value: "Bill", child: Text("Bill")),
                        DropdownMenuItem(
                          value: "Shopping",
                          child: Text("Shopping"),
                        ),
                        DropdownMenuItem(
                          value: "Transport",
                          child: Text("Transport"),
                        ),
                        DropdownMenuItem(
                          value: "Entertainment",
                          child: Text("Entertainment"),
                        ),
                        DropdownMenuItem(
                          value: "Health",
                          child: Text("Health"),
                        ),
                      ],
                      onChanged: (v) =>
                          setDialogState(() => selectedCategory = v!),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Amount (MMK)",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: "Note",
                        border: InputBorder.none,
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
                            if (amountController.text.isEmpty) {
                              showMessage('Please enter amount', isError: true);
                              return;
                            }
                            Map body = {
                              "date": DateTime.now().toString().substring(
                                0,
                                10,
                              ),
                              "type": selectedType,
                              "category": selectedCategory,
                              "amount": amountController.text,
                              "note": noteController.text,
                            };
                            Navigator.pop(ctx);
                            addTransaction(body);
                          },
                          child: const Text("Add"),
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

  Map<String, double> getCategoryTotals() {
    Map<String, double> result = {};
    for (var item in data) {
      try {
        DateTime date = DateTime.parse(item['date'] ?? '');
        if (date.month.toString() == selectedMonth &&
            date.year.toString() == selectedYear &&
            item['type'] == 'expense') {
          String cat = item['category']?.toString() ?? 'Unknown';
          double amt = double.tryParse(item['amount']?.toString() ?? '0') ?? 0;
          result[cat] = (result[cat] ?? 0) + amt;
        }
      } catch (_) {}
    }
    return result;
  }

  Widget _buildGlassCard({
    required Widget child,
    EdgeInsets? padding,
    double? width,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.3),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
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

  Widget _buildStatCard(
    String label,
    double value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: _buildGlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              formatMMK(value),
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
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
                            IconButton(
                              onPressed: _pullToRefresh,
                              icon: isRefreshing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF0077B6),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.refresh,
                                      color: Color(0xFF0077B6),
                                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildStatCard(
                      'Income',
                      totalIncome,
                      Colors.green[700]!,
                      Icons.arrow_downward,
                    ),
                    const SizedBox(width: 8),
                    _buildStatCard(
                      'Expense',
                      totalExpense,
                      Colors.red[700]!,
                      Icons.arrow_upward,
                    ),
                    const SizedBox(width: 8),
                    _buildStatCard(
                      'Balance',
                      balance,
                      balance >= 0 ? Colors.green[700]! : Colors.red[700]!,
                      Icons.account_balance,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text(
                      'Recent Transactions',
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
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF87CEEB),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _pullToRefresh,
                        color: const Color(0xFF87CEEB),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: data.length > 5 ? 5 : data.length,
                          itemBuilder: (context, index) {
                            var item = data[index];
                            bool isIncome = item['type'] == 'income';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _buildGlassCard(
                                padding: EdgeInsets.zero,
                                child: InkWell(
                                  onTap: () => showTransactionDetail(item),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: isIncome
                                                ? Colors.green[50]
                                                : Colors.red[50],
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['category'] ?? '',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF0077B6),
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                item['date'] ?? '',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '${isIncome ? '+' : '-'}${formatMMK(double.tryParse(item['amount']?.toString() ?? '0') ?? 0)}',
                                          style: TextStyle(
                                            color: isIncome
                                                ? Colors.green[700]
                                                : Colors.red[700],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== TRANSACTIONS TAB ====================
class TransactionsTab extends StatefulWidget {
  const TransactionsTab({super.key});

  @override
  State<TransactionsTab> createState() => TransactionsTabState();
}

class TransactionsTabState extends State<TransactionsTab> {
  final String url =
      "https://script.google.com/macros/s/AKfycbx2grg3odTkT7KlCvjiUzCH80jXLsrZX2gnFDCntu2FQpW5ko4urwJkn8fd81cBOOKmpA/exec";

  List data = [];
  List cachedData = [];
  String selectedMonth = DateTime.now().month.toString();
  String selectedYear = DateTime.now().year.toString();
  String selectedType = 'all';

  bool isLoading = false;
  bool isRefreshing = false;
  Timer? _autoRefreshTimer;

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

  String formatMMK(double amount) => '${amount.toStringAsFixed(0)}MMK';

  void showMessage(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : const Color(0xFF87CEEB),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> deleteTransaction(String id) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'id': id, 'action': 'delete'}),
      );
      if (response.statusCode == 200) {
        loadData();
        showMessage('Transaction deleted successfully');
      }
    } catch (_) {}
  }

  Future<void> updateTransaction(Map body) async {
    try {
      body['action'] = 'update';
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        loadData();
        showMessage('Transaction updated successfully');
      }
    } catch (_) {}
  }

  Future<void> addTransaction(Map body) async {
    body['action'] = 'add';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 302) {
        loadData();
        showMessage('Transaction added successfully');
      }
    } catch (_) {}
  }

  void showTransactionDetail(Map<String, dynamic> item) {
    String typeVal = item['type']?.toString() ?? '';
    bool isIncome = typeVal == 'income';
    String categoryText = item['category']?.toString() ?? '';
    String dateText = item['date']?.toString() ?? '';
    String noteText = item['note']?.toString() ?? '';
    double amountValue =
        double.tryParse(item['amount']?.toString() ?? '0') ?? 0;
    String itemId = item['id']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isIncome ? Colors.green[50] : Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                color: isIncome ? Colors.green[700] : Colors.red[700],
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              categoryText,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0077B6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${isIncome ? '+' : '-'}${formatMMK(amountValue)}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isIncome ? Colors.green[700] : Colors.red[700],
              ),
            ),
            const SizedBox(height: 20),
            _buildDetailRow(Icons.calendar_today, 'Date', dateText),
            _buildDetailRow(Icons.category, 'Category', categoryText),
            _buildDetailRow(
              Icons.attach_money,
              'Type',
              isIncome ? 'Income' : 'Expense',
            ),
            _buildDetailRow(
              Icons.note,
              'Note',
              noteText.isEmpty ? 'No note' : noteText,
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF87CEEB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        showEditForm(item);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        showDeleteConfirmation(itemId);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF87CEEB)),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: Colors.grey[600])),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Color(0xFF0077B6),
            ),
          ),
        ],
      ),
    );
  }

  void showDeleteConfirmation(String id) {
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
            onPressed: () {
              Navigator.pop(ctx);
              deleteTransaction(id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void showEditForm(Map<String, dynamic> item) {
    final TextEditingController amountController = TextEditingController(
      text: item['amount']?.toString() ?? '',
    );
    final TextEditingController noteController = TextEditingController(
      text: item['note']?.toString() ?? '',
    );
    String selectedType = item['type']?.toString() ?? 'expense';
    String selectedCategory = item['category']?.toString() ?? 'Food';
    String itemId = item['id']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: _buildGlassCard(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Edit Transaction",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0077B6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButton<String>(
                      value: selectedType,
                      isExpanded: true,
                      underline: const SizedBox(),
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
                      onChanged: (v) => setDialogState(() => selectedType = v!),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      underline: const SizedBox(),
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
                      onChanged: (v) =>
                          setDialogState(() => selectedCategory = v!),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Amount (MMK)",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: "Note",
                        border: InputBorder.none,
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
                            if (amountController.text.isEmpty) {
                              showMessage('Please enter amount', isError: true);
                              return;
                            }
                            Map body = {
                              "id": itemId,
                              "date":
                                  item['date']?.toString() ??
                                  DateTime.now().toString().substring(0, 10),
                              "type": selectedType,
                              "category": selectedCategory,
                              "amount": amountController.text,
                              "note": noteController.text,
                            };
                            Navigator.pop(ctx);
                            updateTransaction(body);
                          },
                          child: const Text("Update"),
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

  void showAddForm() {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController noteController = TextEditingController();
    String selectedType = 'expense';
    String selectedCategory = 'Food';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: _buildGlassCard(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Add Transaction",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0077B6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButton<String>(
                      value: selectedType,
                      isExpanded: true,
                      underline: const SizedBox(),
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
                      onChanged: (v) => setDialogState(() => selectedType = v!),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      underline: const SizedBox(),
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
                      onChanged: (v) =>
                          setDialogState(() => selectedCategory = v!),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Amount (MMK)",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: "Note",
                        border: InputBorder.none,
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
                            if (amountController.text.isEmpty) {
                              showMessage('Please enter amount', isError: true);
                              return;
                            }
                            Map body = {
                              "date": DateTime.now().toString().substring(
                                0,
                                10,
                              ),
                              "type": selectedType,
                              "category": selectedCategory,
                              "amount": amountController.text,
                              "note": noteController.text,
                            };
                            Navigator.pop(ctx);
                            addTransaction(body);
                          },
                          child: const Text("Add"),
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
  void initState() {
    super.initState();
    loadData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshDataInBackground(),
    );
  }

  Future<void> _refreshDataInBackground() async {
    if (!mounted) return;
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200 && mounted) {
        List newData = jsonDecode(response.body);
        newData.sort(
          (a, b) => (b['date'] ?? '').toString().compareTo(
            (a['date'] ?? '').toString(),
          ),
        );
        setState(() {
          data = newData;
          cachedData = List.from(newData);
        });
      }
    } catch (_) {}
  }

  Future<void> loadData() async {
    if (!mounted) return;
    if (cachedData.isNotEmpty) {
      data = List.from(cachedData);
      setState(() => isLoading = false);
    } else {
      setState(() => isLoading = true);
    }

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        List newData = jsonDecode(response.body);
        newData.sort(
          (a, b) => (b['date'] ?? '').toString().compareTo(
            (a['date'] ?? '').toString(),
          ),
        );
        if (!mounted) return;
        setState(() {
          data = newData;
          cachedData = List.from(newData);
        });
      }
    } catch (_) {}
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _pullToRefresh() async {
    if (!mounted) return;
    setState(() => isRefreshing = true);
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        List newData = jsonDecode(response.body);
        newData.sort(
          (a, b) => (b['date'] ?? '').toString().compareTo(
            (a['date'] ?? '').toString(),
          ),
        );
        if (!mounted) return;
        setState(() {
          data = newData;
          cachedData = List.from(newData);
        });
      }
    } catch (_) {}
    if (mounted) setState(() => isRefreshing = false);
  }

  List get filteredData {
    return data.where((item) {
      try {
        DateTime date = DateTime.parse(item['date'] ?? '');
        bool monthMatch =
            date.month.toString() == selectedMonth &&
            date.year.toString() == selectedYear;
        bool typeMatch = selectedType == 'all' || item['type'] == selectedType;
        return monthMatch && typeMatch;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  Widget _buildGlassCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.3),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
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

  @override
  Widget build(BuildContext context) {
    int currentYear = DateTime.now().year;
    List<String> years = List.generate(
      5,
      (index) => (currentYear - 2 + index).toString(),
    );
    List filtered = filteredData;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'All Transactions',
          style: TextStyle(color: Color(0xFF0077B6)),
        ),
      ),
      extendBody: true,
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildGlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              "All Transactions",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0077B6),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _pullToRefresh,
                            icon: isRefreshing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF0077B6),
                                    ),
                                  )
                                : const Icon(
                                    Icons.refresh,
                                    color: Color(0xFF0077B6),
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
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
                                  dropdownColor: const Color(0xFFE0F7FA),
                                  items: years
                                      .map(
                                        (y) => DropdownMenuItem(
                                          value: y,
                                          child: Text(
                                            y,
                                            style: const TextStyle(
                                              color: Color(0xFF0077B6),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) {
                                    selectedYear = v!;
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
                                  dropdownColor: const Color(0xFFE0F7FA),
                                  items: List.generate(
                                    12,
                                    (i) => DropdownMenuItem(
                                      value: (i + 1).toString(),
                                      child: Text(
                                        monthNames[i],
                                        style: const TextStyle(
                                          color: Color(0xFF0077B6),
                                        ),
                                      ),
                                    ),
                                  ),
                                  onChanged: (v) {
                                    selectedMonth = v!;
                                    setState(() {});
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildGlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedType,
                            isExpanded: true,
                            dropdownColor: const Color(0xFFE0F7FA),
                            items: const [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text('All Types'),
                              ),
                              DropdownMenuItem(
                                value: 'income',
                                child: Text('Income'),
                              ),
                              DropdownMenuItem(
                                value: 'expense',
                                child: Text('Expense'),
                              ),
                            ],
                            onChanged: (v) {
                              selectedType = v!;
                              setState(() {});
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
                        '${filtered.length}',
                        style: const TextStyle(
                          color: Color(0xFF0077B6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _pullToRefresh,
                      icon: isRefreshing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF0077B6),
                              ),
                            )
                          : const Icon(Icons.refresh, color: Color(0xFF0077B6)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF87CEEB),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _pullToRefresh,
                        color: const Color(0xFF87CEEB),
                        child: filtered.isEmpty
                            ? const Center(
                                child: Text(
                                  'No transactions found',
                                  style: TextStyle(color: Color(0xFF0077B6)),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  var item = filtered[index];
                                  bool isIncome = item['type'] == 'income';
                                  String noteText =
                                      item['note']?.toString() ?? '';
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _buildGlassCard(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: isIncome
                                                  ? Colors.green[50]
                                                  : Colors.red[50],
                                              borderRadius:
                                                  BorderRadius.circular(12),
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
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item['category'] ?? '',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF0077B6),
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                Text(
                                                  noteText.isNotEmpty
                                                      ? '${item['date']} • ${noteText.length > 15 ? '${noteText.substring(0, 15)}...' : noteText}'
                                                      : (item['date'] ?? ''),
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '${isIncome ? '+' : '-'}${formatMMK(double.tryParse(item['amount']?.toString() ?? '0') ?? 0)}',
                                            style: TextStyle(
                                              color: isIncome
                                                  ? Colors.green[700]
                                                  : Colors.red[700],
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: const Text(
                                                    'Delete Transaction',
                                                  ),
                                                  content: const Text(
                                                    'Are you sure you want to delete this transaction?',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(ctx),
                                                      child: const Text(
                                                        'Cancel',
                                                      ),
                                                    ),
                                                    ElevatedButton(
                                                      style:
                                                          ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                Colors.red,
                                                          ),
                                                      onPressed: () {
                                                        Navigator.pop(ctx);
                                                        deleteTransaction(
                                                          item['id']
                                                                  ?.toString() ??
                                                              '',
                                                        );
                                                      },
                                                      child: const Text(
                                                        'Delete',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
