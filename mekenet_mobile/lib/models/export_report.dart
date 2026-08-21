/// lib/models/export_report.dart
///
/// Dart mirrors of the backend's ExportReport, CategoryBreakdown, and
/// TransactionSummary Pydantic models.
/// Matches server/routes/export.py.

class CategoryBreakdown {
  final String category;
  final double total;
  final int count;

  const CategoryBreakdown({
    required this.category,
    required this.total,
    required this.count,
  });

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdown(
      category: json['category'] as String,
      total: (json['total'] as num).toDouble(),
      count: json['count'] as int,
    );
  }
}

class TransactionSummary {
  final String id;
  final String type;
  final double amount;
  final String description;
  final String date;
  final String category;
  final String currency;
  final String syncedAt;

  const TransactionSummary({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    required this.category,
    required this.currency,
    required this.syncedAt,
  });

  factory TransactionSummary.fromJson(Map<String, dynamic> json) {
    return TransactionSummary(
      id: json['id'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      date: json['date'] as String,
      category: json['category'] as String? ?? 'uncategorized',
      currency: json['currency'] as String? ?? 'ETB',
      syncedAt: json['synced_at'] as String? ?? '',
    );
  }
}

class ExportReport {
  final Map<String, dynamic> summary;
  final List<CategoryBreakdown> incomeByCategory;
  final List<CategoryBreakdown> expenseByCategory;
  final List<TransactionSummary> transactions;
  final String generatedAt;
  final Map<String, dynamic> filtersApplied;

  const ExportReport({
    required this.summary,
    required this.incomeByCategory,
    required this.expenseByCategory,
    required this.transactions,
    required this.generatedAt,
    required this.filtersApplied,
  });

  factory ExportReport.fromJson(Map<String, dynamic> json) {
    return ExportReport(
      summary: json['summary'] as Map<String, dynamic>,
      incomeByCategory: (json['income_by_category'] as List)
          .map((e) => CategoryBreakdown.fromJson(e as Map<String, dynamic>))
          .toList(),
      expenseByCategory: (json['expense_by_category'] as List)
          .map((e) => CategoryBreakdown.fromJson(e as Map<String, dynamic>))
          .toList(),
      transactions: (json['transactions'] as List)
          .map((e) => TransactionSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      generatedAt: json['generated_at'] as String,
      filtersApplied: json['filters_applied'] as Map<String, dynamic>? ?? {},
    );
  }

  // Convenience getters for the UI
  double get totalIncome =>
      (summary['total_income'] as num?)?.toDouble() ?? 0.0;
  double get totalExpense =>
      (summary['total_expense'] as num?)?.toDouble() ?? 0.0;
  double get netBalance =>
      (summary['net_balance'] as num?)?.toDouble() ?? 0.0;
  int get transactionCount =>
      (summary['transaction_count'] as num?)?.toInt() ?? 0;
  String get currency => summary['currency'] as String? ?? 'ETB';

  /// Build an ExportReport from a list of local Transaction objects.
  factory ExportReport.buildLocal({
    required List<dynamic> transactions,
    DateTime? fromDate,
    DateTime? toDate,
    String? type,
  }) {
    double totalIncome = 0;
    double totalExpense = 0;
    final incomeByCategory = <String, _CatAccumulator>{};
    final expenseByCategory = <String, _CatAccumulator>{};
    final summaries = <TransactionSummary>[];

    for (final tx in transactions) {
      // Apply type filter
      if (type != null && tx.direction != type) continue;

      final amount = tx.amount as double;
      final dir = tx.direction as String;
      final cat = (tx.category as String?) ?? 'uncategorized';
      final date = (tx.timestamp as DateTime);

      if (dir == 'income') {
        totalIncome += amount;
        incomeByCategory.putIfAbsent(cat, () => _CatAccumulator(cat));
        incomeByCategory[cat]!.total += amount;
        incomeByCategory[cat]!.count++;
      } else {
        totalExpense += amount;
        expenseByCategory.putIfAbsent(cat, () => _CatAccumulator(cat));
        expenseByCategory[cat]!.total += amount;
        expenseByCategory[cat]!.count++;
      }

      final y = date.year.toString().padLeft(4, '0');
      final m = date.month.toString().padLeft(2, '0');
      final d = date.day.toString().padLeft(2, '0');

      summaries.add(TransactionSummary(
        id: tx.id as String,
        type: dir,
        amount: amount,
        description: (tx.counterpartyMasked as String?) ?? '',
        date: '$y-$m-$d',
        category: cat,
        currency: 'ETB',
        syncedAt: '',
      ));
    }

    return ExportReport(
      summary: {
        'total_income': totalIncome,
        'total_expense': totalExpense,
        'net_balance': totalIncome - totalExpense,
        'transaction_count': summaries.length,
        'currency': 'ETB',
      },
      incomeByCategory: incomeByCategory.values
          .map((a) => CategoryBreakdown(
              category: a.category, total: a.total, count: a.count))
          .toList(),
      expenseByCategory: expenseByCategory.values
          .map((a) => CategoryBreakdown(
              category: a.category, total: a.total, count: a.count))
          .toList(),
      transactions: summaries,
      generatedAt: DateTime.now().toIso8601String(),
      filtersApplied: {
        if (fromDate != null) 'from_date': fromDate.toIso8601String(),
        if (toDate != null) 'to_date': toDate.toIso8601String(),
        if (type != null) 'type': type,
      },
    );
  }
}

class _CatAccumulator {
  final String category;
  double total = 0;
  int count = 0;
  _CatAccumulator(this.category);
}
