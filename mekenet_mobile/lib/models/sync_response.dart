/// lib/models/sync_response.dart
///
/// Dart mirror of the backend's SyncResponse Pydantic model.
/// Matches server/routes/sync.py → class SyncResponse.

class SyncResponse {
  final bool success;
  final String message;
  final String transactionId;
  final int storedCount;

  const SyncResponse({
    required this.success,
    required this.message,
    required this.transactionId,
    required this.storedCount,
  });

  factory SyncResponse.fromJson(Map<String, dynamic> json) {
    return SyncResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      transactionId: json['transaction_id'] as String,
      storedCount: json['stored_count'] as int,
    );
  }

  @override
  String toString() =>
      'SyncResponse(success: $success, id: $transactionId, stored: $storedCount)';
}
