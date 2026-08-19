import 'package:flutter/material.dart';

import '../repositories/repository_provider.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/debt_repository.dart';

import '../widgets/bottom_nav_bar.dart';
import 'home_screen.dart';
import 'quick_add_screen.dart';
import 'debts_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  final TransactionRepository transactionRepository;
  final DebtRepository debtRepository;

  const MainScreen({
    super.key,
    required this.transactionRepository,
    required this.debtRepository,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _screens = [
      HomeScreen(
        transactionRepository: widget.transactionRepository,
        debtRepository: widget.debtRepository,
      ),
      QuickAddScreen(
        transactionRepository: widget.transactionRepository,
        debtRepository: widget.debtRepository,
      ),
      DebtsScreen(
        transactionRepository: widget.transactionRepository,
        debtRepository: widget.debtRepository,
      ),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}