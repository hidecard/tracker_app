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
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0077B6),
          brightness: Brightness.light,
          primary: const Color(0xFF0077B6),
          secondary: const Color(0xFF87CEEB),
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: const Color(0xFF0077B6),
          onSurface: const Color(0xFF333333),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F9FC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: const Color(0xFF0077B6),
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          elevation: 8,
          selectedItemColor: Color(0xFF0077B6),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0077B6),
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF0077B6)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0077B6), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: Color(0xFF0077B6),
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
          headlineMedium: TextStyle(
            color: Color(0xFF0077B6),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
          titleLarge: TextStyle(
            color: Color(0xFF0077B6),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          titleMedium: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          bodyLarge: TextStyle(color: Color(0xFF333333), fontSize: 16),
          bodyMedium: TextStyle(color: Color(0xFF666666), fontSize: 14),
          bodySmall: TextStyle(color: Color(0xFF999999), fontSize: 12),
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
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0077B6).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
              _buildNavItem(
                1,
                Icons.receipt_long_outlined,
                Icons.receipt_long_rounded,
                'Transactions',
              ),
              _buildCenterAddButton(context),
              _buildNavItem(
                2,
                Icons.pie_chart_outline_rounded,
                Icons.pie_chart_rounded,
                'Summary',
              ),
              _buildNavItem(
                3,
                Icons.savings_outlined,
                Icons.savings_rounded,
                'Save',
              ),
            ],
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
    return InkWell(
      onTap: () => setCurrentIndex(index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? const Color(0xFF0077B6).withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? const Color(0xFF0077B6) : Colors.grey[500],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF0077B6) : Colors.grey[500],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 11,
              ),
            ),
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
              blurRadius: 12,
              offset: const Offset(0, 4),
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
