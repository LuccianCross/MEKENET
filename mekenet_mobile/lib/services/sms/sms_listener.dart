import 'dart:convert';

import 'package:another_telephony/telephony.dart';
import 'package:crypto/crypto.dart';
import 'package:logger/logger.dart';

import '../../models/transaction.dart';
import '../../repositories/repository_provider.dart';
import '../parser/awash_sms_parser.dart';
import '../parser/bank_identifier.dart';
import '../parser/cbe_sms_parser.dart';
import '../parser/failed_parse_log.dart';
import '../parser/parsed_bank_sms.dart';
import '../parser/telebirr_sms_parser.dart';

class SmsListener {
  final Telephony _telephony = Telephony.instance;
  final Logger _logger = Logger();

  Future<void> initialize() async {
    try {
      await BankIdentifier.load();

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

          _handleSms(smsText, message.address);
        },
        listenInBackground: false,
      );

      _logger.i('SMS listener initialized');
    } catch (e) {
      _logger.e(
        'Error initializing SMS listener',
        error: e,
      );
    }
  }

  Future<void> _handleSms(String smsText, String? sender) async {
    try {
      final bankName = await BankIdentifier.identify(sender, smsText);

      if (bankName == null) {
        await FailedParseLog.save(smsText, sender, 'no_bank_match');
        _logger.w('Unknown sender: $sender');
        return;
      }

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
        _logger.w('Failed to parse $bankName SMS');
        return;
      }

      final smsHash =
          sha256.convert(utf8.encode(smsText)).toString();

      final alreadyExists =
          await RepositoryProvider.transaction.existsBySmsHash(
        smsHash,
      );

      if (alreadyExists) {
        _logger.i('Duplicate SMS ignored');
        return;
      }

      final direction =
          parsed.direction == TransactionDirection.received
              ? 'income'
              : 'expense';

      final transaction = Transaction(
        direction: direction,
        amount: parsed.amount,
        source: bankName.toLowerCase(),
        rawSmsHash: smsHash,
        counterpartyMasked: bankName,
        timestamp: parsed.timestamp,
      );

      await RepositoryProvider.transaction.save(transaction);

      _logger.i('$bankName transaction saved');
    } catch (e) {
      _logger.e(
        'Error handling SMS',
        error: e,
      );
    }
  }
}
