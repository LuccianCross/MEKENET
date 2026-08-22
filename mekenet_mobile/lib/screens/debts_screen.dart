import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/debt.dart';
import '../repositories/repository_provider.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  List<Debt> _owedToMe = [];
  List<Debt> _iOwe = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        RepositoryProvider.debt.getOpenByType('owed_to_me'),
        RepositoryProvider.debt.getOpenByType('i_owe'),
      ]);

      if (mounted) {
        setState(() {
          _owedToMe = results[0];
          _iOwe = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _refreshSilently() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      final results = await Future.wait([
        RepositoryProvider.debt.getOpenByType('owed_to_me'),
        RepositoryProvider.debt.getOpenByType('i_owe'),
      ]);
      if (mounted) {
        setState(() {
          _owedToMe = results[0];
          _iOwe = results[1];
        });
      }
    } catch (_) {}
    _isRefreshing = false;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final currentList = _selectedTab == 0 ? _owedToMe : _iOwe;
    final totalOwedToMe = _owedToMe.fold<double>(0, (s, d) => s + d.amount);
    final totalIOwe = _iOwe.fold<double>(0, (s, d) => s + d.amount);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(loc.t('debts')),
        backgroundColor: const Color(0xFF0A8E48),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDebtSheet(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ListView(
                  children: [
                    const SizedBox(height: 120),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline, size: 50, color: Colors.red),
                            const SizedBox(height: 12),
                            Text(
                              loc.t('couldNotLoadData'),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _loadData,
                              child: Text(loc.t('retry')),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    // Summary cards
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSummaryTile(
                              loc.t('owedToMe'),
                              totalOwedToMe,
                              const Color(0xFF0A8E48),
                              Icons.arrow_downward,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildSummaryTile(
                              loc.t('iOwe'),
                              totalIOwe,
                              const Color(0xFFE53935),
                              Icons.arrow_upward,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Tabs
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          Expanded(child: _buildTab(0, '${loc.t('owedToMe')} (${_owedToMe.length})')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildTab(1, '${loc.t('iOwe')} (${_iOwe.length})')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: currentList.isEmpty
                          ? ListView(
                              children: [
                                const SizedBox(height: 60),
                                Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.people_outline, size: 50, color: Colors.grey[300]),
                                      const SizedBox(height: 12),
                                      Text(
                                        _selectedTab == 0
                                            ? loc.t('noOneOwesYouYet')
                                            : loc.t('youDontOweAnyone'),
                                        style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        loc.t('tapPlusToAdd'),
                                        style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : RefreshIndicator(
                              onRefresh: _refreshSilently,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: currentList.length,
                                itemBuilder: (context, index) {
                                  final debt = currentList[index];
                                  return _buildDebtTile(debt);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSummaryTile(String label, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Br${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    final isSelected = _selectedTab == index;
    final color = index == 0 ? const Color(0xFF0A8E48) : const Color(0xFFE53935);
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: color, width: 1.5) : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? color : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDebtTile(Debt debt) {
    final isPaid = debt.status == 'paid';
    final isIOwe = debt.type == 'i_owe';
    final color = isIOwe ? const Color(0xFFE53935) : const Color(0xFFFF8F00);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(
              isPaid ? Icons.check : (isIOwe ? Icons.arrow_upward : Icons.person),
              color: isPaid ? const Color(0xFF0A8E48) : color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  debt.customerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  isPaid ? AppLocalizations.of(context).t('paid') : _formatDueDate(debt.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: isPaid ? const Color(0xFF0A8E48) : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Br${debt.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isPaid ? const Color(0xFF0A8E48) : color,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isPaid)
                    GestureDetector(
                      onTap: () => _markAsPaid(debt),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A8E48).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          AppLocalizations.of(context).t('markPaid'),
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF0A8E48),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _deleteDebt(debt),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        AppLocalizations.of(context).t('delete'),
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFFE53935),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDueDate(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt).inDays;
    if (difference == 0) return AppLocalizations.of(context).t('addedToday');
    if (difference == 1) return AppLocalizations.of(context).t('addedYesterday');
    return '$difference ${AppLocalizations.of(context).t('addedDaysAgo')}';
  }

  Future<void> _markAsPaid(Debt debt) async {
    try {
      final updated = Debt(
        id: debt.id,
        customerName: debt.customerName,
        amount: debt.amount,
        status: 'paid',
        type: debt.type,
        createdAt: debt.createdAt,
      );
      await RepositoryProvider.debt.update(updated);
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteDebt(Debt debt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).t('deleteDebt')),
        content: Text('Remove ${debt.customerName}\'s debt of Br${debt.amount.toStringAsFixed(0)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context).t('cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context).t('delete'), style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await RepositoryProvider.debt.delete(debt.id);
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  void _showAddDebtSheet(BuildContext context) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    String selectedType = 'owed_to_me';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(ctx).t('addDebtTitle'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  // Type selector
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setSheetState(() => selectedType = 'owed_to_me'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedType == 'owed_to_me'
                                  ? const Color(0xFF0A8E48).withValues(alpha: 0.1)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: selectedType == 'owed_to_me'
                                  ? Border.all(color: const Color(0xFF0A8E48), width: 1.5)
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                AppLocalizations.of(ctx).t('owesMe'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: selectedType == 'owed_to_me'
                                      ? const Color(0xFF0A8E48)
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setSheetState(() => selectedType = 'i_owe'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedType == 'i_owe'
                                  ? const Color(0xFFE53935).withValues(alpha: 0.1)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: selectedType == 'i_owe'
                                  ? Border.all(color: const Color(0xFFE53935), width: 1.5)
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                AppLocalizations.of(ctx).t('iOwe'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: selectedType == 'i_owe'
                                      ? const Color(0xFFE53935)
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(ctx).t('personsName'),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(ctx).t('amountBr'),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.money),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        final amount = double.tryParse(amountController.text.trim());

                        if (name.isEmpty || amount == null || amount <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text(AppLocalizations.of(ctx).t('pleaseFillAllFields'))),
                          );
                          return;
                        }

                        final debt = Debt(
                          customerName: name,
                          amount: amount,
                          type: selectedType,
                        );

                        await RepositoryProvider.debt.save(debt);
                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A8E48),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(AppLocalizations.of(ctx).t('save')),
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
}
