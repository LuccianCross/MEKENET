// This is the MAIN file - it starts the app and connects everything

import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/quick_add_screen.dart';
import 'screens/debts_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/bottom_nav_bar.dart';
import 'repositories/mock_transaction_repository.dart';

void main() {
  runApp(const MyApp());  // This starts the app
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mekenet',
      theme: ThemeData(
        primarySwatch: Colors.green,  // Green theme
        useMaterial3: true,
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,  // Remove debug banner
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Which tab is selected (0=Home, 1=Add, 2=Debts, 3=Settings)
  int _currentIndex = 0;
  
  // Create the mock repository (fake data)
  final mockRepo = MockTransactionRepository();

  // List of screens that match the bottom nav tabs
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Create the 4 screens
    _screens = [
      HomeScreen(repository: mockRepo),  // Tab 0: Home
      const QuickAddScreen(),            // Tab 1: Add
      DebtsScreen(repository: mockRepo), // Tab 2: Debts
      const SettingsScreen(),            // Tab 3: Settings
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Show the selected screen
      body: _screens[_currentIndex],
      
      // Bottom navigation bar
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;  // Switch to selected tab
          });
        },
      ),
    );
  }
}