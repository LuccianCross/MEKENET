import 'dart:convert';

import 'package:flutter/services.dart';

class BankInfo {
  final String name;
  final List<String> senders;
  final List<String> keywords;

  const BankInfo({
    required this.name,
    required this.senders,
    required this.keywords,
  });
}

class BankIdentifier {
  static List<BankInfo>? _banks;

  static Future<void> load() async {
    if (_banks != null) return;

    final json = await rootBundle.loadString('assets/sms_patterns.json');
    final data = jsonDecode(json) as Map<String, dynamic>;
    final banksList = data['banks'] as List;

    _banks = banksList.map((b) {
      return BankInfo(
        name: b['name'] as String,
        senders: List<String>.from(b['senders'] ?? []),
        keywords: List<String>.from(b['keywords'] ?? []),
      );
    }).toList();
  }

  static Future<List<String>> getAllSenderPrefixes() async {
    await load();
    if (_banks == null) return [];
    final prefixes = <String>[];
    for (final bank in _banks!) {
      prefixes.addAll(bank.senders);
    }
    return prefixes;
  }

  static bool _senderMatches(String? normalizedSender, List<String> senders) {
    if (normalizedSender == null) return false;
    for (final knownSender in senders) {
      if (normalizedSender.endsWith(knownSender) ||
          knownSender.endsWith(normalizedSender)) {
        return true;
      }
    }
    return false;
  }

  static Future<String?> identify(String? sender, String smsText) async {
    await load();

    if (_banks == null || _banks!.isEmpty) return null;

    final normalizedSender = sender?.replaceAll(RegExp(r'^\+?251'), '');

    // Step 1: find all banks whose sender matches
    final matchedBanks = <BankInfo>[];
    for (final bank in _banks!) {
      if (_senderMatches(normalizedSender, bank.senders)) {
        matchedBanks.add(bank);
      }
    }

    // No known sender matched → reject (prevents spam/phishing via keyword)
    if (matchedBanks.isEmpty) return null;

    // Exactly one sender match → no ambiguity
    if (matchedBanks.length == 1) return matchedBanks.first.name;

    // Multiple sender matches (shared sender like 8047) → disambiguate by keyword
    final lowerText = smsText.toLowerCase();
    for (final bank in matchedBanks) {
      for (final keyword in bank.keywords) {
        if (lowerText.contains(keyword.toLowerCase())) {
          return bank.name;
        }
      }
    }

    // Keywords didn't disambiguate → return first match
    return matchedBanks.first.name;
  }
}
