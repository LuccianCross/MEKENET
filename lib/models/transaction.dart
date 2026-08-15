class Transaction {
  // These are the properties every transaction has
  final String id;          // Unique ID (like a receipt number)
  final double amount;      // Money amount (500.0, 1000.0, etc.)
  final String? sender;     // Who sent the money (nullable = can be empty)
  final DateTime timestamp; // When the transaction happened
  final String type;        // 'income', 'expense', or 'debt'
  final String? note;       // Optional note about the transaction

  // This is the "constructor" - it creates a new Transaction
  // 'required' means you MUST provide this value when creating one
  Transaction({
    required this.id,
    required this.amount,
    this.sender,             // No 'required' = optional
    required this.timestamp,
    required this.type,
    this.note,
  });

  // This is a "factory" - a special function that creates fake transactions
  // for testing. We'll use this later for mock data.
  factory Transaction.mock({
    double? amount,
    String? sender,
    DateTime? timestamp,
    String? type,
    String? note,
  }) {
    // Return a new Transaction with either provided values or defaults
    return Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Unique ID from current time
      amount: amount ?? 100.0,      // If amount is null, use 100.0
      sender: sender ?? 'Customer',  // If sender is null, use 'Customer'
      timestamp: timestamp ?? DateTime.now(), // If no timestamp, use now
      type: type ?? 'income',        // If no type, use 'income'
      note: note,
    );
  }
}