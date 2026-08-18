import 'dart:developer' as developer;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  static const FlutterSecureStorage _secureStorage =
      FlutterSecureStorage();

  static const String _keyName = 'mekenet_db_key';

  static const String _databaseName = 'mekenet.db';

  static const int _databaseVersion = 1;

  Future<Database> get database async {
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
      _databaseName,
    );

    developer.log(
      'Opening encrypted database',
      name: 'Mekenet.DB',
    );

    return openDatabase(
      databasePath,
      version: _databaseVersion,
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

      developer.log(
        'New database encryption key generated',
        name: 'Mekenet.DB',
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
    await _createTransactionsTable(db);
    await _createDebtsTable(db);

    developer.log(
      'Database tables created successfully',
      name: 'Mekenet.DB',
    );
  }

  Future<void> _createTransactionsTable(
    Database db,
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
        match_confidence TEXT NOT NULL DEFAULT 'unmatched',
        category TEXT,
        timestamp INTEGER NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_transactions_timestamp
      ON transactions(timestamp)
    ''');

    await db.execute('''
      CREATE INDEX idx_transactions_synced
      ON transactions(synced)
    ''');

    await db.execute('''
      CREATE INDEX idx_transactions_raw_sms_hash
      ON transactions(raw_sms_hash)
    ''');
  }

  Future<void> _createDebtsTable(
    Database db,
  ) async {
    await db.execute('''
      CREATE TABLE debts (
        id TEXT PRIMARY KEY,
        customer_name TEXT NOT NULL,
        amount REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'open',
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_debts_status
      ON debts(status)
    ''');

    await db.execute('''
      CREATE INDEX idx_debts_created_at
      ON debts(created_at)
    ''');
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;

      developer.log(
        'Database closed',
        name: 'Mekenet.DB',
      );
    }
  }
}