import 'parsed_bank_sms.dart';

class TelebirrSmsParser {
  static final _amountPattern = RegExp(r'ETB\s+([\d,]+\.\d{2})');
  static final _datePattern = RegExp(
    r'on\s+(\d{2}/\d{2}/\d{4}\s+\d{2}:\d{2}:\d{2})',
  );
  static final _balancePattern = RegExp(
    r'balance\s+is\s+ETB\s+([\d,]+\.\d{2})',
    caseSensitive: false,
  );
  static final _transactionIdPattern = RegExp(
    r'transaction\s+number\s+is\s+([\w\d-]+)',
    caseSensitive: false,
  );
  static final _counterpartyPattern = RegExp(
    r'(?:to|from)\s+([^\(]+)\s*\(',
  );
  static final _serviceFeePattern = RegExp(
    r'service\s+fee\s+is\s+ETB\s+([\d,]+\.\d{2})',
    caseSensitive: false,
  );
  static final _vatPattern = RegExp(
    r'VAT.*?is\s+ETB\s+([\d,]+\.\d{2})',
    caseSensitive: false,
  );

  static ParsedBankSms? parse(String smsText) {
    if (smsText.isEmpty) return null;

    final normalizedText = smsText.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (!normalizedText.toUpperCase().contains('ETB')) return null;

    final lower = normalizedText.toLowerCase();

    final isSent = lower.contains('transferred') ||
        lower.contains('tranfered') ||
        lower.contains('have transferred') ||
        lower.contains('havetranfered') ||
        (lower.contains('transfer') && lower.contains('to '));

    final isReceived = lower.contains('you have received') ||
        lower.contains('you havereceived') ||
        lower.contains('received');

    if (!isSent && !isReceived) return null;

    final direction =
        isSent ? TransactionDirection.sent : TransactionDirection.received;

    final amountMatch = _amountPattern.firstMatch(normalizedText);
    if (amountMatch == null) return null;
    final amount = double.parse(
      amountMatch.group(1)!.replaceAll(',', ''),
    );

    final dateMatch = _datePattern.firstMatch(normalizedText);
    if (dateMatch == null) return null;
    final parts = dateMatch.group(1)!.split(' ');
    final dateParts = parts[0].split('/');
    final timeParts = parts[1].split(':');
    final timestamp = DateTime(
      int.parse(dateParts[2]),
      int.parse(dateParts[1]),
      int.parse(dateParts[0]),
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
      int.parse(timeParts[2]),
    );

    final balanceMatch = _balancePattern.firstMatch(normalizedText);
    final txIdMatch = _transactionIdPattern.firstMatch(normalizedText);
    final counterpartyMatch = _counterpartyPattern.firstMatch(normalizedText);
    final feeMatch = _serviceFeePattern.firstMatch(normalizedText);
    final vatMatch = _vatPattern.firstMatch(normalizedText);

    return ParsedBankSms(
      bankName: 'Telebirr',
      direction: direction,
      amount: amount,
      timestamp: timestamp,
      balanceAfter: balanceMatch != null
          ? double.parse(
              balanceMatch.group(1)!.replaceAll(',', ''),
            )
          : null,
      transactionId: txIdMatch?.group(1)?.trim(),
      counterparty: counterpartyMatch?.group(1)?.trim(),
      serviceFee: feeMatch != null
          ? double.parse(feeMatch.group(1)!.replaceAll(',', ''))
          : null,
      vat: vatMatch != null
          ? double.parse(vatMatch.group(1)!.replaceAll(',', ''))
          : null,
    );
  }
}
