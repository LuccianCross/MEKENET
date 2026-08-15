import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'models/transaction.dart';

class TransactionRepository {
  late Isar _isar;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [TransactionSchema],
      directory: dir.path,
    );
    _isInitialized = true;
  }

  Future<void> addTransaction(Transaction txn) async {
    await _isar.writeTxn(() async {
      await _isar.transactions.put(txn);
    });
  }

  Future<List<Transaction>> getAllTransactions() async {
    final transactions = await _isar.transactions.where().findAll();
    // Sort in memory by timestamp descending
    transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return transactions;
  }

  Future<void> deleteTransaction(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.transactions.delete(id);
    });
  }

  Future<double> calculateTotalProfit() async {
    final all = await getAllTransactions();
    double profit = 0;
    for (final txn in all) {
      if (txn.type == TransactionType.income) {
        profit += txn.amount;
      } else {
        profit -= txn.amount;
      }
    }
    return profit;
  }
}
