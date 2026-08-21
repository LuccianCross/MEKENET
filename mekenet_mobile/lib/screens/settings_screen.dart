/// lib/screens/settings_screen.dart
///
/// Settings screen — updated to include:
///   1. Sync toggle — opt-in, stored in SharedPreferences via SyncService.
///   2. Export Report — calls MekenetApiClient.exportReport() and shows
///      a formatted bottom sheet with real backend data.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:another_telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api_client/mekenet_api_client.dart';
import '../models/export_report.dart';
import '../services/category_service.dart';
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
    // Load saved server URL
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('server_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      MekenetApiClient.baseUrl = savedUrl;
    }
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
        title: const Text('Settings'),
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
            // Privacy card (unchanged from original)
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
                      Icon(
                        Icons.shield,
                        color: const Color(0xFF0A8E48),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Your data stays on your device',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your financial records are 100% private. '
                    'All SMS processing happens securely on your phone '
                    'without sending details to any server.',
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
                              const SnackBar(
                                content: Text('Access allowed!'),
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
                          child: const Text('Allow Access'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Not now'),
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
                  // Privacy tile
                  const ListTile(
                    leading: Icon(Icons.lock_outline, color: Color(0xFF0A8E48)),
                    title: Text('Privacy'),
                    subtitle: Text('Your data stays on your device'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                  const Divider(height: 1),

                  // Offline mode tile
                  const ListTile(
                    leading: Icon(Icons.cloud_off, color: Color(0xFF0A8E48)),
                    title: Text('Offline Mode'),
                    subtitle: Text('Works without internet'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                  const Divider(height: 1),

                  // ── Sync toggle ──────────────────────────────────────────
                  ListTile(
                    leading: const Icon(Icons.sync, color: Color(0xFF0A8E48)),
                    title: const Text('Sync to cloud'),
                    subtitle: Text(
                      _syncEnabled
                          ? 'Transactions will be backed up'
                          : 'Only stored on this device',
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

                  // ── Server URL tile (only when sync is ON) ─────────────
                  if (_syncEnabled) ...[
                    ListTile(
                      leading: const Icon(Icons.dns, color: Color(0xFF0A8E48)),
                      title: const Text('Server URL'),
                      subtitle: Text(MekenetApiClient.baseUrl),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _showServerUrlDialog(context),
                    ),
                    const Divider(height: 1),
                  ],

                  // ── Export Data tile ─────────────────────────────────────
                  ListTile(
                    leading: const Icon(Icons.upload_file,
                        color: Color(0xFF0A8E48)),
                    title: const Text('Export Report'),
                    subtitle: const Text('Send report to bank'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showExportDialog(context),
                  ),
                  const Divider(height: 1),

                  // ── Manage Categories tile ───────────────────────────────
                  ListTile(
                    leading: const Icon(Icons.category,
                        color: Color(0xFF0A8E48)),
                    title: const Text('Manage Categories'),
                    subtitle: const Text('Add or remove expense categories'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showCategoryManager(context),
                  ),
                  const Divider(height: 1),

                  // Version tile
                  const ListTile(
                    leading:
                        Icon(Icons.info_outline, color: Color(0xFF0A8E48)),
                    title: Text('Version'),
                    subtitle: Text('Mekenet v0.1.0'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                  const Divider(height: 1),

                  // ── Change PIN tile ─────────────────────────────────────
                  ListTile(
                    leading: const Icon(Icons.lock_reset, color: Color(0xFF0A8E48)),
                    title: const Text('Change PIN'),
                    subtitle: const Text('Update your security PIN'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showChangePinDialog(context),
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

    try {
      // Build report from local SQLite (works offline)
      final start = fromDate ?? DateTime(2020);
      final end = toDate != null
          ? toDate.add(const Duration(days: 1))
          : DateTime.now().add(const Duration(days: 1));

      final transactions = await RepositoryProvider.transaction
          .getByDateRange(start, end);

      final report = ExportReport.buildLocal(
        transactions: transactions,
        fromDate: fromDate,
        toDate: toDate,
        type: type,
      );

      if (!context.mounted) return;
      Navigator.pop(context); // close loading

      if (report.transactionCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No transactions found for the selected period.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      _showReportSheet(context, report);
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating report: $e')),
      );
    }
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Financial Report',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: () => _copyReportToClipboard(context, report),
                            tooltip: 'Copy to clipboard',
                          ),
                          IconButton(
                            icon: const Icon(Icons.share, size: 20),
                            onPressed: () => _shareReport(context, report),
                            tooltip: 'Share report',
                          ),
                        ],
                      ),
                    ],
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

                  // Export buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _shareReport(context, report),
                          icon: const Icon(Icons.share),
                          label: const Text('Share'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _saveCsvToFile(context, report),
                          icon: const Icon(Icons.save_alt),
                          label: const Text('Save CSV'),
                        ),
                      ),
                    ],
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

  String _generateReportText(ExportReport report) {
    final buffer = StringBuffer();
    buffer.writeln('=== Mekenet Financial Report ===');
    buffer.writeln('Generated: ${report.generatedAt.substring(0, 10)}');
    buffer.writeln('');
    buffer.writeln('--- Summary ---');
    buffer.writeln('Total Income: ${report.currency} ${report.totalIncome.toStringAsFixed(2)}');
    buffer.writeln('Total Expense: ${report.currency} ${report.totalExpense.toStringAsFixed(2)}');
    buffer.writeln('Net Balance: ${report.currency} ${report.netBalance.toStringAsFixed(2)}');
    buffer.writeln('');
    buffer.writeln('--- Transactions (${report.transactionCount}) ---');
    for (final tx in report.transactions) {
      buffer.writeln('${tx.date} | ${tx.type.toUpperCase()} | ${tx.currency} ${tx.amount.toStringAsFixed(2)} | ${tx.description} | ${tx.category}');
    }
    return buffer.toString();
  }

  String _generateCsv(ExportReport report) {
    final buffer = StringBuffer();
    buffer.writeln('Date,Type,Amount,Currency,Description,Category');
    for (final tx in report.transactions) {
      buffer.writeln('${tx.date},${tx.type},${tx.amount.toStringAsFixed(2)},${tx.currency},"${tx.description}",${tx.category}');
    }
    return buffer.toString();
  }

  void _copyReportToClipboard(BuildContext context, ExportReport report) {
    final text = _generateReportText(report);
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report copied to clipboard'),
        backgroundColor: Color(0xFF0A8E48),
      ),
    );
  }

  void _shareReport(BuildContext context, ExportReport report) {
    final text = _generateReportText(report);
    Share.share(text, subject: 'Mekenet Financial Report');
  }

  Future<void> _saveCsvToFile(BuildContext context, ExportReport report) async {
    try {
      final csv = _generateCsv(report);
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().substring(0, 10);
      final file = File('${directory.path}/mekenet_report_$timestamp.csv');
      await file.writeAsString(csv);

      if (context.mounted) {
        // Close the report sheet first
        Navigator.of(context).pop();
        // Small delay to let the sheet close
        await Future.delayed(const Duration(milliseconds: 200));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved: ${file.path.split('/').last}'),
              backgroundColor: const Color(0xFF0A8E48),
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Open',
                textColor: Colors.white,
                onPressed: () async {
                  // Open the file with the platform's default handler
                  await Process.run('open', [directory.path]);
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving file: $e')),
        );
      }
    }
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _showServerUrlDialog(BuildContext context) {
    final controller = TextEditingController(text: MekenetApiClient.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Server URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'http://192.168.1.100:8000',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                setState(() {
                  MekenetApiClient.baseUrl = url;
                });
                // Persist the URL
                SharedPreferences.getInstance().then((prefs) {
                  prefs.setString('server_url', url);
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Server URL updated to $url'),
                    backgroundColor: const Color(0xFF0A8E48),
                  ),
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: Color(0xFF0A8E48))),
          ),
        ],
      ),
    );
  }

  Future<void> _showCategoryManager(BuildContext context) async {
    final catService = CategoryService.instance;
    final initialCategories = await catService.getCategories();
    final initialUsage = await catService.getUsageStats();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6,
              maxChildSize: 0.9,
              builder: (_, controller) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: ListView(
                    controller: controller,
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
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Manage Categories',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Color(0xFF0A8E48)),
                            onPressed: () async {
                              final added = await _addCategory(ctx, catService);
                              if (added) {
                                final updated = await catService.getCategories();
                                setModalState(() {});
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to add custom categories',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<List<String>>(
                        future: catService.getCategories(),
                        builder: (snap, catList) {
                          final cats = catList.data ?? [];
                          return FutureBuilder<Map<String, int>>(
                            future: catService.getUsageStats(),
                            builder: (snap2, usageMap) {
                              final usage = usageMap.data ?? {};
                              return Column(
                                children: cats.map((cat) {
                                  final count = usage[cat] ?? 0;
                                  final isDefault = CategoryService.defaultCategories.contains(cat);
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: const Color(0xFF0A8E48).withValues(alpha: 0.1),
                                      child: Text(
                                        cat.substring(0, 1).toUpperCase(),
                                        style: const TextStyle(color: Color(0xFF0A8E48), fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    title: Text(cat),
                                    subtitle: count > 0 ? Text('Used $count times') : null,
                                    trailing: isDefault
                                        ? const Icon(Icons.lock_outline, size: 18, color: Colors.grey)
                                        : IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                            onPressed: () async {
                                              await catService.removeCategory(cat);
                                              setModalState(() {});
                                            },
                                          ),
                                  );
                                }).toList(),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<bool> _addCategory(BuildContext ctx, CategoryService catService) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Delivery',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, controller.text.trim()),
            child: const Text('Add', style: TextStyle(color: Color(0xFF0A8E48))),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await catService.addCategory(result);
      return true;
    }
    return false;
  }

  void _showChangePinDialog(BuildContext context) {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: const InputDecoration(
                hintText: 'Current PIN',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: newPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: const InputDecoration(
                hintText: 'New PIN',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: const InputDecoration(
                hintText: 'Confirm new PIN',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final oldPin = oldPinController.text.trim();
              final newPin = newPinController.text.trim();
              final confirmPin = confirmPinController.text.trim();

              if (oldPin.length != 4 || newPin.length != 4) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('PIN must be 4 digits')),
                );
                return;
              }
              if (newPin != confirmPin) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('New PINs do not match')),
                );
                return;
              }

              // Verify old PIN
              final secureStorage = FlutterSecureStorage();
              final storedHash = await secureStorage.read(key: 'mekenet_pin_hash');
              final bytes = utf8.encode(oldPin);
              final digest = sha256.convert(bytes);
              if (digest.toString() != storedHash) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Current PIN is incorrect')),
                  );
                }
                return;
              }

              // Save new PIN
              final newBytes = utf8.encode(newPin);
              final newHash = sha256.convert(newBytes);
              await secureStorage.write(key: 'mekenet_pin_hash', value: newHash.toString());

              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN updated successfully'),
                    backgroundColor: Color(0xFF0A8E48),
                  ),
                );
              }
            },
            child: const Text('Update', style: TextStyle(color: Color(0xFF0A8E48))),
          ),
        ],
      ),
    );
  }

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