import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import '../widgets/glass_card.dart';
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
        backgroundColor: isError ? Colors.red[400] : const Color(0xFF0077B6),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: StatefulBuilder(
          builder: (context, setDialogState) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Add Transaction',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0077B6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildTypeSelector(setDialogState, selectedType, (v) {
                  setDialogState(() => selectedType = v!);
                }),
                const SizedBox(height: 16),
                _buildCategorySelector(setDialogState, selectedCategory, (v) {
                  setDialogState(() => selectedCategory = v!);
                }),
                const SizedBox(height: 16),
                _buildAmountFieldNew(amountController),
                const SizedBox(height: 16),
                _buildNoteFieldNew(noteController),
                const SizedBox(height: 24),
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
    );
  }

  Widget _buildTypeSelector(
    StateSetter setDialogState,
    String selectedType,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9FC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeOption(
              'expense',
              'Expense',
              Icons.arrow_upward,
              Colors.red[400]!,
              selectedType == 'expense',
              () => onChanged('expense'),
            ),
          ),
          Expanded(
            child: _buildTypeOption(
              'income',
              'Income',
              Icons.arrow_downward,
              Colors.green[400]!,
              selectedType == 'income',
              () => onChanged('income'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeOption(
    String value,
    String label,
    IconData icon,
    Color color,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector(
    StateSetter setDialogState,
    String selectedCategory,
    Function(String?) onChanged,
  ) {
    final categories = [
      'Food',
      'Rent',
      'Bill',
      'Shopping',
      'Transport',
      'Entertainment',
      'Health',
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        bool isSelected = selectedCategory == cat;
        return GestureDetector(
          onTap: () => onChanged(cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF0077B6)
                  : const Color(0xFFF5F9FC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? const Color(0xFF0077B6) : Colors.grey[300]!,
              ),
            ),
            child: Text(
              cat,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAmountFieldNew(TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Color(0xFF0077B6),
      ),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: '0',
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 24),
        labelText: 'Amount (MMK)',
        labelStyle: const TextStyle(color: Color(0xFF0077B6)),
        prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF0077B6)),
      ),
    );
  }

  Widget _buildNoteFieldNew(TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Note (optional)',
        labelStyle: TextStyle(color: Color(0xFF0077B6)),
        prefixIcon: Icon(Icons.note, color: Color(0xFF0077B6)),
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
          child: OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0077B6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
            child: const Text(
              "Add",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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

    Color accentColor = isSave
        ? Colors.blue
        : (isIncome ? Colors.green : Colors.red);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSave
                    ? Icons.savings
                    : (isIncome ? Icons.arrow_downward : Icons.arrow_upward),
                color: accentColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              categoryText.isEmpty ? 'Save Money' : categoryText,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0077B6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${isIncome ? '+' : '-'}${formatMMK(amountValue)}',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 24),
            _buildDetailRow(Icons.calendar_today, 'Date', dateText),
            _buildDetailRow(
              Icons.category,
              'Category',
              categoryText.isEmpty ? '-' : categoryText,
            ),
            _buildDetailRow(
              Icons.money,
              'Type',
              isSave ? 'Save' : (isIncome ? 'Income' : 'Expense'),
            ),
            _buildDetailRow(
              Icons.note,
              'Note',
              noteText.isEmpty ? 'No note' : noteText,
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0077B6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
                        backgroundColor: Colors.red[400],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
          Icon(icon, size: 20, color: const Color(0xFF0077B6)),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: Colors.grey[600])),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[400]),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: StatefulBuilder(
          builder: (context, setDialogState) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Edit Transaction",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0077B6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildTypeSelector(setDialogState, selectedType, (v) {
                  setDialogState(() => selectedType = v!);
                }),
                const SizedBox(height: 16),
                _buildCategorySelector(setDialogState, selectedCategory, (v) {
                  setDialogState(() => selectedCategory = v!);
                }),
                const SizedBox(height: 16),
                _buildAmountFieldNew(amountController),
                const SizedBox(height: 16),
                _buildNoteFieldNew(noteController),
                const SizedBox(height: 24),
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
          child: OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0077B6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
            child: const Text(
              "Update",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
      backgroundColor: const Color(0xFFF5F9FC),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBalanceCard(balance),
                  const SizedBox(height: 16),
                  _buildMonthYearSelector(years),
                  const SizedBox(height: 16),
                  _buildStatsRow(balance),
                  const SizedBox(height: 16),
                  _buildLineChart(),
                  const SizedBox(height: 24),
                  _buildRecentTransactionsHeader(),
                ],
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
                  if (index >= data.length || index >= 5) return null;
                  return _buildTransactionItem(data[index]);
                }, childCount: data.length > 5 ? 5 : data.length),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF0077B6),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const Text(
          'Dashboard',
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
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
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
        ),
      ],
    );
  }

  Widget _buildBalanceCard(double balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF87CEEB), Color(0xFF0077B6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0077B6).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  monthNames[int.parse(selectedMonth) - 1],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Current Balance',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            formatMMK(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthYearSelector(List<String> years) {
    return Row(
      children: [
        Expanded(
          child: Container(
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
                      (year) => DropdownMenuItem(
                        value: year,
                        child: Text(
                          year,
                          style: const TextStyle(
                            color: Color(0xFF0077B6),
                            fontWeight: FontWeight.w600,
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
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Container(
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
                      monthNames[i],
                      style: const TextStyle(
                        color: Color(0xFF0077B6),
                        fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildStatsRow(double balance) {
    return Row(
      children: [
        _buildStatItem(
          'Income',
          formatMMK(totalIncome),
          Colors.green[400]!,
          Icons.arrow_downward,
        ),
        const SizedBox(width: 8),
        _buildStatItem(
          'Expense',
          formatMMK(totalExpense),
          Colors.red[400]!,
          Icons.arrow_upward,
        ),
        const SizedBox(width: 8),
        _buildStatItem(
          'Saved',
          formatMMK(totalSaved),
          Colors.blue[400]!,
          Icons.savings,
        ),
        const SizedBox(width: 8),
        _buildStatItem(
          'Balance',
          formatMMK(balance),
          balance >= 0 ? Colors.green[400]! : Colors.red[400]!,
          Icons.account_balance,
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
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
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
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

  // Get weekly expense data for line chart
  List<double> getWeeklyExpenses() {
    List<double> weeklyData = List.filled(4, 0);
    for (var item in data) {
      try {
        DateTime date = DateTime.parse(item['date'] ?? '');
        if (date.month.toString() == selectedMonth &&
            date.year.toString() == selectedYear) {
          if (item['type'] == 'expense') {
            double amt =
                double.tryParse(item['amount']?.toString() ?? '0') ?? 0;
            int week = (date.day - 1) ~/ 7;
            if (week < 4) weeklyData[week] += amt;
          }
        }
      } catch (_) {}
    }
    return weeklyData;
  }

  Widget _buildLineChart() {
    List<double> weeklyData = getWeeklyExpenses();

    return Container(
      height: 200,
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
      child: weeklyData.every((e) => e == 0)
          ? const Center(
              child: Text(
                'No expenses',
                style: TextStyle(color: Color(0xFF0077B6)),
              ),
            )
          : BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: weeklyData.reduce((a, b) => a > b ? a : b) * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: const Color(0xFF0077B6),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${formatMMK(rod.toY)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        const titles = ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            titles[value.toInt()],
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval:
                      weeklyData.reduce((a, b) => a > b ? a : b) / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey[200]!, strokeWidth: 1);
                  },
                ),
                barGroups: weeklyData.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value,
                        color: const Color(0xFF0077B6),
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: weeklyData.reduce((a, b) => a > b ? a : b) * 1.2,
                          color: Colors.grey[100]!,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
    );
  }

  Widget _buildRecentTransactionsHeader() {
    return Row(
      children: [
        const Text(
          'Recent Transactions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0077B6),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF0077B6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${data.length}',
            style: const TextStyle(
              color: Color(0xFF0077B6),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
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
      iconColor = Colors.blue;
      bgColor = Colors.blue.withOpacity(0.1);
      icon = Icons.savings;
    } else if (isIncome) {
      iconColor = Colors.green;
      bgColor = Colors.green.withOpacity(0.1);
      icon = Icons.arrow_downward;
    } else {
      iconColor = Colors.red;
      bgColor = Colors.red.withOpacity(0.1);
      icon = Icons.arrow_upward;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => showTransactionDetail(item),
        borderRadius: BorderRadius.circular(16),
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
                      isSave ? 'Save Money' : categoryText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateText,
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
      ),
    );
  }
}
