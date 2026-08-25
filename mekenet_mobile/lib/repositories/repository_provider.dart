import 'debt_repository.dart';
import 'sqlite_debt_repository.dart';
import 'sqlite_transaction_repository.dart';
import 'transaction_repository.dart';

class RepositoryProvider {
  static TransactionRepository? _transactionInstance;
  static DebtRepository? _debtInstance;

  static TransactionRepository get transaction {
    _transactionInstance ??=
        SqliteTransactionRepository();

    return _transactionInstance!;
  }

  static DebtRepository get debt {
    _debtInstance ??=
        SqliteDebtRepository();

    return _debtInstance!;
  }

  static void useTransactionMock(
    TransactionRepository mock,
  ) {
    _transactionInstance = mock;
  }

  static void useDebtMock(
    DebtRepository mock,
  ) {
    _debtInstance = mock;
  }

  static void useReal() {
    _transactionInstance =
        SqliteTransactionRepository();

    _debtInstance =
        SqliteDebtRepository();
  }
}