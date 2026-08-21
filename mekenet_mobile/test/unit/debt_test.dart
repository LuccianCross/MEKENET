import 'package:flutter_test/flutter_test.dart';
import 'package:mekenet/models/debt.dart';

void main() {
  group('Debt model', () {
    test('defaults to owed_to_me when type not provided', () {
      final debt = Debt(
        customerName: 'Abebe',
        amount: 500,
      );
      expect(debt.type, 'owed_to_me');
      expect(debt.status, 'open');
    });

    test('serializes and deserializes with type field', () {
      final debt = Debt(
        id: 'test-123',
        customerName: 'Kebede',
        amount: 1000,
        type: 'i_owe',
        status: 'open',
      );

      final map = debt.toMap();
      expect(map['type'], 'i_owe');

      final restored = Debt.fromMap(map);
      expect(restored.type, 'i_owe');
      expect(restored.customerName, 'Kebede');
      expect(restored.amount, 1000.0);
    });

    test('backward compatible: missing type defaults to owed_to_me', () {
      final map = {
        'id': 'old-debt',
        'customer_name': 'Tigist',
        'amount': 250,
        'status': 'open',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      };

      final debt = Debt.fromMap(map);
      expect(debt.type, 'owed_to_me');
    });

    test('generates id when not provided', () {
      final debt = Debt(
        customerName: 'Test',
        amount: 100,
      );
      expect(debt.id, isNotEmpty);
    });

    test('uses provided id when given', () {
      final debt = Debt(
        id: 'custom-id',
        customerName: 'Test',
        amount: 100,
      );
      expect(debt.id, 'custom-id');
    });
  });
}
