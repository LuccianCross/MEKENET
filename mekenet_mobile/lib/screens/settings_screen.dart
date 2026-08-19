/// lib/screens/settings_screen.dart
///
/// Settings screen — updated to include:
///   1. Sync toggle — opt-in, stored in SharedPreferences via SyncService.
///   2. Export Report — calls MekenetApiClient.exportReport() and shows
///      a formatted bottom sheet with real backend data.

import 'package:flutter/material.dart';

import '../api_client/mekenet_api_client.dart';
import '../models/export_report.dart';
import '../services/sync_service.dart';

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

                  // Version tile
                  const ListTile(
                    leading:
                        Icon(Icons.info_outline, color: Color(0xFF0A8E48)),
                    title: Text('Version'),
                    subtitle: Text('Mekenet v0.1.0'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
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