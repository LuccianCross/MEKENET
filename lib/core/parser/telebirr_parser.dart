import '../storage/models/transaction.dart';

class TelebirrParser {
  /// Parses a raw telebirr SMS and returns a Transaction if successful, or null if it fails to parse.
  static Transaction? parseSms(String smsText) {
    if (smsText.isEmpty) return null;

    final lowerSms = smsText.toLowerCase();

    // Skeleton implementation
    if (lowerSms.contains("received") || lowerSms.contains("credited")) {
      return Transaction()
        ..type = TransactionType.income
        ..source = TransactionSource.telebirr
        ..amount = 0.0 // To be parsed properly
        ..currency = "ETB"
        ..timestamp = DateTime.now()
        ..rawSms = smsText;
    } else if (lowerSms.contains("paid") || lowerSms.contains("transferred") || lowerSms.contains("debited")) {
      return Transaction()
        ..type = TransactionType.expense
        ..source = TransactionSource.telebirr
        ..amount = 0.0 // To be parsed properly
        ..currency = "ETB"
        ..timestamp = DateTime.now()
        ..rawSms = smsText;
    }

    return null;
  }
}
