/// lib/api_client/mekenet_api_client.dart
///
/// Thin HTTP client for the Mekenet FastAPI backend.
/// Responsibilities:
///   - POST /sync/   → send a single transaction to the backend
///   - POST /export/ → request a financial report
///
/// Design rules:
///   1. No business logic here — just HTTP.
///   2. Never throws to the caller. Returns null on failure.
///   3. Every request carries X-Device-ID header.
///   4. Base URL is configurable (default = Android emulator loopback).

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import '../models/export_report.dart';
import '../models/sync_response.dart';
import '../models/transaction.dart';

class MekenetApiClient {
  // -------------------------------------------------------------------------
  // Configuration
  // -------------------------------------------------------------------------

  /// Default: local network for real device testing.
  /// Change this to your computer's IP when testing on a real device.
  static String baseUrl = 'http://10.213.41.190:8000';

  /// Injected at startup by [SyncService] after reading device info.
  static String deviceId = 'unknown-device';

  static final _log = Logger();

  static const Duration _timeout = Duration(seconds: 10);

  // -------------------------------------------------------------------------
  // Common headers
  // -------------------------------------------------------------------------

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-Device-ID': deviceId,
      };

  // -------------------------------------------------------------------------
  // POST /sync/
  // -------------------------------------------------------------------------

  /// Send [tx] to the backend.
  ///
  /// Returns a [SyncResponse] on success, or `null` if the device is offline
  /// or the server returned an error.
  static Future<SyncResponse?> syncTransaction(Transaction tx) async {
    final uri = Uri.parse('$baseUrl/sync/');

    // Map Flutter field names → backend field names
    final body = jsonEncode({
      'id': tx.id,
      'type': tx.direction,                          // direction → type
      'amount': tx.amount,
      'description': tx.counterpartyMasked,          // counterpartyMasked → description
      'date': _formatDate(tx.timestamp),             // DateTime → YYYY-MM-DD
      'category': tx.category ?? 'uncategorized',
      'currency': 'ETB',
    });

    try {
      final response = await http
          .post(uri, headers: _headers, body: body)
          .timeout(_timeout);

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        _log.i('[API] syncTransaction success — id: ${tx.id}');
        return SyncResponse.fromJson(json);
      } else {
        _log.w('[API] syncTransaction HTTP ${response.statusCode}: ${response.body}');
        return null;
      }
    } on SocketException catch (e) {
      _log.w('[API] syncTransaction — no internet: $e');
      return null;
    } on TimeoutException catch (e) {
      _log.w('[API] syncTransaction — timed out: $e');
      return null;
    } catch (e) {
      _log.e('[API] syncTransaction — unexpected error: $e');
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // GET /export/
  // -------------------------------------------------------------------------

  /// Fetch a financial report from the backend.
  ///
  /// All parameters are optional — omit to get all transactions.
  /// Returns an [ExportReport] on success, or `null` on failure.
  static Future<ExportReport?> exportReport({
    String? fromDate,   // YYYY-MM-DD
    String? toDate,     // YYYY-MM-DD
    String? type,       // "income" | "expense" | null = all
  }) async {
    // Build query params
    final queryParams = <String, String>{};
    if (fromDate != null) queryParams['from_date'] = fromDate;
    if (toDate != null)   queryParams['to_date'] = toDate;
    if (type != null)     queryParams['type'] = type;

    final uri = Uri.parse('$baseUrl/export/').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        _log.i('[API] exportReport success');
        return ExportReport.fromJson(json);
      } else if (response.statusCode == 404) {
        _log.w('[API] exportReport — no transactions on server yet');
        return null;
      } else {
        _log.w('[API] exportReport HTTP ${response.statusCode}: ${response.body}');
        return null;
      }
    } on SocketException catch (e) {
      _log.w('[API] exportReport — no internet: $e');
      return null;
    } on TimeoutException catch (e) {
      _log.w('[API] exportReport — timed out: $e');
      return null;
    } catch (e) {
      _log.e('[API] exportReport — unexpected error: $e');
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  /// Format a [DateTime] as "YYYY-MM-DD" (what the backend expects).
  static String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
