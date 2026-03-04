import 'dart:ui';
import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'pages/transactions_page.dart';
import 'pages/summary_page.dart';
import 'pages/save_page.dart';

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

  final GlobalKey<HomePageState> _homeKey = GlobalKey<HomePageState>();
  final GlobalKey<TransactionsPageState> _transactionsKey =
      GlobalKey<TransactionsPageState>();
  final GlobalKey<SavePageState> _saveKey = GlobalKey<SavePageState>();
  final GlobalKey<SummaryPageState> _summaryKey = GlobalKey<SummaryPageState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(key: _homeKey),
      TransactionsPage(key: _transactionsKey),
      SummaryPage(key: _summaryKey),
      SavePage(key: _saveKey),
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
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
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
        width: 56,
        height: 56,
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
          child: Icon(Icons.add, color: Colors.white, size: 28),
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
