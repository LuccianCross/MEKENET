import 'package:flutter_test/flutter_test.dart';
import 'package:mekenet/core/parser/telebirr_parser.dart';
import 'package:mekenet/core/storage/models/transaction.dart';

void main() {
  group('TelebirrParser', () {
    test('returns null for empty string', () {
      final result = TelebirrParser.parseSms("");
      expect(result, isNull);
    });

    test('parses income SMS correctly', () {
      final sms = "Dear Customer, You have received 5,000.00 ETB from John Doe, 0911223344. Your current balance is 15,000.00 ETB. Transaction ID: ABC123XYZ";
      final result = TelebirrParser.parseSms(sms);
      
      expect(result, isNotNull);
      expect(result!.type, TransactionType.income);
      expect(result.source, TransactionSource.telebirr);
      expect(result.amount, 5000.00);
      expect(result.counterparty, "John Doe");
      expect(result.referenceId, "ABC123XYZ");
    });

    test('parses expense SMS correctly', () {
      final sms = "Dear Customer, You have transferred 300.50 ETB to Abebe Kebede. Your current balance is 1,200.00 ETB. Transaction ID: XYZ987CBA";
      final result = TelebirrParser.parseSms(sms);
      
      expect(result, isNotNull);
      expect(result!.type, TransactionType.expense);
      expect(result.source, TransactionSource.telebirr);
      expect(result.amount, 300.50);
      expect(result.counterparty, "Abebe Kebede");
      expect(result.referenceId, "XYZ987CBA");
    });
  });
}
