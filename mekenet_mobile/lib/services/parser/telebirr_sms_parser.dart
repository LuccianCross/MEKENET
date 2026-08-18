enum TransactionDirection { sent, received }

class ParsedTelebirrSms {
  final TransactionDirection direction;
  final double amount;
  final DateTime timestamp;
  final double? serviceFee;
  final double? vat;
  final double? balanceAfter;

  const ParsedTelebirrSms({
    required this.direction,
    required this.amount,
    required this.timestamp,
    this.serviceFee,
    this.vat,
    this.balanceAfter,
  });
}

class TelebirrSmsParser {
  static final _amountPattern = RegExp(r'ETB\s+([\d,]+\.\d{2})');
  static final _datePattern = RegExp(r'on\s+(\d{2}/\d{2}/\d{4}\s+\d{2}:\d{2}:\d{2})');
  static final _feePattern = RegExp(r'service fee is\s+ETB\s+([\d,]+\.\d{2})');
  static final _vatPattern = RegExp(r'VAT on the service fee is\s+ETB\s+([\d,]+\.\d{2})');
  static final _balancePattern = RegExp(r'balance is\s+ETB\s+([\d,]+\.\d{2})');

  static ParsedTelebirrSms? parse(String smsText) {
    if (smsText.isEmpty) return null;
    if (!smsText.contains('ETB')) return null;
    if (!smsText.contains('You have transferred') &&
        !smsText.contains('You have received')) {
      return null;
    }

    final direction = smsText.contains('You have transferred')
        ? TransactionDirection.sent
        : TransactionDirection.received;

    final amountMatch = _amountPattern.firstMatch(smsText);
    if (amountMatch == null) return null;
    final amount = double.parse(amountMatch.group(1)!.replaceAll(',', ''));

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

    final feeMatch = _feePattern.firstMatch(smsText);
    final vatMatch = _vatPattern.firstMatch(smsText);
    final balanceMatch = _balancePattern.firstMatch(smsText);

    return ParsedTelebirrSms(
      direction: direction,
      amount: amount,
      timestamp: timestamp,
      serviceFee: feeMatch != null
          ? double.parse(feeMatch.group(1)!.replaceAll(',', ''))
          : null,
      vat: vatMatch != null
          ? double.parse(vatMatch.group(1)!.replaceAll(',', ''))
          : null,
      balanceAfter: balanceMatch != null
          ? double.parse(balanceMatch.group(1)!.replaceAll(',', ''))
          : null,
    );
  }
}
