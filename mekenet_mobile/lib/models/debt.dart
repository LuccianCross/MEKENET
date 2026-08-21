import 'package:uuid/uuid.dart';

class Debt {
  final String id;
  final String customerName;
  final double amount;
  final String status;
  final String type; // 'owed_to_me' or 'i_owe'
  final DateTime createdAt;

  Debt({
    String? id,
    required this.customerName,
    required this.amount,
    this.status = 'open',
    this.type = 'owed_to_me',
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_name': customerName,
      'amount': amount,
      'status': status,
      'type': type,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'] as String,
      customerName: map['customer_name'] as String,
      amount: (map['amount'] as num).toDouble(),
      status: map['status'] as String,
      type: (map['type'] as String?) ?? 'owed_to_me',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at'] as int,
      ),
    );
  }
}