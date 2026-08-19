import 'package:flutter/material.dart';

import 'database/database_helper.dart';
import 'screens/home_screen.dart';
import 'screens/quick_add_screen.dart';
import 'screens/debts_screen.dart';
import 'screens/settings_screen.dart';
import 'services/sync_service.dart';
import 'widgets/bottom_nav_bar.dart';
import 'services/sms/sms_listener.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseHelper.instance.database;

  final smsListener = SmsListener();
  await smsListener.initialize();

  await SyncService.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mekenet',
      theme: ThemeData(
        primaryColor: const Color(0xFF0A8E48),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A8E48),
          primary: const Color(0xFF0A8E48),
          secondary: const Color(0xFFE8F5E9),
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A8E48),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _screens = const [
      HomeScreen(),
      QuickAddScreen(),
      DebtsScreen(),
      SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
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
