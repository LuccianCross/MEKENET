import '../../database/database_helper.dart';

class FailedParseLog {
  final int? id;
  final String rawSms;
  final String? sender;
  final String reason;
  final DateTime createdAt;

  FailedParseLog({
    this.id,
    required this.rawSms,
    this.sender,
    required this.reason,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'raw_sms': rawSms,
      'sender': sender,
      'reason': reason,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  static Future<void> save(
    String rawSms,
    String? sender,
    String reason,
  ) async {
    final db = await DatabaseHelper.instance.database;

    await db.insert(
      'failed_parses',
      FailedParseLog(
        rawSms: rawSms,
        sender: sender,
        reason: reason,
      ).toMap(),
    );
  }

  static Future<List<FailedParseLog>> getAll() async {
    final db = await DatabaseHelper.instance.database;

    final rows = await db.query(
      'failed_parses',
      orderBy: 'created_at DESC',
    );

    return rows.map((row) {
      return FailedParseLog(
        id: row['id'] as int?,
        rawSms: row['raw_sms'] as String,
        sender: row['sender'] as String?,
        reason: row['reason'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          row['created_at'] as int,
        ),
      );
    }).toList();
  }

  static Future<void> delete(int id) async {
    final db = await DatabaseHelper.instance.database;

    await db.delete(
      'failed_parses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> count() async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM failed_parses',
    );

    return result.first['count'] as int;
  }
}
