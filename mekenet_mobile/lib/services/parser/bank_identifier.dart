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

  static Future<String?> identify(String? sender, String smsText) async {
    await load();

    if (_banks == null || _banks!.isEmpty) return null;

    // Normalize sender: strip +, country code prefixes
    final normalizedSender = sender?.replaceAll(RegExp(r'^\+?251'), '');

    for (final bank in _banks!) {
      // Match sender by endsWith (handles +251911234, 2518047, 8047, etc.)
      if (normalizedSender != null) {
        for (final knownSender in bank.senders) {
          if (normalizedSender.endsWith(knownSender) ||
              knownSender.endsWith(normalizedSender)) {
            return bank.name;
          }
        }
      }

      for (final keyword in bank.keywords) {
        if (smsText.toLowerCase().contains(keyword.toLowerCase())) {
          return bank.name;
        }
      }
    }

    return null;
  }
}
