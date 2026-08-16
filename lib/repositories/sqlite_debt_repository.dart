import 'package:sqflite_sqlcipher/sqflite.dart';
import '../models/debt.dart';
import 'debt_repository.dart';

class SqliteDebtRepository implements DebtRepository {
  final Database db;

  SqliteDebtRepository(this.db);

  @override
  Future<void> save(Debt debt) async {
    await db.insert(
      'debts',
      _toMap(debt),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<Debt>> getAll() async {
    final rows = await db.query(
      'debts',
      orderBy: 'created_at ASC',
    );

    return rows.map(_fromMap).toList();
  }

  @override
  Future<Debt?> getById(String id) async {
    final rows = await db.query(
      'debts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return _fromMap(rows.first);
  }

  @override
  Future<void> update(Debt debt) async {
    await db.update(
      'debts',
      _toMap(debt),
      where: 'id = ?',
      whereArgs: [debt.id],
    );
  }

  @override
  Future<void> delete(String id) async {
    await db.delete(
      'debts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Map<String, Object?> _toMap(Debt debt) {
    return {
      'id': debt.id,
      'customer_name': debt.customerName,
      'amount': debt.amount,
      'status': debt.status,
      'created_at': debt.createdAt.millisecondsSinceEpoch,
    };
  }

  Debt _fromMap(Map<String, Object?> map) {
    return Debt(
      id: map['id'] as String,
      customerName: map['customer_name'] as String,
      amount: (map['amount'] as num).toDouble(),
      status: map['status'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at'] as int,
      ),
    );
  }
}