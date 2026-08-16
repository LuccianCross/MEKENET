import '../models/transaction.dart';

abstract class TransactionRepository {
  Future<List<Transaction>> getTransactions();
  Future<void> addTransaction(Transaction transaction);
  Future<double> getTotalIncome(DateTime start, DateTime end);
  Future<List<Transaction>> getDebts();
}