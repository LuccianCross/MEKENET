/// lib/services/sync_service.dart
///
/// Orchestrates the sync flow between local SQLite and the backend.
library;

import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api_client/mekenet_api_client.dart';
import '../models/transaction.dart';
import '../repositories/sqlite_transaction_repository.dart';

class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final _repo = SqliteTransactionRepository();
  final _log = Logger();
  static SharedPreferences? _cachedPrefs;

  static Future<SharedPreferences> get _prefs async {
    _cachedPrefs ??= await SharedPreferences.getInstance();
    return _cachedPrefs!;
  }

  static const _syncEnabledKey = 'sync_enabled';
  static const _deviceIdKey = 'mekenet_device_id';
  static const _apiKeyKey = 'mekenet_api_key';
  static const _serverUrlKey = 'server_url';
  static const _secureStorage = FlutterSecureStorage();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    final deviceId = await _getOrCreateDeviceId();
    MekenetApiClient.deviceId = deviceId;

    final prefs = await _prefs;
    final savedUrl = prefs.getString(_serverUrlKey);
    if (savedUrl != null && savedUrl.isNotEmpty) {
      MekenetApiClient.baseUrl = savedUrl;
    }

    final savedApiKey = await _secureStorage.read(key: _apiKeyKey);
    if (savedApiKey != null && savedApiKey.isNotEmpty) {
      MekenetApiClient.apiKey = savedApiKey;
    }

    _log.i(
        '[Sync] Initialized. Device: $deviceId, Server: ${MekenetApiClient.baseUrl}');
    _initialized = true;
  }

  Future<void> syncOne(Transaction tx) async {
    if (!await _isSyncEnabled()) {
      _log.d('[Sync] Sync disabled - skipping ${tx.id}');
      return;
    }

    if (MekenetApiClient.apiKey.isEmpty) {
      _log.w('[Sync] No API key configured - skipping ${tx.id}');
      return;
    }

    _log.d('[Sync] Attempting to sync transaction ${tx.id}');

    final response = await MekenetApiClient.syncTransaction(tx);

    if (response != null && response.success) {
      await _repo.markSynced(tx.id);
      _log.i('[Sync] Synced ${tx.id} - backend count: ${response.storedCount}');
    } else {
      _log.w('[Sync] Sync failed for ${tx.id} - will retry later');
    }
  }

  Future<void> retryUnsynced() async {
    if (!await _isSyncEnabled()) return;
    if (MekenetApiClient.apiKey.isEmpty) return;

    final unsynced = await _repo.getUnsynced();
    if (unsynced.isEmpty) {
      _log.d('[Sync] retryUnsynced - nothing to retry');
      return;
    }

    _log.i('[Sync] Retrying ${unsynced.length} unsynced transaction(s)');

    for (final tx in unsynced) {
      await syncOne(tx);
    }
  }

  Future<bool> isSyncEnabled() => _isSyncEnabled();

  Future<void> setSyncEnabled(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_syncEnabledKey, value);
    _log.i('[Sync] Sync ${value ? "enabled" : "disabled"}');
  }

  Future<void> setApiKey(String key) async {
    await _secureStorage.write(key: _apiKeyKey, value: key);
    MekenetApiClient.apiKey = key;
    _log.i('[Sync] API key updated');
  }

  Future<void> setServerUrl(String url) async {
    final prefs = await _prefs;
    await prefs.setString(_serverUrlKey, url);
    MekenetApiClient.baseUrl = url;
    _log.i('[Sync] Server URL updated: $url');
  }

  Future<bool> _isSyncEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_syncEnabledKey) ?? false;
  }

  Future<String> _getOrCreateDeviceId() async {
    String? id = await _secureStorage.read(key: _deviceIdKey);
    if (id == null || id.isEmpty) {
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      final platform = Platform.isAndroid ? 'android' : 'ios';
      id = 'mekenet-$platform-${timestamp.toRadixString(16)}';
      await _secureStorage.write(key: _deviceIdKey, value: id);
      _log.i('[Sync] Generated new device ID: $id');
    }
    return id;
  }
}
