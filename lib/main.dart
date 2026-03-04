import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

class AppLocalizations {
  static String t(String key) => _values[key] ?? key;

  static const Map<String, String> _values = {
    'dashboard': 'Dashboard',
    'current_balance': 'Current Balance',
    'all_transactions': 'All Transactions',
    'add_transaction': 'Add Transaction',
    'home': 'Home',
    'transactions': 'Transactions',
    'balance': 'Balance',
    'month_prefix': 'Month ',
    'failed_to_add_transaction': 'Failed to add transaction',
    'failed_to_fetch_data': 'Failed to fetch data',
    'error': 'Error:',
    'income': 'Income',
    'expense': 'Expense',
    'amount_mmk': 'Amount (MMK)',
    'note': 'Note',
    'cancel': 'Cancel',
    'add': 'Add',
    'update': 'Update',
    'delete': 'Delete',
    'please_enter_amount': 'Please enter amount',
    'transaction_added': 'Transaction added successfully',
    'transaction_deleted': 'Transaction deleted successfully',
    'transaction_updated': 'Transaction updated successfully',
    'edit_transaction': 'Edit Transaction',
    'delete_transaction': 'Delete Transaction',
    'delete_confirmation': 'Are you sure you want to delete this transaction?',
    'date': 'Date',
    'category': 'Category',
    'type': 'Type',
    'no_note': 'No note',
    'edit': 'Edit',
    'language': 'Language',
    'english': 'English',
    'myanmar': 'မြန်မာ',
    'save': 'Save',
    'save_money': 'Save Money',
    'saved_transactions': 'Saved Records',
    'day': 'Day',
    'summary': 'Summary',
  };
}

void main() {
  runApp(const MyApp());
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
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Color(0xFF0077B6),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: const Color(0xFF87CEEB),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white.withOpacity(0.3),
          elevation: 0,
          selectedItemColor: const Color(0xFF0077B6),
          unselectedItemColor: Colors.grey[600],
          showSelectedLabels: false,
          showUnselectedLabels: false,
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            color: Color(0xFF0077B6),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          bodyMedium: TextStyle(color: Color(0xFF333333), fontSize: 14),
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

  final GlobalKey<_HomeTabState> _homeKey = GlobalKey<_HomeTabState>();
  final GlobalKey<TransactionsTabState> _transactionsKey =
      GlobalKey<TransactionsTabState>();
  final GlobalKey<TransactionsTabState> _saveKey =
      GlobalKey<TransactionsTabState>();
  final GlobalKey<SummaryTabState> _summaryKey = GlobalKey<SummaryTabState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeTab(key: _homeKey),
      TransactionsTab(key: _transactionsKey),
      SummaryTab(key: _summaryKey),
      TransactionsTab(key: _saveKey, forcedType: 'save'),
    ];
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
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.home_outlined, Icons.home, 'home'),
                    _buildNavItem(
                      1,
                      Icons.receipt_long_outlined,
                      Icons.receipt_long,
                      'transactions',
                    ),
                    _buildCenterAddButton(context),
                    _buildNavItem(
                      2,
                      Icons.insert_chart_outlined,
                      Icons.insert_chart,
                      'summary',
                    ),
                    _buildNavItem(
                      3,
                      Icons.savings_outlined,
                      Icons.savings,
                      'save',
                    ),
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
    String labelKey,
  ) {
    bool isSelected = _currentIndex == index;
    final label = AppLocalizations.t(labelKey);
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
              ? const Color(0xFF87CEEB).withOpacity(0.2)
              : Colors.transparent,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF87CEEB).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
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
              size: isSelected ? 28 : 24,
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
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF87CEEB), Color(0xFF0077B6)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0077B6).withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.add, color: Colors.white, size: 32),
        ),
      ),
    );
  }

  void _showAddFormFromNav() {
    if (_currentIndex == 1) {
      _transactionsKey.currentState?.showAddForm();
    } else if (_currentIndex == 3) {
      _saveKey.currentState?.showAddForm();
    } else {
      _homeKey.currentState?.showAddForm();
    }
  }
}

// ==================== SUMMARY TAB ====================
class SummaryTab extends StatefulWidget {
  const SummaryTab({super.key});

  @override
  State<SummaryTab> createState() => SummaryTabState();
}

