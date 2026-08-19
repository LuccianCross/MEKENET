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
}
