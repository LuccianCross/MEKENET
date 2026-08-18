import 'dart:convert';

import 'package:another_telephony/telephony.dart';
import 'package:crypto/crypto.dart';
import 'package:logger/logger.dart';

import '../../models/transaction.dart';
import '../../repositories/repository_provider.dart';
import '../parser/telebirr_sms_parser.dart';

class SmsListener {
  final Telephony _telephony = Telephony.instance;
  final Logger _logger = Logger();

  Future<void> initialize() async {
    try {
      final permissionGranted =
          await _telephony.requestSmsPermissions;

      if (permissionGranted != true) {
        _logger.w('SMS permission denied');
        return;
      }

      _telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          final smsText = message.body;

          if (smsText == null || smsText.isEmpty) {
            return;
          }

          _handleSms(smsText);
        },
        listenInBackground: false,
      );
    } catch (e) {
      _logger.e(
        'Error initializing SMS listener',
        error: e,
      );
    }
  }

  Future<void> _handleSms(String smsText) async {
    try {
      // Ignore non-Telebirr SMS.
      if (!smsText.contains('ETB') ||
          !smsText.contains('Telebirr')) {
        return;
      }

      // Parse the Telebirr SMS.
      final parsed = TelebirrSmsParser.parse(smsText);

      if (parsed == null) {
        _logger.w('Failed to parse Telebirr SMS');
        return;
      }

      // Create a stable hash for deduplication.
      final smsHash =
          sha256.convert(utf8.encode(smsText)).toString();

      // Ignore duplicate SMS.
      final alreadyExists =
          await RepositoryProvider.transaction.existsBySmsHash(
        smsHash,
      );

      if (alreadyExists) {
        _logger.i('Duplicate SMS ignored');
        return;
      }

      // Map parser direction to Transaction direction.
      final direction =
          parsed.direction == TransactionDirection.received
              ? 'income'
              : 'expense';

      // Create transaction.
      final transaction = Transaction(
        direction: direction,
        amount: parsed.amount,
        source: 'telebirr',
        rawSmsHash: smsHash,
        counterpartyMasked: 'Telebirr',
        timestamp: parsed.timestamp,
      );

      // Save transaction.
      await RepositoryProvider.transaction.save(transaction);

      _logger.i('Telebirr transaction saved');
    } catch (e) {
      _logger.e(
        'Error handling SMS',
        error: e,
      );
    }
  }
}