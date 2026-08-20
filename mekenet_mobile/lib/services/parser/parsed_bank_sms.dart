enum TransactionDirection { sent, received }

class ParsedBankSms {
  final String bankName;
  final TransactionDirection direction;
  final double amount;
  final DateTime? timestamp;
  final double? balanceAfter;

  const ParsedBankSms({
    required this.bankName,
    required this.direction,
    required this.amount,
    required this.timestamp,
    this.balanceAfter,
  });
}
