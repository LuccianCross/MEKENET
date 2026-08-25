import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geez_fonts/geez_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'database/database_helper.dart';
import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/quick_add_screen.dart';
import 'screens/debts_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/pin_screen.dart';
import 'services/sync_service.dart';
import 'services/sms/sms_listener.dart';
import 'widgets/bottom_nav_bar.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseHelper.instance.database;

  await SyncService.instance.initialize();

  // Load saved language
  final prefs = await SharedPreferences.getInstance();
  final savedLang = prefs.getString('app_language') ?? 'en';

  runApp(MyMekenet(initialLocale: savedLang));
}

class MyMekenet extends StatefulWidget {
  final String initialLocale;

  const MyMekenet({super.key, required this.initialLocale});

  static MyMekenetState? of(BuildContext context) =>
      context.findAncestorStateOfType<MyMekenetState>();

  @override
  State<MyMekenet> createState() => MyMekenetState();
}

class MyMekenetState extends State<MyMekenet> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = Locale(widget.initialLocale);
  }

  void setLocale(String langCode) {
    setState(() {
      _locale = Locale(langCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Mekenet',
      locale: _locale,
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
          textTheme: _locale.languageCode == 'am'
              ? GeezFonts.benaiahTextTheme(
                  ThemeData(useMaterial3: true).textTheme,
                )
              : null,
        ),
      home: const StartupScreen(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('am'),
      ],
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
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo.jpg',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(color: Color(0xFF0A8E48)),
            ],
          ),
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

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final Set<int> _visitedTabs = {0};
  StreamSubscription<void>? _smsSub;
  Timer? _smsSnackDebounce;
  int _pendingTxCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Defer SMS setup until after the home UI's first frame so the
    // PIN -> home transition isn't blocked by permission checks,
    // inbox reading, and per-message DB work.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () async {
        if (!mounted) return;
        await SmsListener.instance.initialize();
        if (!mounted) return;
        if (SmsListener.inboxImportState.value ==
            InboxImportState.notAsked) {
          _showInboxConsentDialog();
        }
      });
    });

    _smsSub = SmsListener.instance.onTransactionAdded.listen((_) {
      if (!mounted) return;
      _pendingTxCount++;
      _smsSnackDebounce?.cancel();
      _smsSnackDebounce = Timer(const Duration(milliseconds: 800), () {
        if (!mounted || _pendingTxCount == 0) return;
        final count = _pendingTxCount;
        _pendingTxCount = 0;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                count == 1
                    ? 'New transaction recorded'
                    : '$count new transactions recorded',
              ),
              backgroundColor: const Color(0xFF0A8E48),
              duration: const Duration(seconds: 2),
            ),
          );
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SyncService.instance.retryUnsynced();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _smsSub?.cancel();
    _smsSnackDebounce?.cancel();
    super.dispose();
  }

  /// One-time, one-tap choice: import past transactions from the SMS
  /// inbox, or only track new messages from now on.
  void _showInboxConsentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Read your SMS history?'),
          content: const Text(
            'Mekenet can read your bank SMS inbox once to rebuild your past '
            'transactions.\n\nIf you skip, we only track new SMS from now '
            'on. You can change this later in Settings.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                SmsListener.instance.setInboxConsent(false);
              },
              child: const Text('No, just new ones'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                SmsListener.instance.setInboxConsent(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0A8E48),
              ),
              child: const Text('Yes, import history'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const screens = [
      HomeScreen(),
      QuickAddScreen(),
      DebtsScreen(),
      SettingsScreen(),
    ];
    return Scaffold(
      // Lazy tabs: each screen is built on first visit (kept alive with
      // Offstage afterwards) instead of all four initializing at once.
      body: Stack(
        children: [
          for (var i = 0; i < screens.length; i++)
            if (_visitedTabs.contains(i))
              Offstage(
                offstage: i != _currentIndex,
                child: screens[i],
              ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _visitedTabs.add(index);
          });
        },
      ),
    );
  }
}