class SummaryTabState extends State<SummaryTab> {
  final String url =
      "https://script.google.com/macros/s/AKfycbx2grg3odTkT7KlCvjiUzCH80jXLsrZX2gnFDCntu2FQpW5ko4urwJkn8fd81cBOOKmpA/exec";

  List data = [];
  bool isLoading = false;
  String mode = 'month'; // 'month' or 'day'
  DateTime selectedDate = DateTime.now();
  String selectedMonth = DateTime.now().month.toString();
  String selectedYear = DateTime.now().year.toString();
  final TextEditingController searchController = TextEditingController();

  double totalIncome = 0;
  double totalExpense = 0;
  double totalSaved = 0;

  String formatMMK(double amount) => '${amount.toStringAsFixed(0)}MMK';

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
        setState(() {
          data = newData;
        });
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
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search category, note or date',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (_) => calculateTotals(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ToggleButtons(
                    isSelected: [mode == 'day', mode == 'month'],
                    onPressed: (i) {
                      setState(() => mode = i == 0 ? 'day' : 'month');
                      calculateTotals();
                    },
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('Day'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('Month'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  if (mode == 'day') ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.8),
                          foregroundColor: const Color(0xFF0077B6),
                        ),
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          '${selectedDate.toString().substring(0, 10)}',
                        ),
                        onPressed: _pickDate,
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedYear,
                          items: years
                              .map(
                                (y) =>
                                    DropdownMenuItem(value: y, child: Text(y)),
                              )
                              .toList(),
                          onChanged: (v) => setState(() {
                            selectedYear = v!;
                            calculateTotals();
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedMonth,
                          items: List.generate(
                            12,
                            (i) => DropdownMenuItem(
                              value: (i + 1).toString(),
                              child: Text('${i + 1}'),
                            ),
                          ).toList(),
                          onChanged: (v) => setState(() {
                            selectedMonth = v!;
                            calculateTotals();
                          }),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _smallStat(
                    'Income',
                    formatMMK(totalIncome),
                    Colors.green[700]!,
                  ),
                  _smallStat(
                    'Expense',
                    formatMMK(totalExpense),
                    Colors.red[700]!,
                  ),
                  _smallStat('Saved', formatMMK(totalSaved), Colors.blue[700]!),
                  _smallStat(
                    'Balance',
                    formatMMK(balance),
                    balance >= 0 ? Colors.green[700]! : Colors.red[700]!,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: filteredItems().length,
                      itemBuilder: (context, idx) {
                        var item = filteredItems()[idx];
                        bool isIncome = item['type'] == 'income';
                        bool isSave = item['type'] == 'save';
                        return Card(
                          child: ListTile(
                            leading: Icon(
                              isSave
                                  ? Icons.savings
                                  : (isIncome
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward),
                              color: isSave
                                  ? Colors.blue[700]
                                  : (isIncome
                                        ? Colors.green[700]
                                        : Colors.red[700]),
                            ),
                            title: Text(
                              item['category'] ?? (isSave ? 'Save' : ''),
                            ),
                            subtitle: Text(item['date'] ?? ''),
                            trailing: Text(
                              '${isIncome ? '+' : '-'}${formatMMK(double.tryParse(item['amount']?.toString() ?? '0') ?? 0)}',
                              style: TextStyle(
                                color: isSave
                                    ? Colors.blue[700]
                                    : (isIncome
                                          ? Colors.green[700]
                                          : Colors.red[700]),
                                fontWeight: FontWeight.bold,
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
    );
  }

  Widget _smallStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
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
  double totalSaved = 0;

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
        showMessage(AppLocalizations.t('transaction_deleted'));
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
        showMessage(AppLocalizations.t('transaction_updated'));
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
        showMessage(AppLocalizations.t('transaction_added'));
      } else {
        showMessage(
          AppLocalizations.t('failed_to_add_transaction'),
          isError: true,
        );
      }
    } catch (e) {
      showMessage(
        '${AppLocalizations.t('error')} ${e.toString()}',
        isError: true,
      );
    }
  }

  void showTransactionDetail(Map<String, dynamic> item) {
    String typeVal = item['type']?.toString() ?? '';
    bool isIncome = typeVal == 'income';
    bool isSave = typeVal == 'save';
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
                color: isSave
                    ? Colors.blue[50]
                    : (isIncome ? Colors.green[50] : Colors.red[50]),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSave
                    ? Icons.savings
                    : (isIncome ? Icons.arrow_downward : Icons.arrow_upward),
                color: isSave
                    ? Colors.blue[700]
                    : (isIncome ? Colors.green[700] : Colors.red[700]),
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              categoryText.isEmpty
                  ? AppLocalizations.t('save_money')
                  : categoryText,
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
                color: isSave
                    ? Colors.blue[700]
                    : (isIncome ? Colors.green[700] : Colors.red[700]),
              ),
            ),
            const SizedBox(height: 20),
            _buildDetailRow(
              Icons.calendar_today,
              AppLocalizations.t('date'),
              dateText,
            ),
            _buildDetailRow(
              Icons.category,
              AppLocalizations.t('category'),
              categoryText.isEmpty ? '-' : categoryText,
            ),
            _buildDetailRow(
              Icons.attach_money,
              AppLocalizations.t('type'),
              isSave
                  ? AppLocalizations.t('save_money')
                  : (isIncome
                        ? AppLocalizations.t('income')
                        : AppLocalizations.t('expense')),
            ),
            _buildDetailRow(
              Icons.note,
              AppLocalizations.t('note'),
              noteText.isEmpty ? AppLocalizations.t('no_note') : noteText,
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
                              showMessage(
                                AppLocalizations.t('please_enter_amount'),
                                isError: true,
                              );
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
          error = null;
        });
        calculateTotals();
      }
    } catch (e) {
      if (mounted)
        setState(() => error = AppLocalizations.t('failed_to_fetch_data'));
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
    totalSaved = 0;
    for (var item in data) {
      try {
        DateTime date = DateTime.parse(item['date'] ?? '');
        if (date.month.toString() == selectedMonth &&
            date.year.toString() == selectedYear) {
          if (item['type'] == 'income') {
            totalIncome +=
                double.tryParse(item['amount']?.toString() ?? '0') ?? 0;
          } else if (item['type'] == 'expense') {
            totalExpense +=
                double.tryParse(item['amount']?.toString() ?? '0') ?? 0;
          } else if (item['type'] == 'save') {
            totalSaved +=
                double.tryParse(item['amount']?.toString() ?? '0') ?? 0;
          }
        }
      } catch (_) {}
    }
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
                  Text(
                    AppLocalizations.t('add_transaction'),
                    style: const TextStyle(
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
                              showMessage(
                                AppLocalizations.t('please_enter_amount'),
                                isError: true,
                              );
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
    String labelKey,
    double value,
    Color color,
    IconData icon,
  ) {
    final label = AppLocalizations.t(labelKey);
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
    double balance = totalIncome - totalExpense - totalSaved;
    Map<String, double> categoryTotals = getCategoryTotals();
    int currentYear = DateTime.now().year;
    List<String> years = List.generate(
      5,
      (index) => (currentYear - 2 + index).toString(),
    );

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF87CEEB), Color(0xFF0077B6)],
            ),
          ),
        ),
        title: Text(AppLocalizations.t('dashboard')),
      ),
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.t('current_balance'),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF0077B6),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatMMK(balance),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0077B6),
                                    ),
                                  ),
                                ],
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
                      'income',
                      totalIncome,
                      Colors.green[700]!,
                      Icons.arrow_downward,
                    ),
                    const SizedBox(width: 8),
                    _buildStatCard(
                      'expense',
                      totalExpense,
                      Colors.red[700]!,
                      Icons.arrow_upward,
                    ),
                    const SizedBox(width: 8),
                    _buildStatCard(
                      'save_money',
                      totalSaved,
                      Colors.blue[700]!,
                      Icons.savings,
                    ),
                    const SizedBox(width: 8),
                    _buildStatCard(
                      'balance',
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
                            bool isSave = item['type'] == 'save';
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
                                            color: isSave
                                                ? Colors.blue[50]
                                                : (isIncome
                                                      ? Colors.green[50]
                                                      : Colors.red[50]),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Icon(
                                            isSave
                                                ? Icons.savings
                                                : (isIncome
                                                      ? Icons.arrow_downward
                                                      : Icons.arrow_upward),
                                            color: isSave
                                                ? Colors.blue[700]
                                                : (isIncome
                                                      ? Colors.green[700]
                                                      : Colors.red[700]),
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
                                                item['category'] ??
                                                    (isSave
                                                        ? AppLocalizations.t(
                                                            'save_money',
                                                          )
                                                        : ''),
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
                                            color: isSave
                                                ? Colors.blue[700]
                                                : (isIncome
                                                      ? Colors.green[700]
                                                      : Colors.red[700]),
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
  final String? forcedType;
  const TransactionsTab({super.key, this.forcedType});

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

  @override
  void initState() {
    super.initState();
    if (widget.forcedType != null) {
      selectedType = widget.forcedType!;
    }
    loadData();
    _startAutoRefresh();
  }

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
        showMessage(AppLocalizations.t('transaction_deleted'));
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
        showMessage(AppLocalizations.t('transaction_updated'));
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
        showMessage(AppLocalizations.t('transaction_added'));
      }
    } catch (_) {}
  }

  void showTransactionDetail(Map<String, dynamic> item) {
    String typeVal = item['type']?.toString() ?? '';
    bool isIncome = typeVal == 'income';
    bool isSave = typeVal == 'save';
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
                color: isSave
                    ? Colors.blue[50]
                    : (isIncome ? Colors.green[50] : Colors.red[50]),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSave
                    ? Icons.savings
                    : (isIncome ? Icons.arrow_downward : Icons.arrow_upward),
                color: isSave
                    ? Colors.blue[700]
                    : (isIncome ? Colors.green[700] : Colors.red[700]),
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              categoryText.isEmpty
                  ? AppLocalizations.t('save_money')
                  : categoryText,
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
                color: isSave
                    ? Colors.blue[700]
                    : (isIncome ? Colors.green[700] : Colors.red[700]),
              ),
            ),
            const SizedBox(height: 20),
            _buildDetailRow(
              Icons.calendar_today,
              AppLocalizations.t('date'),
              dateText,
            ),
            _buildDetailRow(
              Icons.category,
              AppLocalizations.t('category'),
              categoryText.isEmpty ? '-' : categoryText,
            ),
            _buildDetailRow(
              Icons.attach_money,
              AppLocalizations.t('type'),
              isSave
                  ? AppLocalizations.t('save_money')
                  : (isIncome
                        ? AppLocalizations.t('income')
                        : AppLocalizations.t('expense')),
            ),
            _buildDetailRow(
              Icons.note,
              AppLocalizations.t('note'),
              noteText.isEmpty ? AppLocalizations.t('no_note') : noteText,
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
    if (widget.forcedType == 'save') {
      final TextEditingController amountController = TextEditingController(
        text: item['amount']?.toString() ?? '',
      );
      final TextEditingController noteController = TextEditingController(
        text: item['note']?.toString() ?? '',
      );
      String itemId = item['id']?.toString() ?? '';
      DateTime selectedDate;
      try {
        selectedDate = DateTime.parse(item['date']?.toString() ?? '');
      } catch (_) {
        selectedDate = DateTime.now();
      }

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
                      "Edit Save Entry",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0077B6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Color(0xFF0077B6),
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                  onSurface: Color(0xFF0077B6),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Color(0xFF0077B6),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF0077B6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: Color(0xFF0077B6),
                            ),
                          ],
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
                                showMessage(
                                  AppLocalizations.t('please_enter_amount'),
                                  isError: true,
                                );
                                return;
                              }
                              Map body = {
                                "id": itemId,
                                "date": selectedDate.toString().substring(
                                  0,
                                  10,
                                ),
                                "type": 'save',
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
      return;
    }

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
                              showMessage(
                                AppLocalizations.t('please_enter_amount'),
                                isError: true,
                              );
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
    if (widget.forcedType == 'save') {
      final TextEditingController amountController = TextEditingController();
      final TextEditingController noteController = TextEditingController();
      DateTime selectedDate = DateTime.now();

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
                    Text(
                      AppLocalizations.t('save_money'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0077B6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Color(0xFF0077B6),
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                  onSurface: Color(0xFF0077B6),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Color(0xFF0077B6),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF0077B6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: Color(0xFF0077B6),
                            ),
                          ],
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
                                showMessage(
                                  AppLocalizations.t('please_enter_amount'),
                                  isError: true,
                                );
                                return;
                              }
                              Map body = {
                                "date": selectedDate.toString().substring(
                                  0,
                                  10,
                                ),
                                "type": 'save',
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
      return;
    }

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
                              showMessage(
                                AppLocalizations.t('please_enter_amount'),
                                isError: true,
                              );
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
        bool typeMatch;
        if (widget.forcedType != null) {
          typeMatch = item['type'] == widget.forcedType;
        } else {
          if (selectedType == 'all') {
            typeMatch = item['type'] != 'save';
          } else {
            typeMatch = item['type'] == selectedType;
          }
        }
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

  Widget _buildSummaryCard() {
    double monthIncome = 0;
    double monthExpense = 0;
    double monthSaved = 0;

    for (var item in data) {
      try {
        DateTime date = DateTime.parse(item['date'] ?? '');
        if (date.month.toString() == selectedMonth &&
            date.year.toString() == selectedYear) {
          String type = item['type'] ?? '';
          double amount =
              double.tryParse(item['amount']?.toString() ?? '0') ?? 0;
          if (type == 'income') {
            monthIncome += amount;
          } else if (type == 'expense') {
            monthExpense += amount;
          } else if (type == 'save') {
            monthSaved += amount;
          }
        }
      } catch (_) {}
    }

    double monthBalance = monthIncome - monthExpense - monthSaved;

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0077B6), Color(0xFF87CEEB)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0077B6).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${monthNames[int.parse(selectedMonth) - 1]} $selectedYear Summary',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'Income',
                      formatMMK(monthIncome),
                      Icons.arrow_downward,
                      Colors.green[100]!,
                      Colors.green[700]!,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryItem(
                      'Expense',
                      formatMMK(monthExpense),
                      Icons.arrow_upward,
                      Colors.red[100]!,
                      Colors.red[700]!,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'Saved',
                      formatMMK(monthSaved),
                      Icons.savings,
                      Colors.blue[100]!,
                      Colors.blue[700]!,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryItem(
                      'Balance',
                      formatMMK(monthBalance),
                      Icons.account_balance_wallet,
                      monthBalance >= 0 ? Colors.green[100]! : Colors.red[100]!,
                      monthBalance >= 0 ? Colors.green[700]! : Colors.red[700]!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color bgColor,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: iconColor.withOpacity(0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF87CEEB), Color(0xFF0077B6)],
            ),
          ),
        ),
        title: Text(
          widget.forcedType == 'save'
              ? AppLocalizations.t('saved_transactions')
              : AppLocalizations.t('all_transactions'),
          style: const TextStyle(color: Colors.white),
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
                                  ).toList(),
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
                          child: widget.forcedType == null
                              ? DropdownButton<String>(
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
                                )
                              : const SizedBox.shrink(),
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
                    Text(
                      widget.forcedType == 'save'
                          ? AppLocalizations.t('saved_transactions')
                          : AppLocalizations.t('transactions'),
                      style: const TextStyle(
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
                                itemCount: filtered.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == filtered.length) {
                                    return _buildSummaryCard();
                                  }
                                  var item = filtered[index];
                                  bool isIncome = item['type'] == 'income';
                                  bool isSave = item['type'] == 'save';
                                  String noteText =
                                      item['note']?.toString() ?? '';
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _buildGlassCard(
                                      padding: const EdgeInsets.all(12),
                                      child: InkWell(
                                        onTap: () =>
                                            showTransactionDetail(item),
                                        borderRadius: BorderRadius.circular(16),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: isSave
                                                    ? Colors.blue[50]
                                                    : (isIncome
                                                          ? Colors.green[50]
                                                          : Colors.red[50]),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                isSave
                                                    ? Icons.savings
                                                    : (isIncome
                                                          ? Icons.arrow_downward
                                                          : Icons.arrow_upward),
                                                color: isSave
                                                    ? Colors.blue[700]
                                                    : (isIncome
                                                          ? Colors.green[700]
                                                          : Colors.red[700]),
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
                                                    item['category'] ??
                                                        (isSave
                                                            ? AppLocalizations.t(
                                                                'save_money',
                                                              )
                                                            : ''),
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
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
                                                color: isSave
                                                    ? Colors.blue[700]
                                                    : (isIncome
                                                          ? Colors.green[700]
                                                          : Colors.red[700]),
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
