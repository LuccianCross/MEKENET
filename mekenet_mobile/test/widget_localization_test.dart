import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mekenet/l10n/l10n.dart';
import 'package:mekenet/widgets/bottom_nav_bar.dart';
import 'package:mekenet/screens/onboarding_screen.dart';
import 'package:mekenet/screens/quick_add_screen.dart';

Widget createTestApp(WidgetBuilder builder) {
  return ListenableBuilder(
    listenable: L10n.instance,
    builder: (context, _) {
      return MaterialApp(
        key: ValueKey(L10n.instance.currentLanguageCode),
        locale: L10n.instance.currentLocale,
        supportedLocales: const [
          Locale('en'),
          Locale('am'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(builder: builder),
      );
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await L10n.instance.init();
    await L10n.instance.setLocale('en');
  });

  group('Widget Localization & Dynamic Reactivity Tests', () {
    testWidgets('BottomNavBar updates dynamically on language toggle', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          (context) => Scaffold(
            bottomNavigationBar: BottomNavBar(
              currentIndex: 0,
              onTap: (_) {},
            ),
          ),
        ),
      );

      // In English
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
      expect(find.text('Debts'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Switch to Amharic
      await L10n.instance.setLocale('am');
      await tester.pumpAndSettle();

      // In Amharic
      expect(find.text('መነሻ'), findsOneWidget);
      expect(find.text('አክል'), findsOneWidget);
      expect(find.text('ዕዳዎች'), findsOneWidget);
      expect(find.text('ቅንብሮች'), findsOneWidget);

      // Switch back to English
      await L10n.instance.setLocale('en');
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('OnboardingScreen renders localized content and reacts to locale change', (tester) async {
      await tester.pumpWidget(
        createTestApp((context) => const OnboardingScreen()),
      );

      // In English
      expect(find.text('My Money Record'), findsOneWidget);
      expect(find.text('Your daily money record, automatically'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);

      // Switch to Amharic
      await L10n.instance.setLocale('am');
      await tester.pumpAndSettle();

      // In Amharic
      expect(find.text('የገንዘብ መዝገቤ'), findsOneWidget);
      expect(find.text('የዕለት ተዕለት የገንዘብ መዝገብዎ በራስ-ሰር ይያዛል'), findsOneWidget);
      expect(find.text('ቀጣይ'), findsOneWidget);
      expect(find.text('እለፍ'), findsOneWidget);

      // Switch back to English
      await L10n.instance.setLocale('en');
      await tester.pumpAndSettle();

      expect(find.text('My Money Record'), findsOneWidget);
    });

    testWidgets('QuickAddScreen renders translated labels and chips', (tester) async {
      await tester.pumpWidget(
        createTestApp((context) => const QuickAddScreen()),
      );

      // In English
      expect(find.text('Add Expense'), findsOneWidget);
      expect(find.text('Amount (Br)'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Supplies'), findsOneWidget);
      expect(find.text('Rent'), findsOneWidget);
      expect(find.text('Save Expense'), findsOneWidget);

      // Switch to Amharic
      await L10n.instance.setLocale('am');
      await tester.pumpAndSettle();

      // In Amharic
      expect(find.text('ወጪ አክል'), findsOneWidget);
      expect(find.text('መጠን (ብር)'), findsOneWidget);
      expect(find.text('ምድብ'), findsOneWidget);
      expect(find.text('አቅርቦቶች'), findsOneWidget);
      expect(find.text('ኪራይ'), findsOneWidget);
      expect(find.text('ወጪ አስቀምጥ'), findsOneWidget);
    });
  });
}
