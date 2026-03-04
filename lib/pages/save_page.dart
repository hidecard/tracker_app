import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/glass_card.dart';
import '../widgets/common_components.dart';

class SavePage extends StatefulWidget {
  final VoidCallback? onAddPressed;

  const SavePage({super.key, this.onAddPressed});

  @override
  State<SavePage> createState() => SavePageState();
}

class SavePageState extends State<SavePage> {
  final String url =
      "https://script.google.com/macros/s/AKfycbx2grg3odTkT7KlCvjiUzCH80jXLsrZX2gnFDCntu2FQpW5ko4urwJkn8fd81cBOOKmpA/exec";

  List data = [];
  List cachedData = [];
  String selectedMonth = DateTime.now().month.toString();
  String selectedYear = DateTime.now().year.toString();

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
        showMessage('Save record deleted successfully');
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
        showMessage('Save record updated successfully');
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
        showMessage('Save record added successfully');
      }
    } catch (_) {}
  }

  void showAddForm() {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();

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
                    'Save Money',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0077B6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  _buildDatePicker(
                    selectedDate,
                    setDialogState,
                    (date) => setDialogState(() => selectedDate = date),
                  ),
                  const SizedBox(height: 12),
                  _buildAmountField(amountController),
                  const SizedBox(height: 12),
                  _buildNoteField(noteController),
                  const SizedBox(height: 20),
                  _buildDialogButtons(
                    ctx,
                    amountController,
                    noteController,
                    selectedDate,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(
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
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
    DateTime selectedDate,
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
                "date": selectedDate.toString().substring(0, 10),
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
    );
  }

  void showTransactionDetail(Map<String, dynamic> item) {
    String dateText = item['date']?.toString() ?? '';
    String noteText = item['note']?.toString() ?? '';
    double amountValue =
        double.tryParse(item['amount']?.toString() ?? '0') ?? 0;

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
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.savings, color: Colors.blue[700], size: 32),
            ),
            const SizedBox(height: 12),
            const Text(
              'Save Money',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0077B6),
              ),
            ),
            Text(
              '-${formatMMK(amountValue)}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(height: 20),
            _buildDetailRow(Icons.calendar_today, 'Date', dateText),
            _buildDetailRow(
              Icons.attach_money,
              'Amount',
              formatMMK(amountValue),
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
        title: const Text('Delete Save Record'),
        content: const Text(
          'Are you sure you want to delete this save record?',
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
          child: GlassCard(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Edit Save Entry',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0077B6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  _buildDatePicker(
                    selectedDate,
                    setDialogState,
                    (date) => setDialogState(() => selectedDate = date),
                  ),
                  const SizedBox(height: 12),
                  _buildAmountField(amountController),
                  const SizedBox(height: 12),
                  _buildNoteField(noteController),
                  const SizedBox(height: 20),
                  _buildEditDialogButtons(
                    ctx,
                    item['id']?.toString() ?? '',
                    amountController,
                    noteController,
                    selectedDate,
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
    String itemId,
    TextEditingController amountController,
    TextEditingController noteController,
    DateTime selectedDate,
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
                "date": selectedDate.toString().substring(0, 10),
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
      if (item['type'] != 'save') return false;
      try {
        DateTime date = DateTime.parse(item['date'] ?? '');
        return date.month.toString() == selectedMonth &&
            date.year.toString() == selectedYear;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  double get totalSaved {
    double total = 0;
    for (var item in filteredData) {
      total += double.tryParse(item['amount']?.toString() ?? '0') ?? 0;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    int currentYear = DateTime.now().year;
    List<String> years = List.generate(
      5,
      (index) => (currentYear - 2 + index).toString(),
    );

    return Scaffold(
      appBar: _buildAppBar(),
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
              _buildHeader(years),
              _buildSavedHeader(),
              Expanded(child: _buildSavedList()),
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
      title: const Text('Saved Records', style: TextStyle(color: Colors.white)),
    );
  }

  Widget _buildHeader(List<String> years) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Save Records",
                    style: TextStyle(
                      fontSize: 18,
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
                      : const Icon(Icons.refresh, color: Color(0xFF0077B6)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildYearDropdown(years)),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: _buildMonthDropdown()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearDropdown(List<String> years) {
    return GlassCard(
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
          onChanged: (v) {
            selectedYear = v!;
            setState(() {});
          },
        ),
      ),
    );
  }

  Widget _buildMonthDropdown() {
    return GlassCard(
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
                monthNames[i],
                style: const TextStyle(color: Color(0xFF0077B6)),
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

  Widget _buildSavedHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text(
            'Saved Records',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0077B6),
            ),
          ),
          const Spacer(),
          AppBadge(text: '${filteredData.length}'),
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
    );
  }

  Widget _buildSavedList() {
    if (isLoading) return const LoadingIndicator();
    return RefreshIndicator(
      onRefresh: _pullToRefresh,
      color: const Color(0xFF87CEEB),
      child: filteredData.isEmpty
          ? const EmptyState(
              icon: Icons.savings_outlined,
              title: 'No saved records',
              subtitle: 'Start saving money to see your records here',
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredData.length + 1,
              itemBuilder: (context, index) {
                if (index == filteredData.length) return _buildTotalCard();
                return _buildSaveItem(filteredData[index]);
              },
            ),
    );
  }

  Widget _buildTotalCard() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.savings, color: Colors.blue[700], size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Saved',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0077B6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      formatMMK(totalSaved),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
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

  Widget _buildSaveItem(Map<String, dynamic> item) {
    String noteText = item['note']?.toString() ?? '';
    double amountValue =
        double.tryParse(item['amount']?.toString() ?? '0') ?? 0;
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
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.savings, color: Colors.blue[700], size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Save Money',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0077B6),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    noteText.isNotEmpty
                        ? '${item['date']} • ${noteText.length > 15 ? '${noteText.substring(0, 15)}...' : noteText}'
                        : (item['date'] ?? ''),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              '-${formatMMK(amountValue)}',
              style: TextStyle(
                color: Colors.blue[700],
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
              onPressed: () =>
                  showDeleteConfirmation(item['id']?.toString() ?? ''),
            ),
          ],
        ),
      ),
    );
  }
}
