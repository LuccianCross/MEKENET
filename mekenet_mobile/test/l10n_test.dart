import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mekenet/l10n/l10n.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await L10n.instance.init();
  });

  group('L10n Localization Service Tests', () {
    test('Defaults to English locale', () {
      expect(L10n.instance.currentLanguageCode, 'en');
      expect(L10n.instance.isAmharic, isFalse);
      expect(L10n.instance.t('app_title'), 'Mekenet');
    });

    test('Switches to Amharic and persists preference', () async {
      await L10n.instance.setLocale('am');
      expect(L10n.instance.currentLanguageCode, 'am');
      expect(L10n.instance.isAmharic, isTrue);
      expect(L10n.instance.t('app_title'), 'መቀነት');

      // Check SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('mekenet_language'), 'am');
    });

    test('Switches back to English', () async {
      await L10n.instance.setLocale('am');
      expect(L10n.instance.t('nav_home'), 'መነሻ');

      await L10n.instance.setLocale('en');
      expect(L10n.instance.currentLanguageCode, 'en');
      expect(L10n.instance.t('nav_home'), 'Home');
    });

    test('Dynamic template interpolation with single and double braces', () {
      expect(
        L10n.instance.t('welcome_message', {'name': 'Abebe'}),
        'Welcome, Abebe',
      );
      expect(
        L10n.instance.t('pin_too_many_attempts', {'seconds': 30}),
        'Too many attempts. Try again in 30 seconds.',
      );

      L10n.instance.setLocale('am');
      expect(
        L10n.instance.t('welcome_message', {'name': 'አበበ'}),
        'እንኳን ደህና መጡ፣ አበበ',
      );
      expect(
        L10n.instance.t('pin_too_many_attempts', {'seconds': 30}),
        'ብዙ ሙከራዎች ተደርገዋል። ከ 30 ሰከንዶች በኋላ እንደገና ይሞክሩ።',
      );
    });

    test('Currency formatting in English and Amharic', () {
      L10n.instance.setLocale('en');
      expect(L10n.instance.formatCurrency(150), 'Br150');
      expect(L10n.instance.formatCurrencyDecimal(150.5), 'Br 150.50');

      L10n.instance.setLocale('am');
      expect(L10n.instance.formatCurrency(150), '150 ብር');
      expect(L10n.instance.formatCurrencyDecimal(150.5), '150.50 ብር');
    });

    test('Category translation', () {
      L10n.instance.setLocale('en');
      expect(L10n.instance.translateCategory('Supplies'), 'Supplies');
      expect(L10n.instance.translateCategory('Rent'), 'Rent');
      expect(L10n.instance.translateCategory('Utilities'), 'Utilities');
      expect(L10n.instance.translateCategory('Salaries'), 'Salaries');
      expect(L10n.instance.translateCategory('Transport'), 'Transport');
      expect(L10n.instance.translateCategory('Other'), 'Other');
      expect(L10n.instance.translateCategory('uncategorized'), 'Uncategorized');

      L10n.instance.setLocale('am');
      expect(L10n.instance.translateCategory('Supplies'), 'አቅርቦቶች');
      expect(L10n.instance.translateCategory('Rent'), 'ኪራይ');
      expect(L10n.instance.translateCategory('Utilities'), 'አገልግሎቶች');
      expect(L10n.instance.translateCategory('Salaries'), 'ደሞዝ');
      expect(L10n.instance.translateCategory('Transport'), 'ትራንስፖርት');
      expect(L10n.instance.translateCategory('Other'), 'ሌላ');
      expect(L10n.instance.translateCategory('uncategorized'), 'ያልተመደበ');
    });

    test('Source translation', () {
      L10n.instance.setLocale('en');
      expect(L10n.instance.translateSource('manual'), 'Manual');
      expect(L10n.instance.translateSource('telebirr'), 'Telebirr');
      expect(L10n.instance.translateSource('cbe'), 'CBE');
      expect(L10n.instance.translateSource('awash'), 'Awash Bank');

      L10n.instance.setLocale('am');
      expect(L10n.instance.translateSource('manual'), 'በእጅ የተመዘገበ');
      expect(L10n.instance.translateSource('telebirr'), 'ቴሌብር');
      expect(L10n.instance.translateSource('cbe'), 'ሲቢኢ (CBE)');
      expect(L10n.instance.translateSource('awash'), 'አዋሽ ባንክ');
    });

    test('API Error translation mapping', () {
      L10n.instance.setLocale('en');
      expect(L10n.instance.translateApiError('USER_NOT_FOUND'), 'User not found');
      expect(L10n.instance.translateApiError('INVALID_PASSWORD'), 'Invalid password or PIN');
      expect(L10n.instance.translateApiError('TRANSACTION_FAILED'), 'Transaction failed');
      expect(L10n.instance.translateApiError('NETWORK_ERROR'), 'Network error. Please check your connection.');
      expect(L10n.instance.translateApiError('SERVER_ERROR'), 'Server error occurred');

      L10n.instance.setLocale('am');
      expect(L10n.instance.translateApiError('USER_NOT_FOUND'), 'ተጠቃሚው አልተገኘም');
      expect(L10n.instance.translateApiError('INVALID_PASSWORD'), 'የተሳሳተ ፒን ወይም የይለፍ ቃል');
      expect(L10n.instance.translateApiError('TRANSACTION_FAILED'), 'ዝውውሩ አልተሳካም');
      expect(L10n.instance.translateApiError('NETWORK_ERROR'), 'የኔትወርክ ስህተት። እባክዎ ኢንተርኔትዎን ያረጋግጡ።');
      expect(L10n.instance.translateApiError('SERVER_ERROR'), 'የሰርቨር ስህተት አጋጥሟል');
    });

    test('Relative debt due date and pluralization', () {
      final now = DateTime.now();
      L10n.instance.setLocale('en');
      expect(L10n.instance.formatDueDateLabel(now), 'Added today');
      expect(L10n.instance.formatDueDateLabel(now.subtract(const Duration(days: 1))), 'Added yesterday');
      expect(L10n.instance.formatDueDateLabel(now.subtract(const Duration(days: 5))), 'Added 5 days ago');

      L10n.instance.setLocale('am');
      expect(L10n.instance.formatDueDateLabel(now), 'ዛሬ የተጨመረ');
      expect(L10n.instance.formatDueDateLabel(now.subtract(const Duration(days: 1))), 'ትናንት የተጨመረ');
      expect(L10n.instance.formatDueDateLabel(now.subtract(const Duration(days: 5))), 'ከ 5 ቀናት በፊት የተጨመረ');
    });

    test('Date label formatting', () {
      final now = DateTime.now();
      L10n.instance.setLocale('en');
      final todayLabel = L10n.instance.formatDateLabel(now);
      expect(todayLabel.startsWith('Today,'), isTrue);

      final yesterday = DateTime(now.year, now.month, now.day - 1, 10, 0);
      expect(L10n.instance.formatDateLabel(yesterday), 'Yesterday');

      L10n.instance.setLocale('am');
      final todayLabelAm = L10n.instance.formatDateLabel(now);
      expect(todayLabelAm.startsWith('ዛሬ፣'), isTrue);
      expect(L10n.instance.formatDateLabel(yesterday), 'ትናንት');
    });

    test('Fallback for unknown key returns key itself', () {
      expect(L10n.instance.t('completely_nonexistent_key'), 'completely_nonexistent_key');
    });
  });
}
