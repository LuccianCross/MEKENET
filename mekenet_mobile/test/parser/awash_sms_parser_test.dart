import 'package:test/test.dart';
import 'package:mekenet/services/parser/awash_sms_parser.dart';
import 'package:mekenet/services/parser/parsed_bank_sms.dart';

const transferMsg1 = '''
Dear Customer , You have transferred to other bank ETB  500  To [account number] (name) In Commercial Bank of Ethiopia with charge of 3.00 VAT: 0.45  EDRRF 0.15 ETB. Your available Balance is  ETB 1,077.20. Receipt Link: [transaction link]. Contact Center  8980.
''';

const transferMsg2 = '''
Dear Customer , You have transferred to other bank ETB  1,000  To [account number] (name) In Commercial Bank of Ethiopia with charge of 6.00 VAT: 0.90  EDRRF 0.30 ETB. Your available Balance is  ETB 1,580.80. Receipt Link: [transaction link]. Contact Center  8980.
''';

const transferMsg3 = '''
Dear Customer , You have transferred to other bank ETB  800  To [account number] (name) In Commercial Bank of Ethiopia VAT: 0.72. Your available Balance is  ETB 88.55. Receipt Link: [transaction link]. Contact Center  8980.
''';

const receivedMsg1 = '''
Dear Customer, ETB 2,000 has been credited to your account from (name) on : 2026-08-07 20:41:52 with Txn ID: [link]. Your available balance is now ETB 2,588.00. Receipt Link: [transaction link] Contact center 8980.
''';

const receivedMsg2 = '''
Dear Customer, your Account [account number] has been Credited with ETB 500.00 on 2026-07-31 14:28:33 by(name). Your balance now is ETB 588.55. For any complaint or enquiry, please call 8980. Awash Bank.
''';

void main() {
  group('AwashSmsParser - real samples', () {
    test('transfer: extracts sent direction, amount and balance', () {
      final t = AwashSmsParser.parse(transferMsg1)!;

      expect(t.direction, TransactionDirection.sent);
      expect(t.amount, 500.00);
      expect(t.balanceAfter, 1077.20);
      expect(t.bankName, 'Awash');
    });

    test('transfer: handles comma-formatted amount', () {
      final t = AwashSmsParser.parse(transferMsg2)!;

      expect(t.direction, TransactionDirection.sent);
      expect(t.amount, 1000.00);
      expect(t.balanceAfter, 1580.80);
    });

    test('transfer: handles transfer without charge text', () {
      final t = AwashSmsParser.parse(transferMsg3)!;

      expect(t.direction, TransactionDirection.sent);
      expect(t.amount, 800.00);
      expect(t.balanceAfter, 88.55);
    });

    test('received: extracts received direction, amount and balance', () {
      final t = AwashSmsParser.parse(receivedMsg1)!;

      expect(t.direction, TransactionDirection.received);
      expect(t.amount, 2000.00);
      expect(t.balanceAfter, 2588.00);
      expect(t.bankName, 'Awash');
    });

    test('received: handles "Credited with" format', () {
      final t = AwashSmsParser.parse(receivedMsg2)!;

      expect(t.direction, TransactionDirection.received);
      expect(t.amount, 500.00);
      expect(t.balanceAfter, 588.55);
    });

    test('non-transaction text returns null', () {
      expect(AwashSmsParser.parse('Your OTP is 1234'), isNull);
      expect(AwashSmsParser.parse(''), isNull);
    });
  });
}