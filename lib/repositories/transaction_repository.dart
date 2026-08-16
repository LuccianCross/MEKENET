import '../models/transaction.dart';

abstract class TransactionRepository {
  Future<void> save(Transaction transaction);

  Future<List<Transaction>> getByDateRange(
    DateTime start,
    DateTime end,
  );

  Future<Transaction?> getById(String id);

  Future<void> update(Transaction transaction);

  Future<void> delete(String id);
}