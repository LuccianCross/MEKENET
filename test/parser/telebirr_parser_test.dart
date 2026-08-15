import 'package:flutter_test/flutter_test.dart';
import 'package:mekenet/core/parser/telebirr_parser.dart';
import 'package:mekenet/core/storage/models/transaction.dart';

void main() {
  group('TelebirrParser', () {
    test('returns null for empty string', () {
      final result = TelebirrParser.parseSms("");
      expect(result, isNull);
    });

    test('parses income SMS skeleton', () {
      final sms = "You have received 100 ETB from John Doe...";
      final result = TelebirrParser.parseSms(sms);
      
      expect(result, isNotNull);
      expect(result!.type, TransactionType.income);
      expect(result.source, TransactionSource.telebirr);
    });

    test('parses expense SMS skeleton', () {
      final sms = "You have paid 50 ETB to Some Store...";
      final result = TelebirrParser.parseSms(sms);
      
      expect(result, isNotNull);
      expect(result!.type, TransactionType.expense);
      expect(result.source, TransactionSource.telebirr);
    });
  });
}
