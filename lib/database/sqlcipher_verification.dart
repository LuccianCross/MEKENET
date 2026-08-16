import 'dart:developer' as developer;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class SqlCipherVerification {
  static const FlutterSecureStorage _secureStorage =
      FlutterSecureStorage();

  static const String _keyName = 'mekenet_sqlcipher_test_key';

  static Future<void> run() async {
    try {
      // 1. Get the encryption key from secure storage.
      String? key = await _secureStorage.read(key: _keyName);

      // 2. Generate and securely store a key if one does not exist.
      if (key == null || key.isEmpty) {
        key = _generateKey();

        await _secureStorage.write(
          key: _keyName,
          value: key,
        );
      }

      // 3. Get the database path.
      final databasesPath = await getDatabasesPath();
      final databasePath = join(
        databasesPath,
        'mekenet_sqlcipher_verification.db',
      );

      // 4. Open an encrypted database.
      final db = await openDatabase(
        databasePath,
        version: 1,
        password: key,
        onCreate: (database, version) async {
          await database.execute('''
            CREATE TABLE verification_data (
              id INTEGER PRIMARY KEY,
              message TEXT NOT NULL
            )
          ''');
        },
      );

      // 5. Write test data.
      await db.insert(
        'verification_data',
        <String, Object?>{
          'id': 1,
          'message': 'SQLCipher works!',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 6. Read the data back.
      final rows = await db.query('verification_data');

      if (rows.isEmpty ||
          rows.first['message'] != 'SQLCipher works!') {
        await db.close();
        throw Exception(
          'SQLCipher write/read verification failed.',
        );
      }

      developer.log(
        'SQLCipher write/read test: PASSED',
        name: 'Mekenet.SQLCipher',
      );

      await db.close();

      // 7. Reopen the database using the same secure key.
      final reopenedDb = await openDatabase(
        databasePath,
        version: 1,
        password: key,
      );

      // 8. Read the previously stored data.
      final reopenedRows = await reopenedDb.query(
        'verification_data',
      );

      if (reopenedRows.isEmpty ||
          reopenedRows.first['message'] != 'SQLCipher works!') {
        await reopenedDb.close();
        throw Exception(
          'SQLCipher reopen verification failed.',
        );
      }

      developer.log(
        'SQLCipher reopen test: PASSED',
        name: 'Mekenet.SQLCipher',
      );

      await reopenedDb.close();

      developer.log(
        'SQLCipher verification completed successfully.',
        name: 'Mekenet.SQLCipher',
      );
    } catch (error, stackTrace) {
      developer.log(
        'SQLCipher verification FAILED.',
        name: 'Mekenet.SQLCipher',
        error: error,
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  static String _generateKey() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;

    return 'mekenet-${timestamp.toRadixString(16)}-${Object().hashCode}';
  }
}