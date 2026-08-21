/// lib/services/sync_service.dart
///
/// Orchestrates the sync flow between local SQLite and the backend.
///
/// Responsibilities:
///   1. Read device ID once at startup and inject it into the API client.
///   2. syncOne(tx)     — called right after a transaction is saved locally.
///   3. retryUnsynced() — called on app resume or network-restored event.
///
/// Opt-in rule: sync only runs when the user has enabled it.
/// The flag is stored under SharedPreferences key "sync_enabled" (bool).
///
/// Error rule: network failures are logged and silenced — never propagated
/// to the UI. The transaction stays in SQLite with synced = 0.

import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api_client/mekenet_api_client.dart';
import '../models/transaction.dart';
import '../repositories/sqlite_transaction_repository.dart';

class SyncService {
  // -------------------------------------------------------------------------
  // Singleton
  // -------------------------------------------------------------------------
  SyncService._();
  static final SyncService instance = SyncService._();

  // -------------------------------------------------------------------------
  // Dependencies
  // -------------------------------------------------------------------------
  final _repo = SqliteTransactionRepository();
  final _log = Logger();

  static const _syncEnabledKey = 'sync_enabled';
  static const _deviceIdKey = 'mekenet_device_id';
  static const _secureStorage = FlutterSecureStorage();

  bool _initialized = false;

  // -------------------------------------------------------------------------
  // Initialization — call once from main() or app startup
  // -------------------------------------------------------------------------

  /// Reads (or generates) a stable device ID and injects it into the API
  /// client so every request carries the correct X-Device-ID header.
  Future<void> initialize() async {
    if (_initialized) return;

    final deviceId = await _getOrCreateDeviceId();
    MekenetApiClient.deviceId = deviceId;

    // Restore saved server URL
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('server_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      MekenetApiClient.baseUrl = savedUrl;
    }

    _log.i('[Sync] Initialized. Device ID: $deviceId, Server: ${MekenetApiClient.baseUrl}');
    _initialized = true;
  }

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Called immediately after saving a transaction locally.
  ///
  /// Flow:
  ///   1. Check opt-in flag — if disabled, do nothing.
  ///   2. POST to /sync/
  ///   3. On success → markSynced in SQLite.
  ///   4. On failure → leave synced = 0, log, continue.
  Future<void> syncOne(Transaction tx) async {
    if (!await _isSyncEnabled()) {
      _log.d('[Sync] Sync disabled by user — skipping ${tx.id}');
      return;
    }

    _log.d('[Sync] Attempting to sync transaction ${tx.id}');

    final response = await MekenetApiClient.syncTransaction(tx);

    if (response != null && response.success) {
      await _repo.markSynced(tx.id);
      _log.i('[Sync] ✅ Synced ${tx.id} — backend count: ${response.storedCount}');
    } else {
      // Leave synced = 0. retryUnsynced() will handle it later.
      _log.w('[Sync] ⚠ Sync failed for ${tx.id} — will retry later');
    }
  }

  /// Retry all transactions that were saved locally but never synced.
  ///
  /// Call this when:
  ///   - App resumes from background
  ///   - Network connectivity is restored
  ///   - User manually taps "Retry sync" (optional)
  Future<void> retryUnsynced() async {
    if (!await _isSyncEnabled()) return;

    final unsynced = await _repo.getUnsynced();
    if (unsynced.isEmpty) {
      _log.d('[Sync] retryUnsynced — nothing to retry');
      return;
    }

    _log.i('[Sync] Retrying ${unsynced.length} unsynced transaction(s)');

    for (final tx in unsynced) {
      await syncOne(tx);
    }
  }

  // -------------------------------------------------------------------------
  // Settings helpers (read/write the opt-in flag)
  // -------------------------------------------------------------------------

  /// Returns the current value of the sync opt-in toggle.
  Future<bool> isSyncEnabled() => _isSyncEnabled();

  /// Persist the user's sync preference.
  Future<void> setSyncEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_syncEnabledKey, value);
    _log.i('[Sync] Sync ${value ? "enabled" : "disabled"} by user');
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  Future<bool> _isSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_syncEnabledKey) ?? false; // off by default
  }

  /// Returns a stable device ID stored in secure storage.
  /// Creates one the first time the app runs.
  Future<String> _getOrCreateDeviceId() async {
    String? id = await _secureStorage.read(key: _deviceIdKey);
    if (id == null || id.isEmpty) {
      // Generate a stable ID from platform + timestamp
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      final platform = Platform.isAndroid ? 'android' : 'ios';
      id = 'mekenet-$platform-${timestamp.toRadixString(16)}';
      await _secureStorage.write(key: _deviceIdKey, value: id);
      _log.i('[Sync] Generated new device ID: $id');
    }
    return id;
  }
}
