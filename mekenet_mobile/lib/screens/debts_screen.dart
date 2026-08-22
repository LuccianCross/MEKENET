import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/debt.dart';
import '../repositories/repository_provider.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  List<Debt> _debts = [];
  double _totalOwed = 0;
  bool _isLoading = true;
  String? _error;

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
      final debts = await RepositoryProvider.debt.getOpen();
      final total = debts.fold<double>(0, (sum, d) => sum + d.amount);

      if (mounted) {
        setState(() {
          _debts = debts;
          _totalOwed = total;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(L10n.instance.t('debts_title')),
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
                              L10n.instance.t('could_not_load_debts'),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _loadData,
                              child: Text(L10n.instance.t('btn_retry')),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.all(16),
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              L10n.instance.t('total_outstanding_owed'),
                              style: const TextStyle(fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              L10n.instance.formatCurrency(_totalOwed),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0A8E48),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _debts.isEmpty
                            ? ListView(
                                children: [
                                  const SizedBox(height: 60),
                                  Center(
                                    child: Column(
                                      children: [
                                        Icon(Icons.people_outline, size: 50, color: Colors.grey[300]),
                                        const SizedBox(height: 12),
                                        Text(
                                          L10n.instance.t('no_debts_recorded'),
                                          style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          L10n.instance.t('tap_plus_to_add_debt'),
                                          style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _debts.length,
                                itemBuilder: (context, index) {
                                  final debt = _debts[index];
                                  return _buildDebtTile(debt);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDebtTile(Debt debt) {
    final isPaid = debt.status == 'paid';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isPaid
            ? Border.all(color: const Color(0xFF0A8E48), width: 1.5)
            : null,
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
            backgroundColor: isPaid
                ? const Color(0xFF0A8E48).withValues(alpha: 0.1)
                : const Color(0xFFFF8F00).withValues(alpha: 0.1),
            child: Icon(
              isPaid ? Icons.check : Icons.person,
              color: isPaid ? const Color(0xFF0A8E48) : const Color(0xFFFF8F00),
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
                  isPaid
                      ? L10n.instance.t('status_paid')
                      : L10n.instance.formatDueDateLabel(debt.createdAt),
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
                L10n.instance.formatCurrency(debt.amount),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isPaid ? const Color(0xFF0A8E48) : const Color(0xFFFF8F00),
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
                          L10n.instance.t('btn_mark_paid'),
                          style: const TextStyle(
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
                        L10n.instance.t('btn_delete'),
                        style: const TextStyle(
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
  Future<void> _markAsPaid(Debt debt) async {
    try {
      final updated = Debt(
        id: debt.id,
        customerName: debt.customerName,
        amount: debt.amount,
        status: 'paid',
        createdAt: debt.createdAt,
      );
      await RepositoryProvider.debt.update(updated);
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              L10n.instance.t('msg_error_generic', {'error': e}),
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteDebt(Debt debt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(L10n.instance.t('dialog_delete_debt_title')),
        content: Text(
          L10n.instance.t('dialog_delete_debt_msg', {
            'name': debt.customerName,
            'amount': L10n.instance.formatCurrency(debt.amount),
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(L10n.instance.t('btn_cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              L10n.instance.t('btn_delete'),
              style: const TextStyle(color: Colors.red),
            ),
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
            SnackBar(
              content: Text(
                L10n.instance.t('msg_error_generic', {'error': e}),
              ),
            ),
          );
        }
      }
    }
  }

  void _showAddDebtSheet(BuildContext context) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
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
              Text(
                L10n.instance.t('add_debt_sheet_title'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: L10n.instance.t('hint_person_name'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: L10n.instance.t('hint_debt_amount'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.money),
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
                        SnackBar(content: Text(L10n.instance.t('val_fill_all_fields'))),
                      );
                      return;
                    }

                    final debt = Debt(
                      customerName: name,
                      amount: amount,
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
                  child: Text(L10n.instance.t('btn_save')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}