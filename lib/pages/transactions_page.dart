import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/common_components.dart';

class TransactionsPage extends StatefulWidget {
  final String? forcedType;
  final VoidCallback? onAddPressed;

  const TransactionsPage({super.key, this.forcedType, this.onAddPressed});

  @override
  State<TransactionsPage> createState() => TransactionsPageState();
}

class TransactionsPageState extends State<TransactionsPage> {
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
      }
    } catch (_) {}
  }

  void showAddForm() {
    if (widget.forcedType == 'save') {
      _showSaveAddForm();
      return;
    }
    _showTransactionAddForm();
  }

  void _showSaveAddForm() {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();

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
                  'Save Money',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0077B6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildDatePickerNew(selectedDate, setDialogState, (date) {
                  setDialogState(() => selectedDate = date);
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
                  selectedDate,
                  isSave: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTransactionAddForm() {
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
                _buildTypeSelectorNew(
                  setDialogState,
                  selectedType,
                  (v) => setDialogState(() => selectedType = v!),
                ),
                const SizedBox(height: 16),
                _buildCategorySelectorNew(
                  setDialogState,
                  selectedCategory,
                  (v) => setDialogState(() => selectedCategory = v!),
                ),
                const SizedBox(height: 16),
                _buildAmountFieldNew(amountController),
                const SizedBox(height: 16),
                _buildNoteFieldNew(noteController),
                const SizedBox(height: 24),
                _buildDialogButtons(
                  ctx,
                  amountController,
                  noteController,
                  DateTime.now(),
                  selectedType: selectedType,
                  selectedCategory: selectedCategory,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerNew(
    DateTime selectedDate,
    StateSetter setDialogState,
    Function(DateTime) onDateSelected,
  ) {
    return GestureDetector(
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
        if (picked != null) onDateSelected(picked);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F9FC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
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
            const Icon(Icons.arrow_drop_down, color: Color(0xFF0077B6)),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelectorNew(
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

  Widget _buildCategorySelectorNew(
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
    DateTime selectedDate, {
    bool isSave = false,
    String? selectedType,
    String? selectedCategory,
  }) {
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
                "date": selectedDate.toString().substring(0, 10),
                "type": isSave ? 'save' : selectedType,
                "category": isSave ? '' : selectedCategory,
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
                        showDeleteConfirmation(item['id']?.toString() ?? '');
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
    if (widget.forcedType == 'save') {
      _showSaveEditForm(item);
      return;
    }
    _showTransactionEditForm(item);
  }

  void _showSaveEditForm(Map<String, dynamic> item) {
    final TextEditingController amountController = TextEditingController(
      text: item['amount']?.toString() ?? '',
    );
    final TextEditingController noteController = TextEditingController(
      text: item['note']?.toString() ?? '',
    );
    DateTime selectedDate;
    try {
      selectedDate = DateTime.parse(item['date']?.toString() ?? '');
    } catch (_) {
      selectedDate = DateTime.now();
    }

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
                  'Edit Save Entry',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0077B6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildDatePickerNew(
                  selectedDate,
                  setDialogState,
                  (date) => setDialogState(() => selectedDate = date),
                ),
                const SizedBox(height: 16),
                _buildAmountFieldNew(amountController),
                const SizedBox(height: 16),
                _buildNoteFieldNew(noteController),
                const SizedBox(height: 24),
                _buildEditDialogButtons(
                  ctx,
                  item['id']?.toString() ?? '',
                  amountController,
                  noteController,
                  selectedDate,
                  isSave: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTransactionEditForm(Map<String, dynamic> item) {
    final TextEditingController amountController = TextEditingController(
      text: item['amount']?.toString() ?? '',
    );
    final TextEditingController noteController = TextEditingController(
      text: item['note']?.toString() ?? '',
    );
    String selectedType = item['type']?.toString() ?? 'expense';
    String selectedCategory = item['category']?.toString() ?? 'Food';

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
                  'Edit Transaction',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0077B6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildTypeSelectorNew(
                  setDialogState,
                  selectedType,
                  (v) => setDialogState(() => selectedType = v!),
                ),
                const SizedBox(height: 16),
                _buildCategorySelectorNew(
                  setDialogState,
                  selectedCategory,
                  (v) => setDialogState(() => selectedCategory = v!),
                ),
                const SizedBox(height: 16),
                _buildAmountFieldNew(amountController),
                const SizedBox(height: 16),
                _buildNoteFieldNew(noteController),
                const SizedBox(height: 24),
                _buildEditDialogButtons(
                  ctx,
                  item['id']?.toString() ?? '',
                  amountController,
                  noteController,
                  DateTime.now(),
                  selectedType: selectedType,
                  selectedCategory: selectedCategory,
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
    String itemId,
    TextEditingController amountController,
    TextEditingController noteController,
    DateTime selectedDate, {
    bool isSave = false,
    String? selectedType,
    String? selectedCategory,
  }) {
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
                "date": selectedDate.toString().substring(0, 10),
                "type": isSave ? 'save' : selectedType,
                "category": isSave ? '' : selectedCategory,
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
    if (widget.forcedType != null) selectedType = widget.forcedType!;
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
        bool typeMatch;
        if (widget.forcedType != null) {
          typeMatch = item['type'] == widget.forcedType;
        } else {
          typeMatch = selectedType == 'all'
              ? item['type'] != 'save'
              : item['type'] == selectedType;
        }
        return monthMatch && typeMatch;
      } catch (_) {
        return false;
      }
    }).toList();
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
      backgroundColor: const Color(0xFFF5F9FC),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(years),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (widget.forcedType == null) _buildTypeFilterDropdown(),
                  const SizedBox(height: 12),
                  _buildTransactionsHeader(filtered.length),
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
          else if (filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No transactions found',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add a new transaction to get started',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index == filtered.length) return _buildSummaryCard();
                  return _buildTransactionItem(filtered[index]);
                }, childCount: filtered.length + 1),
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
        title: Text(
          widget.forcedType == 'save' ? 'Saved Records' : 'All Transactions',
          style: const TextStyle(
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
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(70),
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
          child: Row(
            children: [
              Expanded(child: _buildYearDropdown(years)),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: _buildMonthDropdown()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYearDropdown(List<String> years) {
    return Container(
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
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0077B6)),
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
          onChanged: (v) {
            selectedYear = v!;
            setState(() {});
          },
        ),
      ),
    );
  }

  Widget _buildMonthDropdown() {
    return Container(
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
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0077B6)),
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
          onChanged: (v) {
            selectedMonth = v!;
            setState(() {});
          },
        ),
      ),
    );
  }

  Widget _buildTypeFilterDropdown() {
    return Container(
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
          value: selectedType,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0077B6)),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All Types')),
            DropdownMenuItem(value: 'income', child: Text('Income')),
            DropdownMenuItem(value: 'expense', child: Text('Expense')),
          ],
          onChanged: (v) {
            selectedType = v!;
            setState(() {});
          },
        ),
      ),
    );
  }

  Widget _buildTransactionsHeader(int count) {
    return Row(
      children: [
        Text(
          widget.forcedType == 'save' ? 'Saved Records' : 'Transactions',
          style: const TextStyle(
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
            '$count',
            style: const TextStyle(
              color: Color(0xFF0077B6),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    double monthIncome = 0, monthExpense = 0, monthSaved = 0;
    for (var item in data) {
      try {
        DateTime date = DateTime.parse(item['date'] ?? '');
        if (date.month.toString() == selectedMonth &&
            date.year.toString() == selectedYear) {
          String type = item['type'] ?? '';
          double amount =
              double.tryParse(item['amount']?.toString() ?? '0') ?? 0;
          if (type == 'income')
            monthIncome += amount;
          else if (type == 'expense')
            monthExpense += amount;
          else if (type == 'save')
            monthSaved += amount;
        }
      } catch (_) {}
    }
    double monthBalance = monthIncome - monthExpense - monthSaved;
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(20),
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
                    Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryItem(
                    'Expense',
                    formatMMK(monthExpense),
                    Icons.arrow_upward,
                    Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Saved',
                    formatMMK(monthSaved),
                    Icons.savings,
                    Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryItem(
                    'Balance',
                    formatMMK(monthBalance),
                    Icons.account_balance_wallet,
                    monthBalance >= 0 ? Colors.white : Colors.red[200]!,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color.withOpacity(0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
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

  Widget _buildTransactionItem(Map<String, dynamic> item) {
    bool isIncome = item['type'] == 'income';
    bool isSave = item['type'] == 'save';
    String noteText = item['note']?.toString() ?? '';
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
                      isSave ? 'Save Money' : (item['category'] ?? ''),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      noteText.isNotEmpty
                          ? '${item['date']} • ${noteText.length > 15 ? '${noteText.substring(0, 15)}...' : noteText}'
                          : (item['date'] ?? ''),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.red[300],
                  size: 20,
                ),
                onPressed: () =>
                    showDeleteConfirmation(item['id']?.toString() ?? ''),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
