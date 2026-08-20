import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'database/database_helper.dart';
import 'repositories/repository_provider.dart';

import 'screens/onboarding_screen.dart';
import 'screens/pin_screen.dart';
import 'screens/home_screen.dart';
import 'screens/quick_add_screen.dart';
import 'screens/debts_screen.dart';
import 'screens/settings_screen.dart';
import 'services/sync_service.dart';
import 'services/sms/sms_listener.dart';
import 'widgets/bottom_nav_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await DatabaseHelper.instance.database;
    RepositoryProvider.useReal();
  } catch (e) {
    debugPrint('Database initialization error: $e');
  }

  await SyncService.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mekenet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0A5C36),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF0A5C36),
          secondary: Color(0xFF1B7A4A),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A5C36),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      home: const StartupScreen(),
    );
  }
}

class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key});

  Future<bool> _hasPin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('has_pin') ?? false;
    } catch (e) {
      debugPrint('Could not read PIN setting: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasPin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0A8E48),
              ),
            ),
          );
        }

        if (snapshot.data == true) {
          return const PinSetupScreen();
        }

        return const OnboardingScreen();
      },
    );
  }
}

// ========== MainScreen ==========
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

    // Initialize SMS listener AFTER UI is ready
    SmsListener.instance.initialize();
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