import 'package:test/test.dart';
import 'package:app/lib/services/parser/telebirr_sms_parser.dart';

// These are the exact 10 real, redacted messages saved in
// app/test_assets/telebirr_sms_samples.md. Keep this file in sync with
// that one if new samples are added.

const msg001 = '''
Dear [name]
You have transferred ETB 110.00 to [name] (phone) on 08/08/2026 14:16:26. Your transaction number is [transaction id]. The service fee is  ETB 1.74 and  15% VAT on the service fee is ETB 0.26. Your current E-Money Account  balance is ETB 101.10. To download your payment information please click this link:[transaction link]

Thank you for using telebirr
Ethio telecom''';

const msg002 = '''
Dear [name]
You have received ETB 340.00 from [name] (phone) transaction id on 01/06/2026 18:18:43. Your transaction number is [transaction id]. Your current E-Money Account balance is ETB 340.00.
Thank you for using telebirr
Ethio telecom''';

const msg003 = '''
Dear [name]
You have transferred ETB 200.00 to [name] (phone) on 03/08/2026 19:45:37. Your transaction number is [transaction id]. The service fee is  ETB 1.74 and  15% VAT on the service fee is ETB 0.26. Your current E-Money Account  balance is ETB 77.90. To download your payment information please click this link:[transaction link]

Thank you for using telebirr
Ethio telecom''';

const msg004 = '''
Dear [name]
You have received ETB 80.00 from [name](phone) on 10/08/2026 15:25:36. Your transaction number is [transaction id]. Your current E-Money Account balance is ETB 120.20.
Thank you for using telebirr
Ethio telecom''';

const msg005 = '''
Dear [name]
You have transferred ETB 150.00 to [name](phone) on 18/04/2026 22:33:12. Your transaction number is [transation id]. The service fee is  ETB 1.74 and  15% VAT on the service fee is ETB 0.26. Your current E-Money Account  balance is ETB 89.25. To download your payment information please click this link:[transaction link]
Thank you for using telebirr
Ethio telecom''';

const msg006 = '''
Dear [name]
You have received ETB 2,000.00 from [name](phone)  on 25/07/2026 15:24:18. Your transaction number is [transaciton id]. Your current E-Money Account balance is ETB 2,064.39.
Thank you for using telebirr
Ethio telecom''';

const msg007 = '''
Dear [name]
You have transferred ETB 400.00 to [name] (phone) on 31/03/2026 14:06:10. Your transaction number is [transaction id]. The service fee is  ETB 1.74 and  15% VAT on the service fee is ETB 0.26. Your current E-Money Account  balance is ETB 597.71. To download your payment information please click this link:[transaction link]

Thank you for using telebirr
Ethio telecom''';

const msg008 = '''
Dear [name]
You have received ETB 80.00 from [name](phone)  on 10/08/2026 19:18:09. Your transaction number is [transaction id]. Your current E-Money Account balance is ETB 80.00.
Thank you for using telebirr
Ethio telecom''';

const msg009 = '''
Dear [name]
You have transferred ETB 65.00 to [name](phone) on 03/03/2026 21:52:18. Your transaction number is [transaction id]. The service fee is  ETB 0.87 and  15% VAT on the service fee is ETB 0.13. Your current E-Money Account  balance is ETB 64.74. To download your payment information please click this link:[transaction link]

Thank you for using telebirr
Ethio telecom''';

const msg010 = '''
Dear [name]
You have received ETB 200.00 from [name](phone)  on 03/07/2026 07:30:30. Your transaction number is [transaction id]. Your current E-Money Account balance is ETB 200.00.
Thank you for using telebirr
Ethio telecom''';

void main() {
  group('TelebirrSmsParser - real samples', () {
    test('msg_001: sent, has fee/VAT, single-space "(phone)"', () {
      final t = TelebirrSmsParser.parse(msg001)!;
      expect(t.direction, TransactionDirection.sent);
      expect(t.amount, 110.00);
      expect(t.timestamp, DateTime(2026, 8, 8, 14, 16, 26));
      expect(t.serviceFee, 1.74);
      expect(t.vat, 0.26);
      expect(t.balanceAfter, 101.10);
    });

    test('msg_002: received, extra "transaction id" text before "on"', () {
      final t = TelebirrSmsParser.parse(msg002)!;
      expect(t.direction, TransactionDirection.received);
      expect(t.amount, 340.00);
      expect(t.timestamp, DateTime(2026, 6, 1, 18, 18, 43));
      expect(t.serviceFee, isNull);
      expect(t.vat, isNull);
      expect(t.balanceAfter, 340.00);
    });

    test('msg_003: sent', () {
      final t = TelebirrSmsParser.parse(msg003)!;
      expect(t.direction, TransactionDirection.sent);
      expect(t.amount, 200.00);
      expect(t.balanceAfter, 77.90);
    });

    test('msg_004: received, no space before "(phone)"', () {
      final t = TelebirrSmsParser.parse(msg004)!;
      expect(t.direction, TransactionDirection.received);
      expect(t.amount, 80.00);
      expect(t.balanceAfter, 120.20);
    });

    test('msg_005: sent, no space before "(phone)"', () {
      final t = TelebirrSmsParser.parse(msg005)!;
      expect(t.direction, TransactionDirection.sent);
      expect(t.amount, 150.00);
      expect(t.serviceFee, 1.74);
      expect(t.vat, 0.26);
    });

    test('msg_006: received, comma-formatted amount and balance', () {
      final t = TelebirrSmsParser.parse(msg006)!;
      expect(t.direction, TransactionDirection.received);
      expect(t.amount, 2000.00);
      expect(t.balanceAfter, 2064.39);
    });

    test('msg_007: sent', () {
      final t = TelebirrSmsParser.parse(msg007)!;
      expect(t.direction, TransactionDirection.sent);
      expect(t.amount, 400.00);
      expect(t.balanceAfter, 597.71);
    });

    test('msg_008: received, double space before "on"', () {
      final t = TelebirrSmsParser.parse(msg008)!;
      expect(t.direction, TransactionDirection.received);
      expect(t.amount, 80.00);
      expect(t.balanceAfter, 80.00);
    });

    test('msg_009: sent, smaller fee tier (0.87 / 0.13)', () {
      final t = TelebirrSmsParser.parse(msg009)!;
      expect(t.direction, TransactionDirection.sent);
      expect(t.amount, 65.00);
      expect(t.serviceFee, 0.87);
      expect(t.vat, 0.13);
      expect(t.balanceAfter, 64.74);
    });

    test('msg_010: received, double space before "on"', () {
      final t = TelebirrSmsParser.parse(msg010)!;
      expect(t.direction, TransactionDirection.received);
      expect(t.amount, 200.00);
      expect(t.balanceAfter, 200.00);
    });

    test('non-transaction text returns null instead of throwing', () {
      expect(TelebirrSmsParser.parse('Your OTP is 1234'), isNull);
      expect(TelebirrSmsParser.parse(''), isNull);
    });
  });
}
