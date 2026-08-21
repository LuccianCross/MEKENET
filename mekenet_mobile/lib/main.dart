import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'database/database_helper.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/quick_add_screen.dart';
import 'screens/debts_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/pin_screen.dart';
import 'services/sync_service.dart';
import 'services/sms/sms_listener.dart';
import 'widgets/bottom_nav_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseHelper.instance.database;

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
      home: const StartupScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  static const _secureStorage = FlutterSecureStorage();
  bool _checking = true;
  bool _hasPin = false;

  @override
  void initState() {
    super.initState();
    _checkPin();
  }

  Future<void> _checkPin() async {
    final hasPin = await _secureStorage.read(key: 'mekenet_has_pin') == 'true';
    if (mounted) {
      setState(() {
        _hasPin = hasPin;
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0A8E48)),
        ),
      );
    }

    if (_hasPin) {
      return const PinScreen();
    }

    return const OnboardingScreen();
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

    // Initialize SMS listener AFTER UI is ready (Activity exists for permission dialog)
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
