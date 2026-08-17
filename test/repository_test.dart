import 'package:flutter_test/flutter_test.dart';
import 'package:mekenet/models/transaction.dart';
import 'package:mekenet/models/debt.dart';

void main() {
  group('Transaction Model Tests', () {
    test('Transaction can be created with default values', () {
      final transaction = Transaction(
        direction: 'income',
        amount: 100.0,
        source: 'sms',
        counterpartyMasked: '1234',
      );

      expect(transaction.direction, 'income');
      expect(transaction.amount, 100.0);
      expect(transaction.matchConfidence, 'unmatched');
      expect(transaction.synced, false);
    });

    test('Transaction can be created with all fields', () {
      final transaction = Transaction(
        direction: 'expense',
        amount: 50.0,
        source: 'manual',
        counterpartyMasked: '5678',
        rawSmsHash: 'hash123',
        itemId: 'item123',
        matchConfidence: 'confirmed',
        category: 'stock',
        synced: true,
      );

      expect(transaction.direction, 'expense');
      expect(transaction.amount, 50.0);
      expect(transaction.rawSmsHash, 'hash123');
      expect(transaction.matchConfidence, 'confirmed');
      expect(transaction.synced, true);
    });

    test('Transaction toMap returns correct map', () {
      final transaction = Transaction(
        direction: 'income',
        amount: 100.0,
        source: 'sms',
        counterpartyMasked: '1234',
        rawSmsHash: 'hash123',
      );

      final map = transaction.toMap();
      expect(map['amount'], 100.0);
      expect(map['direction'], 'income');
      expect(map['raw_sms_hash'], 'hash123');
    });
  });

  group('Debt Model Tests', () {
    test('Debt can be created with default values', () {
      final debt = Debt(
        customerName: 'John Doe',
        amount: 500.0,
      );

      expect(debt.customerName, 'John Doe');
      expect(debt.amount, 500.0);
      expect(debt.status, 'open');
    });

    test('Debt toMap returns correct map', () {
      final debt = Debt(
        customerName: 'John Doe',
        amount: 500.0,
      );

      final map = debt.toMap();
      expect(map['customer_name'], 'John Doe');
      expect(map['amount'], 500.0);
      expect(map['status'], 'open');
    });
  });
}