import 'dart:developer' as developer;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart' hide Transaction;

import '../models/transaction.dart';
import 'transaction_repository.dart';

class SqliteTransactionRepository implements TransactionRepository {
  static Database? _database;

  static const FlutterSecureStorage _secureStorage =
      FlutterSecureStorage();

  static const String _keyName = 'mekenet_db_key';

  Future<Database> get _db async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final key = await _getOrCreateKey();

    final databasesPath = await getDatabasesPath();
    final databasePath = join(
      databasesPath,
      'mekenet.db',
    );

    return openDatabase(
      databasePath,
      version: 1,
      password: key,
      onCreate: _onCreate,
    );
  }

  Future<String> _getOrCreateKey() async {
    String? key = await _secureStorage.read(
      key: _keyName,
    );

    if (key == null || key.isEmpty) {
      key = _generateKey();

      await _secureStorage.write(
        key: _keyName,
        value: key,
      );
    }

    return key;
  }

  String _generateKey() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;

    return 'mekenet-${timestamp.toRadixString(16)}-${Object().hashCode}';
  }

  Future<void> _onCreate(
    Database db,
    int version,
  ) async {
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        direction TEXT NOT NULL,
        amount REAL NOT NULL,
        source TEXT NOT NULL,
        raw_sms_hash TEXT,
        counterparty_masked TEXT NOT NULL,
        item_id TEXT,
        match_confidence TEXT DEFAULT 'unmatched',
        category TEXT,
        timestamp INTEGER NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_transactions_timestamp '
      'ON transactions(timestamp)',
    );

    await db.execute(
      'CREATE INDEX idx_transactions_synced '
      'ON transactions(synced)',
    );

    await db.execute(
      'CREATE INDEX idx_transactions_raw_sms_hash '
      'ON transactions(raw_sms_hash)',
    );

    developer.log(
      'Transactions table created successfully',
      name: 'Mekenet.DB',
    );
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
}