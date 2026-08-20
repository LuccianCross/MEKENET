import 'parsed_bank_sms.dart';

class TelebirrSmsParser {
  // Edge case: flexible whitespace around amount (multiple spaces/tabs)
  static final _amountPattern = RegExp(r'ETB\s+([\d,]+\.\d{2})');
  
  // Edge case: flexible whitespace before date, handles "on  " (double space)
  static final _datePattern = RegExp(
    r'on\s+(\d{2}/\d{2}/\d{4}\s+\d{2}:\d{2}:\d{2})',
  );
  
  // Edge case: flexible whitespace in balance pattern
  static final _balancePattern = RegExp(
    r'balance\s+is\s+ETB\s+([\d,]+\.\d{2})',
    caseSensitive: false,
  );
  
  // New: Extract transaction ID (edge case: may have different formats)
  static final _transactionIdPattern = RegExp(
    r'transaction number is\s+([\w\d-]+)',
    caseSensitive: false,
  );
  
  // New: Extract counterparty name (edge case: may or may not have spaces)
  static final _counterpartyPattern = RegExp(
    r'(?:to|from)\s+([^\(]+)\s*\(',
  );
  
  // New: Extract service fee (edge case: variable spacing)
  static final _serviceFeePattern = RegExp(
    r'service fee is\s+ETB\s+([\d,]+\.\d{2})',
    caseSensitive: false,
  );
  
  // New: Extract VAT (edge case: may have variations in wording)
  static final _vatPattern = RegExp(
    r'VAT.*?is\s+ETB\s+([\d,]+\.\d{2})',
    caseSensitive: false,
  );

  static ParsedBankSms? parse(String smsText) {
    // Edge case: normalize whitespace first (multiple spaces -> single space)
    final normalizedText = smsText.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // Edge case: handle empty or very short messages
    if (normalizedText.isEmpty || normalizedText.length < 20) return null;
    
    // Edge case: case-insensitive currency check
    if (!normalizedText.toUpperCase().contains('ETB')) return null;
    
    // Edge case: case-insensitive telebirr check
    if (!normalizedText.toLowerCase().contains('telebirr')) return null;

    // Edge case: check for transaction keywords (case-insensitive)
    final lowerText = normalizedText.toLowerCase();
    if (!lowerText.contains('you have transferred') &&
        !lowerText.contains('you have received') &&
        !lowerText.contains('transferred') &&
        !lowerText.contains('received')) {
      return null;
    }

    // Determine direction with edge case handling
    final direction = lowerText.contains('you have transferred') ||
            lowerText.contains('transferred')
        ? TransactionDirection.sent
        : TransactionDirection.received;

    // Extract amount (edge case: handle missing amount gracefully)
    final amountMatch = _amountPattern.firstMatch(normalizedText);
    if (amountMatch == null) return null;
    
    // Edge case: safe parsing with error handling
    double? amount;
    try {
      amount = double.parse(
        amountMatch.group(1)!.replaceAll(',', ''),
      );
      // Edge case: validate amount is positive
      if (amount <= 0) return null;
    } catch (e) {
      return null;
    }

    // Extract date (edge case: handle date parsing errors)
    final dateMatch = _datePattern.firstMatch(normalizedText);
    if (dateMatch == null) return null;
    
    DateTime? timestamp;
    try {
      final parts = dateMatch.group(1)!.split(' ');
      final dateParts = parts[0].split('/');
      final timeParts = parts[1].split(':');
      
      // Edge case: validate date components before parsing
      if (dateParts.length != 3 || timeParts.length != 3) return null;
      
      timestamp = DateTime(
        int.parse(dateParts[2]), // year
        int.parse(dateParts[1]), // month
        int.parse(dateParts[0]), // day
        int.parse(timeParts[0]), // hour
        int.parse(timeParts[1]), // minute
        int.parse(timeParts[2]), // second
      );
      
      // Edge case: validate timestamp is reasonable (not in far future)
      final now = DateTime.now();
      if (timestamp.isAfter(now.add(const Duration(days: 365)))) {
        return null;
      }
    } catch (e) {
      return null;
    }

    // Extract optional fields with edge case handling
    final balanceMatch = _balancePattern.firstMatch(normalizedText);
    double? balanceAfter;
    if (balanceMatch != null) {
      try {
        balanceAfter = double.parse(
          balanceMatch.group(1)!.replaceAll(',', ''),
        );
      } catch (e) {
        // Edge case: ignore balance if parsing fails
        balanceAfter = null;
      }
    }

    // Extract transaction ID (new field)
    final txIdMatch = _transactionIdPattern.firstMatch(normalizedText);
    final transactionId = txIdMatch?.group(1)?.trim();

    // Extract counterparty name (new field)
    final counterpartyMatch = _counterpartyPattern.firstMatch(normalizedText);
    final counterparty = counterpartyMatch?.group(1)?.trim();

    // Extract service fee (new field)
    final feeMatch = _serviceFeePattern.firstMatch(normalizedText);
    double? serviceFee;
    if (feeMatch != null) {
      try {
        serviceFee = double.parse(
          feeMatch.group(1)!.replaceAll(',', ''),
        );
      } catch (e) {
        serviceFee = null;
      }
    }

    // Extract VAT (new field)
    final vatMatch = _vatPattern.firstMatch(normalizedText);
    double? vat;
    if (vatMatch != null) {
      try {
        vat = double.parse(
          vatMatch.group(1)!.replaceAll(',', ''),
        );
      } catch (e) {
        vat = null;
      }
    }

    return ParsedBankSms(
      bankName: 'Telebirr',
      direction: direction,
      amount: amount,
      timestamp: timestamp,
      balanceAfter: balanceAfter,
      transactionId: transactionId,
      counterparty: counterparty,
      serviceFee: serviceFee,
      vat: vat,
    );
  }
}
