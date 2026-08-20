import 'parsed_bank_sms.dart';

class AwashSmsParser {
  static final _amountPattern = RegExp(
    r'ETB\s*([\d,]+(?:\.\d{2})?)',
    caseSensitive: false,
  );

  static final _datePattern = RegExp(
    r'(?:on\s*:?\s*)?(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2})',
    caseSensitive: false,
  );

  static final _balancePattern = RegExp(
    r'(?:available\s+balance\s+is(?:\s+now)?|balance\s+now\s+is)\s*ETB\s*([\d,]+\.\d{2})',
    caseSensitive: false,
  );

  static ParsedBankSms? parse(String smsText) {
    if (smsText.trim().isEmpty) return null;

    final normalizedText = smsText.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (!RegExp(r'\bETB\b', caseSensitive: false).hasMatch(normalizedText)) {
      return null;
    }

    final isSent = RegExp(
      r'\btransferred\s+to\s+other\s+bank\b',
      caseSensitive: false,
    ).hasMatch(normalizedText);

    final isReceived = RegExp(
      r'\b(?:has\s+been\s+credited\s+to\s+your\s+account|has\s+been\s+credited\s+with)\b',
      caseSensitive: false,
    ).hasMatch(normalizedText);

    if (!isSent && !isReceived) return null;

    final direction = isSent
        ? TransactionDirection.sent
        : TransactionDirection.received;

    final amountMatch = _amountPattern.firstMatch(normalizedText);
    if (amountMatch == null) return null;

    final amount = double.parse(amountMatch.group(1)!.replaceAll(',', ''));

    DateTime? timestamp;

    final dateMatch = _datePattern.firstMatch(normalizedText);

    if (dateMatch != null) {
      final parts = dateMatch.group(1)!.split(' ');
      final dateParts = parts[0].split('-');
      final timeParts = parts[1].split(':');

      timestamp = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
        int.parse(timeParts[2]),
      );
    }

    final balanceMatch = _balancePattern.firstMatch(normalizedText);

    return ParsedBankSms(
      bankName: 'Awash',
      direction: direction,
      amount: amount,
      timestamp: timestamp,
      balanceAfter: balanceMatch != null
          ? double.parse(balanceMatch.group(1)!.replaceAll(',', ''))
          : null,
    );
  }
}
