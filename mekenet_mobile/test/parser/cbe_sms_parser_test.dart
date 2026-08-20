import 'package:test/test.dart';
import 'package:mekenet/services/parser/cbe_sms_parser.dart';
import 'package:mekenet/services/parser/parsed_bank_sms.dart';

const msg001 = '''
Dear [name] You have successfully transferred ETB205.00 from account [account number] to account [account number] (name). Service charge of ETB 0.50 and VAT(15%) of ETB0.08 and Disaster Recovery(5%) of 0.03 with total of ETB205.61. Your current balance is ETB2,295.80. Thanks for Banking with CBE. [transaction link] for feedback:[feedback link]
''';

const msg002 = '''
Dear [name] You have successfully transferred ETB560.00 from account [account number] to account [account number] (name). Service charge of ETB 0.50 and VAT(15%) of ETB0.08 and Disaster Recovery(5%) of 0.03 with total of ETB560.61. Your current balance is ETB2,602.02. Thanks for Banking with CBE. [transaction link] for feedback: [feedback link]
''';

const msg003 = '''
Dear [name] You have successfully transferred ETB260.00 from account [account number] to account [account number] (name). Service charge of ETB 0.50 and VAT(15%) of ETB0.08 and Disaster Recovery(5%) of 0.03 with total of ETB260.61. Your current balance is ETB285.24. Thanks for Banking with CBE. [transaction link] for feedback:[feedback link]
''';

const msg004 = '''
Dear [name] You have successfully transferred ETB230.00 from account [account number] to account [account number] (name). Service charge of ETB 0.50 and VAT(15%) of ETB0.08 and Disaster Recovery(5%) of 0.03 with total of ETB230.61. Your current balance is ETB757.07. Thanks for Banking with CBE. [transaction link] for feedback: [feedback link]
''';

const msg005 = '''
Dear [name] You have successfully transferred ETB780.00 from account [account number] to account [account number] (name). Service charge of ETB 0.50 and VAT(15%) of ETB0.08 and Disaster Recovery(5%) of 0.03 with total of ETB780.61. Your current balance is ETB1,449.51. Thanks for Banking with CBE. [transaction link] for feedback: [feedback link]
''';

const msg006 = '''
Dear [name] You have successfully transferred ETB320.00 from account [account number] to account [account number] (name). Service charge of ETB 0.50 and VAT(15%) of ETB0.08 and Disaster Recovery(5%) of 0.03 with total of ETB320.61. Your current balance is ETB3,346.56. Thanks for Banking with CBE. [transaction link] for feedback: [feedback link]
''';

const msg007 = '''
Dear [name] You have received ETB 3,000.00 from account [account number] (name) to your account [account number]. Your current balance is ETB3,042.63. Thanks for Banking with CBE. [transaction link] for feedback: [feedback link]
''';

const msg008 = '''
Dear [name] You have received ETB 160.00 from account [account number](name) to your account [account number]. Your current balance is ETB3,323.95. Thanks for Banking with CBE. [transaction link] for feedback: [feedback link]
''';

const msg009 = '''
Dear [name] You have received ETB 2,500.00 from account [account number] (name) to your account [account number]. Your current balance is ETB2,508.66. Thanks for Banking with CBE. [transaction link] for feedback: [feedback link]
''';

const msg010 = '''
Dear [name] You have received ETB 4,000.00 from account [account number] (name) to your account [account number]. Your current balance is ETB4,343.75. Thanks for Banking with CBE.[transaction link]
''';

const msg011 = '''
Dear [name] You have received ETB 100.00 from account [account number](name) to your account [account number]. Your current balance is ETB151.52. Thanks for Banking with CBE. [transaction link]
''';

void main() {
  group('CbeSmsParser - real samples', () {
    test('msg_001: sent, ETB without space, balance with comma', () {
      final t = CbeSmsParser.parse(msg001)!;
      expect(t.direction, TransactionDirection.sent);
      expect(t.amount, 205.00);
      expect(t.timestamp, isNull);
      expect(t.balanceAfter, 2295.80);
      expect(t.bankName, 'CBE');
    });

    test('msg_002: sent', () {
      final t = CbeSmsParser.parse(msg002)!;
      expect(t.direction, TransactionDirection.sent);
      expect(t.amount, 560.00);
      expect(t.timestamp, isNull);
      expect(t.balanceAfter, 2602.02);
    });

    test('msg_003: sent', () {
      final t = CbeSmsParser.parse(msg003)!;
      expect(t.direction, TransactionDirection.sent);
      expect(t.amount, 260.00);
      expect(t.balanceAfter, 285.24);
    });

    test('msg_004: sent', () {
      final t = CbeSmsParser.parse(msg004)!;
      expect(t.direction, TransactionDirection.sent);
      expect(t.amount, 230.00);
      expect(t.balanceAfter, 757.07);
    });

    test('msg_005: sent, comma-formatted balance', () {
      final t = CbeSmsParser.parse(msg005)!;
      expect(t.direction, TransactionDirection.sent);
      expect(t.amount, 780.00);
      expect(t.balanceAfter, 1449.51);
    });

    test('msg_006: sent', () {
      final t = CbeSmsParser.parse(msg006)!;
      expect(t.direction, TransactionDirection.sent);
      expect(t.amount, 320.00);
      expect(t.balanceAfter, 3346.56);
    });

    test('msg_007: received, comma-formatted amount', () {
      final t = CbeSmsParser.parse(msg007)!;
      expect(t.direction, TransactionDirection.received);
      expect(t.amount, 3000.00);
      expect(t.timestamp, isNull);
      expect(t.balanceAfter, 3042.63);
    });

    test('msg_008: received, no space before name', () {
      final t = CbeSmsParser.parse(msg008)!;
      expect(t.direction, TransactionDirection.received);
      expect(t.amount, 160.00);
      expect(t.balanceAfter, 3323.95);
    });

    test('msg_009: received', () {
      final t = CbeSmsParser.parse(msg009)!;
      expect(t.direction, TransactionDirection.received);
      expect(t.amount, 2500.00);
      expect(t.balanceAfter, 2508.66);
    });

    test('msg_010: received', () {
      final t = CbeSmsParser.parse(msg010)!;
      expect(t.direction, TransactionDirection.received);
      expect(t.amount, 4000.00);
      expect(t.balanceAfter, 4343.75);
    });

    test('msg_011: received, no space before name', () {
      final t = CbeSmsParser.parse(msg011)!;
      expect(t.direction, TransactionDirection.received);
      expect(t.amount, 100.00);
      expect(t.balanceAfter, 151.52);
    });

    test('non-transaction text returns null instead of throwing', () {
      expect(CbeSmsParser.parse('Your OTP is 1234'), isNull);
      expect(CbeSmsParser.parse(''), isNull);
    });
  });
}
