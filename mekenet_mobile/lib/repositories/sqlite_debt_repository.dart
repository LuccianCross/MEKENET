import 'dart:developer' as developer;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../models/debt.dart';
import 'debt_repository.dart';

class SqliteDebtRepository implements DebtRepository {
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
      CREATE TABLE IF NOT EXISTS debts (
        id TEXT PRIMARY KEY,
        customer_name TEXT NOT NULL,
        amount REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'open',
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_debts_status '
      'ON debts(status)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_debts_created_at '
      'ON debts(created_at)',
    );

    developer.log(
      'Debts table created successfully',
      name: 'Mekenet.DB',
    );
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
}