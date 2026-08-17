import 'transaction_repository.dart';
import 'sqlite_transaction_repository.dart';

class RepositoryProvider {
  static TransactionRepository? _instance;

  static TransactionRepository get instance {
    _instance ??= SqliteTransactionRepository();
    return _instance!;
  }

  static void useMock(TransactionRepository mock) {
    _instance = mock;
  }

  static void useReal() {
    _instance = SqliteTransactionRepository();
  }
}