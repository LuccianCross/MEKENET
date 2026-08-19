import 'parsed_bank_sms.dart';

class CbeSmsParser {
  static final _amountPattern = RegExp(r'ETB\s*([\d,]+\.\d{2})');
  static final _datePattern = RegExp(
    r'on\s+(\d{2}/\d{2}/\d{4}\s+\d{2}:\d{2}:\d{2})',
  );
  static final _balancePattern = RegExp(
    r'balance\s+is\s+ETB\s*([\d,]+\.\d{2})',
  );

  static ParsedBankSms? parse(String smsText) {
    if (smsText.isEmpty) return null;
    if (!smsText.contains('ETB')) return null;
    if (!smsText.contains('CBE') &&
        !smsText.contains('Commercial Bank')) {
      return null;
    }

    if (!smsText.contains('debited') &&
        !smsText.contains('credited')) {
      return null;
    }

    final direction = smsText.contains('debited')
        ? TransactionDirection.sent
        : TransactionDirection.received;

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
      bankName: 'CBE',
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
