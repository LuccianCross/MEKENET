/// lib/api_client/mekenet_api_client.dart
///
/// Thin HTTP client for the Mekenet FastAPI backend.
/// Every request carries X-Device-ID and X-API-Key headers.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import '../models/export_report.dart';
import '../models/sync_response.dart';
import '../models/transaction.dart';

class MekenetApiClient {
  static String baseUrl = 'http://10.0.2.2:8000';
  static String deviceId = 'unknown-device';
  static String apiKey = '';

  static final _log = Logger();
  static const Duration _timeout = Duration(seconds: 10);

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-Device-ID': deviceId,
        'X-API-Key': apiKey,
      };

  static Future<SyncResponse?> syncTransaction(Transaction tx) async {
    final uri = Uri.parse('$baseUrl/sync/');

    final body = jsonEncode({
      'id': tx.id,
      'type': tx.direction,
      'amount': tx.amount,
      'description': tx.counterpartyMasked,
      'date': _formatDate(tx.timestamp),
      'category': tx.category ?? 'uncategorized',
      'currency': 'ETB',
    });

    try {
      final response =
          await http.post(uri, headers: _headers, body: body).timeout(_timeout);

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        _log.i('[API] syncTransaction success - id: ${tx.id}');
        return SyncResponse.fromJson(json);
      } else {
        _log.w(
            '[API] syncTransaction HTTP ${response.statusCode}: ${response.body}');
        return null;
      }
    } on SocketException catch (e) {
      _log.w('[API] syncTransaction - no internet: $e');
      return null;
    } on TimeoutException catch (e) {
      _log.w('[API] syncTransaction - timed out: $e');
      return null;
    } catch (e) {
      _log.e('[API] syncTransaction - unexpected error: $e');
      return null;
    }
  }

  static Future<ExportReport?> exportReport({
    String? fromDate,
    String? toDate,
    String? type,
    int page = 1,
    int pageSize = 100,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    if (fromDate != null) queryParams['from_date'] = fromDate;
    if (toDate != null) queryParams['to_date'] = toDate;
    if (type != null) queryParams['type'] = type;

    final uri = Uri.parse('$baseUrl/export/')
        .replace(queryParameters: queryParams);

    try {
      final response =
          await http.get(uri, headers: _headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        _log.i('[API] exportReport success');
        return ExportReport.fromJson(json);
      } else if (response.statusCode == 404) {
        _log.w('[API] exportReport - no transactions on server yet');
        return null;
      } else {
        _log.w(
            '[API] exportReport HTTP ${response.statusCode}: ${response.body}');
        return null;
      }
    } on SocketException catch (e) {
      _log.w('[API] exportReport - no internet: $e');
      return null;
    } on TimeoutException catch (e) {
      _log.w('[API] exportReport - timed out: $e');
      return null;
    } catch (e) {
      _log.e('[API] exportReport - unexpected error: $e');
      return null;
    }
  }

  static String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
