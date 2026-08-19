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

  static Future<String?> identify(String? sender, String smsText) async {
    await load();

    if (_banks == null || _banks!.isEmpty) return null;

    for (final bank in _banks!) {
      if (sender != null && bank.senders.contains(sender)) {
        return bank.name;
      }

      for (final keyword in bank.keywords) {
        if (smsText.contains(keyword)) {
          return bank.name;
        }
      }
    }

    return null;
  }
}
