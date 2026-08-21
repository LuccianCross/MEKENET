import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'appTitle': 'Mekenet',
      'home': 'Home',
      'add': 'Add',
      'debts': 'Debts',
      'settings': 'Settings',
      'myMoneyRecord': 'My Money Record',
      'income': 'Income',
      'expenses': 'Expenses',
      'owed': 'Owed',
      'todayProfit': 'Today Profit',
      'todayLoss': 'Today Loss',
      'thisWeekProfit': 'This Week Profit',
      'thisWeekLoss': 'This Week Loss',
      'thisMonthProfit': 'This Month Profit',
      'thisMonthLoss': 'This Month Loss',
      'today': 'Today',
      'thisWeek': 'This Week',
      'thisMonth': 'This Month',
      'last7Days': 'Last 7 Days',
      'recentTransactions': 'Recent Transactions',
      'noTransactionsYet': 'No transactions yet',
      'bankSmsWillAppear': 'Bank SMS will appear here automatically',
      'addExpense': 'Add Expense',
      'amount': 'Amount',
      'category': 'Category',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'retry': 'Retry',
      'couldNotLoadData': 'Could not load data',
      'openDebts': 'Open Debts',
      'addDebt': 'Add Debt',
      'customerName': 'Customer Name',
      'markPaid': 'Mark Paid',
      'noOpenDebts': 'No open debts',
      'serverUrl': 'Server URL',
      'exportReport': 'Export Report',
      'manageCategories': 'Manage Categories',
      'syncData': 'Sync Data',
      'exportData': 'Export Data',
      'shareReport': 'Share Report',
      'copyReport': 'Copy Report',
      'saveCSV': 'Save CSV',
      'reportGenerated': 'Report Generated',
      'ok': 'OK',
      'confirm': 'Confirm',
      'chooseLanguage': 'Choose Language',
      'chooseLanguageDesc': 'Select your preferred language',
      'getStarted': 'Get Started',
      'skip': 'Skip',
      'next': 'Next',
      'neverShare': 'We\'ll never share your data',
      'allowSmsAccess': 'Allow access to SMS?',
      'allowSmsAccessDesc': 'We read only bank payment messages to automatically log your sales and business expenses. We ignore personal chats.',
      'dataStaysOnDevice': 'Your data stays on your device',
      'dataStaysOnDeviceDesc': 'Your financial records are 100% private. All SMS processing happens securely on your phone without sending details to any server.',
      'onboardingSubtitle': 'Your daily money record, automatically',
      'incomeByCategory': 'Income by Category',
    },
    'am': {
      'appTitle': 'መቀነት',
      'home': 'መነሻ',
      'add': 'መጨመር',
      'debts': '뽐ዓን',
      'settings': 'ማስተካከያ',
      'myMoneyRecord': 'የገንዘብ መዝገቢ',
      'income': 'ግቢ',
      'expenses': 'ወጪ',
      'owed': 'የተበደለ',
      'todayProfit': 'የዛሬ ቀሪ',
      'todayLoss': 'የዛሬ ኪሳራ',
      'thisWeekProfit': 'የዚህ ሳምንት ቀሪ',
      'thisWeekLoss': 'የዚህ ሳምንት ኪሳራ',
      'thisMonthProfit': 'የዚህ ወር ቀሪ',
      'thisMonthLoss': 'የዚህ ወር ኪሳራ',
      'today': 'ዛሬ',
      'thisWeek': 'ዚህ ሳምንት',
      'thisMonth': 'ዚህ ወር',
      'last7Days': 'ለ7 ቀናት',
      'recentTransactions': 'የቅርብ ግብይቶች',
      'noTransactionsYet': 'ገብይቶች አልተፈተጡም',
      'bankSmsWillAppear': 'የባንክ SMS በእዚህ በራስ-ሰር ይታያሉ',
      'addExpense': 'ወጪ መጨመር',
      'amount': 'መጠን',
      'category': 'ምድር',
      'save': 'ማስቀመጥ',
      'cancel': 'ሰርዝ',
      'delete': 'ማጥፋት',
      'retry': 'እንደገና ሞክር',
      'couldNotLoadData': 'መረጃ መጫን አልተቻለም',
      'openDebts': 'ተከፍተው የሚገኙ ፖሞዎች',
      'addDebt': 'ፖሞ መጨመር',
      'customerName': 'የደንበኛ ስም',
      'markPaid': 'ከፍለዋል ምልክት',
      'noOpenDebts': 'ተከፍተው የሚገኙ ፖሞዎች የሉም',
      'serverUrl': 'የአገልጋይ URL',
      'exportReport': 'ሪፖርት መላክ',
      'manageCategories': 'ምድሮችን ማስተካከል',
      'syncData': 'መረጃ ማ_sync',
      'exportData': 'መረጃ መላክ',
      'shareReport': 'ሪፖርት መጋራት',
      'copyReport': 'ሪፖርት ቅרון',
      'saveCSV': 'CSV ማስቀመጥ',
      'reportGenerated': 'ሪፖርት ተዘርግቷል',
      'ok': 'እሺ',
      'confirm': 'ማረጋገጫ',
      'chooseLanguage': 'ቋንቋ ምረጥ',
      'chooseLanguageDesc': 'የምትመርጠውን ቋንቋ ምረጥ',
      'getStarted': 'ጀምር',
      'skip': '愆 largo',
      'next': 'ቀጥል',
      'neverShare': 'መረጃዎን አንጋራም አይደለም',
      'allowSmsAccess': 'SMS መድረስ ይስጡ?',
      'allowSmsAccessDesc': 'ንብረት ግብይቶች ብቻ እንобеспечивать ለራስ-ሰር በራስ-ሰር የሚመነኩ ሽያጭዎችን እና የንግድ ወጪዎችን ለመመዝገብ። የግል ቻቶችን እን توفير።',
      'dataStaysOnDevice': 'መረጃዎ በመሣሪያ ላይ ይ ይወጣል',
      'dataStaysOnDeviceDesc': 'የገንዘብ መዝገቢዎችዎ 100% የግል ናቸው። ሁሉም SMS ሂደት በመሣሪያዎ ላይ በደህንነት ይሠራል።',
      'onboardingSubtitle': 'የዕለት ገንዘብ መዝገቢዎ፣ በራስ-ሰር',
      'incomeByCategory': 'ገቢ በምድር መሰረት',
    },
  };

  String t(String key) => _translations[locale.languageCode]?[key] ?? key;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'am'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
