import 'parsed_bank_sms.dart';

class TelebirrSmsParser {
  static final _amountPattern = RegExp(r'ETB\s+([\d,]+\.\d{2})');
  static final _datePattern = RegExp(
    r'on\s+(\d{2}/\d{2}/\d{4}\s+\d{2}:\d{2}:\d{2})',
  );
  static final _balancePattern = RegExp(
    r'balance is\s+ETB\s+([\d,]+\.\d{2})',
  );

  static ParsedBankSms? parse(String smsText) {
    if (smsText.isEmpty) return null;
    if (!smsText.toUpperCase().contains('ETB')) return null;

    final lower = smsText.toLowerCase();

    // Detect direction: look for transfer/receive keywords (handles typos, spacing)
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

    final amountMatch = _amountPattern.firstMatch(smsText);
    if (amountMatch == null) return null;
    final amount = double.parse(
      amountMatch.group(1)!.replaceAll(',', ''),
    );

    final dateMatch = _datePattern.firstMatch(smsText);
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

    final balanceMatch = _balancePattern.firstMatch(smsText);

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
    );
  }
}
