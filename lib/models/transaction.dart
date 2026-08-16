class Transaction {
  final String id;
  final String direction;
  final double amount;
  final String source;
  final String rawSmsHash;
  final String counterpartyMasked;
  final String? itemId;
  final String matchConfidence;
  final String? category;
  final DateTime timestamp;
  final bool synced;

  const Transaction({
    required this.id,
    required this.direction,
    required this.amount,
    required this.source,
    required this.rawSmsHash,
    required this.counterpartyMasked,
    this.itemId,
    required this.matchConfidence,
    this.category,
    required this.timestamp,
    required this.synced,
  });
}