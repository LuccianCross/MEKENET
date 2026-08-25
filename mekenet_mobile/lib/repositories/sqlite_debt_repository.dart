import 'package:sqflite_sqlcipher/sqflite.dart';

import '../database/database_helper.dart';
import '../models/debt.dart';
import 'debt_repository.dart';

class SqliteDebtRepository implements DebtRepository {
  Future<Database> get _db async {
    return DatabaseHelper.instance.database;
  }

  @override
  Future<void> save(Debt debt) async {
    final db = await _db;

    await db.insert(
      'debts',
      debt.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<Debt>> getAll() async {
    final db = await _db;

    final rows = await db.query(
      'debts',
      orderBy: 'created_at DESC',
    );

    return rows
        .map((map) => Debt.fromMap(map))
        .toList();
  }

  @override
  Future<Debt?> getById(String id) async {
    final db = await _db;

    final rows = await db.query(
      'debts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return Debt.fromMap(rows.first);
  }

  @override
  Future<void> update(Debt debt) async {
    final db = await _db;

    await db.update(
      'debts',
      debt.toMap(),
      where: 'id = ?',
      whereArgs: [debt.id],
    );
  }

  @override
  Future<void> delete(String id) async {
    final db = await _db;

    await db.delete(
      'debts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<Debt>> getOpen() async {
    final db = await _db;

    final rows = await db.query(
      'debts',
      where: 'status = ?',
      whereArgs: ['open'],
      orderBy: 'created_at DESC',
    );

    return rows
        .map((map) => Debt.fromMap(map))
        .toList();
  }

  @override
  Future<List<Debt>> getPaid() async {
    final db = await _db;

    final rows = await db.query(
      'debts',
      where: 'status = ?',
      whereArgs: ['paid'],
      orderBy: 'created_at DESC',
    );

    return rows
        .map((map) => Debt.fromMap(map))
        .toList();
  }

  @override
  Future<List<Debt>> getOpenByType(String type) async {
    final db = await _db;

    final rows = await db.query(
      'debts',
      where: 'status = ? AND type = ?',
      whereArgs: ['open', type],
      orderBy: 'created_at DESC',
    );

    return rows
        .map((map) => Debt.fromMap(map))
        .toList();
  }
}