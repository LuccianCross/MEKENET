enum TransactionDirection { sent, received }

class ParsedBankSms {
  final String bankName;
  final TransactionDirection direction;
  final double amount;
  final DateTime? timestamp;
  final double? balanceAfter;
  final String? transactionId;
  final String? counterparty;
  final double? serviceFee;
  final double? vat;

  const ParsedBankSms({
    required this.bankName,
    required this.direction,
    required this.amount,
    required this.timestamp,
    this.balanceAfter,
    this.transactionId,
    this.counterparty,
    this.serviceFee,
    this.vat,
  });
}
