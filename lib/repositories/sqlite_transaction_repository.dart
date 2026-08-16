import 'package:sqflite_sqlcipher/sqflite.dart' hide Transaction;
import '../models/transaction.dart';
import 'transaction_repository.dart';

class SqliteTransactionRepository implements TransactionRepository {
  final Database db;

  SqliteTransactionRepository(this.db);

  @override
  Future<void> save(Transaction transaction) async {
    await db.insert(
      'transactions',
      _toMap(transaction),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<Transaction>> getByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final rows = await db.query(
      'transactions',
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
      orderBy: 'timestamp ASC',
    );

    return rows.map(_fromMap).toList();
  }

  @override
  Future<Transaction?> getById(String id) async {
    final rows = await db.query(
      'transactions',
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
  Future<void> update(Transaction transaction) async {
    await db.update(
      'transactions',
      _toMap(transaction),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  @override
  Future<void> delete(String id) async {
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Map<String, Object?> _toMap(Transaction transaction) {
    return {
      'id': transaction.id,
      'direction': transaction.direction,
      'amount': transaction.amount,
      'source': transaction.source,
      'raw_sms_hash': transaction.rawSmsHash,
      'counterparty_masked': transaction.counterpartyMasked,
      'item_id': transaction.itemId,
      'match_confidence': transaction.matchConfidence,
      'category': transaction.category,
      'timestamp': transaction.timestamp.millisecondsSinceEpoch,
      'synced': transaction.synced ? 1 : 0,
    };
  }

  Transaction _fromMap(Map<String, Object?> map) {
    return Transaction(
      id: map['id'] as String,
      direction: map['direction'] as String,
      amount: (map['amount'] as num).toDouble(),
      source: map['source'] as String,
      rawSmsHash: map['raw_sms_hash'] as String,
      counterpartyMasked: map['counterparty_masked'] as String,
      itemId: map['item_id'] as String?,
      matchConfidence: map['match_confidence'] as String,
      category: map['category'] as String?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        map['timestamp'] as int,
      ),
      synced: (map['synced'] as int) == 1,
    );
  }
}