import 'package:sqflite_sqlcipher/sqflite.dart' hide Transaction;

import '../database/database_helper.dart';
import '../models/transaction.dart';
import 'transaction_repository.dart';

class SqliteTransactionRepository
    implements TransactionRepository {
  Future<Database> get _db async {
    return DatabaseHelper.instance.database;
  }

  @override
  Future<void> save(Transaction transaction) async {
    final db = await _db;

    await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<Transaction>> getByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _db;

    final rows = await db.query(
      'transactions',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
      orderBy: 'timestamp DESC',
    );

    return rows
        .map((map) => Transaction.fromMap(map))
        .toList();
  }

  @override
  Future<Transaction?> getById(String id) async {
    final db = await _db;

    final rows = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return Transaction.fromMap(rows.first);
  }

  @override
  Future<void> update(Transaction transaction) async {
    final db = await _db;

    await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  @override
  Future<void> delete(String id) async {
    final db = await _db;

    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<Transaction>> getToday() async {
    final now = DateTime.now();

    final start = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final end = start.add(
      const Duration(days: 1),
    );

    return getByDateRange(start, end);
  }

  @override
  Future<List<Transaction>> getThisWeek() async {
    final now = DateTime.now();

    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(
      Duration(days: now.weekday - 1),
    );

    final end = start.add(
      const Duration(days: 7),
    );

    return getByDateRange(start, end);
  }

  @override
  Future<List<Transaction>> getThisMonth() async {
    final now = DateTime.now();

    final start = DateTime(
      now.year,
      now.month,
      1,
    );

    final end = DateTime(
      now.year,
      now.month + 1,
      1,
    );

    return getByDateRange(start, end);
  }

  @override
  Future<double> getTotalIncome(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _db;

    final result = await db.rawQuery(
      '''
      SELECT SUM(amount) AS total
      FROM transactions
      WHERE direction = 'income'
        AND timestamp >= ?
        AND timestamp < ?
      ''',
      [
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  @override
  Future<double> getTotalExpenses(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _db;

    final result = await db.rawQuery(
      '''
      SELECT SUM(amount) AS total
      FROM transactions
      WHERE direction = 'expense'
        AND timestamp >= ?
        AND timestamp < ?
      ''',
      [
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  @override
  Future<bool> existsBySmsHash(
    String rawSmsHash,
  ) async {
    final db = await _db;

    final rows = await db.query(
      'transactions',
      columns: ['id'],
      where: 'raw_sms_hash = ?',
      whereArgs: [rawSmsHash],
      limit: 1,
    );

    return rows.isNotEmpty;
  }

  @override
  Future<List<Transaction>> getUnsynced() async {
    final db = await _db;

    final rows = await db.query(
      'transactions',
      where: 'synced = 0',
      orderBy: 'timestamp ASC',
    );

    return rows
        .map((map) => Transaction.fromMap(map))
        .toList();
  }

  @override
  Future<void> markSynced(String id) async {
    final db = await _db;

    await db.update(
      'transactions',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<Transaction>> getUnmatched() async {
    final db = await _db;

    final rows = await db.query(
      'transactions',
      where: 'match_confidence = ?',
      whereArgs: ['unmatched'],
      orderBy: 'timestamp DESC',
    );

    return rows
        .map((map) => Transaction.fromMap(map))
        .toList();
  }

  @override
  Future<String?> getCategoryByCounterparty(String counterparty,
      {String? direction}) async {
    final db = await _db;

    String query;
    List<dynamic> args;

    if (direction != null) {
      query = '''
      SELECT category, COUNT(*) AS cnt
      FROM transactions
      WHERE counterparty_masked = ?
        AND direction = ?
        AND category IS NOT NULL
        AND category != 'other'
        AND category != 'uncategorized'
      GROUP BY category
      ORDER BY cnt DESC
      LIMIT 1
      ''';
      args = [counterparty, direction];
    } else {
      query = '''
      SELECT category, COUNT(*) AS cnt
      FROM transactions
      WHERE counterparty_masked = ?
        AND category IS NOT NULL
        AND category != 'other'
        AND category != 'uncategorized'
      GROUP BY category
      ORDER BY cnt DESC
      LIMIT 1
      ''';
      args = [counterparty];
    }

    final rows = await db.rawQuery(query, args);

    if (rows.isEmpty) return null;
    return rows.first['category'] as String;
  }

  @override
  Future<List<MapEntry<String, double>>> getCategoryBreakdown(
      DateTime start, DateTime end, String direction) async {
    final db = await _db;
    final rows = await db.rawQuery(
      '''
      SELECT COALESCE(category, 'Other') AS cat, SUM(amount) AS total
      FROM transactions
      WHERE direction = ?
        AND timestamp >= ?
        AND timestamp <= ?
      GROUP BY cat
      ORDER BY total DESC
      ''',
      [
        direction,
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
    );

    return rows
        .map((r) => MapEntry(r['cat'] as String, (r['total'] as num).toDouble()))
        .toList();
  }
}