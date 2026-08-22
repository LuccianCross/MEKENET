/// lib/services/category_service.dart
///
/// Manages income and expense categories, tracks usage for smart pre-filling.
library;

import 'dart:convert';

import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryService {
  CategoryService._();
  static final CategoryService instance = CategoryService._();

  static const _categoriesKey = 'custom_categories';
  static const _incomeCategoriesKey = 'custom_income_categories';
  static const _usageKey = 'category_usage';
  static final _log = Logger();
  static SharedPreferences? _cachedPrefs;

  static Future<SharedPreferences> get _prefs async {
    _cachedPrefs ??= await _prefs;
    return _cachedPrefs!;
  }

  // Default expense categories
  static const List<String> defaultExpenseCategories = [
    'Inventory',
    'Transport',
    'Rent',
    'Staff',
    'Utilities',
    'Packaging',
    'Loan Repayment',
    'Tax',
    'Marketing',
    'Other',
  ];

  // Default income categories
  static const List<String> defaultIncomeCategories = [
    'Sales',
    'Customer Payment',
    'Transfer In',
    'Loan Received',
    'Other Income',
  ];

  // Backward-compatible getter
  List<String> get defaultCategories => defaultExpenseCategories;

  Future<List<String>> getCategories({String direction = 'expense'}) async {
    final key =
        direction == 'income' ? _incomeCategoriesKey : _categoriesKey;
    final defaults =
        direction == 'income' ? defaultIncomeCategories : defaultExpenseCategories;

    final prefs = await _prefs;
    final customJson = prefs.getString(key);
    final custom = customJson != null
        ? List<String>.from(jsonDecode(customJson) as List)
        : [];
    return [...defaults, ...custom];
  }

  Future<void> addCategory(String name,
      {String direction = 'expense'}) async {
    final key =
        direction == 'income' ? _incomeCategoriesKey : _categoriesKey;
    final defaults =
        direction == 'income' ? defaultIncomeCategories : defaultExpenseCategories;

    final prefs = await _prefs;
    final customJson = prefs.getString(key);
    final custom = customJson != null
        ? List<String>.from(jsonDecode(customJson) as List)
        : [];

    if (custom.contains(name) || defaults.contains(name)) return;

    custom.add(name);
    await prefs.setString(key, jsonEncode(custom));
    _log.i('[Category] Added custom $direction category: $name');
  }

  Future<void> removeCategory(String name,
      {String direction = 'expense'}) async {
    final defaults =
        direction == 'income' ? defaultIncomeCategories : defaultExpenseCategories;
    if (defaults.contains(name)) return;

    final key =
        direction == 'income' ? _incomeCategoriesKey : _categoriesKey;

    final prefs = await _prefs;
    final customJson = prefs.getString(key);
    final custom = customJson != null
        ? List<String>.from(jsonDecode(customJson) as List)
        : [];

    custom.remove(name);
    await prefs.setString(key, jsonEncode(custom));
    _log.i('[Category] Removed custom $direction category: $name');
  }

  /// Records usage with direction-aware key.
  Future<void> recordUsage(String category, {String direction = 'expense'}) async {
    final prefs = await _prefs;
    final usageJson = prefs.getString(_usageKey);
    final usage = usageJson != null
        ? Map<String, int>.from(jsonDecode(usageJson) as Map)
        : {};

    final key = '$direction:$category';
    usage[key] = (usage[key] ?? 0) + 1;
    await prefs.setString(_usageKey, jsonEncode(usage));
  }

  /// Returns the most-used category for the given direction.
  Future<String?> getMostUsedCategory({String direction = 'expense'}) async {
    final prefs = await _prefs;
    final usageJson = prefs.getString(_usageKey);
    if (usageJson == null) return null;

    final usage = Map<String, int>.from(jsonDecode(usageJson) as Map);
    if (usage.isEmpty) return null;

    String? topCategory;
    int topCount = 0;
    final prefix = '$direction:';
    usage.forEach((key, count) {
      if (key.startsWith(prefix) && count > topCount) {
        topCount = count;
        topCategory = key.substring(prefix.length);
      }
    });

    return topCategory;
  }

  Future<Map<String, int>> getUsageStats() async {
    final prefs = await _prefs;
    final usageJson = prefs.getString(_usageKey);
    if (usageJson == null) return {};

    return Map<String, int>.from(jsonDecode(usageJson) as Map);
  }

  Future<void> clearUsage() async {
    final prefs = await _prefs;
    await prefs.remove(_usageKey);
    _log.i('[Category] Cleared usage data');
  }
}
