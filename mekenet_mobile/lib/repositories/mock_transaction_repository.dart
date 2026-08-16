import '../models/transaction.dart';
import 'transaction_repository.dart';

class MockTransactionRepository implements TransactionRepository {
  final List<Transaction> _transactions = [
    Transaction.mock(amount: 500, sender: 'Tigist', type: 'income'),
    Transaction.mock(amount: 1200, sender: 'Abebe', type: 'income'),
    Transaction.mock(amount: 300, sender: 'Meron', type: 'income'),
    Transaction.mock(amount: 150, type: 'expense', note: 'Bought inventory'),
    Transaction.mock(amount: 1000, sender: 'Kebede', type: 'debt', note: 'Owes me'),
  ];

  @override
  Future<List<Transaction>> getTransactions() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _transactions;
  }

  @override
  Future<void> addTransaction(Transaction transaction) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _transactions.add(transaction);
  }

  @override
  Future<double> getTotalIncome(DateTime start, DateTime end) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final income = _transactions
        .where((t) => 
            t.type == 'income' && 
            t.timestamp.isAfter(start) && 
            t.timestamp.isBefore(end))
        .fold(0.0, (sum, t) => sum + t.amount);
    return income;
  }

  @override
  Future<List<Transaction>> getDebts() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _transactions.where((t) => t.type == 'debt').toList();
  }
}