import 'package:uuid/uuid.dart';

class Transaction {
  final String id;
  final String direction;
  final double amount;
  final String source;
  final String? rawSmsHash;
  final String counterpartyMasked;
  final String? itemId;
  final String matchConfidence;
  final String? category;
  final DateTime timestamp;
  final bool synced;

  Transaction({
    String? id,
    required this.direction,
    required this.amount,
    required this.source,
    this.rawSmsHash,
    required this.counterpartyMasked,
    this.itemId,
    this.matchConfidence = 'unmatched',
    this.category,
    DateTime? timestamp,
    this.synced = false,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'direction': direction,
      'amount': amount,
      'source': source,
      'raw_sms_hash': rawSmsHash,
      'counterparty_masked': counterpartyMasked,
      'item_id': itemId,
      'match_confidence': matchConfidence,
      'category': category,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'synced': synced ? 1 : 0,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      direction: map['direction'] as String,
      amount: (map['amount'] as num).toDouble(),
      source: map['source'] as String,
      rawSmsHash: map['raw_sms_hash'] as String?,
      counterpartyMasked: map['counterparty_masked'] as String,
      itemId: map['item_id'] as String?,
      matchConfidence: map['match_confidence'] as String,
      category: map['category'] as String?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      synced: (map['synced'] as int) == 1,
    );
  }
}