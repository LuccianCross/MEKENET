class Transaction {
  final String id;
  final double amount;
  final String? sender;
  final DateTime timestamp;
  final String type; // 'income', 'expense', 'debt'
  final String? note;

  Transaction({
    required this.id,
    required this.amount,
    this.sender,
    required this.timestamp,
    required this.type,
    this.note,
  });

  factory Transaction.mock({
    double? amount,
    String? sender,
    DateTime? timestamp,
    String? type,
    String? note,
  }) {
    return Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount ?? 100.0,
      sender: sender ?? 'Customer',
      timestamp: timestamp ?? DateTime.now(),
      type: type ?? 'income',
      note: note,
    );
  }
}