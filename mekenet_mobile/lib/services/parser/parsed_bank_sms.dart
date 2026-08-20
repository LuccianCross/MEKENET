enum TransactionDirection { sent, received }

class ParsedBankSms {
  final String bankName;
  final TransactionDirection direction;
  final double amount;
  final DateTime timestamp;
  final double? balanceAfter;
  final String? transactionId;        // New: transaction reference number
  final String? counterparty;         // New: name or phone of other party
  final double? serviceFee;           // New: transaction fee
  final double? vat;                  // New: VAT on service fee

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
