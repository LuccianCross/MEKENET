import '../models/transaction.dart';

abstract class TransactionRepository {
  // Core CRUD
  Future<void> save(Transaction transaction);

  Future<List<Transaction>> getByDateRange(
    DateTime start,
    DateTime end,
  );

  Future<Transaction?> getById(String id);

  Future<void> update(Transaction transaction);

  Future<void> delete(String id);

  // Convenience queries for UI
  Future<List<Transaction>> getToday();

  Future<List<Transaction>> getThisWeek();

  Future<List<Transaction>> getThisMonth();

  // Analytics
  Future<double> getTotalIncome(
    DateTime start,
    DateTime end,
  );

  Future<double> getTotalExpenses(
    DateTime start,
    DateTime end,
  );

  // Sync related
  Future<bool> existsBySmsHash(String rawSmsHash);

  Future<List<Transaction>> getUnsynced();

  Future<void> markSynced(String id);

  // Parser related
  Future<List<Transaction>> getUnmatched();

  /// Look up the most common category for a given counterparty name.
  Future<String?> getCategoryByCounterparty(String counterparty);
}