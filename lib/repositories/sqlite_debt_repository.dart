import 'package:sqflite_sqlcipher/sqflite.dart';
import '../models/debt.dart';
import 'debt_repository.dart';

class SqliteDebtRepository implements DebtRepository {
  final Database db;

  SqliteDebtRepository(this.db);

  Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS debts (
        id TEXT PRIMARY KEY,
        customer_name TEXT NOT NULL,
        amount REAL NOT NULL,
        status TEXT DEFAULT 'open',
        created_at INTEGER NOT NULL
      )
    ''');
  }

  @override
  Future<void> save(Debt debt) async {
    await db.insert(
      'debts',
      debt.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<Debt>> getAll() async {
    final rows = await db.query(
      'debts',
      orderBy: 'created_at DESC',
    );
    return rows.map((map) => Debt.fromMap(map)).toList();
  }

  @override
  Future<Debt?> getById(String id) async {
    final rows = await db.query(
      'debts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Debt.fromMap(rows.first);
  }

  @override
  Future<void> update(Debt debt) async {
    await db.update(
      'debts',
      debt.toMap(),
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

  @override
  Future<List<Debt>> getOpen() async {
    final rows = await db.query(
      'debts',
      where: 'status = ?',
      whereArgs: ['open'],
      orderBy: 'created_at DESC',
    );
    return rows.map((map) => Debt.fromMap(map)).toList();
  }

  @override
  Future<List<Debt>> getPaid() async {
    final rows = await db.query(
      'debts',
      where: 'status = ?',
      whereArgs: ['paid'],
      orderBy: 'created_at DESC',
    );
    return rows.map((map) => Debt.fromMap(map)).toList();
  }
}