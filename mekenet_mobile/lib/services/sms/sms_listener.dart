import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:another_telephony/telephony.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/database_helper.dart';
import '../../models/transaction.dart';
import '../../repositories/repository_provider.dart';
import '../parser/awash_sms_parser.dart';
import '../parser/bank_identifier.dart';
import '../parser/cbe_sms_parser.dart';
import '../parser/failed_parse_log.dart';
import '../parser/parsed_bank_sms.dart';
import '../parser/telebirr_sms_parser.dart';
import '../sync_service.dart';

@pragma('vm:entry-point')
void onBackgroundMessage(SmsMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  final body = message.body;
  final sender = message.address;

  if (body == null || body.isEmpty) return;

  final logger = Logger();
  logger.i('BG SMS from $sender');

  await DatabaseHelper.instance.database;
  await BankIdentifier.load();

  await _handleSmsStatic(body, sender, logger);
}

Future<void> _handleSmsStatic(
  String smsText,
  String? sender,
  Logger logger,
) async {
  try {
    final bankName = await BankIdentifier.identify(sender, smsText);

    if (bankName == null) {
      await FailedParseLog.save(smsText, sender, 'no_bank_match');
      logger.w('BG: Unknown sender: $sender');
      return;
    }

    logger.i('BG: Identified bank: $bankName');

    ParsedBankSms? parsed;

    switch (bankName) {
      case 'Telebirr':
        parsed = TelebirrSmsParser.parse(smsText);
        break;
      case 'CBE':
        parsed = CbeSmsParser.parse(smsText);
        break;
      case 'Awash':
        parsed = AwashSmsParser.parse(smsText);
        break;
    }

    if (parsed == null) {
      await FailedParseLog.save(smsText, sender, 'parse_error');
      logger.w('BG: Failed to parse $bankName SMS');
      return;
    }

    final smsHash = sha256.convert(utf8.encode(smsText)).toString();

    final alreadyExists =
        await RepositoryProvider.transaction.existsBySmsHash(smsHash);

    if (alreadyExists) {
      logger.i('BG: Duplicate SMS ignored');
      return;
    }

    final direction =
        parsed.direction == TransactionDirection.received ? 'income' : 'expense';

    // Use parsed counterparty if available, otherwise fall back to bank name
    final counterparty = parsed.counterparty ?? bankName;

    // Auto-categorize: direction-aware counterparty lookup
    final learnedCategory = await RepositoryProvider.transaction
        .getCategoryByCounterparty(counterparty, direction: direction);
    final category = learnedCategory ?? (direction == 'income' ? 'Sales' : 'other');

    final transaction = Transaction(
      direction: direction,
      amount: parsed.amount,
      source: bankName.toLowerCase(),
      rawSmsHash: smsHash,
      counterpartyMasked: counterparty,
      category: category,
      timestamp: parsed.timestamp,
    );

    await RepositoryProvider.transaction.save(transaction);
    SmsListener.transactionStream.add(null);

    // Sync to server if enabled — fire-and-forget with error guard
    SyncService.instance.syncOne(transaction).catchError((e) {
      logger.w('BG: Sync failed for transaction', error: e);
    });

    logger.i('BG: $bankName transaction saved: $direction Br${parsed.amount}');
  } catch (e) {
    logger.e('BG: Error handling SMS', error: e);
  }
}

class SmsListener {
  SmsListener._();
  static final SmsListener instance = SmsListener._();

  final Telephony _telephony = Telephony.instance;
  final Logger _logger = Logger();
  bool _initialized = false;

  static final StreamController<void> transactionStream =
      StreamController<void>.broadcast();
  Stream<void> get onTransactionAdded => transactionStream.stream;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await BankIdentifier.load();

      // Request SMS permissions via another_telephony (handles RECEIVE_SMS + READ_SMS)
      final permissionGranted = await _telephony.requestSmsPermissions;
      if (permissionGranted != true) {
        // Fallback: try permission_handler for READ_SMS
        final status = await Permission.sms.request();
        if (!status.isGranted) {
          _logger.w('SMS permission not granted');
          return;
        }
      }

      // Listen for incoming SMS — foreground AND background
      _telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          final smsText = message.body;
          if (smsText == null || smsText.isEmpty) return;
          _handleSms(smsText, message.address);
        },
        onBackgroundMessage: onBackgroundMessage,
      );

      _initialized = true;
      _logger.i('SMS listener initialized (foreground + background)');

      // Sync today's inbox to catch messages received while app was closed
      _syncInbox();
    } catch (e) {
      _logger.e('Error initializing SMS listener', error: e);
    }
  }

  /// Read today's SMS inbox from known bank senders.
  /// Only processes SMS received AFTER the last known processed SMS timestamp.
  void _syncInbox() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastProcessedMs = prefs.getInt('sms_last_processed_ms') ?? 0;

      final messages = await _telephony.getInboxSms(
        columns: [
          SmsColumn.ID,
          SmsColumn.ADDRESS,
          SmsColumn.BODY,
          SmsColumn.DATE,
        ],
        filter: SmsFilter.where(SmsColumn.DATE).greaterThan(
          lastProcessedMs.toString(),
        ),
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );

      int processed = 0;
      int newestTimestamp = lastProcessedMs;

      for (final sms in messages) {
        final smsText = sms.body;
        if (smsText == null || smsText.isEmpty) continue;

        final bankName = await BankIdentifier.identify(sms.address, smsText);
        if (bankName == null) continue;

        final hash = sha256.convert(utf8.encode(smsText)).toString();
        final exists =
            await RepositoryProvider.transaction.existsBySmsHash(hash);
        if (exists) continue;

        await _handleSms(smsText, sms.address);
        processed++;

        // Track the newest SMS timestamp we've seen
        if (sms.date != null && sms.date! > newestTimestamp) {
          newestTimestamp = sms.date!;
        }
      }

      // Save the newest timestamp so next time we only check newer SMS
      if (newestTimestamp > lastProcessedMs) {
        await prefs.setInt('sms_last_processed_ms', newestTimestamp);
      }

      _logger.i('Inbox sync: $processed new bank messages processed');
    } catch (e) {
      _logger.e('Error syncing inbox', error: e);
    }
  }

  Future<void> _handleSms(String smsText, String? sender) async {
    await _handleSmsStatic(smsText, sender, _logger);
  }
}
