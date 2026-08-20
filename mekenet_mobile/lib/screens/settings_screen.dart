import 'package:flutter/material.dart';
import 'package:another_telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';

import '../api_client/mekenet_api_client.dart';
import '../models/export_report.dart';
import '../services/sync_service.dart';
import '../services/parser/bank_identifier.dart';
import '../services/parser/telebirr_sms_parser.dart';
import '../services/parser/cbe_sms_parser.dart';
import '../services/parser/awash_sms_parser.dart';
import '../services/parser/parsed_bank_sms.dart';
import '../services/parser/failed_parse_log.dart';
import '../repositories/repository_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF0A8E48),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Privacy Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.06),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A8E48).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.shield,
                          color: Color(0xFF0A8E48),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Your data stays on your device',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Your financial records are 100% private. '
                    'All SMS processing happens securely on your phone '
                    'without sending details to any server.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Access allowed! (Mock)'),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A8E48),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Allow Access',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                        ),
                        child: const Text('Not now'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Settings List
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.04),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.lock_outline, color: Color(0xFF0A8E48)),
                    title: Text('Privacy'),
                    subtitle: Text('Your data stays on your device'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  const ListTile(
                    leading: Icon(Icons.cloud_off, color: Color(0xFF0A8E48)),
                    title: Text('Offline Mode'),
                    subtitle: Text('Works without internet'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.upload_file, color: Color(0xFF0A8E48)),
                    title: const Text('Export Data'),
                    subtitle: const Text('Send report to bank'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    onTap: () {
                      _showExportDialog(context);
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  const ListTile(
                    leading: Icon(Icons.info_outline, color: Color(0xFF0A8E48)),
                    title: Text('Version'),
                    subtitle: Text('Mekenet v0.1.0'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ),
                  const Divider(height: 1),

                  // Debug SMS tile
                  ListTile(
                    leading: const Icon(Icons.bug_report, color: Colors.orange),
                    title: const Text('Debug SMS'),
                    subtitle: const Text('Test each SMS pipeline step'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _runSmsDebug(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Export flow
  // --------------------------------------------------------------------------

  void _showExportDialog(BuildContext context) {
    DateTime? fromDate;
    DateTime? toDate;
    String? typeFilter; // null = all, "income", "expense"

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Export Report',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // From date
                  _DatePickerRow(
                    label: 'From',
                    date: fromDate,
                    onPick: (d) => setModalState(() => fromDate = d),
                  ),
                  const SizedBox(height: 12),

                  // To date
                  _DatePickerRow(
                    label: 'To',
                    date: toDate,
                    onPick: (d) => setModalState(() => toDate = d),
                  ),
                  const SizedBox(height: 16),

                  // Type filter
                  const Text('Type',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: typeFilter == null,
                        onTap: () => setModalState(() => typeFilter = null),
                      ),
                      _FilterChip(
                        label: 'Income',
                        selected: typeFilter == 'income',
                        onTap: () =>
                            setModalState(() => typeFilter = 'income'),
                      ),
                      _FilterChip(
                        label: 'Expense',
                        selected: typeFilter == 'expense',
                        onTap: () =>
                            setModalState(() => typeFilter = 'expense'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Export button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.download),
                      label: const Text('Get Report'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A8E48),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _fetchAndShowReport(
                          context: context,
                          fromDate: fromDate,
                          toDate: toDate,
                          type: typeFilter,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _fetchAndShowReport({
    required BuildContext context,
    DateTime? fromDate,
    DateTime? toDate,
    String? type,
  }) async {
    // Show a loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    String? from = fromDate != null ? _fmt(fromDate) : null;
    String? to   = toDate   != null ? _fmt(toDate)   : null;

    final report = await MekenetApiClient.exportReport(
      fromDate: from,
      toDate: to,
      type: type,
    );

    if (!context.mounted) return;
    Navigator.pop(context); // close loading

    if (report == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not fetch report. Make sure the server is running '
            'and you have synced at least one transaction.',
          ),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    _showReportSheet(context, report);
  }

  void _showReportSheet(BuildContext context, ExportReport report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: ListView(
                controller: controller,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Financial Report',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Generated: ${report.generatedAt.substring(0, 10)}',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 20),

                  // Summary cards
                  _SummaryRow(
                    label: 'Total Income',
                    value: '${report.currency} ${report.totalIncome.toStringAsFixed(2)}',
                    color: Colors.green,
                  ),
                  _SummaryRow(
                    label: 'Total Expense',
                    value: '${report.currency} ${report.totalExpense.toStringAsFixed(2)}',
                    color: Colors.red,
                  ),
                  _SummaryRow(
                    label: 'Net Balance',
                    value: '${report.currency} ${report.netBalance.toStringAsFixed(2)}',
                    color: report.netBalance >= 0 ? Colors.green : Colors.red,
                    bold: true,
                  ),
                  const SizedBox(height: 16),

                  // Transactions list
                  Text(
                    'Transactions (${report.transactionCount})',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ...report.transactions.map((tx) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: tx.type == 'income'
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          child: Icon(
                            tx.type == 'income'
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            size: 16,
                            color: tx.type == 'income'
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        title: Text(tx.description,
                            style: const TextStyle(fontSize: 14)),
                        subtitle: Text('${tx.date} · ${tx.category}',
                            style: const TextStyle(fontSize: 12)),
                        trailing: Text(
                          '${tx.currency} ${tx.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: tx.type == 'income'
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      )),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _runSmsDebug(BuildContext context) async {
    final results = <String>[];
    results.add('=== SMS DEBUG START ===\n');

    // ── CHECK 1: Permissions ──
    results.add('--- CHECK 1: Permissions ---');
    try {
      final telephony = Telephony.instance;
      final telePerm = await telephony.requestSmsPermissions;
      results.add('another_telephony permission: ${telePerm ?? "null"}');
    } catch (e) {
      results.add('another_telephony permission ERROR: $e');
    }
    try {
      final status = await Permission.sms.status;
      results.add('permission_handler READ_SMS: ${status.isGranted}');
    } catch (e) {
      results.add('permission_handler ERROR: $e');
    }
    try {
      final recv = await Permission.sms.status;
      results.add('permission_handler SMS status: $recv');
    } catch (e) {
      results.add('RECEIVE_SMS check ERROR: $e');
    }
    results.add('');

    // ── CHECK 2: Read Inbox ──
    results.add('--- CHECK 2: Read Inbox ---');
    int inboxCount = 0;
    List<SmsMessage> todaySms = [];
    try {
      final telephony = Telephony.instance;
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final allSms = await telephony.getInboxSms(
        columns: [SmsColumn.ID, SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        filter: SmsFilter.where(SmsColumn.DATE).greaterThan(
          startOfDay.millisecondsSinceEpoch.toString(),
        ),
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );
      inboxCount = allSms.length;
      results.add('Total SMS from today: $inboxCount');
      todaySms = allSms;
      // Show first 5 raw messages
      final show = allSms.take(5).toList();
      for (int i = 0; i < show.length; i++) {
        final s = show[i];
        results.add('  [$i] From: ${s.address}');
        results.add('       Body: ${(s.body ?? "null").substring(0, (s.body?.length ?? 0).clamp(0, 120))}');
      }
      if (allSms.isEmpty) {
        results.add('  (No SMS found from today)');
      }
    } catch (e) {
      results.add('Inbox read ERROR: $e');
    }
    results.add('');

    // ── CHECK 3: Bank Identification ──
    results.add('--- CHECK 3: Bank Identification ---');
    try {
      await BankIdentifier.load();
      int identified = 0;
      for (final sms in todaySms) {
        final bank = await BankIdentifier.identify(sms.address, sms.body ?? '');
        if (bank != null) {
          identified++;
          results.add('  From ${sms.address} → $bank');
        }
      }
      results.add('Identified: $identified / ${todaySms.length}');
      if (identified == 0 && todaySms.isNotEmpty) {
        results.add('  (None matched any bank sender or keyword)');
        // Show addresses for debugging
        final addrs = todaySms.map((s) => s.address).toSet();
        results.add('  Unique senders: ${addrs.join(", ")}');
      }
    } catch (e) {
      results.add('Bank identification ERROR: $e');
    }
    results.add('');

    // ── CHECK 4: Parser ──
    results.add('--- CHECK 4: Parser ---');
    try {
      int parsed = 0;
      for (final sms in todaySms) {
        final bank = await BankIdentifier.identify(sms.address, sms.body ?? '');
        if (bank == null) continue;
        ParsedBankSms? result;
        switch (bank) {
          case 'Telebirr':
            result = TelebirrSmsParser.parse(sms.body ?? '');
            break;
          case 'CBE':
            result = CbeSmsParser.parse(sms.body ?? '');
            break;
          case 'Awash':
            result = AwashSmsParser.parse(sms.body ?? '');
            break;
        }
        if (result != null) {
          parsed++;
          results.add('  ${result.bankName} → ${result.direction} Br${result.amount}');
        } else {
          results.add('  $bank parse FAILED: ${(sms.body ?? "").substring(0, (sms.body?.length ?? 0).clamp(0, 80))}');
        }
      }
      results.add('Parsed: $parsed');
    } catch (e) {
      results.add('Parser ERROR: $e');
    }
    results.add('');

    // ── CHECK 5: Database ──
    results.add('--- CHECK 5: Database ---');
    try {
      final txCount = await RepositoryProvider.transaction.getThisWeek();
      results.add('Transactions this week: ${txCount.length}');
      final failedCount = await FailedParseLog.count();
      results.add('Failed parses logged: $failedCount');
      if (failedCount > 0) {
        final failures = await FailedParseLog.getAll();
        for (final f in failures.take(3)) {
          results.add('  Reason: ${f.reason} | Sender: ${f.sender}');
          results.add('  SMS: ${f.rawSms.substring(0, (f.rawSms.length).clamp(0, 80))}');
        }
      }
    } catch (e) {
      results.add('Database ERROR: $e');
    }
    results.add('');
    results.add('=== SMS DEBUG END ===');

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('SMS Debug Results'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(
              results.join('\n'),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Small helper widgets
// ────────────────────────────────────────────────────────────────────────────

class _DatePickerRow extends StatelessWidget {
  final String label;
  final DateTime? date;
  final ValueChanged<DateTime> onPick;

  const _DatePickerRow({
    required this.label,
    required this.date,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(label,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) onPick(picked);
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                date != null
                    ? '${date!.day}/${date!.month}/${date!.year}'
                    : 'Any',
                style: TextStyle(
                  color: date != null ? Colors.black87 : Colors.grey,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(label),
        backgroundColor:
            selected ? const Color(0xFF0A8E48) : Colors.grey.shade200,
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontWeight:
              selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}