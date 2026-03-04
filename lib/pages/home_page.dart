import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import '../widgets/glass_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/common_components.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? onAddPressed;

  const HomePage({super.key, this.onAddPressed});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
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

  String formatMMK(double amount) => '${amount.toStringAsFixed(0)} MMK';

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
      } else {
        showMessage('Failed to add transaction', isError: true);
      }
    } catch (e) {
      showMessage('Error: ${e.toString()}', isError: true);
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
          child: GlassCard(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Add Transaction',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0077B6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  _buildTypeDropdown(setDialogState, selectedType, (v) {
                    setDialogState(() => selectedType = v!);
                  }),
                  const SizedBox(height: 12),
                  _buildCategoryDropdown(setDialogState, selectedCategory, (v) {
                    setDialogState(() => selectedCategory = v!);
                  }),
                  const SizedBox(height: 12),
                  _buildAmountField(amountController),
                  const SizedBox(height: 12),
                  _buildNoteField(noteController),
                  const SizedBox(height: 20),
                  _buildDialogButtons(
                    ctx,
                    amountController,
                    noteController,
                    selectedType,
                    selectedCategory,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeDropdown(
    StateSetter setDialogState,
    String selectedType,
    Function(String?) onChanged,
  ) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonFormField<String>(
        value: selectedType,
        isExpanded: true,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
        ),
        dropdownColor: const Color(0xFFE0F7FA),
        items: const [
          DropdownMenuItem(value: "income", child: Text("Income")),
          DropdownMenuItem(value: "expense", child: Text("Expense")),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildCategoryDropdown(
    StateSetter setDialogState,
    String selectedCategory,
    Function(String?) onChanged,
  ) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonFormField<String>(
        value: selectedCategory,
        isExpanded: true,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
        ),
        dropdownColor: const Color(0xFFE0F7FA),
        items: [
          "Food",
          "Rent",
          "Bill",
          "Shopping",
          "Transport",
          "Entertainment",
          "Health",
        ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildAmountField(TextEditingController controller) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: "Amount (MMK)",
          border: InputBorder.none,
          prefixIcon: Icon(Icons.attach_money, color: Color(0xFF0077B6)),
        ),
      ),
    );
  }

  Widget _buildNoteField(TextEditingController controller) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: "Note",
          border: InputBorder.none,
          prefixIcon: Icon(Icons.note, color: Color(0xFF0077B6)),
        ),
      ),
    );
  }

  Widget _buildDialogButtons(
    BuildContext ctx,
    TextEditingController amountController,
    TextEditingController noteController,
    String selectedType,
    String selectedCategory,
  ) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
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
                "date": DateTime.now().toString().substring(0, 10),
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
    );
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
            _buildDetailHandle(),
            const SizedBox(height: 20),
            _buildDetailIcon(isSave, isIncome),
            const SizedBox(height: 12),
            _buildDetailTitle(categoryText, isSave),
            _buildDetailAmount(amountValue, isSave, isIncome),
            const SizedBox(height: 20),
            _buildDetailRow(Icons.calendar_today, 'Date', dateText),
            _buildDetailRow(
              Icons.category,
              'Category',
              categoryText.isEmpty ? '-' : categoryText,
            ),
            _buildDetailRow(
              Icons.attach_money,
              'Type',
              isSave ? 'Save' : (isIncome ? 'Income' : 'Expense'),
            ),
            _buildDetailRow(
              Icons.note,
              'Note',
              noteText.isEmpty ? 'No note' : noteText,
            ),
            const SizedBox(height: 20),
            _buildDetailActions(ctx, item),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildDetailIcon(bool isSave, bool isIncome) {
    return Container(
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
    );
  }

  Widget _buildDetailTitle(String categoryText, bool isSave) {
    return Text(
      categoryText.isEmpty ? 'Save Money' : categoryText,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF0077B6),
      ),
    );
  }

  Widget _buildDetailAmount(double amountValue, bool isSave, bool isIncome) {
    return Text(
      '${isIncome ? '+' : '-'}${formatMMK(amountValue)}',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: isSave
            ? Colors.blue[700]
            : (isIncome ? Colors.green[700] : Colors.red[700]),
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

  Widget _buildDetailActions(BuildContext ctx, Map<String, dynamic> item) {
    return Padding(
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
                showDeleteConfirmation(item['id']?.toString() ?? '');
              },
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
          child: GlassCard(
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
                  const SizedBox(height: 20),
                  _buildTypeDropdown(
                    setDialogState,
                    selectedType,
                    (v) => setDialogState(() => selectedType = v!),
                  ),
                  const SizedBox(height: 12),
                  _buildCategoryDropdown(
                    setDialogState,
                    selectedCategory,
                    (v) => setDialogState(() => selectedCategory = v!),
                  ),
                  const SizedBox(height: 12),
                  _buildAmountField(amountController),
                  const SizedBox(height: 12),
                  _buildNoteField(noteController),
                  const SizedBox(height: 20),
                  _buildEditDialogButtons(
                    ctx,
                    amountController,
                    noteController,
                    selectedType,
                    selectedCategory,
                    itemId,
                    item,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditDialogButtons(
    BuildContext ctx,
    TextEditingController amountController,
    TextEditingController noteController,
    String selectedType,
    String selectedCategory,
    String itemId,
    Map<String, dynamic> item,
  ) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
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
        });
        calculateTotals();
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
      appBar: _buildAppBar(),
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
              _buildBalanceCard(balance),
              _buildMonthYearSelector(years),
              _buildStatsRow(balance),
              _buildPieChart(categoryTotals),
              _buildRecentTransactionsHeader(),
              Expanded(child: _buildTransactionsList()),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF87CEEB), Color(0xFF0077B6)],
          ),
        ),
      ),
      title: const Text('Dashboard'),
      actions: [
        IconButton(
          onPressed: _pullToRefresh,
          icon: isRefreshing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.refresh, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(double balance) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF87CEEB).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Color(0xFF0077B6),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Balance',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0077B6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatMMK(balance),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0077B6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthYearSelector(List<String> years) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedYear,
                  isExpanded: true,
                  dropdownColor: const Color(0xFFE0F7FA),
                  icon: const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF0077B6),
                    size: 18,
                  ),
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
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedMonth,
                  isExpanded: true,
                  dropdownColor: const Color(0xFFE0F7FA),
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xFF0077B6),
                  ),
                  items: List.generate(
                    12,
                    (i) => DropdownMenuItem(
                      value: (i + 1).toString(),
                      child: Text(
                        monthNames[i],
                        style: const TextStyle(
                          color: Color(0xFF0077B6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ).toList(),
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
    );
  }

  Widget _buildStatsRow(double balance) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStatItem(
            'Income',
            formatMMK(totalIncome),
            Colors.green[700]!,
            Icons.arrow_downward,
          ),
          const SizedBox(width: 8),
          _buildStatItem(
            'Expense',
            formatMMK(totalExpense),
            Colors.red[700]!,
            Icons.arrow_upward,
          ),
          const SizedBox(width: 8),
          _buildStatItem(
            'Saved',
            formatMMK(totalSaved),
            Colors.blue[700]!,
            Icons.savings,
          ),
          const SizedBox(width: 8),
          _buildStatItem(
            'Balance',
            formatMMK(balance),
            balance >= 0 ? Colors.green[700]! : Colors.red[700]!,
            Icons.account_balance,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: Colors.grey[700], fontSize: 10),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(Map<String, double> categoryTotals) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
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
    );
  }

  Widget _buildRecentTransactionsHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
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
          AppBadge(text: '${data.length}'),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (isLoading) {
      return const LoadingIndicator();
    }
    return RefreshIndicator(
      onRefresh: _pullToRefresh,
      color: const Color(0xFF87CEEB),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: data.length > 5 ? 5 : data.length,
        itemBuilder: (context, index) {
          var item = data[index];
          return _buildTransactionItem(item);
        },
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> item) {
    bool isIncome = item['type'] == 'income';
    bool isSave = item['type'] == 'save';
    String categoryText = item['category']?.toString() ?? '';
    String dateText = item['date']?.toString() ?? '';
    double amountValue =
        double.tryParse(item['amount']?.toString() ?? '0') ?? 0;

    Color iconColor;
    Color bgColor;
    IconData icon;

    if (isSave) {
      iconColor = Colors.blue[700]!;
      bgColor = Colors.blue[50]!;
      icon = Icons.savings;
    } else if (isIncome) {
      iconColor = Colors.green[700]!;
      bgColor = Colors.green[50]!;
      icon = Icons.arrow_downward;
    } else {
      iconColor = Colors.red[700]!;
      bgColor = Colors.red[50]!;
      icon = Icons.arrow_upward;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        onTap: () => showTransactionDetail(item),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
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
                    isSave ? 'Save Money' : categoryText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0077B6),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    dateText,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : '-'}${formatMMK(amountValue)}',
              style: TextStyle(
                color: isSave
                    ? Colors.blue[700]
                    : (isIncome ? Colors.green[700] : Colors.red[700]),
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
