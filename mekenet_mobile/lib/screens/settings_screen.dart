/// lib/screens/settings_screen.dart
///
/// Settings screen — updated to include:
///   1. Sync toggle — opt-in, stored in SharedPreferences via SyncService.
///   2. Export Report — calls MekenetApiClient.exportReport() and shows
///      a formatted bottom sheet with real backend data.

import 'package:flutter/material.dart';
import 'package:another_telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';

import '../l10n/l10n.dart';
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
  bool _syncEnabled = false;
  bool _loadingSync = true;

  @override
  void initState() {
    super.initState();
    _loadSyncPreference();
  }

  Future<void> _loadSyncPreference() async {
    final enabled = await SyncService.instance.isSyncEnabled();
    if (mounted) {
      setState(() {
        _syncEnabled = enabled;
        _loadingSync = false;
      });
    }
  }

  Future<void> _toggleSync(bool value) async {
    await SyncService.instance.setSyncEnabled(value);
    setState(() => _syncEnabled = value);

    // If just enabled, retry any pending unsynced transactions
    if (value) {
      SyncService.instance.retryUnsynced();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(L10n.instance.t('settings_title')),
        backgroundColor: const Color(0xFF0A8E48),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------------------------------------------------------
            // Privacy card
            // ------------------------------------------------------------------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.08),
                    spreadRadius: 1,
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.shield,
                        color: Color(0xFF0A8E48),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          L10n.instance.t('privacy_card_title'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    L10n.instance.t('privacy_card_desc'),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  L10n.instance.t('access_allowed_msg'),
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A8E48),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(L10n.instance.t('btn_allow_access')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(L10n.instance.t('btn_not_now')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ------------------------------------------------------------------
            // Settings list
            // ------------------------------------------------------------------
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.05),
                    spreadRadius: 1,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // ── Language tile ─────────────────────────────────────────
                  ListTile(
                    leading: const Icon(Icons.language, color: Color(0xFF0A8E48)),
                    title: Text(L10n.instance.t('setting_language')),
                    subtitle: Text(L10n.instance.t('setting_language_sub')),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showLanguageSelector(context),
                  ),
                  const Divider(height: 1),

                  // Privacy tile
                  ListTile(
                    leading: const Icon(Icons.lock_outline, color: Color(0xFF0A8E48)),
                    title: Text(L10n.instance.t('setting_privacy')),
                    subtitle: Text(L10n.instance.t('setting_privacy_sub')),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                  const Divider(height: 1),

                  // Offline mode tile
                  ListTile(
                    leading: const Icon(Icons.cloud_off, color: Color(0xFF0A8E48)),
                    title: Text(L10n.instance.t('setting_offline_mode')),
                    subtitle: Text(L10n.instance.t('setting_offline_mode_sub')),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                  const Divider(height: 1),
                  // ── Sync toggle ──────────────────────────────────────────
                  ListTile(
                    leading: const Icon(Icons.sync, color: Color(0xFF0A8E48)),
                    title: Text(L10n.instance.t('setting_sync')),
                    subtitle: Text(
                      _syncEnabled
                          ? L10n.instance.t('setting_sync_sub_on')
                          : L10n.instance.t('setting_sync_sub_off'),
                    ),
                    trailing: _loadingSync
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Switch(
                            value: _syncEnabled,
                            onChanged: _toggleSync,
                            activeColor: const Color(0xFF0A8E48),
                          ),
                  ),
                  const Divider(height: 1),

                  // ── Export Data tile ─────────────────────────────────────
                  ListTile(
                    leading: const Icon(Icons.upload_file,
                        color: Color(0xFF0A8E48)),
                    title: Text(L10n.instance.t('setting_export')),
                    subtitle: Text(L10n.instance.t('setting_export_sub')),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showExportDialog(context),
                  ),
                  const Divider(height: 1),

                  // Version tile
                  ListTile(
                    leading:
                        const Icon(Icons.info_outline, color: Color(0xFF0A8E48)),
                    title: Text(L10n.instance.t('setting_version')),
                    subtitle: Text(L10n.instance.t('setting_version_sub')),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                  const Divider(height: 1),

                  // Debug SMS tile
                  ListTile(
                    leading: const Icon(Icons.bug_report, color: Colors.orange),
                    title: Text(L10n.instance.t('setting_debug_sms')),
                    subtitle: Text(L10n.instance.t('setting_debug_sms_sub')),
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
  // Language Selector Modal
  // --------------------------------------------------------------------------
  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Text(
                L10n.instance.t('select_language_title'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.language, color: Color(0xFF0A8E48)),
                title: Text(L10n.instance.t('lang_english')),
                trailing: L10n.instance.currentLanguageCode == 'en'
                    ? const Icon(Icons.check, color: Color(0xFF0A8E48))
                    : null,
                onTap: () async {
                  await L10n.instance.setLocale('en');
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.language, color: Color(0xFF0A8E48)),
                title: Text(L10n.instance.t('lang_amharic')),
                trailing: L10n.instance.currentLanguageCode == 'am'
                    ? const Icon(Icons.check, color: Color(0xFF0A8E48))
                    : null,
                onTap: () async {
                  await L10n.instance.setLocale('am');
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
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
                  Text(
                    L10n.instance.t('export_dialog_title'),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  // From date
                  _DatePickerRow(
                    label: L10n.instance.t('filter_from'),
                    date: fromDate,
                    onPick: (d) => setModalState(() => fromDate = d),
                  ),
                  const SizedBox(height: 12),

                  // To date
                  _DatePickerRow(
                    label: L10n.instance.t('filter_to'),
                    date: toDate,
                    onPick: (d) => setModalState(() => toDate = d),
                  ),
                  const SizedBox(height: 16),

                  // Type filter
                  Text(L10n.instance.t('filter_type'),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _FilterChip(
                        label: L10n.instance.t('filter_type_all'),
                        selected: typeFilter == null,
                        onTap: () => setModalState(() => typeFilter = null),
                      ),
                      _FilterChip(
                        label: L10n.instance.t('filter_type_income'),
                        selected: typeFilter == 'income',
                        onTap: () =>
                            setModalState(() => typeFilter = 'income'),
                      ),
                      _FilterChip(
                        label: L10n.instance.t('filter_type_expense'),
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
                      label: Text(L10n.instance.t('btn_get_report')),
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
        SnackBar(
          content: Text(
            L10n.instance.t('msg_could_not_fetch_report'),
          ),
          duration: const Duration(seconds: 4),
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
                  Text(
                    L10n.instance.t('report_sheet_title'),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    L10n.instance.t('report_generated', {
                      'date': report.generatedAt.substring(0, 10),
                    }),
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 20),

                  // Summary cards
                  _SummaryRow(
                    label: L10n.instance.t('report_total_income'),
                    value: L10n.instance.formatCurrencyDecimal(report.totalIncome),
                    color: Colors.green,
                  ),
                  _SummaryRow(
                    label: L10n.instance.t('report_total_expense'),
                    value: L10n.instance.formatCurrencyDecimal(report.totalExpense),
                    color: Colors.red,
                  ),
                  _SummaryRow(
                    label: L10n.instance.t('report_net_balance'),
                    value: L10n.instance.formatCurrencyDecimal(report.netBalance),
                    color: report.netBalance >= 0 ? Colors.green : Colors.red,
                    bold: true,
                  ),
                  const SizedBox(height: 16),
                  // Transactions list
                  Text(
                    L10n.instance.t('report_transactions_count', {
                      'count': report.transactionCount,
                    }),
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
                        subtitle: Text('${tx.date} · ${L10n.instance.translateCategory(tx.category)}',
                            style: const TextStyle(fontSize: 12)),
                        trailing: Text(
                          L10n.instance.formatCurrencyDecimal(tx.amount),
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
        title: Text(L10n.instance.t('sms_debug_title')),
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
            child: Text(L10n.instance.t('btn_close')),
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
                    : L10n.instance.t('filter_any'),
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