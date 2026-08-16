class Debt {
  final String id;
  final String customerName;
  final double amount;
  final String status;
  final DateTime createdAt;

  const Debt({
    required this.id,
    required this.customerName,
    required this.amount,
    required this.status,
    required this.createdAt,
  });
}