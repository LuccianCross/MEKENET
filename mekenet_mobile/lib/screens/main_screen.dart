import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'debts_screen.dart';
import 'quick_add_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    DebtsScreen(),
    QuickAddScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,

        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },

        backgroundColor: Colors.white,

        indicatorColor:
            const Color(0xFF0A8E48).withValues(alpha: 0.15),

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(
              Icons.home,
              color: Color(0xFF0A8E48),
            ),
            label: 'Home',
          ),

          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(
              Icons.people,
              color: Color(0xFF0A8E48),
            ),
            label: 'Debts',
          ),

          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(
              Icons.add_circle,
              color: Color(0xFF0A8E48),
            ),
            label: 'Quick Add',
          ),

          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(
              Icons.settings,
              color: Color(0xFF0A8E48),
            ),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}