/// lib/l10n/l10n.dart
///
/// Localization service for MEKENET application.
/// Manages English ('en') and Amharic ('am') translations with persistence
/// via SharedPreferences and reactive UI state updates using ChangeNotifier.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class L10n extends ChangeNotifier {
  L10n._();
  static final L10n instance = L10n._();

  static const String _prefLanguageKey = 'mekenet_language';
  Locale _currentLocale = const Locale('en');

  Locale get currentLocale => _currentLocale;
  String get currentLanguageCode => _currentLocale.languageCode;
  bool get isAmharic => _currentLocale.languageCode == 'am';

  /// Initialize stored language preference from SharedPreferences
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString(_prefLanguageKey) ?? 'en';
    _currentLocale = Locale(savedLang);
    notifyListeners();
  }

  /// Change language ('en' or 'am') and persist preference
  Future<void> setLocale(String languageCode) async {
    if (languageCode != 'en' && languageCode != 'am') return;
    _currentLocale = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefLanguageKey, languageCode);
    notifyListeners();
  }

  /// Translate a key with optional dynamic template arguments
  /// Example: t("welcome.message", {"name": "Abebe"})
  String t(String key, [Map<String, dynamic>? args]) {
    final dict = isAmharic ? _am : _en;
    String text = dict[key] ?? _en[key] ?? key;

    if (args != null && args.isNotEmpty) {
      args.forEach((argKey, val) {
        text = text.replaceAll(
          RegExp(r'\{\{?\s*' + RegExp.escape(argKey) + r'\s*\}\}?'),
          val.toString(),
        );
      });
    }

    return text;
  }

  /// Translate transaction categories dynamically
  String translateCategory(String category) {
    final key = category.toLowerCase().trim();
    switch (key) {
      case 'supplies':
        return t('cat_supplies');
      case 'rent':
        return t('cat_rent');
      case 'utilities':
        return t('cat_utilities');
      case 'salaries':
        return t('cat_salaries');
      case 'transport':
        return t('cat_transport');
      case 'other':
        return t('cat_other');
      case 'uncategorized':
        return t('cat_uncategorized');
      default:
        return category;
    }
  }

  /// Translate transaction source dynamically
  String translateSource(String source) {
    final key = source.toLowerCase().trim();
    switch (key) {
      case 'manual':
        return t('source_manual');
      case 'telebirr':
        return t('source_telebirr');
      case 'cbe':
        return t('source_cbe');
      case 'awash':
        return t('source_awash');
      default:
        return source.toUpperCase();
    }
  }

  /// Translate backend API error codes or error messages
  String translateApiError(String? codeOrError) {
    if (codeOrError == null || codeOrError.trim().isEmpty) {
      return t('API_UNKNOWN_ERROR');
    }
    final clean = codeOrError.trim();
    final upper = clean.toUpperCase();

    if (_en.containsKey(clean) || _am.containsKey(clean)) {
      return t(clean);
    }
    if (_en.containsKey(upper) || _am.containsKey(upper)) {
      return t(upper);
    }

    final apiPrefixed = 'API_$upper';
    if (_en.containsKey(apiPrefixed) || _am.containsKey(apiPrefixed)) {
      return t(apiPrefixed);
    }

    return t('msg_error_generic', {'error': codeOrError});
  }

  /// Format currency display according to locale
  String formatCurrency(double amount) {
    final formattedAmount = amount.toStringAsFixed(0);
    if (isAmharic) {
      return '$formattedAmount ብር';
    } else {
      return 'Br$formattedAmount';
    }
  }

  /// Format precise currency with decimals
  String formatCurrencyDecimal(double amount) {
    final formattedAmount = amount.toStringAsFixed(2);
    if (isAmharic) {
      return '$formattedAmount ብር';
    } else {
      return 'Br $formattedAmount';
    }
  }

  /// Format transaction date labels dynamically
  String formatDateLabel(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      final hourStr = date.hour.toString().padLeft(2, '0');
      final minStr = date.minute.toString().padLeft(2, '0');
      return t('date_today_at', {'time': '$hourStr:$minStr'});
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      return t('date_yesterday');
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Format debt due date labels dynamically with pluralization
  String formatDueDateLabel(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt).inDays;
    if (difference <= 0) {
      return t('added_today');
    } else if (difference == 1) {
      return t('added_yesterday');
    } else {
      return t('added_days_ago', {'days': difference});
    }
  }

  // ---------------------------------------------------------------------------
  // English Translations
  // ---------------------------------------------------------------------------
  static const Map<String, String> _en = {
    // General
    'welcome_message': 'Welcome, {{name}}',
    'msg_error_generic': 'Error: {error}',
    'msg_success_generic': 'Success',
    'loading': 'Loading...',

    // App & Navigation
    'app_title': 'Mekenet',
    'nav_home': 'Home',
    'nav_add': 'Add',
    'nav_debts': 'Debts',
    'nav_settings': 'Settings',

    // Onboarding Screen
    'onboarding_title_1': 'My Money Record',
    'onboarding_subtitle_1': 'Your daily money record, automatically',
    'onboarding_title_2': 'Allow access to SMS?',
    'onboarding_subtitle_2':
        'We read only bank payment messages to automatically log your sales and business expenses. We ignore personal chats.',
    'onboarding_title_3': 'Your data stays on your device',
    'onboarding_subtitle_3':
        'Your financial records are 100% private. All SMS processing happens securely on your phone without sending details to any server.',
    'onboarding_never_share': 'We\'ll never share your data',
    'btn_get_started': 'Get Started',
    'btn_skip': 'Skip',
    'btn_next': 'Next',

    // PIN Screen
    'pin_set_title': 'Set PIN',
    'pin_confirm_title': 'Confirm PIN',
    'pin_enter_title': 'Enter PIN',
    'pin_create_subtitle': 'Create your PIN',
    'pin_confirm_subtitle': 'Confirm your PIN',
    'pin_enter_subtitle': 'Enter your PIN',
    'pin_create_desc': 'Set a 4-digit PIN to secure your data',
    'pin_confirm_desc': 'Enter your 4-digit PIN again',
    'pin_enter_desc': 'Please enter your 4-digit PIN',
    'pin_clear_start_over': 'Clear and start over',
    'pin_mismatch': 'PINs do not match. Try again.',
    'pin_too_many_attempts': 'Too many attempts. Try again in {seconds} seconds.',
    'pin_locked_out': 'Too many attempts. Locked for 30 seconds.',
    'pin_incorrect_count': 'Incorrect PIN. {count}/5 attempts.',

    // Home Screen
    'home_title': 'My Money Record',
    'todays_profit': 'Today\'s Profit',
    'todays_loss': 'Today\'s Loss',
    'summary_income': 'INCOME',
    'summary_expenses': 'EXPENSES',
    'summary_owed': 'OWED',
    'recent_transactions': 'Recent Transactions',
    'no_transactions_yet': 'No transactions yet',
    'sms_appear_automatically': 'Bank SMS will appear here automatically',
    'label_income': 'Income',
    'label_expense': 'Expense',
    'label_expenses': 'Expenses',
    'could_not_load_data': 'Could not load data',
    'btn_retry': 'Retry',
    'date_today_at': 'Today, {time}',
    'date_yesterday': 'Yesterday',

    // Quick Add Screen
    'add_expense_title': 'Add Expense',
    'form_label_amount': 'Amount (Br)',
    'form_hint_amount': 'Enter expense amount',
    'form_label_category': 'Category',
    'form_label_date': 'Date',
    'form_label_note': 'Note (Optional)',
    'form_hint_note': 'e.g. Weekly stock refill',
    'btn_save_expense': 'Save Expense',
    'val_enter_amount': 'Please enter an amount',
    'val_enter_valid_amount': 'Please enter a valid amount',
    'msg_expense_saved': 'Expense saved ✓',
    'msg_error_saving_expense': 'Error saving expense: {error}',

    // Categories
    'cat_supplies': 'Supplies',
    'cat_rent': 'Rent',
    'cat_utilities': 'Utilities',
    'cat_salaries': 'Salaries',
    'cat_transport': 'Transport',
    'cat_other': 'Other',
    'cat_uncategorized': 'Uncategorized',

    // Sources
    'source_manual': 'Manual',
    'source_telebirr': 'Telebirr',
    'source_cbe': 'CBE',
    'source_awash': 'Awash Bank',

    // Debts Screen
    'debts_title': 'Who Owes Me',
    'total_outstanding_owed': 'Total Outstanding Owed',
    'no_debts_recorded': 'No debts recorded',
    'tap_plus_to_add_debt': 'Tap + to add someone who owes you',
    'could_not_load_debts': 'Could not load debts',
    'status_paid': 'Paid',
    'added_today': 'Added today',
    'added_yesterday': 'Added yesterday',
    'added_days_ago': 'Added {days} days ago',
    'btn_mark_paid': 'Mark Paid',
    'btn_delete': 'Delete',
    'dialog_delete_debt_title': 'Delete Debt?',
    'dialog_delete_debt_msg': 'Remove {name}\'s debt of {amount}?',
    'btn_cancel': 'Cancel',
    'add_debt_sheet_title': 'Add Debt',
    'hint_person_name': 'Person\'s name',
    'hint_debt_amount': 'Amount (Br)',
    'val_fill_all_fields': 'Please fill in all fields',
    'btn_save': 'Save',

    // Settings Screen
    'settings_title': 'Settings',
    'privacy_card_title': 'Your data stays on your device',
    'privacy_card_desc':
        'Your financial records are 100% private. All SMS processing happens securely on your phone without sending details to any server.',
    'btn_allow_access': 'Allow Access',
    'btn_not_now': 'Not now',
    'access_allowed_msg': 'Access allowed!',
    'setting_language': 'Language / ቋንቋ',
    'setting_language_sub': 'English (Current: English)',
    'setting_privacy': 'Privacy',
    'setting_privacy_sub': 'Your data stays on your device',
    'setting_offline_mode': 'Offline Mode',
    'setting_offline_mode_sub': 'Works without internet',
    'setting_sync': 'Sync to cloud',
    'setting_sync_sub_on': 'Transactions will be backed up',
    'setting_sync_sub_off': 'Only stored on this device',
    'setting_export': 'Export Report',
    'setting_export_sub': 'Send report to bank',
    'setting_version': 'Version',
    'setting_version_sub': 'Mekenet v0.1.0',
    'setting_debug_sms': 'Debug SMS',
    'setting_debug_sms_sub': 'Test each SMS pipeline step',

    // Language Selector Sheet
    'select_language_title': 'Select Language',
    'lang_english': 'English',
    'lang_amharic': 'አማርኛ (Amharic)',

    // Export Dialog & Report Sheet
    'export_dialog_title': 'Export Report',
    'filter_from': 'From',
    'filter_to': 'To',
    'filter_type': 'Type',
    'filter_type_all': 'All',
    'filter_type_income': 'Income',
    'filter_type_expense': 'Expense',
    'filter_any': 'Any',
    'btn_get_report': 'Get Report',
    'report_sheet_title': 'Financial Report',
    'report_generated': 'Generated: {date}',
    'report_total_income': 'Total Income',
    'report_total_expense': 'Total Expense',
    'report_net_balance': 'Net Balance',
    'report_transactions_count': 'Transactions ({count})',
    'msg_could_not_fetch_report':
        'Could not fetch report. Make sure the server is running and you have synced at least one transaction.',

    // API Error Code Mappings & Standard Errors
    'USER_NOT_FOUND': 'User not found',
    'INVALID_PASSWORD': 'Invalid password or PIN',
    'TRANSACTION_FAILED': 'Transaction failed',
    'NETWORK_ERROR': 'Network error. Please check your connection.',
    'SERVER_ERROR': 'Server error occurred',
    'NO_TRANSACTIONS': 'No transactions found',
    'EXPORT_FAILED': 'Failed to export report',
    'API_USER_NOT_FOUND': 'User not found',
    'API_INVALID_PASSWORD': 'Invalid password or PIN',
    'API_TRANSACTION_FAILED': 'Transaction failed',
    'API_NETWORK_ERROR': 'Network error. Please check your connection.',
    'API_SERVER_ERROR': 'Server error occurred',
    'API_NO_TRANSACTIONS': 'No transactions found',
    'API_EXPORT_FAILED': 'Failed to export report',
    'API_UNKNOWN_ERROR': 'An unexpected error occurred',

    // Debug SMS Dialog
    'sms_debug_title': 'SMS Debug Results',
    'btn_close': 'Close',
  };

  // ---------------------------------------------------------------------------
  // Amharic Translations
  // ---------------------------------------------------------------------------
  static const Map<String, String> _am = {
    // General
    'welcome_message': 'እንኳን ደህና መጡ፣ {{name}}',
    'msg_error_generic': 'ስህተት፡ {error}',
    'msg_success_generic': 'ተሳክቷል',
    'loading': 'በመጫን ላይ...',

    // App & Navigation
    'app_title': 'መቀነት',
    'nav_home': 'መነሻ',
    'nav_add': 'አክል',
    'nav_debts': 'ዕዳዎች',
    'nav_settings': 'ቅንብሮች',

    // Onboarding Screen
    'onboarding_title_1': 'የገንዘብ መዝገቤ',
    'onboarding_subtitle_1': 'የዕለት ተዕለት የገንዘብ መዝገብዎ በራስ-ሰር ይያዛል',
    'onboarding_title_2': 'ለአጭር መልእክት (SMS) ፈቃድ ይሰጣሉ?',
    'onboarding_subtitle_2':
        'የሽያጭና የወጪ መረጃዎችን በራስ-ሰር ለመመዝገብ የባንክ መልእክቶችን ብቻ እናነባለን። የግል መልእክቶችዎን ፈጽሞ አናይም።',
    'onboarding_title_3': 'መረጃዎ በስልክዎ ላይ ብቻ ይጠበቃል',
    'onboarding_subtitle_3':
        'የፋይናንስ መረጃዎ 100% ምሥጢራዊ ነው። ሁሉም የኤስኤምኤስ ማጣራት በስልክዎ ላይ በደህና ሁኔታ ስለሚከናወን ወደ የትኛውም ሰርቨር አይላክም።',
    'onboarding_never_share': 'መረጃዎን ለሶስተኛ ወገን ፈጽሞ አናካፍልም',
    'btn_get_started': 'ጀምር',
    'btn_skip': 'እለፍ',
    'btn_next': 'ቀጣይ',

    // PIN Screen
    'pin_set_title': 'ፒን አዘጋጅ',
    'pin_confirm_title': 'ፒን ያረጋግጡ',
    'pin_enter_title': 'ፒን ያስገቡ',
    'pin_create_subtitle': 'አዲስ ፒን ይፍጠሩ',
    'pin_confirm_subtitle': 'ፒንዎን ያረጋግጡ',
    'pin_enter_subtitle': 'ፒንዎን ያስገቡ',
    'pin_create_desc': 'መረጃዎን ለመጠበቅ የ 4 አሃዝ ፒን ያዘጋጁ',
    'pin_confirm_desc': 'የ 4 አሃዝ ፒንዎን እንደገና ያስገቡ',
    'pin_enter_desc': 'እባክዎ የ 4 አሃዝ ፒንዎን ያስገቡ',
    'pin_clear_start_over': 'አፅዳና እንደገና ጀምር',
    'pin_mismatch': 'ፒን አይመሳሰልም። እባክዎ እንደገና ይሞክሩ።',
    'pin_too_many_attempts': 'ብዙ ሙከራዎች ተደርገዋል። ከ {seconds} ሰከንዶች በኋላ እንደገና ይሞክሩ።',
    'pin_locked_out': 'ብዙ ሙከራዎች ተደርገዋል። ለ 30 ሰከንዶች ተቆልፏል።',
    'pin_incorrect_count': 'ስህተት ፒን። {count}/5 ሙከራዎች።',

    // Home Screen
    'home_title': 'የገንዘብ መዝገቤ',
    'todays_profit': 'የዛሬ አትርፎ',
    'todays_loss': 'የዛሬ ኪሳራ',
    'summary_income': 'ገቢ',
    'summary_expenses': 'ወጪ',
    'summary_owed': 'ዕዳ',
    'recent_transactions': 'የቅርብ ጊዜ ዝውውሮች',
    'no_transactions_yet': 'ምንም ዝውውር አልተመዘገበም',
    'sms_appear_automatically': 'የባንክ ኤስኤምኤስ በራስ-ሰር እዚህ ይታያል',
    'label_income': 'ገቢ',
    'label_expense': 'ወጪ',
    'label_expenses': 'ወጪዎች',
    'could_not_load_data': 'መረጃውን መጫን አልተቻለም',
    'btn_retry': 'ድጋሚ ሞክር',
    'date_today_at': 'ዛሬ፣ {time}',
    'date_yesterday': 'ትናንት',

    // Quick Add Screen
    'add_expense_title': 'ወጪ አክል',
    'form_label_amount': 'መጠን (ብር)',
    'form_hint_amount': 'የወጪ መጠን ያስገቡ',
    'form_label_category': 'ምድብ',
    'form_label_date': 'ቀን',
    'form_label_note': 'ማስታወሻ (ከተፈለገ)',
    'form_hint_note': 'ምሳሌ፡ የሳምንት ዕቃ ግዢ',
    'btn_save_expense': 'ወጪ አስቀምጥ',
    'val_enter_amount': 'እባክዎ መጠን ያስገቡ',
    'val_enter_valid_amount': 'እባክዎ ትክክለኛ መጠን ያስገቡ',
    'msg_expense_saved': 'ወጪው ተቀምጧል ✓',
    'msg_error_saving_expense': 'ወጪን በማስቀመጥ ላይ ስህተት፡ {error}',

    // Categories
    'cat_supplies': 'አቅርቦቶች',
    'cat_rent': 'ኪራይ',
    'cat_utilities': 'አገልግሎቶች',
    'cat_salaries': 'ደሞዝ',
    'cat_transport': 'ትራንስፖርት',
    'cat_other': 'ሌላ',
    'cat_uncategorized': 'ያልተመደበ',

    // Sources
    'source_manual': 'በእጅ የተመዘገበ',
    'source_telebirr': 'ቴሌብር',
    'source_cbe': 'ሲቢኢ (CBE)',
    'source_awash': 'አዋሽ ባንክ',

    // Debts Screen
    'debts_title': 'ማን ይበደረኛል',
    'total_outstanding_owed': 'ጠቅላላ ያልተሰበሰበ ዕዳ',
    'no_debts_recorded': 'ምንም የተመዘገበ ዕዳ የለም',
    'tap_plus_to_add_debt': 'ተበዳሪ ለመመዝገብ + ይጫኑ',
    'could_not_load_debts': 'ዕዳዎችን መጫን አልተቻለም',
    'status_paid': 'ተከፍሏል',
    'added_today': 'ዛሬ የተጨመረ',
    'added_yesterday': 'ትናንት የተጨመረ',
    'added_days_ago': 'ከ {days} ቀናት በፊት የተጨመረ',
    'btn_mark_paid': 'ተከፍሏል በል',
    'btn_delete': 'ሰርዝ',
    'dialog_delete_debt_title': 'ዕዳ ይሰረዝ?',
    'dialog_delete_debt_msg': 'የ{name} የ {amount} ዕዳ ይወገድ?',
    'btn_cancel': 'ሰርዝ/ተመለስ',
    'add_debt_sheet_title': 'ዕዳ አክል',
    'hint_person_name': 'የሰውየው ስም',
    'hint_debt_amount': 'መጠን (ብር)',
    'val_fill_all_fields': 'እባክዎ ሁሉንም መስኮች ይሙሉ',
    'btn_save': 'አስቀምጥ',

    // Settings Screen
    'settings_title': 'ቅንብሮች',
    'privacy_card_title': 'መረጃዎ በስልክዎ ላይ ብቻ ይጠበቃል',
    'privacy_card_desc':
        'የፋይናንስ መረጃዎ 100% ምሥጢራዊ ነው። ሁሉም የኤስኤምኤስ ማጣራት በስልክዎ ላይ በደህና ሁኔታ ስለሚከናወን ወደ የትኛውም ሰርቨር አይላክም።',
    'btn_allow_access': 'ፈቃድ ስጥ',
    'btn_not_now': 'አሁን አይደለም',
    'access_allowed_msg': 'ፈቃድ ተሰጥቷል!',
    'setting_language': 'ቋንቋ / Language',
    'setting_language_sub': 'አማርኛ (የአሁኑ፡ አማርኛ)',
    'setting_privacy': 'ምሥጢራዊነት',
    'setting_privacy_sub': 'መረጃዎ በስልክዎ ላይ ብቻ ይጠበቃል',
    'setting_offline_mode': 'ያለ ኢንተርኔት መስሪያ',
    'setting_offline_mode_sub': 'ያለ ኢንተርኔት ይሰራል',
    'setting_sync': 'ወደ ክላውድ አስቀምጥ (Sync)',
    'setting_sync_sub_on': 'ዝውውሮች ባክአፕ ይደረጋሉ',
    'setting_sync_sub_off': 'በዚህ ስልክ ላይ ብቻ ተቀምጧል',
    'setting_export': 'ሪፖርት ላክ',
    'setting_export_sub': 'ሪፖርቱን ወደ ባንክ ላክ',
    'setting_version': 'ስሪት',
    'setting_version_sub': 'መቀነት v0.1.0',
    'setting_debug_sms': 'የኤስኤምኤስ ሙከራ',
    'setting_debug_sms_sub': 'የኤስኤምኤስ ሂደቶችን ፈትሽ',

    // Language Selector Sheet
    'select_language_title': 'ቋንቋ ይምረጡ',
    'lang_english': 'English (እንግሊዝኛ)',
    'lang_amharic': 'አማርኛ',

    // Export Dialog & Report Sheet
    'export_dialog_title': 'ሪፖርት ላክ',
    'filter_from': 'ከቀን',
    'filter_to': 'እስከ ቀን',
    'filter_type': 'ዓይነት',
    'filter_type_all': 'ሁሉም',
    'filter_type_income': 'ገቢ',
    'filter_type_expense': 'ወጪ',
    'filter_any': 'ማንኛውም',
    'btn_get_report': 'ሪፖርት አውጣ',
    'report_sheet_title': 'የፋይናንስ ሪፖርት',
    'report_generated': 'የተዘጋጀበት፡ {date}',
    'report_total_income': 'ጠቅላላ ገቢ',
    'report_total_expense': 'ጠቅላላ ወጪ',
    'report_net_balance': 'የተጣራ ቀሪ',
    'report_transactions_count': 'ዝውውሮች ({count})',
    'msg_could_not_fetch_report':
        'ሪፖርት ማምጣት አልተቻለም። ሰርቨሩ እየሰራ መሆኑንና ቢያንስ አንድ ዝውውር መላኩን ያረጋግጡ።',

    // API Error Code Mappings & Standard Errors
    'USER_NOT_FOUND': 'ተጠቃሚው አልተገኘም',
    'INVALID_PASSWORD': 'የተሳሳተ ፒን ወይም የይለፍ ቃል',
    'TRANSACTION_FAILED': 'ዝውውሩ አልተሳካም',
    'NETWORK_ERROR': 'የኔትወርክ ስህተት። እባክዎ ኢንተርኔትዎን ያረጋግጡ።',
    'SERVER_ERROR': 'የሰርቨር ስህተት አጋጥሟል',
    'NO_TRANSACTIONS': 'ምንም ዝውውር አልተገኘም',
    'EXPORT_FAILED': 'ሪፖርት ማውጣት አልተሳካም',
    'API_USER_NOT_FOUND': 'ተጠቃሚው አልተገኘም',
    'API_INVALID_PASSWORD': 'የተሳሳተ ፒን ወይም የይለፍ ቃል',
    'API_TRANSACTION_FAILED': 'ዝውውሩ አልተሳካም',
    'API_NETWORK_ERROR': 'የኔትወርክ ስህተት። እባክዎ ኢንተርኔትዎን ያረጋግጡ።',
    'API_SERVER_ERROR': 'የሰርቨር ስህተት አጋጥሟል',
    'API_NO_TRANSACTIONS': 'ምንም ዝውውር አልተገኘም',
    'API_EXPORT_FAILED': 'ሪፖርት ማውጣት አልተሳካም',
    'API_UNKNOWN_ERROR': 'ያልተጠበቀ ስህተት ተከስቷል',

    // Debug SMS Dialog
    'sms_debug_title': 'የኤስኤምኤስ ሙከራ ውጤቶች',
    'btn_close': 'ዝጋ',
  };
}