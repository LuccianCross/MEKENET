import '../storage/models/transaction.dart';

class TelebirrParser {
  /// Parses a raw telebirr SMS and returns a Transaction if successful, or null if it fails to parse.
  static Transaction? parseSms(String smsText) {
    if (smsText.isEmpty) return null;

    final lowerSms = smsText.toLowerCase();

    // Regular expressions for extracting data
    // Matches "received X ETB", "transferred X ETB", "paid X ETB"
    final amountRegExp = RegExp(r'(?:received|transferred|paid)\s+([0-9,.]+)\s+ETB', caseSensitive: false);
    
    // Matches "from <Name>" or "to <Name>" up to a comma or period
    final incomeNameRegExp = RegExp(r'from\s+([A-Za-z\s]+)(?:,|\.)', caseSensitive: false);
    final expenseNameRegExp = RegExp(r'to\s+([A-Za-z\s]+)(?:,|\.)', caseSensitive: false);
    
    // Matches "Transaction ID: <ID>"
    final refRegExp = RegExp(r'Transaction ID:\s*([A-Za-z0-9]+)', caseSensitive: false);

    final amountMatch = amountRegExp.firstMatch(smsText);
    double amount = 0.0;
    if (amountMatch != null && amountMatch.groupCount >= 1) {
      final amountStr = amountMatch.group(1)!.replaceAll(',', '');
      amount = double.tryParse(amountStr) ?? 0.0;
    }

    final refMatch = refRegExp.firstMatch(smsText);
    String? referenceId = refMatch != null ? refMatch.group(1) : null;

    if (lowerSms.contains("received") || lowerSms.contains("credited")) {
      final nameMatch = incomeNameRegExp.firstMatch(smsText);
      final counterparty = nameMatch != null ? nameMatch.group(1)?.trim() : null;

      return Transaction()
        ..type = TransactionType.income
        ..source = TransactionSource.telebirr
        ..amount = amount
        ..currency = "ETB"
        ..counterparty = counterparty
        ..referenceId = referenceId
        ..timestamp = DateTime.now()
        ..rawSms = smsText;
    } else if (lowerSms.contains("paid") || lowerSms.contains("transferred") || lowerSms.contains("debited")) {
      final nameMatch = expenseNameRegExp.firstMatch(smsText);
      final counterparty = nameMatch != null ? nameMatch.group(1)?.trim() : null;

      return Transaction()
        ..type = TransactionType.expense
        ..source = TransactionSource.telebirr
        ..amount = amount
        ..currency = "ETB"
        ..counterparty = counterparty
        ..referenceId = referenceId
        ..timestamp = DateTime.now()
        ..rawSms = smsText;
    }

    return null;
  }
}
