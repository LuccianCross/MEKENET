/// lib/services/category_service.dart
///
/// Manages expense categories and tracks usage for smart pre-filling.
///
/// Responsibilities:
///   - Store/load custom categories
///   - Track how often each category is used
///   - Suggest the most-used category when adding an expense

import 'dart:convert';

import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryService {
  // -------------------------------------------------------------------------
  // Singleton
  // -------------------------------------------------------------------------
  CategoryService._();
  static final CategoryService instance = CategoryService._();

  static const _categoriesKey = 'custom_categories';
  static const _usageKey = 'category_usage';
  static final _log = Logger();

  // -------------------------------------------------------------------------
  // Default business categories
  // -------------------------------------------------------------------------
  static const List<String> defaultCategories = [
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

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Returns all categories (defaults + custom).
  Future<List<String>> getCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final customJson = prefs.getString(_categoriesKey);
    final custom = customJson != null
        ? List<String>.from(jsonDecode(customJson) as List)
        : [];
    return [...defaultCategories, ...custom];
  }

  /// Adds a custom category.
  Future<void> addCategory(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final customJson = prefs.getString(_categoriesKey);
    final custom = customJson != null
        ? List<String>.from(jsonDecode(customJson) as List)
        : [];

    if (custom.contains(name) || defaultCategories.contains(name)) return;

    custom.add(name);
    await prefs.setString(_categoriesKey, jsonEncode(custom));
    _log.i('[Category] Added custom category: $name');
  }

  /// Removes a custom category (cannot remove defaults).
  Future<void> removeCategory(String name) async {
    if (defaultCategories.contains(name)) return;

    final prefs = await SharedPreferences.getInstance();
    final customJson = prefs.getString(_categoriesKey);
    final custom = customJson != null
        ? List<String>.from(jsonDecode(customJson) as List)
        : [];

    custom.remove(name);
    await prefs.setString(_categoriesKey, jsonEncode(custom));
    _log.i('[Category] Removed custom category: $name');
  }

  /// Records that a category was used.
  Future<void> recordUsage(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final usageJson = prefs.getString(_usageKey);
    final usage = usageJson != null
        ? Map<String, int>.from(jsonDecode(usageJson) as Map)
        : {};

    usage[category] = (usage[category] ?? 0) + 1;
    await prefs.setString(_usageKey, jsonEncode(usage));
  }

  /// Returns the most-used category, or null if no usage data.
  Future<String?> getMostUsedCategory() async {
    final prefs = await SharedPreferences.getInstance();
    final usageJson = prefs.getString(_usageKey);
    if (usageJson == null) return null;

    final usage = Map<String, int>.from(jsonDecode(usageJson) as Map);
    if (usage.isEmpty) return null;

    String? topCategory;
    int topCount = 0;
    usage.forEach((cat, count) {
      if (count > topCount) {
        topCount = count;
        topCategory = cat;
      }
    });

    return topCategory;
  }

  /// Returns usage counts for all categories.
  Future<Map<String, int>> getUsageStats() async {
    final prefs = await SharedPreferences.getInstance();
    final usageJson = prefs.getString(_usageKey);
    if (usageJson == null) return {};

    return Map<String, int>.from(jsonDecode(usageJson) as Map);
  }

  /// Clears all usage data.
  Future<void> clearUsage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usageKey);
    _log.i('[Category] Cleared usage data');
  }
}
