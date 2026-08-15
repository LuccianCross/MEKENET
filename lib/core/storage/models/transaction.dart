import 'package:isar/isar.dart';

part 'transaction.g.dart';

enum TransactionType { income, expense }
enum TransactionSource { telebirr, cash, manualDebt, other }

@collection
class Transaction {
  Id id = Isar.autoIncrement;

  @enumerated
  late TransactionType type;

  late double amount;

  late String currency;

  late DateTime timestamp;

  @enumerated
  late TransactionSource source;

  String? counterparty;

  String? referenceId;

  String? rawSms;

  bool isSynced = false;

  List<String> tags = [];
}
